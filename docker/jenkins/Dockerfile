FROM jenkins/jenkins:lts-jdk17

USER root

RUN apt-get update \
    && apt-get install -y --no-install-recommends docker-cli docker.io curl \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -g 119 dockersock \
    && usermod -aG dockersock jenkins

RUN curl -fsSL https://dl.k8s.io/release/v1.29.15/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl

USER jenkins

COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt
