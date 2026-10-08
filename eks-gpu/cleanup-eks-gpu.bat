@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM ============================================================
REM CONFIG
REM ============================================================
set "REGION=eu-central-1"
set "CLUSTER=eks-gpu"
set "NODEGROUP=eks-gpu-small"
set "VPC_NAME=eks-gpu-dev"

REM Bootstrap backend created by .github/workflows/terraform-bootstrap.yml
set "STATE_BUCKET=eks-gpu-state"
set "LOCK_TABLE=eks-gpu-dev-lock"

REM Terraform naming from eks-gpu-modules
set "CLUSTER_ROLE=eks-cluster-cluster-role"
set "WORKER_ROLE=eks-cluster-worker-role"
set "VPC_CNI_ROLE=eks-cluster-vpc-cni"
set "LBC_ROLE=eks-cluster-lbc"
set "EXTDNS_ROLE=eks-cluster-ext-dns"
set "EBS_CSI_ROLE=eks-cluster-ebs-csi"

set "LBC_POLICY=eks-cluster-AWSLoadBalancerControllerIAMPolicy"
set "EXTDNS_POLICY=eks-cluster-AWSExternalDnsIAMPolicy"

set "LOG_GROUP=/aws/eks/eks-cluster/cluster"
set "KMS_ALIAS=alias/eks-cluster-kms"

REM 0 = keep S3/DynamoDB bootstrap backend
REM 1 = delete backend too
set "DELETE_BACKEND=0"

echo ============================================================
echo AWS cleanup for %CLUSTER%
echo Region: %REGION%
echo VPC tag Name: %VPC_NAME%
echo DELETE_BACKEND: %DELETE_BACKEND%
echo ============================================================
echo.
echo WARNING: This script DELETES AWS resources.
echo It assumes these names belong only to this lab.
echo.
set /p "CONFIRM=Type DELETE to continue: "
if /I not "%CONFIRM%"=="DELETE" (
  echo Aborted.
  exit /b 1
)
echo.

REM ============================================================
REM BASIC IDENTITY CHECK
REM ============================================================
echo [AWS] Current identity:
aws sts get-caller-identity --no-cli-pager
if errorlevel 1 (
  echo [AWS] ERROR: unable to authenticate to AWS.
  exit /b 1
)
echo.

REM Capture this cluster's exact OIDC issuer BEFORE deleting the cluster.
set "EKS_OIDC_URL="
for /f "usebackq delims=" %%U in (`aws eks describe-cluster --name "%CLUSTER%" --region "%REGION%" --query "cluster.identity.oidc.issuer" --output text --no-cli-pager 2^>nul`) do set "EKS_OIDC_URL=%%U"
if defined EKS_OIDC_URL echo [OIDC] Captured issuer: %EKS_OIDC_URL%
echo.

REM ============================================================
REM BEST-EFFORT KUBERNETES CLEANUP
REM Removes Ingress / LoadBalancer Services / PVC before EKS.
REM ============================================================
echo [K8S] Best-effort cleanup of resources that may own AWS resources...
aws eks update-kubeconfig --name "%CLUSTER%" --region "%REGION%" >nul 2>&1
kubectl get nodes >nul 2>&1
if errorlevel 1 (
  echo [K8S] Cluster API not reachable - skipping Kubernetes cleanup.
) else (
  echo [K8S] Deleting all Ingresses...
  kubectl delete ingress --all -A --ignore-not-found=true >nul 2>&1

  echo [K8S] Deleting LoadBalancer Services...
  for /f "tokens=1,2" %%N in ('kubectl get svc -A --field-selector spec.type^=LoadBalancer -o custom-columns^=NS:.metadata.namespace,NAME:.metadata.name --no-headers 2^>nul') do (
    echo [K8S] Delete service %%N/%%O
    kubectl delete svc "%%O" -n "%%N" --ignore-not-found=true >nul 2>&1
  )

  echo [K8S] Deleting PVCs...
  kubectl delete pvc --all -A --ignore-not-found=true >nul 2>&1

  echo [K8S] Waiting 45 seconds for LBC / ExternalDNS / CSI cleanup...
  timeout /t 45 /nobreak >nul
)
echo.

