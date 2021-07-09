#!/bin/bash -xe

## Need to be passed the machine index + bucket
BROKER_ID="${MYID}"
S3_CERTS_BUCKET="${S3_CERTS_BUCKET}"
SSL_FOLDER=/etc/kafka/ssl
TMP_FOLDER=/tmp/keystoregen
JAVA_HOME=/usr/lib/jvm/master-java
KEYTOOL="$JAVA_HOME/bin/keytool"
CACERTS="$JAVA_HOME/lib/security/cacerts"

# Pass madness
KEYSTORE_PASS="${KFKCFG_SSL_KEYSTORE_PASSWORD}"
SSL_PASS="${KFKCFG_SSL_KEY_PASSWORD}"

mkdir -p ${SSL_FOLDER}
mkdir -p ${TMP_FOLDER}

echo "Retrieving certificates & PK..."
aws s3 cp s3://${S3_CERTS_BUCKET}/${BROKER_ID}/cert ${TMP_FOLDER}
aws s3 cp s3://${S3_CERTS_BUCKET}/${BROKER_ID}/cert-issuer ${TMP_FOLDER}
aws s3 cp s3://${S3_CERTS_BUCKET}/${BROKER_ID}/key ${TMP_FOLDER}
aws s3 cp s3://${S3_CERTS_BUCKET}/ca-cert ${TMP_FOLDER}
# create cert full chain
cat ${TMP_FOLDER}/cert ${TMP_FOLDER}/cert-issuer > ${TMP_FOLDER}/cert-chain

# echo "Generating a p12 file including the keys + cert..."
openssl pkcs12 -export -in ${TMP_FOLDER}/cert-chain -inkey ${TMP_FOLDER}/key -name "localhost" -passout "pass:${SSL_PASS}" -out ${TMP_FOLDER}/certs.p12

echo "Importing the p12 into the keystore..."
${KEYTOOL} -importkeystore -srcstorepass "${SSL_PASS}" -deststorepass "${KEYSTORE_PASS}" -destkeypass "${SSL_PASS}"  -destkeystore ${SSL_FOLDER}/kafka.server.keystore.jks -srckeystore ${TMP_FOLDER}/certs.p12 -srcstoretype PKCS12 --noprompt

# import self signed cert into java cacerts
if [ -z "$CACERTS" ]; then
    echo "Error could not locate java truststore.."
    exit 1;
fi

# TODO: make optional
${KEYTOOL} -import -alias "kfkca" -keystore $CACERTS -file ${TMP_FOLDER}/ca-cert -deststorepass changeit -noprompt

rm -r /tmp/keystoregen

printf "\xf0\x9f\x9a\x80 Keystore & Truststore generated \xf0\x9f\x9a\x80\n"
