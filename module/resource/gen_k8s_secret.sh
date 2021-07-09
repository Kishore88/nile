#!/bin/bash -xe

TMP_FOLDER=/tmp/kafka/
SECRET_NAMESPACE=${SECRET_NAMESPACE}
SECRET_NAME=${SECRET_NAME}
SECRET_KEY_VALUE=${SECRET_KEY_VALUE}
SASL_CONNECT_EXTRAS=${SASL_CONNECT_EXTRAS}

mkdir -p $TMP_FOLDER

secret_exists(){
  if [ "$(kubectl describe secrets/$1 -n $2 2>/dev/null | grep -ic opaque)" -ge 1 ]
  then
      echo "k8s secret $1 exist - deleting it"
      kubectl delete secret $1 -n $2
  fi
}

# create namespace
if [ "$(kubectl get namespaces | grep -c $SECRET_NAMESPACE)" -eq 0 ]
then
    echo "k8s namespace $SECRET_NAMESPACE doesnt exist - creating it"
    cat > $TMP_FOLDER/kafka.json << EOF
    {
      "apiVersion": "v1",
      "kind": "Namespace",
      "metadata": {
        "name": "$SECRET_NAMESPACE",
        "labels": {
          "name": "$SECRET_NAMESPACE"
        }
      }
    }
EOF
    kubectl create -f $TMP_FOLDER/kafka.json
fi

secret_exists $SECRET_NAME $SECRET_NAMESPACE $SECRET_KEY_NAME
echo $SECRET_KEY_VALUE > $TMP_FOLDER/sasl_jaas_config

if [ $SASL_CONNECT_EXTRAS -eq 1 ]
  then
    echo "with connect ssl extra"
    echo $SECRET_KEY_VALUE > $TMP_FOLDER/consumer_sasl_jaas_config
    echo $SECRET_KEY_VALUE > $TMP_FOLDER/producer_sasl_jaas_config
    kubectl create secret generic $SECRET_NAME -n $SECRET_NAMESPACE \
      --from-file=$TMP_FOLDER/sasl_jaas_config \
      --from-file=$TMP_FOLDER/consumer_sasl_jaas_config \
      --from-file=$TMP_FOLDER/producer_sasl_jaas_config
  else
    kubectl create secret generic $SECRET_NAME -n $SECRET_NAMESPACE \
      --from-file=$TMP_FOLDER/sasl_jaas_config
fi