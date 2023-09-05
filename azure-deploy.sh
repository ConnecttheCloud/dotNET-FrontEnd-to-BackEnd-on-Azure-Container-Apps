RG="RG04"
LOCATION="southeastasia"
ENVIRONMENT="env-apiapp03"
STORE_APP="frontendaca009"
ACR_NAME="testdemoacr01"

pwd
echo $(pwd)

az group create -n $RG --location $LOCATION

az acr create \
  --resource-group $RG \
  --name $ACR_NAME \
  --sku Basic \
  --admin-enabled true

#create container App Env:
az containerapp env create \
  --name $ENVIRONMENT \
  --resource-group $RG \
  --location $LOCATION

#Create Container App with helloworld image
az containerapp create \
  --name $STORE_APP \
  --resource-group $RG \
  --environment $ENVIRONMENT \
  --image mcr.microsoft.com/azuredocs/containerapps-helloworld:latest \
  --target-port 80 \
  --ingress 'external' \
  --registry-server $ACR_NAME.azurecr.io \
  --query properties.configuration.ingress.fqdn

az acr build --registry $ACR_NAME --image $STORE_APP -f ./dotNET-FrontEnd-to-BackEnd-on-Azure-Container-Apps/src/Store/Dockerfile ./src/

az identity create --resource-group $RG --name myACRId

# Get resource ID of the user-assigned identity
userID=$(az identity show --resource-group $RG --name myACRId --query id --output tsv)

# Get service principal ID of the user-assigned identity
spID=$(az identity show --resource-group $RG --name myACRId --query principalId --output tsv)

#Get reource ID of ACR
resourceID=$(az acr show --resource-group $RG --name $ACR_NAME --query id --output tsv)

az role assignment create --assignee $spID --scope $resourceID --role acrpull

az containerapp identity assign --resource-group $RG --name $STORE_APP --user-assigned $userID
