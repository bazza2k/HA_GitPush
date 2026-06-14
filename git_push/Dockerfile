FROM ghcr.io/home-assistant/aarch64-base:3.19 

# Install git and other dependencies
RUN \
    apk add --no-cache \
        git \
        openssh-client \
        openssh \
        bash \
        jq

# Copy run script
COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
