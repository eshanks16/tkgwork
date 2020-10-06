#! /bin/bash

#Global Variables
cluster_repo=$1 #Repository for the Cluster Configs
cluster_branch=$2 #Branch for the Cluster Configs
cluster_name=$3 #Cluster Name
dex_repo=$4 #Dex Config Repository
dex_branch=$5 #Dex Config branch
lb_cert=$6 #Load Balancer Certificate
AWS_REGION=$7 #AWS Region
CLUSTER_CIDR=$8 #Cluster CIDR
AWS_SSH_KEY_NAME=$9 #SSH Key for AWS Nodes
SECURITY_GROUP_MOVEIP=${10}
ENV_NAME=${11} #Environment Name
AWS_VPC_ID=${12} #AWS VPC ID to use
CONTROL_PLANE_MACHINE_TYPE=${13} #Control Plane AWS Family
MONITORING_NODE_MACHINE_TYPE=${14} #Monitoring Node AWS Family
WORKER_NODE_MACHINE_TYPE=${15} #Worker Node AWS Family
CONTROL_PLANE_MACHINE_COUNT=${16} #Control Plane Quantity
WORKER_MACHINE_COUNT=${17} #Worker Machine Quantity
WORKER_MACHINE_COUNT_MONITORING=${18} #Monitor Machine Quantity
AVAILABILITY_ZONE_1=${19} #AZ1
AVAILABILITY_ZONE_2=${20} #AZ2
AVAILABILITY_ZONE_3=${21} #AZ3
BASTION_HOST_ENABLED=${22} #Using Bastion Host
NODE_STARTUP_TIMEOUT=${23} #Node Timeout
COMPUTE_NODE_MACHINE_TYPE=${24} #Compute Node Family
NODE_MACHINE_TYPE=${25} #Node Machines
AWS_NODE_AZ=${26} #Node AZ

cluster_filename=$cluster_name-tkg-mgmt.yaml #Filename of cluster config to update
tkg_dex_filename=$cluster_name-dex-tkg-mgmt.yaml #Filename of dex config to update

#Pull down git repo
clone() {
    local repo=$1
    echo "The repository is $repo"
    GIT_SSH_COMMAND='ssh -i /etc/ssh-key/vmw-mac' git clone $repo
}

#Update File within Git Repo
file_update() {
    local repo=$1
    local branch=$2
    local file=$3
    local field=$4
    local value=$5
    cd "$(basename "$repo" .git)"
    
    git checkout $branch
    if [ $(ls $file) ]
    then
        #File already exists - Update File
        echo "File $file exists - updating in place"
    else
        #File does not exist - Create File
        echo "File $file does NOT exist"
        cat > $file
    fi
    echo "Writing $field with value $value to file $file"
    yq w -i $file $field "$value"
    echo "Resetting directory"
    cd ..
}

push() {
    local repo=$1
    local branch=$2
    cd "$(basename "$repo" .git)"
    echo "Pushing Repo $repo"
    git checkout $branch
    git add .
    git commit -m "Updating Config Files through Dex Bootstrapper Automation"
    GIT_SSH_COMMAND='ssh -i /etc/ssh-key/vmw-mac' git push
    cd ..
}

#Clone any repos
git config --global user.email "dexautomation@dish.com"
git config --global push.default simple
clone $cluster_repo
clone $dex_repo

