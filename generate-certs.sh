#!/bin/sh
set -e

DIR=certs/kafka
rm -rf $DIR && mkdir -p $DIR && cd $DIR

## 1. Create certificate authority (CA)
openssl req -new -x509 -keyout ca-key -out ca-cert -days 3650 -passin pass:kafkadocker -passout pass:kafkadocker -subj "/CN=localhost/OU=Saneet Bhella/O=Saneet Bhella/L=Wolverhampton/ST=West Midlands/C=GB"

## 2. Create client keystore
keytool -noprompt -keyalg RSA -keystore client.keystore.jks -genkey -alias localhost -dname "CN=localhost, OU=Saneet Bhella, O=Saneet Bhella, L=Wolverhampton, ST=West Midlands, C=GB" -storepass kafkadocker -keypass kafkadocker

## 3. Create server keystore
keytool -noprompt -keyalg RSA -keystore server.keystore.jks -genkey -alias kafka -dname "CN=localhost, OU=Saneet Bhella, O=Saneet Bhella, L=Wolverhampton, ST=West Midlands, C=GB" -storepass kafkadocker -keypass kafkadocker

## 4. Sign client certificate
keytool -noprompt -keyalg RSA -keystore client.keystore.jks -alias localhost -certreq -file cert-unsigned -storepass kafkadocker
openssl x509 -req -CA ca-cert -CAkey ca-key -in cert-unsigned -out cert-signed -days 3650 -CAcreateserial -passin pass:kafkadocker

## 5. Import CA and signed client certificate into client keystore
keytool -noprompt -keyalg RSA -keystore client.keystore.jks -alias CARoot -import -file ca-cert -storepass kafkadocker
keytool -noprompt -keyalg RSA -keystore client.keystore.jks -alias localhost -import -file cert-signed -storepass kafkadocker

## 6. Import CA into server truststore
keytool -noprompt -keyalg RSA -keystore server.truststore.jks -alias CARoot -import -file ca-cert -storepass kafkadocker

## 7. Sign server certificate
keytool -noprompt -keyalg RSA -keystore server.keystore.jks -alias kafka -certreq -file cert-unsigned -storepass kafkadocker
openssl x509 -req -CA ca-cert -CAkey ca-key -in cert-unsigned -out cert-signed -days 3650 -CAcreateserial -passin pass:kafkadocker

## 8. Import CA and signed server certificate into server keystore
keytool -noprompt -keyalg RSA -keystore server.keystore.jks -alias CARoot -import -file ca-cert -storepass kafkadocker
keytool -noprompt -keyalg RSA -keystore server.keystore.jks -alias kafka -import -file cert-signed -storepass kafkadocker

## 9. Extract signed client certificate
keytool -noprompt -keyalg RSA -keystore client.keystore.jks -exportcert -alias localhost -rfc -storepass kafkadocker -file certificate.pem

## 10. Extract client key
keytool -noprompt -keyalg RSA -srckeystore client.keystore.jks -importkeystore -srcalias localhost -destkeystore cert_and_key.p12 -deststoretype PKCS12 -srcstorepass kafkadocker -storepass kafkadocker
openssl pkcs12 -in cert_and_key.p12 -nocerts -nodes -passin pass:kafkadocker -out private_key.pem

## 11. Extract CA certificate
keytool -noprompt -keyalg RSA -keystore client.keystore.jks -exportcert -alias CARoot -rfc -file ca.pem -storepass kafkadocker

## 12. Remove unnecessary files
rm ca-key ca-cert ca-cert.srl cert_and_key.p12 cert-signed cert-unsigned client.keystore.jks

## 13. Add credentials to file
cat > kafka-credentials << EOF
kafkadocker
EOF
