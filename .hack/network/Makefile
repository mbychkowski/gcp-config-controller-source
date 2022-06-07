# Source important environmental variables that need to be persisted and are easy to forget about
-include .env.make

network:
	# Create custom network for the cluster
	@gcloud compute networks create ${CONFIG_CONTROLLER_NETWORK}-net --description="VPC Network for the GKE Cluster hosting Config Connector & Policy Controller" \
		--subnet-mode=custom
	# Create subnet for the cluster
	@gcloud compute networks subnets create ${CONFIG_CONTROLLER_NETWORK}-subnet \
		--network=${CONFIG_CONTROLLER_NETWORK}-net \
		--range=${LOCAL_IP_ADDRESS_CONFIG_CONTROLLER}/28 \
		--secondary-range pod=${VPC_NATIVE_IP_ADDRESS_POD}/20 \
		--secondary-range svc=${VPC_NATIVE_IP_ADDRESS_SVC}/25 \		
		--description="Subnet for the automation cluster" \
		--enable-flow-logs \
		--enable-private-ip-google-access \
		--purpose=PRIVATE \
		--region=${CONFIG_CONTROLLER_LOCATION}
	# Create subnet for admin VM
	@gcloud compute networks subnets create ${CONFIG_CONTROLLER_NETWORK}-subnet-admin \
		--network=${CONFIG_CONTROLLER_NETWORK}-net \
		--range=${LOCAL_IP_ADDRESS_ADMIN_JUMPBOX}/28 \
		--description="Subnet to securely access the test cluster control plane" \
		--enable-flow-logs \
		--enable-private-ip-google-access \
		--purpose=PRIVATE \
		--region=${CONFIG_CONTROLLER_LOCATION}
	# Create firewall rule
	@gcloud compute firewall-rules create allow-ssh-admin --allow tcp:22,tcp:3389,icmp \
		--source-ranges="35.235.240.0/20" --description="SSH via IAP" \
		--target-tags=ssh-iap \
		--network=${CONFIG_CONTROLLER_NETWORK}-net
	# Create a Cloud Router for the admin VM subnet:
	@gcloud compute routers create ${CONFIG_CONTROLLER_NETWORK}-router \
		--network=${CONFIG_CONTROLLER_NETWORK}-net \
		--region=${CONFIG_CONTROLLER_LOCATION}
	# Create NAT 
	@gcloud compute routers nats create ${CONFIG_CONTROLLER_NETWORK}-nat \
	    --router=${CONFIG_CONTROLLER_NETWORK}-router \
	    --auto-allocate-nat-external-ips \
	    --router-region=${CONFIG_CONTROLLER_LOCATION} \
	    --nat-custom-subnet-ip-ranges=${CONFIG_CONTROLLER_NETWORK}-subnet-admin,${CONFIG_CONTROLLER_NETWORK}-subnet -q

k8s-admin-vm:
	@gcloud beta compute instances create k8s-admin \
		--zone=${CONFIG_CONTROLLER_LOCATION}-b --machine-type=e2-small --subnet=${CONFIG_CONTROLLER_NETWORK}-vpc \
		--no-address --maintenance-policy=MIGRATE --no-service-account --no-scopes \
		--tags=ssh-iap --private-network-ip=10.142.1.1 --metadata=block-project-ssh-keys=true \
		--image=debian-10-buster-v20220118 --image-project=debian-cloud --boot-disk-size=10GB \
		--boot-disk-type=pd-ssd --boot-disk-device-name=dbs-k8s-jumpbox --shielded-secure-boot \
		--shielded-vtpm --shielded-integrity-monitoring --reservation-affinity=any -q \
		--metadata-from-file=startup-script=./.hack/network/k8s-admin-vm-startup.sh
