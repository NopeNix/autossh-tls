FROM alpine:3.18

LABEL org.opencontainers.image.title="autossh-tls" \
      org.opencontainers.image.description="Properly configured autossh over TLS with SNI & real monitoring" \
      org.opencontainers.image.authors="Phil" \
      org.opencontainers.image.source="https://github.com/yourname/autossh-tls" \
      org.opencontainers.image.licenses="MIT"

RUN apk add --no-cache \
    autossh \
    openssh-client \
    openssl \
    ca-certificates

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY ssh-tls-wrapper.sh /usr/local/bin/ssh-tls-wrapper.sh 

RUN chmod +x /usr/local/bin/entrypoint.sh \
             /usr/local/bin/ssh-tls-wrapper.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]