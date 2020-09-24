#! /bin/bash
cluster=$1
argoserver=$2

# find out what status the cluster is in
get_cluster_status(){
    status=$(kubectl get cluster $cluster -o json | jq '.status.phase')
    echo $status
}

# get tkg credentials for a cluster
get_creds(){
    ###result=$(tkg get credentials $cluster)
    kubectl get secret $cluster-kubeconfig -o jsonpath='{.data.value}' | base64 -d > ./$cluster-kubeconfig
    echo $result
}

add2argo(){
    #Login to argocd
    argologin=$(argocd login $argoserver --username $(cat /etc/argosecrets/username) --password $(cat /etc/argosecrets/password) --insecure)
    export KUBECONFIG=./$cluster-kubeconfig
    result=$(argocd cluster add $cluster-admin@$cluster)
    echo $result
}

i=1
clusterstatus=NULL
#timeout at (60 loops * 30 seconds) = 30 minutes
until [ $i -gt 60 ]
do 
    clusterstatus=$(get_cluster_status $cluster)
    if [[ $clusterstatus == '"Provisioned"' ]]
    then
        echo "Cluster has been provisioned"
        creds=$(get_creds $cluster)
        argoresult=$(add2argo)
        if [ $? -eq 0 ]
        then
            break
        fi
    else
        echo "Waiting on Cluster..."
    fi
    
    #timeout
    i=$(( i+1 )) 
    sleep 30
done

