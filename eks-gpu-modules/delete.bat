@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "REGION=eu-central-1"
set "CLUSTER=eks-gpu"
set "VPC_NAME=eks-gpu-dev"
set "STATE_BUCKET=eks-gpu-dev-state"
set "LOCK_TABLE=eks-gpu-dev-lock"
set "CLUSTER_ROLE=eks-cluster-cluster-role"
set "WORKER_ROLE=eks-cluster-worker-role"
set "LOG_GROUP=/aws/eks/eks-cluster/cluster"
set "KMS_ALIAS=alias/eks-cluster-kms"

echo ============================================================
echo AWS cleanup: eks-gpu
echo This script will manualy delete all related resources to the terraform code
echo Region: %REGION%
echo ============================================================
echo.

REM ============================================================
REM EKS CLUSTER
REM ============================================================
echo [EKS] Sprawdzam cluster %CLUSTER%...
aws eks describe-cluster --name "%CLUSTER%" --region "%REGION%" --no-cli-pager >nul 2>&1
if errorlevel 1 (
    echo [EKS] MSG = nie istnieje
) else (
    echo [EKS] Usuwam cluster %CLUSTER%...
    aws eks delete-cluster --name "%CLUSTER%" --region "%REGION%" --no-cli-pager >nul
    if errorlevel 1 (
        echo [EKS] BLAD podczas delete-cluster
    ) else (
        echo [EKS] Czekam na zakonczenie usuwania...
        aws eks wait cluster-deleted --name "%CLUSTER%" --region "%REGION%"
        if errorlevel 1 (
            echo [EKS] BLAD podczas oczekiwania na usuniecie
        ) else (
            echo [EKS] OK = usunieto
        )
    )
)
echo.

REM ============================================================
REM LAUNCH TEMPLATES
REM ============================================================
echo [LT] Sprawdzam Launch Templates eks-gpu-default-*...
set "FOUND_LT=0"
for /f "usebackq delims=" %%L in (`aws ec2 describe-launch-templates --region "%REGION%" --query "LaunchTemplates[?starts_with(LaunchTemplateName, 'eks-gpu-default-')].LaunchTemplateId" --output text --no-cli-pager 2^>nul`) do (
    if not "%%L"=="" if not "%%L"=="None" (
        set "FOUND_LT=1"
        for %%I in (%%L) do (
            echo [LT] Usuwam %%I...
            aws ec2 delete-launch-template --launch-template-id "%%I" --region "%REGION%" --no-cli-pager >nul
            if errorlevel 1 (echo [LT] BLAD = %%I) else echo [LT] OK = %%I
        )
    )
)
if "!FOUND_LT!"=="0" echo [LT] MSG = nie istnieje
echo.

REM ============================================================
REM CLOUDWATCH LOG GROUP
REM ============================================================
echo [CW] Sprawdzam Log Group %LOG_GROUP%...
aws logs describe-log-groups --log-group-name-prefix "%LOG_GROUP%" --region "%REGION%" --query "logGroups[?logGroupName=='%LOG_GROUP%'].logGroupName" --output text --no-cli-pager | findstr /x /c:"%LOG_GROUP%" >nul 2>&1
if errorlevel 1 (
    echo [CW] MSG = nie istnieje
) else (
    echo [CW] Usuwam Log Group...
    aws logs delete-log-group --log-group-name "%LOG_GROUP%" --region "%REGION%" --no-cli-pager
    if errorlevel 1 (echo [CW] BLAD) else echo [CW] OK = usunieto
)
echo.

REM ============================================================
REM KMS - najpierw zapisujemy KeyId, potem kasujemy alias
REM ============================================================
echo [KMS] Sprawdzam alias %KMS_ALIAS%...
set "KMS_KEY_ID="
for /f "usebackq delims=" %%K in (`aws kms list-aliases --region "%REGION%" --query "Aliases[?AliasName=='%KMS_ALIAS%'].TargetKeyId | [0]" --output text --no-cli-pager 2^>nul`) do set "KMS_KEY_ID=%%K"

if not defined KMS_KEY_ID (
    echo [KMS] MSG = nie istnieje
) else if "%KMS_KEY_ID%"=="None" (
    echo [KMS] MSG = nie istnieje
) else (
    echo [KMS] KeyId = %KMS_KEY_ID%
    echo [KMS] Usuwam alias...
    aws kms delete-alias --alias-name "%KMS_ALIAS%" --region "%REGION%" --no-cli-pager
    if errorlevel 1 (
        echo [KMS] BLAD podczas delete-alias
    ) else (
        echo [KMS] Alias OK = usunieto
    )

    set "KMS_STATE="
    for /f "usebackq delims=" %%S in (`aws kms describe-key --key-id "%KMS_KEY_ID%" --region "%REGION%" --query "KeyMetadata.KeyState" --output text --no-cli-pager 2^>nul`) do set "KMS_STATE=%%S"

    if "!KMS_STATE!"=="PendingDeletion" (
        echo [KMS] Key MSG = juz jest PendingDeletion
    ) else (
        echo [KMS] Planuje usuniecie Key za 7 dni...
        aws kms schedule-key-deletion --key-id "%KMS_KEY_ID%" --pending-window-in-days 7 --region "%REGION%" --no-cli-pager >nul
        if errorlevel 1 (echo [KMS] BLAD podczas schedule-key-deletion) else echo [KMS] OK = PendingDeletion
    )
)
echo.

REM ============================================================
REM VPC / NAT / ROUTING / SUBNETS / IGW / DHCP
REM ============================================================
echo [VPC] Szukam VPC z tagiem Name=%VPC_NAME%...
set "VPC_ID="
for /f "usebackq delims=" %%V in (`aws ec2 describe-vpcs --filters "Name=tag:Name,Values=%VPC_NAME%" --region "%REGION%" --query "Vpcs[0].VpcId" --output text --no-cli-pager 2^>nul`) do set "VPC_ID=%%V"

if not defined VPC_ID goto VPC_NOT_FOUND
if "%VPC_ID%"=="None" goto VPC_NOT_FOUND

echo [VPC] Znaleziono %VPC_ID%
echo.

REM NAT GATEWAYS
echo [NAT] Sprawdzam NAT Gateways...
set "FOUND_NAT=0"
for /f "usebackq delims=" %%N in (`aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=%VPC_ID%" --region "%REGION%" --query "NatGateways[?State!='deleted'].NatGatewayId" --output text --no-cli-pager 2^>nul`) do (
    if not "%%N"=="" if not "%%N"=="None" (
        set "FOUND_NAT=1"
        for %%I in (%%N) do (
            echo [NAT] Usuwam %%I...
            aws ec2 delete-nat-gateway --nat-gateway-id "%%I" --region "%REGION%" --no-cli-pager >nul
            if errorlevel 1 (
                echo [NAT] BLAD = %%I
            ) else (
                echo [NAT] Czekam na usuniecie %%I...
                aws ec2 wait nat-gateway-deleted --nat-gateway-ids "%%I" --region "%REGION%"
                if errorlevel 1 (echo [NAT] BLAD wait = %%I) else echo [NAT] OK = %%I
            )
        )
    )
)
if "!FOUND_NAT!"=="0" echo [NAT] MSG = nie istnieje
echo.

REM ROUTE TABLES - usuwamy explicit associations i non-main route tables
echo [RTB] Sprawdzam niestandardowe Route Tables...
set "FOUND_RTB=0"
for /f "usebackq delims=" %%R in (`aws ec2 describe-route-tables --filters "Name=vpc-id,Values=%VPC_ID%" --region "%REGION%" --query "RouteTables[?length(Associations[?Main==`true`]) == `0`].RouteTableId" --output text --no-cli-pager 2^>nul`) do (
    if not "%%R"=="" if not "%%R"=="None" (
        for %%I in (%%R) do (
            set "FOUND_RTB=1"
            echo [RTB] Route table %%I

            for /f "usebackq delims=" %%A in (`aws ec2 describe-route-tables --route-table-ids "%%I" --region "%REGION%" --query "RouteTables[0].Associations[?Main==`false`].RouteTableAssociationId" --output text --no-cli-pager 2^>nul`) do (
                if not "%%A"=="" if not "%%A"=="None" (
                    for %%J in (%%A) do (
                        echo [RTB] Disassociate %%J...
                        aws ec2 disassociate-route-table --association-id "%%J" --region "%REGION%" --no-cli-pager >nul 2>&1
                    )
                )
            )

            echo [RTB] Usuwam %%I...
            aws ec2 delete-route-table --route-table-id "%%I" --region "%REGION%" --no-cli-pager >nul
            if errorlevel 1 (echo [RTB] BLAD = %%I) else echo [RTB] OK = %%I
        )
    )
)
if "!FOUND_RTB!"=="0" echo [RTB] MSG = nie istnieje
echo.

REM SUBNETS
echo [SUBNET] Sprawdzam subnety...
set "FOUND_SUBNET=0"
for /f "usebackq delims=" %%S in (`aws ec2 describe-subnets --filters "Name=vpc-id,Values=%VPC_ID%" --region "%REGION%" --query "Subnets[].SubnetId" --output text --no-cli-pager 2^>nul`) do (
    if not "%%S"=="" if not "%%S"=="None" (
        set "FOUND_SUBNET=1"
        for %%I in (%%S) do (
            echo [SUBNET] Usuwam %%I...
            aws ec2 delete-subnet --subnet-id "%%I" --region "%REGION%" --no-cli-pager >nul
            if errorlevel 1 (echo [SUBNET] BLAD = %%I) else echo [SUBNET] OK = %%I
        )
    )
)
if "!FOUND_SUBNET!"=="0" echo [SUBNET] MSG = nie istnieje
echo.