REM ============================================================
REM EKS NODE GROUP
REM ============================================================
echo [EKS] Checking node group %NODEGROUP%...
aws eks describe-nodegroup --cluster-name "%CLUSTER%" --nodegroup-name "%NODEGROUP%" --region "%REGION%" --no-cli-pager >nul 2>&1
if errorlevel 1 (
  echo [EKS] Node group does not exist.
) else (
  echo [EKS] Deleting node group %NODEGROUP%...
  aws eks delete-nodegroup --cluster-name "%CLUSTER%" --nodegroup-name "%NODEGROUP%" --region "%REGION%" --no-cli-pager >nul
  if errorlevel 1 (
    echo [EKS] ERROR deleting node group.
  ) else (
    echo [EKS] Waiting for node group deletion...
    aws eks wait nodegroup-deleted --cluster-name "%CLUSTER%" --nodegroup-name "%NODEGROUP%" --region "%REGION%"
  )
)
echo.

REM ============================================================
REM EKS CLUSTER
REM ============================================================
echo [EKS] Checking cluster %CLUSTER%...
aws eks describe-cluster --name "%CLUSTER%" --region "%REGION%" --no-cli-pager >nul 2>&1
if errorlevel 1 (
  echo [EKS] Cluster does not exist.
) else (
  echo [EKS] Deleting cluster %CLUSTER%...
  aws eks delete-cluster --name "%CLUSTER%" --region "%REGION%" --no-cli-pager >nul
  if errorlevel 1 (
    echo [EKS] ERROR during delete-cluster.
  ) else (
    echo [EKS] Waiting for cluster deletion...
    aws eks wait cluster-deleted --name "%CLUSTER%" --region "%REGION%"
  )
)
echo.

REM ============================================================
REM LAUNCH TEMPLATES
REM ============================================================
echo [LT] Checking Launch Templates eks-gpu-default-*...
for /f "usebackq delims=" %%L in (`aws ec2 describe-launch-templates --region "%REGION%" --query "LaunchTemplates[?starts_with(LaunchTemplateName, 'eks-gpu-default-')].LaunchTemplateId" --output text --no-cli-pager 2^>nul`) do (
  if not "%%L"=="" if not "%%L"=="None" (
    for %%I in (%%L) do (
      echo [LT] Deleting %%I...
      aws ec2 delete-launch-template --launch-template-id "%%I" --region "%REGION%" --no-cli-pager >nul 2>&1
    )
  )
)
echo.

REM ============================================================
REM CLOUDWATCH LOG GROUP
REM ============================================================
echo [CW] Checking %LOG_GROUP%...
aws logs describe-log-groups --log-group-name-prefix "%LOG_GROUP%" --region "%REGION%" --query "logGroups[?logGroupName=='%LOG_GROUP%'].logGroupName" --output text --no-cli-pager | findstr /x /c:"%LOG_GROUP%" >nul 2>&1
if errorlevel 1 (
  echo [CW] Log group does not exist.
) else (
  echo [CW] Deleting log group...
  aws logs delete-log-group --log-group-name "%LOG_GROUP%" --region "%REGION%" --no-cli-pager >nul
)
echo.

