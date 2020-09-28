FROM ubuntu:16.04

ENV HOME /root/

RUN apt-get update && \ 
    apt-get install -y jq curl git wget && \
    wget https://github.com/mikefarah/yq/releases/download/3.4.0/yq_linux_amd64 -O /usr/bin/yq && chmod +x /usr/bin/yq && \
    curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && chmod +x ./kubectl && mv ./kubectl /usr/local/bin && mkdir ~/.ssh/

COPY script.sh .
COPY sshconfig $HOME/.ssh/config

ENTRYPOINT ["/bin/bash"]

CMD ["./script.sh", "git@github.com:eshanks16/tkgtest.git", "branchname", "cluster_name", "LB_CERT"]
