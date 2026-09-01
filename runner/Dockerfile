FROM jenkins/jenkins:2.568.1-lts-jdk21

USER root

ARG COMPOSE_VERSION=v2.35.1
ARG DOCKER_VERSION=29.6.2
ARG OC_CLIENT_URL=https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable/openshift-client-linux.tar.gz

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl nodejs npm tar \
    && npm install --global newman@6 \
    && curl --fail --location --silent --show-error \
        "https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VERSION}.tgz" \
        | tar --extract --gzip --file - --strip-components=1 --directory /usr/local/bin docker/docker \
    && install -d -m 0755 /usr/local/lib/docker/cli-plugins \
    && curl --fail --location --silent --show-error \
        "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-x86_64" \
        --output /usr/local/lib/docker/cli-plugins/docker-compose \
    && chmod +x /usr/local/lib/docker/cli-plugins/docker-compose \
    && curl --fail --location --silent --show-error "$OC_CLIENT_URL" \
        | tar --extract --gzip --file - --directory /usr/local/bin oc kubectl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

USER jenkins
