param (
    [switch]$RDP,
    [switch]$SSH,
    [switch]$DB,
    [switch]$ALL
)
Import-Module '.\Identity Authentication\IdentityAuth.psm1'

$global:exportedObjects = @()

function Get-OAuthHeader {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, HelpMessage='Please provide the OAuth Token')]
        [ValidateNotNullOrEmpty()]
        [string]$BearerToken
    )
    process {
        return @{"Authorization" = "$($BearerToken)"}
    }
}

function Get-RDPToken {
    [CmdletBinding()]
    param (
        [hashtable]$headers
    )

    begin {
        $uri = "https://${subdomain}-jit.cyberark.cloud/api/adb/sso/acquire"
        $body = '{"tokenType":"password","service":"DPA-RDP"}'
    }

    process {
        return Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body
    }
}

function Get-DBToken {
    [CmdletBinding()]
    param (
        [hashtable]$headers
    )

    begin {
        $uri = "https://${subdomain}-jit.cyberark.cloud/api/adb/sso/acquire"
        $body = '{"tokenType":"password","service":"DPA-DB"}'
    }

    process {
        return Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body
    }
}

function Get-SSHToken {
    param (
        [hashtable]$headers
    )

    begin{
        $headers.Add("Content-Disposition", "attachment;")
    }

    process{
        $reqUrl = "https://${subdomain}-jit.cyberark.cloud/api/ssh/sso/key"
        $response = Invoke-RestMethod -Uri $reqUrl -Method Get -Headers $headers
        return $response
    }

}

if (-not (Test-Path -Path "config.psd1")) {
    Write-Error "Configuration file 'config.psd1' not found. Please create it with the required parameters."
    exit 1
}
$config = Import-PowerShellDataFile -Path "config.psd1"
# Define required keys
$requiredKeys = @('subdomain', 'identitytenantid', 'username', 'ssh_file_path')

# Check if all required keys are present and non-empty
foreach ($key in $requiredKeys) {
    if (-not $config.ContainsKey($key) -or [string]::IsNullOrWhiteSpace($config[$key])) {
        Write-Warning "$key is missing or empty"
    } else {
        if($key -eq "subdomain"){
            $subdomain = $config[$key]
        }elseif($key -eq "identitytenantid"){
            $tenantid = $config[$key]
        }elseif($key -eq "username"){
            $identityUserName = $config[$key]
        }elseif($key -eq "ssh_file_path"){
            $ssh_file_path = $config[$key]
        }

        Write-Verbose "$key = $($config[$key])"
    }
}
if(-Not $ssh_file_path){
    $ssh_file_path = Read-Host "Enter the SSH file path"
    if(-Not $ssh_file_path){
        $ssh_file_path = "$HOME\.cyberark\sia_key.pem"
        Write-Host "Using default SSH file path: $ssh_file_path"
    }
}
if(-Not (Test-Path -Path $ssh_file_path)){
    New-Item -Path $ssh_file_path -ItemType File -Force | Out-Null
    Write-Host "SSH file created at: $ssh_file_path"
}
else{
    Write-Host "SSH file already exists at: $ssh_file_path"
}


if(-Not $tenantid){
    $tenantid = Read-Host "Enter Identity Tenant Id"
}
if($tenantid){
    $identityTenantURL = "https://${tenantid}.id.cyberark.cloud"
}
else{
    Throw "Tenant Id is required"
}


if(-Not $identityUserName){
    $identityUserName = Read-Host "Enter Identity User Name"
    if(-Not $identityUserName){
        Throw "Identity User Name is required"
    }
}

if(-Not $subdomain){
    $subdomain = Read-Host "Enter subdomain"
    if(-Not $subdomain){
        Throw "Subdomain is required"
    }
}

#$BearerToken = (Get-IdentityHeader -IdentityTenantURL $identityTenantURL -IdentityUserName $identityUserName -IdentityTenantId $tenantid -PCloudSubdomain $subdomain).Authorization
$BearerToken = (Get-IdentityHeader -IdentityTenantURL $identityTenantURL -IdentityUserName $identityUserName -PCloudSubdomain $subdomain).Authorization
if(-Not $BearerToken){
    $BearerToken = Read-Host "Enter the bearer Token"
    if(-Not $BearerToken){
        Throw "Bearer token in required"
    }
}
$header = Get-OAuthHeader -BearerToken $BearerToken
if ($RDP -or $ALL){
    Write-Host "Generating RDP Token..."
    $jsonResponse = Get-RDPToken -headers $header
    Write-Host $jsonResponse.token.key -ForegroundColor Green
}
if ($SSH -or $ALL) {
    Write-Host "Generating SSH Token..."
    Get-SSHToken -headers $header | Out-File -FilePath $ssh_file_path -Encoding ascii
    Write-Host "Token saved to path ${ssh_file_path}"
}
if ($DB -or $ALL){
    Write-Host "Generating DB Token..."
    $jsonResponse = Get-DBToken -headers $header
    Write-Host $jsonResponse.token.key -ForegroundColor Green
}

