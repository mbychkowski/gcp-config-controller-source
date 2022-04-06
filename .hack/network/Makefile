# Source important environmental variables that need to be persisted and are easy to forget about
-include .env.make

network:
	# Create custom network for the cluster
	@gcloud compute networks create kpt-test-net --description="VPC Network for the Test GKE Cluster hosting Config Connector & Policy Controller" \
		--subnet-mode=custom
	# Create subnet for the cluster
	@gcloud compute networks subnets create kpt-test-subnet \
		--network=kpt-test-net \
		--range=10.0.0.0/28 \
		--secondary-range svc=192.168.64.0/25 \
		--secondary-range pod=172.16.0.0/20 \
		--description="Subnet for the automation cluster" \
		--enable-flow-logs \
		--enable-private-ip-google-access \
		--purpose=PRIVATE \
		--region=us-central1
	# Create subnet for admin VM
	@gcloud compute networks subnets create kpt-test-admin-subnet \
		--network=kpt-test-net \
		--range=10.0.1.0/28 \
		--description="Subnet to securely access the test cluster control plane" \
		--enable-flow-logs \
		--enable-private-ip-google-access \
		--purpose=PRIVATE \
		--region=us-central1
	# Create firewall rule
	@gcloud compute firewall-rules create allow-ssh-admin --allow tcp:22,tcp:3389,icmp \
		--source-ranges="35.235.240.0/20" --description="SSH via IAP" \
		--target-tags=ssh-iap \
		--network=kpt-test-net
	# Create a Cloud Router for the admin VM subnet:
	@gcloud compute routers create kpt-test-router \
		--network=kpt-test-net \
		--region=us-central1
	# Create NAT 
	@gcloud compute routers nats create kpt-test-nat \
	    --router=kpt-test-router \
	    --auto-allocate-nat-external-ips \
	    --router-region=us-central1 \
	    --nat-custom-subnet-ip-ranges=kpt-test-admin-subnet,kpt-test-subnet -q

k8s-admin-vm:
	@gcloud beta compute instances create k8s-admin \
		--zone=us-central1-b --machine-type=e2-medium --subnet=kpt-test-admin-subnet \
		--no-address --maintenance-policy=MIGRATE --no-service-account --no-scopes \
		--tags=ssh-iap --private-network-ip=10.0.1.2 --metadata=block-project-ssh-keys=true \
		--image=debian-10-buster-v20220118 --image-project=debian-cloud --boot-disk-size=10GB \
		--boot-disk-type=pd-ssd --boot-disk-device-name=dbs-k8s-jumpbox --shielded-secure-boot \
		--shielded-vtpm --shielded-integrity-monitoring --reservation-affinity=any -q \
		--metadata-from-file=startup-script=./.hack/network/k8s-admin-vm-startup.sh
