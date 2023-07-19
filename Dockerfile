FROM alpine:latest as tmp

ENV JETTY_VERSION=9.4.29.v20200521 
ENV JETTY_HASH=71b572d99fe2c1342231ac3bd2e14327f523e532dd01ff203f331d52f2cf2747 
ENV JETTY_HOME=/opt/jetty-home 
ENV JETTY_BASE=/opt/jetty-base 
ENV JAVA_HOME=/usr/lib/jvm/default-jvm 
ENV PATH=$PATH:$JAVA_HOME/bin

LABEL maintainer="Noriyuki TAKEI"

RUN apk --no-cache add wget tar openjdk11-jre-headless 

# Jettyをダウンロードする。
RUN wget -q https://repo1.maven.org/maven2/org/eclipse/jetty/jetty-distribution/$JETTY_VERSION/jetty-distribution-$JETTY_VERSION.tar.gz \
    && echo "$JETTY_HASH  jetty-distribution-$JETTY_VERSION.tar.gz" | sha256sum -c - \
    && tar -zxvf jetty-distribution-$JETTY_VERSION.tar.gz -C /opt \
    && ln -s /opt/jetty-distribution-$JETTY_VERSION/ $JETTY_HOME \
    && rm jetty-distribution-$JETTY_VERSION.tar.gz

# Jettyの初期設定を行う。
RUN mkdir -p $JETTY_BASE/modules $JETTY_BASE/lib/ext $JETTY_BASE/lib/logging $JETTY_BASE/resources \
    && cd $JETTY_BASE \
    && $JAVA_HOME/bin/java -jar $JETTY_HOME/start.jar --create-startd --add-to-start=http2,http2c,deploy,ext,annotations,jstl,rewrite,ssl,http-forwarded

COPY opt/jetty-base/etc/tweak-ssl.xml $JETTY_BASE/etc/tweak-ssl.xml
COPY opt/jetty-base/webapps/idp.xml $JETTY_BASE/webapps/idp.xml

FROM alpine:latest

ENV IDP_VERSION=4.3.1
ENV IDP_HASH=04d08d324a5a5f016ca69b96dbab58abbb5b3e0045455cc15cf0d33ffd6742d5

ENV JETTY_HOME=/opt/jetty-home
ENV JETTY_BASE=/opt/jetty-base
ENV JETTY_KEYSTORE_PASSWORD=storepwd
ENV JETTY_KEYSTORE_PATH=etc/keystore
ENV IDP_HOME=/opt/shibboleth-idp
ENV JAVA_HOME=/usr/lib/jvm/default-jvm
ENV IDP_SRC=/opt/shibboleth-identity-provider-$IDP_VERSION
ENV IDP_SCOPE=example.org
ENV IDP_HOST_NAME=idp.example.org
ENV IDP_ENTITY_ID=https://idp.example.org/idp/shibboleth
ENV IDP_KEYSTORE_PASSWORD=password
ENV IDP_SEALER_PASSWORD=password
ENV JETTY_JAVA_ARGS="jetty.home=$JETTY_HOME \
    jetty.base=$JETTY_BASE \
    -Djetty.sslContext.keyStorePassword=$JETTY_KEYSTORE_PASSWORD \
    -Djetty.sslContext.keyStorePath=$JETTY_KEYSTORE_PATH"
ENV PATH=$PATH:$JAVA_HOME/bin

RUN apk --no-cache add openjdk11-jre-headless curl bash

LABEL maintainer="Noriyuki TAKEI"

COPY bin/ /usr/local/bin/

RUN chmod +x /usr/local/bin/gen-idp-conf.sh

COPY --from=tmp /opt/ /opt/
COPY /opt/ /opt/

# HTTP(8080)、HTTPS(8443)のポートを開ける。
EXPOSE 8080 8443

# Jettyを起動する。
CMD $JAVA_HOME/bin/java -jar $JETTY_HOME/start.jar $JETTY_JAVA_ARGS
