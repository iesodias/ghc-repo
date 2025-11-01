#!/bin/bash

set -euo pipefail

# Variables
LOCATION="brazilsouth"
TERRAFORM_RG="gh-terraform"
STORAGE_ACCOUNT="ghdevopsautomatf"
CONTAINER_NAME="tfstate"

# Environment Resource Groups
DEV_RG="gh-devops-dev"
HML_RG="gh-devops-hml"
PRD_RG="gh-devops-prd"

echo " Setting up Azure infrastructure for AKS CI/CD Pipeline..."

# Function to check if resource group exists
resource_group_exists() {
    az group show --name "$1" --query "name" -o tsv 2>/dev/null || echo ""
}

# Function to check if storage account exists
storage_account_exists() {
    az storage account show --name "$1" --resource-group "$2" --query "name" -o tsv 2>/dev/null || echo ""
}

# Create Terraform state Resource Group
echo " Creating Terraform state Resource Group..."
if [[ -z $(resource_group_exists $TERRAFORM_RG) ]]; then
    az group create --name $TERRAFORM_RG --location $LOCATION
    echo " Resource Group '$TERRAFORM_RG' created successfully"
else
    echo "  Resource Group '$TERRAFORM_RG' already exists"
fi

# Create Storage Account for Terraform state
echo " Creating Storage Account for Terraform state..."
if [[ -z $(storage_account_exists $STORAGE_ACCOUNT $TERRAFORM_RG) ]]; then
    az storage account create \
        --name $STORAGE_ACCOUNT \
        --resource-group $TERRAFORM_RG \
        --location $LOCATION \
        --sku Standard_LRS \
        --kind StorageV2 \
        --access-tier Hot \
        --encryption-services blob file \
        --https-only true \
        --min-tls-version TLS1_2
    echo " Storage Account '$STORAGE_ACCOUNT' created successfully"
else
    echo "  Storage Account '$STORAGE_ACCOUNT' already exists"
fi

# Create container for Terraform state
echo " Creating container for Terraform state..."
az storage container create \
    --name $CONTAINER_NAME \
    --account-name $STORAGE_ACCOUNT \
    --auth-mode login || echo "  Container '$CONTAINER_NAME' already exists"

# Create Environment Resource Groups
echo " Creating environment Resource Groups..."

for rg in $DEV_RG $HML_RG $PRD_RG; do
    if [[ -z $(resource_group_exists $rg) ]]; then
        az group create --name $rg --location $LOCATION
        echo " Resource Group '$rg' created successfully"
    else
        echo "  Resource Group '$rg' already exists"
    fi
done

# Get Storage Account details for Terraform backend configuration
echo " Getting Storage Account details..."
STORAGE_ACCOUNT_KEY=$(az storage account keys list \
    --resource-group $TERRAFORM_RG \
    --account-name $STORAGE_ACCOUNT \
    --query '[0].value' -o tsv)

echo ""
echo " Azure infrastructure setup completed!"
echo ""
echo " Backend configuration for Terraform:"
echo "--------------------------------------------"
echo "resource_group_name  = \"$TERRAFORM_RG\""
echo "storage_account_name = \"$STORAGE_ACCOUNT\""
echo "container_name       = \"$CONTAINER_NAME\""
echo "key                  = \"aks/{environment}.tfstate\""
echo ""
echo " Storage Account Key (for GitHub Secrets):"
echo "ARM_ACCESS_KEY=$STORAGE_ACCOUNT_KEY"
echo ""
echo " Next steps:"
echo "1. Add ARM_ACCESS_KEY to GitHub repository secrets"
echo "2. Configure Azure Service Principal for GitHub Actions"
echo "3. Run terraform init with the backend configuration"