#Get Dex Load Balancer Address from the management cluster
lbaddress=$(kubectl get svc dexsvc -n tanzu-system-auth -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
while [ $? -ne 0 ]; do
    sleep 15
    lbaddress=$(kubectl get svc dexsvc -n tanzu-system-auth -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
done

echo "The load balancer address is: $lbaddress"

#Get DEX CA Certificate from the management cluster
DEX_CA=$(kubectl get secret dex-cert-tls -n tanzu-system-auth -o 'go-template={{ index .data "ca.crt" }}' | base64 -d | gzip | base64) 
while [ $? -ne 0 ]; do
    sleep 15
    DEX_CA=$(kubectl get secret dex-cert-tls -n tanzu-system-auth -o 'go-template={{ index .data "ca.crt" }}' | base64 -d | gzip | base64)
done

echo "The DEX CA Cert is: $DEX_CA"

#Update the tkg-dex repository
file_update $dex_repo $dex_branch $tkg_dex_filename DEX_LB_HOSTNAME $lbaddress
file_update $dex_repo $dex_branch $tkg_dex_filename CNAME $cluster_name-tkgdex.aws.imovetv.com
file_update $dex_repo $dex_branch $tkg_dex_filename LB_CERT $lb_cert
#Push the changes
push $dex_repo $dex_branch

#Update the Cluster Configuration Files
file_update $cluster_repo $cluster_branch $cluster_filename AWS_REGION $AWS_REGION
file_update $cluster_repo $cluster_branch $cluster_filename AWS_NODE_AZ $AWS_NODE_AZ
file_update $cluster_repo $cluster_branch $cluster_filename AWS_AVAILABILITY_ZONE_1 $AVAILABILITY_ZONE_1
file_update $cluster_repo $cluster_branch $cluster_filename AWS_AVAILABILITY_ZONE_2 $AVAILABILITY_ZONE_2
file_update $cluster_repo $cluster_branch $cluster_filename AWS_AVAILABILITY_ZONE_3 $AVAILABILITY_ZONE_3
file_update $cluster_repo $cluster_branch $cluster_filename SECURITY_GROUP_MOVEIP $SECURITY_GROUP_MOVEIP
file_update $cluster_repo $cluster_branch $cluster_filename AWS_PUBLIC_SUBNET_ID ""
file_update $cluster_repo $cluster_branch $cluster_filename AWS_PRIVATE_SUBNET_ID ""
file_update $cluster_repo $cluster_branch $cluster_filename AWS_SSH_KEY_NAME $AWS_SSH_KEY_NAME
file_update $cluster_repo $cluster_branch $cluster_filename AWS_VPC_ID $AWS_VPC_ID
file_update $cluster_repo $cluster_branch $cluster_filename NODE_MACHINE_TYPE $NODE_MACHINE_TYPE
file_update $cluster_repo $cluster_branch $cluster_filename CLUSTER_CIDR $CLUSTER_CIDR
file_update $cluster_repo $cluster_branch $cluster_filename CONTROL_PLANE_MACHINE_TYPE $CONTROL_PLANE_MACHINE_TYPE
file_update $cluster_repo $cluster_branch $cluster_filename MONITORING_MACHINE_TYPE $MONITORING_NODE_MACHINE_TYPE
file_update $cluster_repo $cluster_branch $cluster_filename WORKER_MACHINE_TYPE $WORKER_NODE_MACHINE_TYPE
file_update $cluster_repo $cluster_branch $cluster_filename COMPUTE_NODE_MACHINE_TYPE $COMPUTE_NODE_MACHINE_TYPE
file_update $cluster_repo $cluster_branch $cluster_filename BASTION_HOST_ENABLED $BASTION_HOST_ENABLED
file_update $cluster_repo $cluster_branch $cluster_filename overridesFolder /home/ubuntu/.tkg/overrides
file_update $cluster_repo $cluster_branch $cluster_filename NODE_STARTUP_TIMEOUT $NODE_STARTUP_TIMEOUT
file_update $cluster_repo $cluster_branch $cluster_filename CONTROL_PLANE_MACHINE_COUNT $CONTROL_PLANE_MACHINE_COUNT
file_update $cluster_repo $cluster_branch $cluster_filename ENV_NAME $ENV_NAME
file_update $cluster_repo $cluster_branch $cluster_filename WORKER_MACHINE_COUNT $WORKER_MACHINE_COUNT
file_update $cluster_repo $cluster_branch $cluster_filename MONITORING_MACHINE_COUNT $WORKER_MACHINE_COUNT_MONITORING
file_update $cluster_repo $cluster_branch $cluster_filename DEX_CA "$DEX_CA"
file_update $cluster_repo $cluster_branch $cluster_filename OIDC_ISSUER_URL $lbaddress
#Push the changes
push $cluster_repo $cluster_branch