REM INTERNET GATEWAY
echo [IGW] Sprawdzam Internet Gateway...
set "IGW_ID="
for /f "usebackq delims=" %%G in (`aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=%VPC_ID%" --region "%REGION%" --query "InternetGateways[0].InternetGatewayId" --output text --no-cli-pager 2^>nul`) do set "IGW_ID=%%G"

if not defined IGW_ID (
    echo [IGW] MSG = nie istnieje
) else if "%IGW_ID%"=="None" (
    echo [IGW] MSG = nie istnieje
) else (
    echo [IGW] Odlaczam %IGW_ID%...
    aws ec2 detach-internet-gateway --internet-gateway-id "%IGW_ID%" --vpc-id "%VPC_ID%" --region "%REGION%" --no-cli-pager >nul
    if errorlevel 1 (
        echo [IGW] BLAD podczas detach = %IGW_ID%
    ) else (
        echo [IGW] Usuwam %IGW_ID%...
        aws ec2 delete-internet-gateway --internet-gateway-id "%IGW_ID%" --region "%REGION%" --no-cli-pager >nul
        if errorlevel 1 (echo [IGW] BLAD = %IGW_ID%) else echo [IGW] OK = %IGW_ID%
    )
)
echo.

REM DHCP OPTIONS
echo [DHCP] Sprawdzam custom DHCP Options...
set "DHCP_ID="
for /f "usebackq delims=" %%D in (`aws ec2 describe-dhcp-options --filters "Name=tag:Name,Values=%VPC_NAME%" --region "%REGION%" --query "DhcpOptions[0].DhcpOptionsId" --output text --no-cli-pager 2^>nul`) do set "DHCP_ID=%%D"

if not defined DHCP_ID (
    echo [DHCP] MSG = nie istnieje
) else if "%DHCP_ID%"=="None" (
    echo [DHCP] MSG = nie istnieje
) else (
    echo [DHCP] Przelaczam VPC na default DHCP Options...
    aws ec2 associate-dhcp-options --dhcp-options-id default --vpc-id "%VPC_ID%" --region "%REGION%" --no-cli-pager >nul
    if errorlevel 1 (
        echo [DHCP] BLAD podczas associate default
    ) else (
        echo [DHCP] Usuwam %DHCP_ID%...
        aws ec2 delete-dhcp-options --dhcp-options-id "%DHCP_ID%" --region "%REGION%" --no-cli-pager >nul
        if errorlevel 1 (echo [DHCP] BLAD = %DHCP_ID%) else echo [DHCP] OK = %DHCP_ID%
    )
)
echo.

REM VPC
echo [VPC] Usuwam %VPC_ID%...
aws ec2 delete-vpc --vpc-id "%VPC_ID%" --region "%REGION%" --no-cli-pager >nul
if errorlevel 1 (
    echo [VPC] BLAD - prawdopodobnie pozostala zaleznosc w VPC.
    echo [VPC] Sprawdz ENI, Security Groups, Load Balancers, VPC Endpoints itp.
) else (
    echo [VPC] OK = usunieto %VPC_ID%
)
goto AFTER_VPC

:VPC_NOT_FOUND
echo [VPC] MSG = nie istnieje

:AFTER_VPC
echo.

REM ============================================================
REM IAM CLUSTER ROLE
REM ============================================================
echo [IAM] Sprawdzam role %CLUSTER_ROLE%...
aws iam get-role --role-name "%CLUSTER_ROLE%" --no-cli-pager >nul 2>&1
if errorlevel 1 (
    echo [IAM] %CLUSTER_ROLE% MSG = nie istnieje
) else (
    echo [IAM] Odpinam AmazonEKSClusterPolicy...
    aws iam detach-role-policy --role-name "%CLUSTER_ROLE%" --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy --no-cli-pager >nul 2>&1
    echo [IAM] Usuwam role %CLUSTER_ROLE%...
    aws iam delete-role --role-name "%CLUSTER_ROLE%" --no-cli-pager >nul
    if errorlevel 1 (echo [IAM] BLAD = %CLUSTER_ROLE%) else echo [IAM] OK = %CLUSTER_ROLE%
)
echo.

