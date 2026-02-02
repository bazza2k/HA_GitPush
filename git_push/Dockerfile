ARG BUILD_FROM
FROM $BUILD_FROM

# Install git and other dependencies
RUN \
    apk add --no-cache \
        git \
        openssh-client \
        bash \
        jq

# Copy run script
COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
