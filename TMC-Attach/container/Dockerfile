FROM ubuntu:16.04

ENV HOME /root/

RUN apt-get update && \ 
    apt-get install -y curl && \
    curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && chmod +x ./kubectl && mv ./kubectl /usr/local/bin && mkdir ~/.ssh/

COPY tmc /usr/local/bin/tmc
COPY tmc.sh .
RUN chmod +x tmc.sh /usr/local/bin/tmc

ENTRYPOINT ["/bin/bash"]

CMD ["./tmc.sh", "token", "cluster_name", "group_name"]
