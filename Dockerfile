FROM java:8-alpine

RUN apk add --no-cache ca-certificates java-cacerts

LABEL org.cyverse.git-ref="$git_commit"
LABEL org.cyverse.version="$version"
LABEL org.cyverse.descriptive-version="$descriptive_version"

ADD target/cas.war /cas.war

EXPOSE 8443

ENTRYPOINT ["java", "-jar", "/cas.war"]
