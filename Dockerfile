FROM debian as builder

LABEL maintainer="Nicolas LAURENT <docker@aegypius.com>"

RUN apt-get update -qy && apt-get install -y curl lzma

ARG ARCH

ENV DEBUG=false \
  DOCKER_GEN_VERSION=0.7.6 \
  MKCERT_VERSION=1.4.3 \
  SANDBOX_VERSION=2.2 \
  ARCH=${ARCH:-amd64} \
  DOCKER_HOST=unix:///var/run/docker.sock

# Install docker-gen
WORKDIR /usr/local/bin

RUN curl -L https://github.com/nginx-proxy/docker-gen/releases/download/${DOCKER_GEN_VERSION}/docker-gen-linux-${ARCH}-${DOCKER_GEN_VERSION}.tar.gz  | tar -C . -xz

# Install mkcert
RUN curl -L https://github.com/FiloSottile/mkcert/releases/download/v${MKCERT_VERSION}/mkcert-v${MKCERT_VERSION}-linux-${ARCH} -o ./mkcert

FROM debian

ENV DEBUG=false \
  DOCKER_HOST=unix:///var/run/docker.sock \
  CAROOT=/app/ca

VOLUME /app/certs /app/ca
WORKDIR /app/certs

RUN apt-get update -qqy && apt-get install -qy openssl libnss3-tools ca-certificates procps jq curl

COPY --from=builder /usr/local/bin/docker-gen /usr/local/bin/docker-gen
COPY --from=builder /usr/local/bin/mkcert /usr/local/bin/mkcert
COPY ./app /app
RUN chmod +x /usr/local/bin/docker-gen /usr/local/bin/mkcert /app/*

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["/app/start.sh"]
