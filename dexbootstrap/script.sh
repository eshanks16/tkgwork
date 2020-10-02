#! /bin/bash

#Global Variables
cluster_repo=$1 #Repository for the Cluster Configs
cluster_branch=$2 #Branch for the Cluster Configs
cluster_name=$3 #Cluster Name
dex_repo=$4 #Dex Config Repository
dex_branch=$5 #Dex Config branch
lb_cert=$6 #Load Balancer Certificate
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
        echo "File exists - updating in place"
    else
        #File does not exist - Create File
        echo "File does NOT exist"
        cat > $file
    fi
    echo "Writing to file"
    yq w -i $file $field "$value"
    echo "Resetting directory"
    cd ..
}

push() {
    local repo=$1
    local branch=$2
    cd "$(basename "$repo" .git)"
    echo "The repository is $repo"
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
file_update $cluster_repo $cluster_branch $cluster_filename DEX_CA "$DEX_CA"
#Push the changes
push $cluster_repo $cluster_branch