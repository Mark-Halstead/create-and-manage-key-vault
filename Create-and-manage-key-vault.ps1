# Function to validate input choices with added logging
function Validate-Action {
    param ([string]$input)

    # Log the input for debugging
    Write-Host "Raw input received: '$input'" -ForegroundColor Cyan

    # Try to cast input to an integer
    try {
        $inputInt = [int]$input
        Write-Host "Converted input to integer: $inputInt" -ForegroundColor Cyan
    } catch {
        Write-Host "Invalid input. Please choose a number between 1 and 7." -ForegroundColor Red
        return $false
    }

    # Validate if the input is between 1 and 7
    if ($inputInt -ge 1 -and $inputInt -le 7) {
        return $true
    } else {
        Write-Host "Invalid input. Please choose a number between 1 and 7." -ForegroundColor Red
        return $false
    }
}

# Function to check if the Key Vault exists
function Check-KeyVaultExists {
    param (
        [string]$vaultName,
        [string]$resourceGroupName
    )

    $keyVault = Get-AzKeyVault -VaultName $vaultName -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue
    if ($null -eq $keyVault) {
        Write-Host "Key Vault '$vaultName' does not exist." -ForegroundColor Red
        return $false
    } else {
        Write-Host "Key Vault '$vaultName' exists." -ForegroundColor Green
        return $true
    }
}

# Prompt for Key Vault name and resource group
$vaultName = Read-Host -Prompt "Enter the name of the Key Vault"
$resourceGroupName = Read-Host -Prompt "Enter the name of the resource group"
$location = Read-Host -Prompt "Enter the Azure region (e.g., eastus, westeurope)"

# Check if Key Vault already exists before creating
if (-not (Check-KeyVaultExists -vaultName $vaultName -resourceGroupName $resourceGroupName)) {
    # Create the Key Vault if it doesn't exist
    Write-Host "Creating Key Vault..." -ForegroundColor Green
    New-AzKeyVault -ResourceGroupName $resourceGroupName -VaultName $vaultName -Location $location
} else {
    Write-Host "Key Vault already exists, skipping creation." -ForegroundColor Yellow
}

# Key Vault management options
function Manage-KeyVault {
    param (
        [string]$vaultName,
        [string]$resourceGroupName
    )

    while ($true) {
        $action = Read-Host -Prompt "Choose an action: 1) Add secret 2) Retrieve secret 3) Add key 4) Retrieve key 5) Add certificate 6) Retrieve certificate 7) Exit"

        # Log input
        Write-Host "Action selected: $action" -ForegroundColor Cyan

        # Validate the input action
        if (-not (Validate-Action -input $action)) {
            continue
        }

        # Cast input to integer for easier comparison
        $actionInt = [int]$action

        if ($actionInt -eq 1) {
            # Add a secret to the Key Vault
            $secretName = Read-Host -Prompt "Enter the name of the secret"
            $secretValue = Read-Host -Prompt "Enter the value of the secret"
            if ($secretName -and $secretValue) {
                Write-Host "Adding secret..." -ForegroundColor Green
                Set-AzKeyVaultSecret -VaultName $vaultName -Name $secretName -SecretValue (ConvertTo-SecureString $secretValue -AsPlainText -Force)
            } else {
                Write-Host "Secret name and value cannot be empty." -ForegroundColor Red
            }
        }
        elseif ($actionInt -eq 2) {
            # Retrieve a secret from the Key Vault
            $secretName = Read-Host -Prompt "Enter the name of the secret"
            if ($secretName) {
                $secret = Get-AzKeyVaultSecret -VaultName $vaultName -Name $secretName -ErrorAction SilentlyContinue
                if ($secret) {
                    Write-Host "Secret Value: $($secret.SecretValueText)" -ForegroundColor Yellow
                } else {
                    Write-Host "Secret '$secretName' not found." -ForegroundColor Red
                }
            } else {
                Write-Host "Secret name cannot be empty." -ForegroundColor Red
            }
        }
        elseif ($actionInt -eq 3) {
            # Add a key to the Key Vault
            $keyName = Read-Host -Prompt "Enter the name of the key"
            if ($keyName) {
                Write-Host "Adding key..." -ForegroundColor Green
                Add-AzKeyVaultKey -VaultName $vaultName -Name $keyName -KeyOps "encrypt", "decrypt"
            } else {
                Write-Host "Key name cannot be empty." -ForegroundColor Red
            }
        }
        elseif ($actionInt -eq 4) {
            # Retrieve a key from the Key Vault
            $keyName = Read-Host -Prompt "Enter the name of the key"
            if ($keyName) {
                $key = Get-AzKeyVaultKey -VaultName $vaultName -Name $keyName -ErrorAction SilentlyContinue
                if ($key) {
                    Write-Host "Key ID: $($key.Id)" -ForegroundColor Yellow
                } else {
                    Write-Host "Key '$keyName' not found." -ForegroundColor Red
                }
            } else {
                Write-Host "Key name cannot be empty." -ForegroundColor Red
            }
        }
        elseif ($actionInt -eq 5) {
            # Add a certificate to the Key Vault
            $certName = Read-Host -Prompt "Enter the name of the certificate"
            if ($certName) {
                $certPolicy = Get-AzKeyVaultCertificatePolicy -VaultName $vaultName -CertificatePolicyDefault
                Write-Host "Adding certificate..." -ForegroundColor Green
                Add-AzKeyVaultCertificate -VaultName $vaultName -Name $certName -CertificatePolicy $certPolicy
            } else {
                Write-Host "Certificate name cannot be empty." -ForegroundColor Red
            }
        }
        elseif ($actionInt -eq 6) {
            # Retrieve a certificate from the Key Vault
            $certName = Read-Host -Prompt "Enter the name of the certificate"
            if ($certName) {
                $cert = Get-AzKeyVaultCertificate -VaultName $vaultName -Name $certName -ErrorAction SilentlyContinue
                if ($cert) {
                    Write-Host "Certificate Thumbprint: $($cert.X509Thumbprint)" -ForegroundColor Yellow
                } else {
                    Write-Host "Certificate '$certName' not found." -ForegroundColor Red
                }
            } else {
                Write-Host "Certificate name cannot be empty." -ForegroundColor Red
            }
        }
        elseif ($actionInt -eq 7) {
            Write-Host "Exiting..." -ForegroundColor Red
            break
        } else {
            Write-Host "Invalid option. Please try again." -ForegroundColor Red
        }
    }
}

# Call the management function
Manage-KeyVault -vaultName $vaultName -resourceGroupName $resourceGroupName
