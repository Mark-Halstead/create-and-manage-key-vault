# Ensure that the user is authenticated with Azure
try {
    $azContext = Get-AzContext
    if (-not $azContext) {
        Write-Host "No Azure session found. Please log in." -ForegroundColor Yellow
        Connect-AzAccount
    }
} catch {
    Write-Host "Azure authentication required. Logging in..." -ForegroundColor Yellow
    Connect-AzAccount
}

# Prompt for Key Vault name, resource group, and location
$vaultName = Read-Host -Prompt "Enter the name of the Key Vault"
$resourceGroupName = Read-Host -Prompt "Enter the name of the resource group"
$location = Read-Host -Prompt "Enter the Azure region (e.g., eastus, westeurope)"

# Check if the Key Vault exists
$keyVault = Get-AzKeyVault -VaultName $vaultName -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue

if ($keyVault) {
    Write-Host "Key Vault '$vaultName' already exists in resource group '$resourceGroupName'." -ForegroundColor Yellow
} else {
    # Create the Key Vault if it doesn't exist
    Write-Host "Creating Key Vault..." -ForegroundColor Green
    New-AzKeyVault -ResourceGroupName $resourceGroupName -VaultName $vaultName -Location $location
    Write-Host "Key Vault '$vaultName' created successfully in resource group '$resourceGroupName'." -ForegroundColor Green
}

# Prompt the user for what they want to create (secret, key, or certificate)
$createChoice = Read-Host -Prompt "What do you want to create in the Key Vault? (secret/key/certificate/none)"

if ($createChoice -eq 'secret') {
    # Prompt for secret name and value
    $secretName = Read-Host -Prompt "Enter the name of the secret"
    $secretValue = Read-Host -Prompt "Enter the value of the secret"

    # Add the secret to the Key Vault
    Write-Host "Creating secret '$secretName'..." -ForegroundColor Green
    Set-AzKeyVaultSecret -VaultName $vaultName -Name $secretName -SecretValue (ConvertTo-SecureString $secretValue -AsPlainText -Force)
    Write-Host "Secret '$secretName' created successfully." -ForegroundColor Green

} elseif ($createChoice -eq 'key') {
    # Prompt for key name and type
    $keyName = Read-Host -Prompt "Enter the name of the key"
    $keyType = Read-Host -Prompt "Enter the key type (e.g., RSA, RSA-HSM, EC, EC-HSM)"
    
    # Add the key to the Key Vault
    Write-Host "Creating key '$keyName'..." -ForegroundColor Green
    Add-AzKeyVaultKey -VaultName $vaultName -Name $keyName -KeyType $keyType -KeyOps "encrypt", "decrypt"
    Write-Host "Key '$keyName' created successfully." -ForegroundColor Green

} elseif ($createChoice -eq 'certificate') {
    # Prompt for certificate name
    $certName = Read-Host -Prompt "Enter the name of the certificate"
    
    # Create a default certificate policy
    $certPolicy = New-AzKeyVaultCertificatePolicy -SecretContentType 'application/x-pkcs12' -IssuerName 'Self' -SubjectName "CN=$certName"

    # Add the certificate to the Key Vault
    Write-Host "Creating certificate '$certName'..." -ForegroundColor Green
    Add-AzKeyVaultCertificate -VaultName $vaultName -Name $certName -CertificatePolicy $certPolicy
    Write-Host "Certificate '$certName' created successfully." -ForegroundColor Green

} else {
    Write-Host "No item was created. Exiting script." -ForegroundColor Yellow
}
