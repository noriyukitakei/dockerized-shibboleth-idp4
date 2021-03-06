#!/bin/bash

# Shibboleth Idpをダウンロードして、設定ファイルを作成する。
IDP_SRC=/opt/shibboleth-identity-provider-$IDP_VERSION
echo "Generating Shibboleth IdP Configuration... This may take some time."

DL_URL=https://shibboleth.net/downloads/identity-provider/$IDP_VERSION/shibboleth-identity-provider-$IDP_VERSION.tar.gz

status=`curl -ks $DL_URL -o /dev/null -w '%{http_code}\n'`

if [ $status = "404" ]; then
  DL_URL=https://shibboleth.net/downloads/identity-provider/archive/$IDP_VERSION/shibboleth-identity-provider-$IDP_VERSION.tar.gz
fi

wget -q $DL_URL \
&& echo "$IDP_HASH  shibboleth-identity-provider-$IDP_VERSION.tar.gz" | sha256sum -c - \
&& tar -zxvf  shibboleth-identity-provider-$IDP_VERSION.tar.gz -C /opt \
&& $IDP_SRC/bin/install.sh \
-Didp.scope=$IDP_SCOPE \
-Didp.target.dir=$IDP_HOME \
-Didp.src.dir=$IDP_SRC \
-Didp.scope=$IDP_SCOPE \
-Didp.host.name=$IDP_HOST_NAME \
-Didp.noprompt=true \
-Didp.sealer.password=$IDP_SEALER_PASSWORD \
-Didp.keystore.password=$IDP_KEYSTORE_PASSWORD \
-Didp.entityID=$IDP_ENTITY_ID \
&& rm shibboleth-identity-provider-$IDP_VERSION.tar.gz \
&& rm -rf shibboleth-identity-provider-$IDP_VERSION

mkdir -p /ext-mount/shibboleth-idp/

# 作成したShibboleth IdPの設定ファイルを、マウントしているホスト上のディレクトリにコピーする。
cd /opt/shibboleth-idp
cp -r * /ext-mount/shibboleth-idp/

echo "Finished generating Shibboleth IdP Configuration!!"
