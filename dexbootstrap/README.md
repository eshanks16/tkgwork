There are a few assumptions that are necessary for this code to work.
 
Assumptions:
-   There is a secret created within the TKG management that has the credentials to access whatever git repository is to be used. We likely need to do this in Gitlab ahead of time when the cluster is built.
-   The Dex service has already been created and is named “dexsvc” within the tanzu-system-auth namespace
Build and Push your new docker image and update the Kubernetes manifest to reference the name of that image
 
Instructions:
-   You’ll want to build the container from the Dockerfile after updating your secret name (Mine was `vmw-mac`) replace my secret with the name of your secret.
-   You can also update the CMD field in the Dockerfile to place default parameters if you’d like. This isn’t necessary if you pass them in at runtime through the k8s manifest
-   Update the Kubernetes manifest (helm template) named dexbootstrapper.yaml with the correct ARGS

`./script.sh` is the name of the script to be run when the container starts (DON’T Modify this)

There are a list of variables that need to be updated.
Each parameter in ./script.sh must have a corresponding argument in the correct
order, from the dexbootstrapper.yaml file.

-   Update the sshconfig to include any hosts where you'll pull from git. This
    disables host checking.