REM ============================================================
REM IAM WORKER ROLE
REM ============================================================
echo [IAM] Sprawdzam role %WORKER_ROLE%...
aws iam get-role --role-name "%WORKER_ROLE%" --no-cli-pager >nul 2>&1
if errorlevel 1 (
    echo [IAM] %WORKER_ROLE% MSG = nie istnieje
) else (
    echo [IAM] Odpinam policy...
    aws iam detach-role-policy --role-name "%WORKER_ROLE%" --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy --no-cli-pager >nul 2>&1
    aws iam detach-role-policy --role-name "%WORKER_ROLE%" --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy --no-cli-pager >nul 2>&1
    aws iam detach-role-policy --role-name "%WORKER_ROLE%" --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly --no-cli-pager >nul 2>&1

    echo [IAM] Usuwam role %WORKER_ROLE%...
    aws iam delete-role --role-name "%WORKER_ROLE%" --no-cli-pager >nul
    if errorlevel 1 (echo [IAM] BLAD = %WORKER_ROLE%) else echo [IAM] OK = %WORKER_ROLE%
)
echo.

REM ============================================================
REM DYNAMODB
REM ============================================================
echo [DDB] Sprawdzam table %LOCK_TABLE%...
aws dynamodb describe-table --table-name "%LOCK_TABLE%" --region "%REGION%" --no-cli-pager >nul 2>&1
if errorlevel 1 (
    echo [DDB] MSG = nie istnieje
) else (
    echo [DDB] Usuwam table...
    aws dynamodb delete-table --table-name "%LOCK_TABLE%" --region "%REGION%" --no-cli-pager >nul
    if errorlevel 1 (echo [DDB] BLAD) else echo [DDB] OK = delete requested
)
echo.

REM ============================================================
REM S3 VERSIONED STATE BUCKET
REM ============================================================
echo [S3] Sprawdzam bucket %STATE_BUCKET%...
aws s3api head-bucket --bucket "%STATE_BUCKET%" --region "%REGION%" --no-cli-pager >nul 2>&1
if errorlevel 1 (
    echo [S3] MSG = nie istnieje albo brak dostepu
    goto AFTER_S3
)

echo [S3] Bucket istnieje. Usuwam biezace obiekty...
aws s3 rm "s3://%STATE_BUCKET%" --recursive --region "%REGION%" >nul 2>&1

set "TMPVERS=%TEMP%\eks_gpu_s3_versions_%RANDOM%.json"
set "TMPMARK=%TEMP%\eks_gpu_s3_markers_%RANDOM%.json"

REM Usun wszystkie wersje obiektow
aws s3api list-object-versions --bucket "%STATE_BUCKET%" --region "%REGION%" --query "{Objects: Versions[].{Key:Key,VersionId:VersionId}, Quiet: `true`}" --output json --no-cli-pager > "%TMPVERS%" 2>nul
for %%F in ("%TMPVERS%") do if %%~zF GTR 20 (
    findstr /c:"\"Key\"" "%TMPVERS%" >nul 2>&1
    if not errorlevel 1 (
        echo [S3] Usuwam wersje obiektow...
        aws s3api delete-objects --bucket "%STATE_BUCKET%" --delete "file://%TMPVERS%" --region "%REGION%" --no-cli-pager >nul
        if errorlevel 1 echo [S3] BLAD podczas usuwania Versions
    )
)

REM Usun delete markers
aws s3api list-object-versions --bucket "%STATE_BUCKET%" --region "%REGION%" --query "{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}, Quiet: `true`}" --output json --no-cli-pager > "%TMPMARK%" 2>nul
for %%F in ("%TMPMARK%") do if %%~zF GTR 20 (
    findstr /c:"\"Key\"" "%TMPMARK%" >nul 2>&1
    if not errorlevel 1 (
        echo [S3] Usuwam DeleteMarkers...
        aws s3api delete-objects --bucket "%STATE_BUCKET%" --delete "file://%TMPMARK%" --region "%REGION%" --no-cli-pager >nul
        if errorlevel 1 echo [S3] BLAD podczas usuwania DeleteMarkers
    )
)

del /q "%TMPVERS%" >nul 2>&1
del /q "%TMPMARK%" >nul 2>&1

echo [S3] Usuwam bucket...
aws s3api delete-bucket --bucket "%STATE_BUCKET%" --region "%REGION%" --no-cli-pager >nul
if errorlevel 1 (
    echo [S3] BLAD - bucket nadal zawiera wersje/markery albo ma inna zaleznosc
) else (
    echo [S3] OK = usunieto
)

:AFTER_S3
echo.

echo ============================================================
echo CLEANUP ZAKONCZONY
echo.
echo KMS Key moze pozostac widoczny jako PendingDeletion przez 7 dni.
echo Jezeli VPC nie zostalo usuniete, skrypt wypisal BLAD przy VPC.
echo ============================================================

endlocal
exit /b 0
