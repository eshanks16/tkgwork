#! /bin/bash
repo=$1
file=$2
branch=$3
parameter=$4 #YQ Value

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
yq w -i $file $parameter $lbaddress

#Push the changes back to git
git add $file
git commit -m "Updating Dex LoadBalancer Value"
GIT_SSH_COMMAND='ssh -i /etc/ssh-key/vmw-mac' git push