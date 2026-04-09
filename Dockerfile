FROM python:alpine

# Set environment variables
# ENV KUBECTL_VERSION=$(curl -s https://dl.k8s.io/release/stable.txt)

ADD run.sh /run.sh
RUN chmod 755 /run.sh

# Install required packages
RUN apk add --no-cache \
    bash \
    curl \
    jq \
    netcat-openbsd

RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl \
	&& mv kubectl /usr/local/bin \
	&& chmod +x /usr/local/bin/kubectl

RUN curl -fsSL https://raw.githubusercontent.com/scaleway/scaleway-cli/master/scripts/get.sh | sh


# RUN curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
#     && chmod +x kubectl \
#     && mv kubectl /usr/local/bin/kubectl

    
RUN adduser -S user
USER user
WORKDIR /home/user
ENV PATH=/usr/local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/home/user/.local/bin

RUN pip install awscli --upgrade --user