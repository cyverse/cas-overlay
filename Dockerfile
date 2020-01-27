FROM adoptopenjdk/openjdk13:alpine

RUN apk add --no-cache ca-certificates java-cacerts rsync && \
    mkdir -p /etc/cas/config /etc/cas/services /etc/cas-config/config /etc/cas-config/services

LABEL org.cyverse.git-ref="$git_commit"
LABEL org.cyverse.version="$version"
LABEL org.cyverse.descriptive-version="$descriptive_version"

COPY build/libs/cas.war /cas.war
COPY run-cas.sh /bin

EXPOSE 8443

ENTRYPOINT ["run-cas.sh"]
