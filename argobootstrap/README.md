The purpose of this container is to add a provisioned TKG cluster to ArgoCD
after it's been provisioned.

Accepts inputs:
-   Cluster - The newly provisioned TKG child cluster. This is likely already
    part of a helm template.
-   argoserver - the name of the argoserver in which to register the child
    cluster.


This container mounts a secret that has the username/password combination needed
to login to the argocd server. 
