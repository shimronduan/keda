#!/bin/bash
# Creates the tfstate container in the existing storage account
# Run this once before the first pipeline execution

set -e

RESOURCE_GROUP="tfstate-rg"
STORAGE_ACCOUNT="tfstatesa17329"
CONTAINER_NAME="tfstate"

echo "Creating container '$CONTAINER_NAME' in storage account '$STORAGE_ACCOUNT'..."

az storage container create \
  --name "$CONTAINER_NAME" \
  --account-name "$STORAGE_ACCOUNT" \
  --auth-mode login

echo "Container created successfully!"
echo ""
echo "Next steps:"
echo "1. Configure GitHub OIDC federation (see README)"
echo "2. Add secrets to your GitHub repository:"
echo "   - AZURE_CLIENT_ID"
echo "   - AZURE_TENANT_ID" 
echo "   - AZURE_SUBSCRIPTION_ID"
echo "3. Run the 'Deploy KEDA BlobWorker' workflow"