REM ============================================================
REM KMS
REM ============================================================
echo [KMS] Checking alias %KMS_ALIAS%...
set "KMS_KEY_ID="
for /f "usebackq delims=" %%K in (`aws kms list-aliases --region "%REGION%" --query "Aliases[?AliasName=='%KMS_ALIAS%'].TargetKeyId | [0]" --output text --no-cli-pager 2^>nul`) do set "KMS_KEY_ID=%%K"
if defined KMS_KEY_ID if not "%KMS_KEY_ID%"=="None" (
  echo [KMS] KeyId = %KMS_KEY_ID%
  aws kms delete-alias --alias-name "%KMS_ALIAS%" --region "%REGION%" --no-cli-pager >nul 2>&1
  set "KMS_STATE="
  for /f "usebackq delims=" %%S in (`aws kms describe-key --key-id "%KMS_KEY_ID%" --region "%REGION%" --query "KeyMetadata.KeyState" --output text --no-cli-pager 2^>nul`) do set "KMS_STATE=%%S"
  if "!KMS_STATE!"=="PendingDeletion" (
    echo [KMS] Key already PendingDeletion.
  ) else (
    echo [KMS] Scheduling key deletion in 7 days...
    aws kms schedule-key-deletion --key-id "%KMS_KEY_ID%" --pending-window-in-days 7 --region "%REGION%" --no-cli-pager >nul
  )
) else (
  echo [KMS] Alias not found.
)
echo.

REM ============================================================
REM EKS OIDC PROVIDER
REM Delete ONLY the OIDC provider captured from this cluster.
REM GitHub OIDC provider is never touched.
REM ============================================================
echo [OIDC] Checking exact EKS OIDC provider...
if defined EKS_OIDC_URL (
  set "EKS_OIDC_HOST=!EKS_OIDC_URL:https://=!"
  set "ACCOUNT_ID="
  for /f "usebackq delims=" %%A in (`aws sts get-caller-identity --query Account --output text --no-cli-pager 2^>nul`) do set "ACCOUNT_ID=%%A"
  set "EKS_OIDC_ARN=arn:aws:iam::!ACCOUNT_ID!:oidc-provider/!EKS_OIDC_HOST!"
  aws iam get-open-id-connect-provider --open-id-connect-provider-arn "!EKS_OIDC_ARN!" --no-cli-pager >nul 2>&1
  if errorlevel 1 (
    echo [OIDC] Exact provider not found.
  ) else (
    echo [OIDC] Deleting !EKS_OIDC_ARN!
    aws iam delete-open-id-connect-provider --open-id-connect-provider-arn "!EKS_OIDC_ARN!" --no-cli-pager >nul
  )
) else (
  echo [OIDC] Cluster issuer was not captured - skipping OIDC deletion for safety.
)
echo.

REM ============================================================
REM IAM
REM ============================================================
call :DeleteRoleWithManagedPolicy "%VPC_CNI_ROLE%" "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
call :DeleteRoleWithManagedPolicy "%EBS_CSI_ROLE%" "arn:aws:iam::aws:policy/AmazonEBSCSIDriverPolicyV2"
call :DeleteRoleWithManagedPolicy "%CLUSTER_ROLE%" "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"

echo [IAM] Checking role %WORKER_ROLE%...
aws iam get-role --role-name "%WORKER_ROLE%" --no-cli-pager >nul 2>&1
if errorlevel 1 (
  echo [IAM] %WORKER_ROLE% does not exist.
) else (
  aws iam detach-role-policy --role-name "%WORKER_ROLE%" --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy --no-cli-pager >nul 2>&1
  aws iam detach-role-policy --role-name "%WORKER_ROLE%" --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly --no-cli-pager >nul 2>&1
  aws iam delete-role --role-name "%WORKER_ROLE%" --no-cli-pager >nul
)
echo.

call :DeleteRoleWithCustomPolicy "%LBC_ROLE%" "%LBC_POLICY%"
call :DeleteRoleWithCustomPolicy "%EXTDNS_ROLE%" "%EXTDNS_POLICY%"

REM ============================================================
REM VPC / NAT / ROUTING / SUBNETS / IGW / DHCP / SG / VPC
REM ============================================================
echo [VPC] Looking for VPC Name=%VPC_NAME%...
set "VPC_ID="
for /f "usebackq delims=" %%V in (`aws ec2 describe-vpcs --filters "Name=tag:Name,Values=%VPC_NAME%" --region "%REGION%" --query "Vpcs[0].VpcId" --output text --no-cli-pager 2^>nul`) do set "VPC_ID=%%V"
if not defined VPC_ID goto AFTER_VPC
if "%VPC_ID%"=="None" goto AFTER_VPC

