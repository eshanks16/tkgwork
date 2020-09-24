FROM ubuntu:16.04

ENV HOME /root/

RUN apt-get update && \ 
    apt-get install -y jq curl git wget && \
    wget https://github.com/mikefarah/yq/releases/download/3.4.0/yq_linux_amd64 -O /usr/bin/yq && chmod +x /usr/bin/yq && \
    curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && chmod +x ./kubectl && mv ./kubectl /usr/local/bin && mkdir ~/.ssh/ && \
    curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/v1.7.6/argocd-linux-amd64 && chmod +x /usr/local/bin/argocd

COPY argobootstrap.sh .

ENTRYPOINT ["/bin/bash"]

CMD ["./argobootstrap.sh", "test", "testserver.domain.com"]
