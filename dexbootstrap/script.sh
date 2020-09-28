#! /bin/bash
repo=$1
branch=$2
cluster_name=$3
lb_cert=$4
filename=$cluster_name-tkg-mgmt.yaml

#Pull down the git repository with the Values file to be updated.
GIT_SSH_COMMAND='ssh -i /etc/ssh-key/vmw-mac' git clone $repo
cd "$(basename "$repo" .git)"
git checkout $branch
git config user.email "dexautomation@dish.com"
git config --global push.default simple

#Get Dex Load Balancer Address from the management cluster
lbaddress=$(kubectl get svc dexsvc -n tanzu-system-auth -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
while [ $? -ne 0 ]; do
    sleep 15
    lbaddress=$(kubectl get svc dexsvc -n tanzu-system-auth -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
done

echo "The load balancer address is: $lbaddress"

#Write the load balancer address into the values file
#yq w -i $file $parameter $lbaddress

####Additions
if [ $(ls $cluster_name-tkg-mgmt.yaml) -eq 0 ]
then
    #File already exists - Update File
    echo "File exists - updating in place"
    yq w -i $filename DEX_LB_HOSTNAME $lbaddress
    yq w -i $filename CNAME $cluster_name-tkgdex.aws.imovetv.com
    yq w -i $filename LB_CERT $lb_cert
else
    #File does not exist - Create File
    echo "File does NOT exist"
    cat > $filename
    yq w -i $filename DEX_LB_HOSTNAME $lbaddress
    yq w -i $filename CNAME $cluster_name-tkgdex.aws.imovetv.com
    yq w -i $filename LB_CERT $lb_cert
fi

#############


#Push the changes back to git
git add $filename
git commit -m "Updating Dex LoadBalancer Value"
GIT_SSH_COMMAND='ssh -i /etc/ssh-key/vmw-mac' git push