#! /bin/bash
token=$1
cluster_name=$2
group_name=$3

#Login to TMC Console using a token
export TMC_API_TOKEN=$1
tmc login --name $cluster_name -c

#Attach the Cluster
tmc cluster attach --group=$group_name --name=$cluster_name

#Apply the configuration
kubectl apply -f k8s-attach-manifest.yaml