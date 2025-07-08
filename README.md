# sia-token-generator

This script can be used for generating SIA tokens for RDP, SSH and DB connections.

## Prerequisites

* Clone the repository

```
git clone https://github.com/paulpalayur/sia-token-generator.git
```

* Configure the config.psd1 file with the required details

```
@{
    subdomain  = 'acme'
    identitytenantid = 'aao4805'
    username   = 'user@company.com'
    ssh_file_path = '~\.cyberark\sia_key.pem'
}
```

* `subdomain` is your tenant subdomain. For example, if your tenant URL is https://acme.cyberark.cloud, then your subdomain is `amce`
* `identitytenantid` is your tenant's Identity tenant id. If the above URL redirects to https://aao4805.id.cyberark.cloud/, then your Identity tenant id is `aao4805`
* `username` is your UPN that you use to login to SIA
* `ssh_file_path` is your path to which the script downloads the SSH Private Key. By default it is set to `~\.cyberark\sia_key.pem`. The script will try to create this path

## Executing the Script

* Usage

```
.\Get-Token.ps1 [-RDP|-DB|-SSH|-ALL]
```

* Option 1 - Generate the RDP token

```
.\Get-Token.ps1 -RDP
```

* Option 2 - Generate the SSH Private key

```
.\Get-Token.ps1 -SSH
```

* Option 3 - Generate the DB token

```
.\Get-Token.ps1 -DB
```

* Option 4 - Generate the RDP and SSH token

```
.\Get-Token.ps1 -RDP -SSH
```

* Option 5 - Generate All tokens

```
.\Get-Token.ps1 -ALL
```