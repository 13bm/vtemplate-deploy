#!/bin/bash

# Secure Terraform deployment script for vSphere
# This script prompts for credentials and passes them securely via environment variables

# Function to handle errors
handle_error() {
  echo "Error: $1" >&2
  exit 1
}

# Function to securely get password without echoing to screen
get_password() {
  unset PASSWORD
  prompt="$1"
  while IFS= read -p "$prompt" -r -s -n 1 char; do
    if [[ $char == $'\0' ]]; then
      break
    fi
    if [[ $char == $'\177' ]]; then
      if [ -n "$PASSWORD" ]; then
        PASSWORD="${PASSWORD%?}"
        echo -ne "\b \b"
      fi
    else
      PASSWORD+="$char"
      echo -n "*"
    fi
  done
  echo
}

# Clear any existing TF_VAR environment variables to avoid leaking previous credentials
unset TF_VAR_vsphere_user
unset TF_VAR_vsphere_password

# Welcome message
echo "====================================================="
echo "Secure vSphere Terraform Deployment"
echo "====================================================="
echo "This script will execute Terraform commands using your"
echo "vSphere credentials provided securely via environment variables."
echo

# Get vSphere credentials
read -p "vSphere Username: " VSPHERE_USER || handle_error "Failed to get username"
read -s -p "vSphere Password: " VSPHERE_PASSWORD
VSPHERE_PASSWORD=$PASSWORD

# Export as environment variables for Terraform
export TF_VAR_vsphere_user="$VSPHERE_USER"
export TF_VAR_vsphere_password="$VSPHERE_PASSWORD"

# Verify connection information
echo
echo "====================================================="
echo "Deployment Settings:"
echo "====================================================="
echo "vSphere User: $TF_VAR_vsphere_user"
echo "vSphere Password: [HIDDEN]"
echo

# Confirm settings
read -p "Proceed with deployment? (y/n): " CONFIRM
if [[ $CONFIRM != "y" && $CONFIRM != "Y" ]]; then
  echo "Deployment cancelled."
  exit 0
fi

# Run Terraform commands
echo "====================================================="
echo "Executing Terraform deployment..."
echo "====================================================="

# Initialize Terraform if needed
if [ ! -d ".terraform" ]; then
  echo "Initializing Terraform..."
  terraform init || handle_error "Terraform initialization failed"
fi

# Run plan
echo "Running Terraform plan..."
terraform plan || handle_error "Terraform plan failed"

# Ask for confirmation before applying
read -p "Apply the above plan? (y/n): " APPLY_CONFIRM
if [[ $APPLY_CONFIRM != "y" && $APPLY_CONFIRM != "Y" ]]; then
  echo "Terraform apply cancelled."
  exit 0
fi

# Apply changes
echo "Applying Terraform plan..."
terraform apply -auto-approve || handle_error "Terraform apply failed"

echo "====================================================="
echo "Deployment completed successfully!"
echo "====================================================="

# Clean up environment variables
unset TF_VAR_vsphere_user
unset TF_VAR_vsphere_password
unset VSPHERE_USER
unset VSPHERE_PASSWORD
unset PASSWORD

exit 0