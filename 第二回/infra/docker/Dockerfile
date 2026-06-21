FROM codercom/code-server:latest

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    unzip \
  && curl -sL https://aka.ms/InstallAzureCLIDeb | bash \
  && curl -fsSL https://apt.releases.hashicorp.com/gpg \
    | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg \
  && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
    > /etc/apt/sources.list.d/hashicorp.list \
  && apt-get update \
  && apt-get install -y --no-install-recommends terraform \
  && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /usr/local/bin/workshop-entrypoint.sh
RUN chmod +x /usr/local/bin/workshop-entrypoint.sh

USER coder
WORKDIR /home/coder/workshop

ENTRYPOINT ["/usr/local/bin/workshop-entrypoint.sh"]
