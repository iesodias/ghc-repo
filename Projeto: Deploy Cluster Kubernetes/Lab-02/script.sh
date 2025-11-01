#!/bin/bash

set -euo pipefail

# Variables
SP_NAME="sp-github-actions-aks"
SUBSCRIPTION_ID=$(az account show --query id --output tsv)

echo " Setting up Service Principal for GitHub Actions..."
echo "Subscription ID: $SUBSCRIPTION_ID"

# Create Service Principal
echo " Creating Service Principal..."
SP_OUTPUT=$(az ad sp create-for-rbac \
    --name $SP_NAME \
    --role Contributor \
    --scopes "/subscriptions/$SUBSCRIPTION_ID" \
    --sdk-auth)

echo " Service Principal created successfully!"
echo ""
echo " GitHub Secrets configuration:"
echo "--------------------------------------------"
echo "AZURE_CREDENTIALS:"
echo "$SP_OUTPUT"
echo ""
echo "ARM_SUBSCRIPTION_ID:"
echo "$SUBSCRIPTION_ID"
echo ""
echo " Additional required secrets:"
echo "- ARM_ACCESS_KEY (from setup-azure-infrastructure.sh output)"
echo ""
echo "✨ Next steps:"
echo "1. Add these values to GitHub repository secrets"
echo "2. Grant additional permissions if needed for AKS operations"