echo [VPC] Found %VPC_ID%
echo.

REM ----- Delete ELBv2 resources still in VPC
echo [ELB] Checking load balancers in VPC...
for /f "usebackq delims=" %%L in (`aws elbv2 describe-load-balancers --region "%REGION%" --query "LoadBalancers[?VpcId=='%VPC_ID%'].LoadBalancerArn" --output text --no-cli-pager 2^>nul`) do (
  if not "%%L"=="" if not "%%L"=="None" (
    for %%I in (%%L) do (
      echo [ELB] Deleting %%I...
      aws elbv2 delete-load-balancer --load-balancer-arn "%%I" --region "%REGION%" --no-cli-pager >nul 2>&1
    )
  )
)

echo [ELB] Waiting 30 seconds for ENI cleanup...
timeout /t 30 /nobreak >nul

echo [ELB] Checking target groups in VPC...
for /f "usebackq delims=" %%T in (`aws elbv2 describe-target-groups --region "%REGION%" --query "TargetGroups[?VpcId=='%VPC_ID%'].TargetGroupArn" --output text --no-cli-pager 2^>nul`) do (
  if not "%%T"=="" if not "%%T"=="None" (
    for %%I in (%%T) do (
      echo [ELB] Deleting target group %%I...
      aws elbv2 delete-target-group --target-group-arn "%%I" --region "%REGION%" --no-cli-pager >nul 2>&1
    )
  )
)
echo.

REM ----- NAT gateways
echo [NAT] Checking NAT Gateways...
for /f "usebackq delims=" %%N in (`aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=%VPC_ID%" --region "%REGION%" --query "NatGateways[?State!='deleted'].NatGatewayId" --output text --no-cli-pager 2^>nul`) do (
  if not "%%N"=="" if not "%%N"=="None" (
    for %%I in (%%N) do (
      echo [NAT] Deleting %%I...
      aws ec2 delete-nat-gateway --nat-gateway-id "%%I" --region "%REGION%" --no-cli-pager >nul
      aws ec2 wait nat-gateway-deleted --nat-gateway-ids "%%I" --region "%REGION%"
    )
  )
)
echo.

REM ----- Route tables
echo [RTB] Removing non-main route tables...
for /f "usebackq delims=" %%R in (`aws ec2 describe-route-tables --filters "Name=vpc-id,Values=%VPC_ID%" --region "%REGION%" --query "RouteTables[?length(Associations[?Main==`true`]) == `0`].RouteTableId" --output text --no-cli-pager 2^>nul`) do (
  if not "%%R"=="" if not "%%R"=="None" (
    for %%I in (%%R) do (
      for /f "usebackq delims=" %%A in (`aws ec2 describe-route-tables --route-table-ids "%%I" --region "%REGION%" --query "RouteTables[0].Associations[?Main==`false`].RouteTableAssociationId" --output text --no-cli-pager 2^>nul`) do (
        if not "%%A"=="" if not "%%A"=="None" (
          for %%J in (%%A) do aws ec2 disassociate-route-table --association-id "%%J" --region "%REGION%" --no-cli-pager >nul 2>&1
        )
      )
      aws ec2 delete-route-table --route-table-id "%%I" --region "%REGION%" --no-cli-pager >nul 2>&1
    )
  )
)
echo.

REM ----- Subnets
echo [SUBNET] Deleting subnets...
for /f "usebackq delims=" %%S in (`aws ec2 describe-subnets --filters "Name=vpc-id,Values=%VPC_ID%" --region "%REGION%" --query "Subnets[].SubnetId" --output text --no-cli-pager 2^>nul`) do (
  if not "%%S"=="" if not "%%S"=="None" (
    for %%I in (%%S) do (
      echo [SUBNET] Delete %%I
      aws ec2 delete-subnet --subnet-id "%%I" --region "%REGION%" --no-cli-pager >nul 2>&1
    )
  )
)
echo.

