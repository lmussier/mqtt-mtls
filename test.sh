CERT_FOLDER=certs
CSR_FILE=$CERT_FOLDER/client.csr
KEY_FILE=$CERT_FOLDER/client.key
CRT_FILE=$CERT_FOLDER/client.crt
CA_FILE=$CERT_FOLDER/mosquitto.org.crt

TYPE="TPM"

rm -rf $CERT_FOLDER
mkdir $CERT_FOLDER

echo "Generate a private key"
if [ TYPE = "TPM" ]; then
    openssl genpkey -provider tpm2 -propquery '?provider=tpm2' -algorithm EC -pkeyopt group:P-256 -out $KEY_FILE
else
    openssl genrsa -out $CERT_FOLDER/client.key
fi

echo "Generate a CSR"
if [ TYPE = "TPM" ]; then
    openssl req -provider tpm2 -provider default -propquery '?provider=tpm2' -new -subj "/C=FR/ST=Isere/L=Grenoble/O=Schneider Electric/OU=ETP CDM/CN=DM WITH DM" -key $KEY_FILE -out $CSR_FILE
else
    openssl req -out $CSR_FILE \
                -key $KEY_FILE \
                -subj "/C=FR/ST=Isere/L=Grenoble/O=Schneider Electric/OU=ETP CDM/CN=DM WITHOUT TPM" \
                -new
fi    

CSR=`cat $CSR_FILE`
DATA="csr="$CSR

echo "Get broker's ca cert"
curl http://test.mosquitto.org/ssl/mosquitto.org.crt --location -o $CA_FILE

echo "Ask for connection certificate"
curl 'https://test.mosquitto.org/ssl/index.php' --location -X POST --data-urlencode "$DATA" -o $CRT_FILE


echo "MQTT4"
mosquitto_pub -d -h test.mosquitto.org -p 8884 -t 'lmu/test' --cafile $CA_FILE --cert $CRT_FILE --key $KEY_FILE -m plop
