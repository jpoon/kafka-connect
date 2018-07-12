#!/bin/bash

set -x

CLUSTER_NAME="japoon-aks-kafka-connect"
LOCATION=eastus

RESOURCE_GROUP=$CLUSTER_NAME
ACR_NAME=${CLUSTER_NAME//-/}

## -------
## create service principal
SERVICE_PRINCIPAL_NAME=$CLUSTER_NAME
SERVICE_PRINCIPAL_PASSWORD=`date | md5 | head -c10; echo`
az ad sp delete --id http://$SERVICE_PRINCIPAL_NAME
az ad sp create-for-rbac --name $SERVICE_PRINCIPAL_NAME --password $SERVICE_PRINCIPAL_PASSWORD --skip-assignment -o json
SERVICE_PRINCIPAL_CLIENT_ID=$(az ad sp show --id http://$SERVICE_PRINCIPAL_NAME --query appId --output tsv)

## -------
## create resource group
az group delete --name=$CLUSTER_NAME --yes
az group create --name=$RESOURCE_GROUP --location=$LOCATION

## -------
## create acr
az acr create --resource-group=$RESOURCE_GROUP --name=$ACR_NAME --sku Basic
ACR_ID=$(az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP --query "id" --output tsv)
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --query loginServer --output tsv)
ACR_REGISTRY_ID=$(az acr show --name $ACR_NAME --query id --output tsv)

az role assignment create --assignee $SERVICE_PRINCIPAL_CLIENT_ID --role Reader --scope $ACR_ID

## -------
## create kubernetes cluster
az aks create --resource-group=$RESOURCE_GROUP --name=$CLUSTER_NAME --service-principal http://$SERVICE_PRINCIPAL_NAME --client-secret $SERVICE_PRINCIPAL_PASSWORD --generate-ssh-keys

## -------
## Download Kubernetes Credentials
az aks get-credentials --resource-group=$RESOURCE_GROUP --name=$CLUSTER_NAME 

## ------
## Kube Version
kubectl version

kubectl create secret docker-registry acr-auth --docker-server $ACR_LOGIN_SERVER --docker-username $SERVICE_PRINCIPAL_CLIENT_ID --docker-password $SERVICE_PRINCIPAL_PASSWORD --docker-email email@email.com