REM ----- Internet gateway
echo [IGW] Checking Internet Gateway...
set "IGW_ID="
for /f "usebackq delims=" %%G in (`aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=%VPC_ID%" --region "%REGION%" --query "InternetGateways[0].InternetGatewayId" --output text --no-cli-pager 2^>nul`) do set "IGW_ID=%%G"
if defined IGW_ID if not "%IGW_ID%"=="None" (
  aws ec2 detach-internet-gateway --internet-gateway-id "%IGW_ID%" --vpc-id "%VPC_ID%" --region "%REGION%" --no-cli-pager >nul 2>&1
  aws ec2 delete-internet-gateway --internet-gateway-id "%IGW_ID%" --region "%REGION%" --no-cli-pager >nul 2>&1
)
echo.

REM ----- DHCP options
echo [DHCP] Checking custom DHCP Options...
set "DHCP_ID="
for /f "usebackq delims=" %%D in (`aws ec2 describe-dhcp-options --filters "Name=tag:Name,Values=%VPC_NAME%" --region "%REGION%" --query "DhcpOptions[0].DhcpOptionsId" --output text --no-cli-pager 2^>nul`) do set "DHCP_ID=%%D"
if defined DHCP_ID if not "%DHCP_ID%"=="None" (
  aws ec2 associate-dhcp-options --dhcp-options-id default --vpc-id "%VPC_ID%" --region "%REGION%" --no-cli-pager >nul 2>&1
  aws ec2 delete-dhcp-options --dhcp-options-id "%DHCP_ID%" --region "%REGION%" --no-cli-pager >nul 2>&1
)
echo.

REM ----- Security groups created in VPC (except default)
echo [SG] Checking non-default Security Groups...
for /f "usebackq delims=" %%S in (`aws ec2 describe-security-groups --filters "Name=vpc-id,Values=%VPC_ID%" --region "%REGION%" --query "SecurityGroups[?GroupName!='default'].GroupId" --output text --no-cli-pager 2^>nul`) do (
  if not "%%S"=="" if not "%%S"=="None" (
    for %%I in (%%S) do (
      echo [SG] Attempting delete %%I...
      aws ec2 delete-security-group --group-id "%%I" --region "%REGION%" --no-cli-pager >nul 2>&1
    )
  )
)
echo.

REM ----- VPC
echo [VPC] Deleting %VPC_ID%...
aws ec2 delete-vpc --vpc-id "%VPC_ID%" --region "%REGION%" --no-cli-pager >nul
if errorlevel 1 (
  echo [VPC] ERROR - dependencies remain.
  echo [VPC] Remaining ENIs:
  aws ec2 describe-network-interfaces --filters "Name=vpc-id,Values=%VPC_ID%" --region "%REGION%" --query "NetworkInterfaces[].{Id:NetworkInterfaceId,Description:Description,Status:Status}" --output table --no-cli-pager
) else (
  echo [VPC] Deleted %VPC_ID%
)

:AFTER_VPC
echo.

