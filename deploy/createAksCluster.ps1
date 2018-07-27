$ClusterName="omusavi-aks-kafka-connect";
$Location="eastus";

$ResourceGroup=$ClusterName;
$AcrName=$ClusterName -replace '-','';

## -------
## create service principal
$ServicePrincipalName=$ClusterName;
$ServicePrincipalPassword=[system.web.security.membership]::GeneratePassword(10, 0);

az ad sp delete --id http://$ServicePrincipalName
az ad sp create-for-rbac --name $ServicePrincipalName --password $ServicePrincipalPassword --skip-assignment -o json
$ServicePrincipalClientId=$(az ad sp show --id http://$ServicePrincipalName --query appId --output tsv)

## -------
## create resource group
az group delete --name $ClusterName --yes
az group create --name $ResourceGroup --location $Location

## -------
## create acr
az acr create --resource-group $ResourceGroup --name $AcrName --sku Basic
$AcrId=$(az acr show --name $AcrName --resource-group $ResourceGroup --query "id" --output tsv)
$AcrLoginServer=$(az acr show --name $AcrName --query loginServer --output tsv)

az role assignment create --assignee $ServicePrincipalClientId --role Reader --scope $AcrId

## -------
## create kubernetes cluster
az aks create --resource-group=$ResourceGroup --name $ClusterName --service-principal http://$ServicePrincipalName --client-secret $ServicePrincipalPassword --generate-ssh-keysaz --disable-rbac

## -------
## Download Kubernetes Credentials
az aks get-credentials --resource-group $ResourceGroup --name $ClusterName 

## ------
## Kube Version
kubectl version

kubectl create secret docker-registry acr-auth --docker-server $AcrLoginServer --docker-username $ServicePrincipalClientId --docker-password $ServicePrincipalPassword --docker-email email@email.com