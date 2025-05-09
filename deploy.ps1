# Secure Terraform deployment script for vSphere (PowerShell version)
# This script prompts for credentials and passes them securely via environment variables

function Stop-Execution {
    param (
        [string]$ErrorMessage
    )
    Write-Host "Error: $ErrorMessage" -ForegroundColor Red
    exit 1
}

function Clear-SensitiveVariables {
    # Clear sensitive environment variables
    Remove-Item -Path Env:TF_VAR_vsphere_user -ErrorAction SilentlyContinue
    Remove-Item -Path Env:TF_VAR_vsphere_password -ErrorAction SilentlyContinue
    Remove-Variable -Name vsphereUser -Scope Global -ErrorAction SilentlyContinue
    Remove-Variable -Name vspherePassword -Scope Global -ErrorAction SilentlyContinue
    Remove-Variable -Name securePassword -Scope Global -ErrorAction SilentlyContinue
}

# Clear any existing TF_VAR environment variables
Clear-SensitiveVariables

# Welcome message
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "Secure vSphere Terraform Deployment" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "This script will execute Terraform commands using your"
Write-Host "vSphere credentials provided securely via environment variables."
Write-Host ""

# Get vSphere credentials securely
$vsphereUser = Read-Host -Prompt "vSphere Username"
$securePassword = Read-Host -Prompt "vSphere Password" -AsSecureString

# Convert secure string to plain text for environment variable
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword)
try {
    $vspherePassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
} finally {
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
}

# Export as environment variables for Terraform
$env:TF_VAR_vsphere_user = $vsphereUser
$env:TF_VAR_vsphere_password = $vspherePassword

# Verify connection information
Write-Host ""
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "Deployment Settings:" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "vSphere User: $env:TF_VAR_vsphere_user"
Write-Host "vSphere Password: [HIDDEN]"
Write-Host ""

# Confirm settings
$confirm = Read-Host -Prompt "Proceed with deployment? (y/n)"
if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "Deployment cancelled." -ForegroundColor Yellow
    Clear-SensitiveVariables
    exit 0
}

# Run Terraform commands
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "Executing Terraform deployment..." -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan

# Check if terraform is installed
try {
    # Just check that the command works, displaying the version for informational purposes
    Write-Host "Checking Terraform installation..." -ForegroundColor Green
    terraform --version | Select-Object -First 1
} catch {
    Stop-Execution "Terraform not found. Please install Terraform and ensure it's in your PATH."
}

# Initialize Terraform if needed
if (-not (Test-Path -Path ".terraform")) {
    Write-Host "Initializing Terraform..." -ForegroundColor Green
    terraform init
    if ($LASTEXITCODE -ne 0) {
        Stop-Execution "Terraform initialization failed"
    }
}

# Run plan
Write-Host "Running Terraform plan..." -ForegroundColor Green
terraform plan
if ($LASTEXITCODE -ne 0) {
    Stop-Execution "Terraform plan failed"
}

# Ask for confirmation before applying
$applyConfirm = Read-Host -Prompt "Apply the above plan? (y/n)"
if ($applyConfirm -ne "y" -and $applyConfirm -ne "Y") {
    Write-Host "Terraform apply cancelled." -ForegroundColor Yellow
    Clear-SensitiveVariables
    exit 0
}

# Apply changes
Write-Host "Applying Terraform plan..." -ForegroundColor Green
terraform apply -auto-approve
if ($LASTEXITCODE -ne 0) {
    Stop-Execution "Terraform apply failed"
}

Write-Host "=====================================================" -ForegroundColor Green
Write-Host "Deployment completed successfully!" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Green

# Clean up environment variables
Clear-SensitiveVariables

exit 0