REM ============================================================
REM OPTIONAL BOOTSTRAP BACKEND CLEANUP
REM ============================================================
if "%DELETE_BACKEND%"=="1" (
  echo [BACKEND] Deleting DynamoDB lock table...
  aws dynamodb describe-table --table-name "%LOCK_TABLE%" --region "%REGION%" --no-cli-pager >nul 2>&1
  if not errorlevel 1 (
    aws dynamodb delete-table --table-name "%LOCK_TABLE%" --region "%REGION%" --no-cli-pager >nul
    aws dynamodb wait table-not-exists --table-name "%LOCK_TABLE%" --region "%REGION%" >nul 2>&1
  )

  echo [BACKEND] Deleting versioned S3 bucket...
  aws s3api head-bucket --bucket "%STATE_BUCKET%" --region "%REGION%" --no-cli-pager >nul 2>&1
  if not errorlevel 1 (
    aws s3 rm "s3://%STATE_BUCKET%" --recursive --region "%REGION%" >nul 2>&1

    :S3_VERSION_LOOP
    set "TMPVERS=%TEMP%\eks_gpu_s3_delete_%RANDOM%.json"
    aws s3api list-object-versions --bucket "%STATE_BUCKET%" --region "%REGION%" --query "{Objects: [Versions[], DeleteMarkers[]][].{Key:Key,VersionId:VersionId}, Quiet: `true`}" --output json --no-cli-pager > "%TMPVERS%" 2>nul
    findstr /c:"\"Key\"" "%TMPVERS%" >nul 2>&1
    if not errorlevel 1 (
      aws s3api delete-objects --bucket "%STATE_BUCKET%" --delete "file://%TMPVERS%" --region "%REGION%" --no-cli-pager >nul 2>&1
      del /q "%TMPVERS%" >nul 2>&1
      goto S3_VERSION_LOOP
    )
    del /q "%TMPVERS%" >nul 2>&1
    aws s3api delete-bucket --bucket "%STATE_BUCKET%" --region "%REGION%" --no-cli-pager >nul
  )
) else (
  echo [BACKEND] Keeping %STATE_BUCKET% and %LOCK_TABLE%.
)
echo.

echo ============================================================
echo CLEANUP FINISHED
echo KMS key can remain visible as PendingDeletion for 7 days.
echo If VPC deletion failed, inspect remaining ENIs / SGs / ELBs.
echo ============================================================

endlocal
exit /b 0

REM ============================================================
REM SUBROUTINES
REM ============================================================
:DeleteRoleWithManagedPolicy
set "ROLE_NAME=%~1"
set "POLICY_ARN=%~2"
echo [IAM] Checking role %ROLE_NAME%...
aws iam get-role --role-name "%ROLE_NAME%" --no-cli-pager >nul 2>&1
if errorlevel 1 (
  echo [IAM] %ROLE_NAME% does not exist.
) else (
  aws iam detach-role-policy --role-name "%ROLE_NAME%" --policy-arn "%POLICY_ARN%" --no-cli-pager >nul 2>&1
  aws iam delete-role --role-name "%ROLE_NAME%" --no-cli-pager >nul
)
echo.
exit /b 0

:DeleteRoleWithCustomPolicy
set "ROLE_NAME=%~1"
set "POLICY_NAME=%~2"
set "POLICY_ARN="
for /f "usebackq delims=" %%P in (`aws iam list-policies --scope Local --query "Policies[?PolicyName=='%POLICY_NAME%'].Arn | [0]" --output text --no-cli-pager 2^>nul`) do set "POLICY_ARN=%%P"

echo [IAM] Checking role %ROLE_NAME%...
aws iam get-role --role-name "%ROLE_NAME%" --no-cli-pager >nul 2>&1
if not errorlevel 1 (
  if defined POLICY_ARN if not "%POLICY_ARN%"=="None" (
    aws iam detach-role-policy --role-name "%ROLE_NAME%" --policy-arn "%POLICY_ARN%" --no-cli-pager >nul 2>&1
  )
  aws iam delete-role --role-name "%ROLE_NAME%" --no-cli-pager >nul
)

if defined POLICY_ARN if not "%POLICY_ARN%"=="None" (
  echo [IAM] Removing non-default versions of %POLICY_NAME%...
  for /f "usebackq delims=" %%V in (`aws iam list-policy-versions --policy-arn "%POLICY_ARN%" --query "Versions[?IsDefaultVersion==`false`].VersionId" --output text --no-cli-pager 2^>nul`) do (
    if not "%%V"=="" if not "%%V"=="None" (
      for %%W in (%%V) do aws iam delete-policy-version --policy-arn "%POLICY_ARN%" --version-id "%%W" --no-cli-pager >nul 2>&1
    )
  )
  echo [IAM] Deleting custom policy %POLICY_NAME%...
  aws iam delete-policy --policy-arn "%POLICY_ARN%" --no-cli-pager >nul 2>&1
)
echo.
exit /b 0
