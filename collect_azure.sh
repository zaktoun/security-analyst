#!/bin/bash
# collect_azure.sh – Mengumpulkan data keamanan Azure (perlu Azure CLI terkonfigurasi)

OUTPUT_DIR="./azure_data_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTPUT_DIR"

echo "[1/7] Mengumpulkan subscription information..."
az account show > "$OUTPUT_DIR/account.json"
az account list > "$OUTPUT_DIR/subscriptions.json"

echo "[2/7] Mengumpulkan Azure AD information..."
az ad user list > "$OUTPUT_DIR/ad_users.json"
az ad group list > "$OUTPUT_DIR/ad_groups.json"
az role assignment list > "$OUTPUT_DIR/role_assignments.json"

echo "[3/7] Mengumpulkan Network Security Groups..."
az network nsg list > "$OUTPUT_DIR/nsg_list.json"
az network nsg rule list --nsg-name --query "[*]" > "$OUTPUT_DIR/nsg_rules.json"

echo "[4/7] Mengumpulkan Virtual Machines..."
az vm list --show-details > "$OUTPUT_DIR/vms.json"
az vm list --query "[].{name:name, resourceGroup:resourceGroup, osType:storageProfile.osDisk.osType}" > "$OUTPUT_DIR/vms_summary.json"

echo "[5/7] Mengumpulkan Storage Accounts..."
az storage account list > "$OUTPUT_DIR/storage_accounts.json"
az storage account list --query "[].{name:name, resourceGroup:resourceGroup, allowBlobPublicAccess:allowBlobPublicAccess, minimumTlsVersion:minimumTlsVersion}" > "$OUTPUT_DIR/storage_security.json"

echo "[6/7] Mengumpulkan Key Vaults..."
az keyvault list > "$OUTPUT_DIR/keyvaults.json"

echo "[7/7] Mengumpulkan Policy assignments..."
az policy assignment list > "$OUTPUT_DIR/policies.json"

tar -czf "azure_data_$(date +%Y%m%d_%H%M%S).tar.gz" "$OUTPUT_DIR"
rm -rf "$OUTPUT_DIR"
echo "✅ Data Azure terkumpul"
