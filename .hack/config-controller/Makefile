# Source important environmental variables that need to be persisted and are easy to forget about
-include .env.make

cc-enable-apis: 
	@gcloud --project ${CONFIG_CONTROLLER_PROJECT_ID} services enable \
		cloudbuild.googleapis.com \
		krmapihosting.googleapis.com \
		cloudresourcemanager.googleapis.com \
		compute.googleapis.com

cc-vpc:
	# Create network
	@gcloud compute networks create ${CONFIG_CONTROLLER_NETWORK}-vpc \
		--subnet-mode=auto \
		--mtu=1460 \
		--bgp-routing-mode=global \
		--project=${CONFIG_CONTROLLER_PROJECT_ID}
	# Create subnet for admin VM
	@gcloud compute networks subnets create ${CONFIG_CONTROLLER_NETWORK}-bastion-subnet \
		--network=${CONFIG_CONTROLLER_NETWORK}-vpc \
		--range=${LOCAL_IP_ADDRESS_ADMIN_JUMPBOX}/28 \
		--description="Subnet to securely access the test cluster control plane" \
		--enable-flow-logs \
		--enable-private-ip-google-access \
		--purpose=PRIVATE \
		--region=${CONFIG_CONTROLLER_LOCATION}	
	# Firewall Rules
	@gcloud compute firewall-rules create allow-internal --network=projects/${CONFIG_CONTROLLER_PROJECT_ID}/global/networks/${CONFIG_CONTROLLER_NETWORK}-vpc \
		--direction ingress --source-ranges=10.0.0.0/8 --action=ALLOW --rules=all --project=${CONFIG_CONTROLLER_PROJECT_ID} 
	@gcloud compute firewall-rules create allow-internal-ssh-rdp --network=projects/${CONFIG_CONTROLLER_PROJECT_ID}/global/networks/${CONFIG_CONTROLLER_NETWORK}-vpc \
		--allow tcp:22,tcp:3389,icmp --direction ingress --source-ranges=10.0.0.0/8 --project=${CONFIG_CONTROLLER_PROJECT_ID} 
	@gcloud compute firewall-rules create allow-all-egress --network=projects/${CONFIG_CONTROLLER_PROJECT_ID}/global/networks/${CONFIG_CONTROLLER_NETWORK}-vpc \
		--action allow --direction egress --rules tcp,udp,icmp --destination-ranges 0.0.0.0/0 --project=${CONFIG_CONTROLLER_PROJECT_ID}
	@gcloud compute firewall-rules create allow-ssh-admin --allow tcp:22,tcp:3389,icmp \
		--source-ranges="35.235.240.0/20" --description="SSH via IAP" \
		--target-tags=ssh-iap \
		--network=projects/${CONFIG_CONTROLLER_PROJECT_ID}/global/networks/${CONFIG_CONTROLLER_NETWORK}-vpc
	# Cloud Router
	@gcloud compute routers create router-${CONFIG_CONTROLLER_NETWORK}-vpc --network ${CONFIG_CONTROLLER_NETWORK}-vpc \
		--region ${CONFIG_CONTROLLER_LOCATION} --project ${CONFIG_CONTROLLER_PROJECT_ID}
	# Cloud NAT
	@gcloud compute routers nats create nat-${CONFIG_CONTROLLER_NETWORK}-vpc --router-region ${CONFIG_CONTROLLER_LOCATION} \
		--router router-${CONFIG_CONTROLLER_NETWORK}-vpc --auto-allocate-nat-external-ips --nat-all-subnet-ip-ranges --project ${CONFIG_CONTROLLER_PROJECT_ID}		

cc-config-controller:
	@gcloud alpha anthos config controller create ${CONFIG_CONTROLLER_NAME} \
		--location=${CONFIG_CONTROLLER_LOCATION} \
		--network=${CONFIG_CONTROLLER_NETWORK}-vpc \
		--project=${CONFIG_CONTROLLER_PROJECT_ID} \
		--master-ipv4-cidr-block=172.16.0.0/28 \
		--man-block ${LOCAL_IP_ADDRESS_ADMIN_JUMPBOX}/24 \
		--use-private-endpoint

cc-admin-vm: admin-vm-sa
	@gcloud beta compute instances create cc-admin \
		--zone=${CONFIG_CONTROLLER_LOCATION}-b --machine-type=e2-small --subnet=${CONFIG_CONTROLLER_NETWORK}-bastion-subnet \
		--no-address --maintenance-policy=MIGRATE --service-account=cc-admin-sa@${CONFIG_CONTROLLER_PROJECT_ID}.iam.gserviceaccount.com \
    	--scopes=https://www.googleapis.com/auth/cloud-platform --tags=ssh-iap \
		--metadata=block-project-ssh-keys=true --image=debian-10-buster-v20220118 \
		--image-project=debian-cloud --boot-disk-size=10GB --boot-disk-type=pd-ssd \
		--boot-disk-device-name=dbs-k8s-jumpbox --shielded-secure-boot \
		--shielded-vtpm --shielded-integrity-monitoring --reservation-affinity=any -q \
		--metadata-from-file=startup-script=./.hack/network/k8s-admin-vm-startup.sh

admin-vm-sa:
	@gcloud iam service-accounts create cc-admin-sa \
	    --description="Admin for Config Controller access" \
	    --display-name="cc-admin-vm"
	@gcloud projects add-iam-policy-binding ${CONFIG_CONTROLLER_PROJECT_ID} \
		--condition=None \
		--member="serviceAccount:cc-admin-sa@${CONFIG_CONTROLLER_PROJECT_ID}.iam.gserviceaccount.com" \
		--role=roles/container.admin

cc-service-accounts:
	@gcloud resource-manager folders add-iam-policy-binding ${ORG_OR_FOLDER_ID} \
    	--member="serviceAccount:${CONFIG_CONTROLLER_SA}" \
    	--role='roles/resourcemanager.projectCreator'
	@gcloud resource-manager folders add-iam-policy-binding ${ORG_OR_FOLDER_ID} \
    	--member="serviceAccount:${CONFIG_CONTROLLER_SA}" \
    	--role='roles/resourcemanager.folderAdmin'		
	@gcloud projects add-iam-policy-binding ${CONFIG_CONTROLLER_PROJECT_ID} \
    	--member="serviceAccount:${CONFIG_CONTROLLER_SA}" \
    	--role='roles/serviceusage.serviceUsageAdmin'
	@gcloud projects add-iam-policy-binding ${CONFIG_CONTROLLER_PROJECT_ID} \
    	--member="serviceAccount:${CONFIG_CONTROLLER_SA}" \
    	--role='roles/iam.serviceAccountAdmin'
	@gcloud beta billing accounts add-iam-policy-binding ${BILLING_ACCOUNT_ID} \
    	--member="serviceAccount:${CONFIG_CONTROLLER_SA}" \
    	--role='roles/billing.user'

cc-gh-source-repo:
	@mkdir tmp
	@ssh-keygen -t rsa -b 4096 \
	    -C "${GH_EMAIL}" \
	    -N '' \
	    -f ./tmp/github-org-repo
	@kubectl create secret generic git-cc-source-repo \
	    -n config-management-system \
	    --from-file=ssh=tmp/github_cc_source_repo \
		--dry-run=client github_cc_source_repo \
		-o yaml > ./tmp/secret.yaml
	@mv ./tmp/secret.yaml distribution/configsync/overlays/source-repo
