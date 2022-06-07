# GCP ACM + ASM Confi Controller


## Initial setup of environment variables

Create a config shell script to create all environmnet variables

Note:
* To determine ip address: `curl -4 ifconfig.co`.

```
make authenticate
```

```
WORK_DIR=$(pwd)/
touch ${WORK_DIR}acm-workshop-variables.sh
chmod +x ${WORK_DIR}acm-workshop-variables.sh
```

```
RANDOM_SUFFIX=$(shuf -i 100-999 -n 1)
BILLING_ACCOUNT_ID=019C42-BDA7E5-0365C4
ORG_OR_FOLDER_ID=131889245670
GH_EMAIL=mbychkowski@google.com
echo "export BILLING_ACCOUNT_ID=${BILLING_ACCOUNT_ID}" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export ORG_OR_FOLDER_ID=${ORG_OR_FOLDER_ID}" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export AUTHORIZED_GCP_IP_ADDRESS=${AUTHORIZED_GCP_IP_ADDRESS}" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export CONFIG_CONTROLLER_PROJECT_ID=acm-workshop-${RANDOM_SUFFIX}" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export GH_EMAIL=${GH_EMAIL}" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```

From an fresh environment with folder created in GCP. Create project under folder using folder id:

```
make create-project
```

```
PROJECT_NUMBER=$(gcloud projects list --filter="$(gcloud config get-value project)" --format="value(PROJECT_NUMBER)")
AUTHORIZED_GCP_IP_ADDRESS=35.233.207.90
LOCAL_IP_ADDRESS_CONFIG_CONTROLLER=10.0.0.0
LOCAL_IP_ADDRESS_ADMIN_JUMPBOX=10.0.1.0
VPC_NATIVE_IP_ADDRESS_POD=172.16.0.0
VPC_NATIVE_IP_ADDRESS_SVC=192.168.64.0
echo "export CONFIG_CONTROLLER_PROJECT_NUMBER=${PROJECT_NUMBER}" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export CONFIG_CONTROLLER_NAME=configcontroller" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export CONFIG_CONTROLLER_LOCATION=us-east1" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export CONFIG_CONTROLLER_NETWORK=cc-admin" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export CONFIG_CONTROLLER_SA=service-${PROJECT_NUMBER}@gcp-sa-yakima.iam.gserviceaccount.com" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export ACCESS_TOKEN_FILE=${WORK_DIR}access-token-file.txt" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export LOCAL_IP_ADDRESS_CONFIG_CONTROLLER=${LOCAL_IP_ADDRESS_CONFIG_CONTROLLER}" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export LOCAL_IP_ADDRESS_ADMIN_JUMPBOX=${LOCAL_IP_ADDRESS_ADMIN_JUMPBOX}" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export VPC_NATIVE_IP_ADDRESS_POD=${VPC_NATIVE_IP_ADDRESS_POD}" >> ${WORK_DIR}acm-workshop-variables.sh
echo "export VPC_NATIVE_IP_ADDRESS_SVC=${VPC_NATIVE_IP_ADDRESS_SVC}" >> ${WORK_DIR}acm-workshop-variables.sh
source ${WORK_DIR}acm-workshop-variables.sh
```

Apply policies that are required for GKE creations:

```
make argolis-policy
```

## Stand up config controller instance

This step involves creating the network to host the GKE cluster instance of config controller running. This can be improved by not running in Auto mode for network.

```
make cc-vpc
```

```
make cc-config-controller
```

To interact with the private `configcontroller` cluster we will create a jumpbox within GCP. Determine the ip range of the subnet running `configcontroller`

```
gcloud compute networks subnets describe ${CONFIG_CONTROLLER_NETWORK}-vpc \
    --region ${CONFIG_CONTROLLER_LOCATION} \
    --format 'value(ipCidrRange)'
```

Replace that value within `.hack/config-controller/Makefile` command `k8s-admin-vm` as appropriate.

```
gcloud beta compute instances create k8s-admin \
    ...
    --private-network-ip=10.XXX.1.1
    ...
```

To access cluster via cloud shell:

```
AUTHORIZED_SHELL_NETWORK=dig +short myip.opendns.com @resolver1.opendns.com

gcloud container clusters update krmapihost-configcontroller  \
    --enable-master-authorized-networks \
    --master-authorized-networks ${AUTHORIZED_SHELL_NETWORK}/32 \
    --region ${CONFIG_CONTROLLER_LOCATION} \
    --project ${CONFIG_CONTROLLER_PROJECT_ID}
```

Get the Config Controller instance credentials

```
gcloud anthos config controller get-credentials ${CONFIG_CONTROLLER_NAME} \
    --location ${CONFIG_CONTROLLER_LOCATION}
```