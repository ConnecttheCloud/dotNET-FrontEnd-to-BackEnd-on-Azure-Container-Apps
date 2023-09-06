RG="RG04"
LOCATION="southeastasia"
ENVIRONMENT="env-apiapp03"
STORE_APP="frontendaca009"
ACR_NAME="testdemoacr01"
WORKSPACE_NAME="workspace10011"
INVENTORY_APP=inventoryapiapp008
PRODUCT_APP=productapiapp007
USERIDENTITY=myACRId

az group create -n $RG --location $LOCATION

az acr create \
  --resource-group $RG \
  --name $ACR_NAME \
  --sku Basic \
  # --admin-enabled true

az monitor log-analytics workspace create \
  --resource-group $RG \
  --workspace-name $WORKSPACE_NAME

workspace_id=$(az monitor log-analytics workspace show --resource-group RG04 --workspace-name $WORKSPACE_NAME --query customerId -o tsv)
workspace_key=$(az monitor log-analytics workspace get-shared-keys --resource-group $RG --workspace-name $WORKSPACE_NAME --query primarySharedKey -otsv)

#create container App Env:
az containerapp env create \
  --name $ENVIRONMENT \
  --resource-group $RG \
  --logs-workspace-id $workspace_id \
  --logs-workspace-key $workspace_key \
  --location $LOCATION

#Create Container App with helloworld image
az containerapp create \
  --name $STORE_APP \
  --resource-group $RG \
  --environment $ENVIRONMENT \
  --image mcr.microsoft.com/azuredocs/aci-helloworld \
  --target-port 80 \
  --ingress 'external' \
  --query properties.configuration.ingress.fqdn
  # --image mcr.microsoft.com/azuredocs/containerapps-helloworld:latest \
    # --registry-server $ACR_NAME.azurecr.io \

#Create Container App with helloworld image
az containerapp create \
  --name $INVENTORY_APP \
  --resource-group $RG \
  --environment $ENVIRONMENT \
  --image mcr.microsoft.com/azuredocs/aci-helloworld \
  --target-port 80 \
  --ingress 'internal' \
  --query properties.configuration.ingress.fqdn

#Create Container App with helloworld image
az containerapp create \
  --name $PRODUCT_APP \
  --resource-group $RG \
  --environment $ENVIRONMENT \
  --image mcr.microsoft.com/azuredocs/aci-helloworld \
  --target-port 80 \
  --ingress 'internal' \
  --query properties.configuration.ingress.fqdn

# az acr build --registry $ACR_NAME --image $STORE_APP -f ./src/Store/Dockerfile ./src/
az identity create --resource-group $RG --name $USERIDENTITY
# Get resource ID of the user-assigned identity
userID=$(az identity show --resource-group $RG --name $USERIDENTITY --query id --output tsv)
# Get service principal ID of the user-assigned identity
spID=$(az identity show --resource-group $RG --name $USERIDENTITY --query principalId --output tsv)
#Get reource ID of ACR
resourceID=$(az acr show --resource-group $RG --name $ACR_NAME --query id --output tsv)
az role assignment create --assignee $spID --scope $resourceID --role acrpull
az containerapp identity assign --resource-group $RG --name $STORE_APP --user-assigned $userID
az containerapp identity assign --resource-group $RG --name $INVENTORY_APP --user-assigned $userID
az containerapp identity assign --resource-group $RG --name $PRODUCT_APP --user-assigned $userID


az containerapp registry set \
  --name $STORE_APP \
  --resource-group $RG \
  --server $ACR_NAME.azurecr.io \
  --identity $userID


az containerapp registry set \
  --name $INVENTORY_APP \
  --resource-group $RG \
  --server $ACR_NAME.azurecr.io \
  --identity $userID

az containerapp registry set \
  --name $PRODUCT_APP \
  --resource-group $RG \
  --server $ACR_NAME.azurecr.io \
  --identity $userID
  # az containerapp registry show \
  # --name $INVENTORY_APP \
  # --resource-group $RG \
  # --server $ACR_NAME.azurecr.io \
  # --identity $userID
