# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

.ONESHELL:
.SILENT:
.EXPORT_ALL_VARIABLES:
SHELL := /bin/bash

# Source important environmental variables that need to be persisted and are easy to forget about
-include .env.make


authenticate: 
	@gcloud auth login --brief --update-adc --quiet
	@gcloud auth application-default print-access-token > access-token-file.txt

create-project: 
  # Create a GCP landing zone project
	@gcloud projects create ${PROJECT_ID} --organization=${ORGANIZATION_ID} --set-as-default ${access-token-file.txt}
	@gcloud beta billing projects link ${PROJECT_ID} --billing-account=${BILLING_ACCOUNT_ID} ${access-token-file.txt}
	@gcloud config set project ${PROJECT_ID}

# One time landing zone setup
super-user:
	# Assign Org and Project-level IAM permissions to your Argolis super-user
	@gcloud organizations add-iam-policy-binding ${ORGANIZATION_ID} --condition=None --member="user:${GCP_SUPER_USER}" --role="roles/resourcemanager.organizationAdmin" ${access-token-file.txt}
	@gcloud organizations add-iam-policy-binding ${ORGANIZATION_ID} --condition=None --member="user:${GCP_SUPER_USER}" --role="roles/orgpolicy.policyAdmin" ${access-token-file.txt}	

enable-apis: 
	@gcloud --project ${PROJECT_ID} services enable \
		cloudbuild.googleapis.com \
		krmapihosting.googleapis.com \
		container.googleapis.com \
		cloudresourcemanager.googleapis.com \
		secretmanager.googleapis.com \
		orgpolicy.googleapis.com \
		sourcerepo.googleapis.com

vpc:
	@gcloud compute networks create config-admin-vpc --subnet-mode=auto --mtu=1460 --bgp-routing-mode=global --project=${PROJECT_ID}
	# Firewall Rules
	@gcloud compute firewall-rules create allow-internal --network=projects/${PROJECT_ID}/global/networks/config-admin-vpc  --direction=INGRESS --source-ranges=10.0.0.0/8 --action=ALLOW --rules=all --project=${PROJECT_ID} 
	@gcloud compute firewall-rules create allow-internal-ssh-rdp --network config-admin-vpc --allow tcp:22,tcp:3389,icmp --direction=INGRESS --source-ranges=10.0.0.0/8 --project=${PROJECT_ID} 
	@gcloud compute firewall-rules create allow-all-egress --network config-admin-vpc --action allow --direction egress --rules tcp,udp,icmp --destination-ranges 0.0.0.0/0 --project=${PROJECT_ID}
	# Cloud Router
	@gcloud compute routers create router-config-admin-vpc --network config-admin-vpc --region ${CC_REGION} --project ${PROJECT_ID}
	# Cloud NAT
	@gcloud compute routers nats create nat-config-admin-vpc --router-region ${CC_REGION} --router router-config-admin-vpc --auto-allocate-nat-external-ips --nat-all-subnet-ip-ranges --enable-logging --project ${PROJECT_ID}		

test-var:
	@echo -e CC_SA_EMAIL=$$(kubectl get ConfigConnectorContext -n config-control -o jsonpath='{.items[0].spec.googleServiceAccount}' 2> /dev/null) >> .env.make

use-var: test-var
	echo ${CC_SA_EMAIL}

initial-roles: enable-apis
	# Assign Org and Project-level IAM permissions to your Argolis Org's GCP Workspace 'admin-group' and 'billing-admin-group'
    	
	@gcloud organizations add-iam-policy-binding ${ORGANIZATION_ID} --condition=None --member="group:${GCP_ORGANIZATION_ADMIN}" --role="roles/resourcemanager.organizationAdmin" ${access-token-file.txt}
	@gcloud organizations add-iam-policy-binding ${ORGANIZATION_ID} --condition=None --member="group:${GCP_ORGANIZATION_ADMIN}" --role="roles/resourcemanager.folderAdmin" ${access-token-file.txt}
	@gcloud organizations add-iam-policy-binding ${ORGANIZATION_ID} --condition=None --member="group:${GCP_ORGANIZATION_ADMIN}" --role="roles/resourcemanager.projectCreator" ${access-token-file.txt}
	@gcloud organizations add-iam-policy-binding ${ORGANIZATION_ID} --condition=None --member="group:${GCP_ORGANIZATION_ADMIN}" --role="roles/orgpolicy.policyAdmin" ${access-token-file.txt}
	@gcloud organizations add-iam-policy-binding ${ORGANIZATION_ID} --condition=None --member="group:${GCP_BILLING_ADMIN}" --role="roles/billing.admin" ${access-token-file.txt}
	# Bind IAM permissions to the default Cloud Build service account
	@gcloud projects      add-iam-policy-binding ${PROJECT_ID}      --condition=None --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" --role=roles/owner
	@gcloud organizations add-iam-policy-binding ${ORGANIZATION_ID} --condition=None --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" --role=roles/resourcemanager.organizationAdmin	
	@gcloud organizations add-iam-policy-binding ${ORGANIZATION_ID} --condition=None --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" --role=roles/resourcemanager.folderAdmin
	@gcloud organizations add-iam-policy-binding ${ORGANIZATION_ID} --condition=None --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" --role="roles/resourcemanager.projectCreator"
	@gcloud organizations add-iam-policy-binding ${ORGANIZATION_ID} --condition=None --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" --role="roles/orgpolicy.policyAdmin"
	@gcloud organizations add-iam-policy-binding ${ORGANIZATION_ID} --condition=None --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" --role=roles/billing.user

config-controller:
	@gcloud alpha anthos config controller create config-controller --location=${CC_REGION} --network=config-admin-vpc --project=${PROJECT_ID}
# Bind IAM permissions to the config controller service account
	@gcloud projects      add-iam-policy-binding ${PROJECT_ID}      --condition=None --member="serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-yakima.iam.gserviceaccount.com" --role=roles/owner
	@gcloud organizations add-iam-policy-binding ${ORGANIZATION_ID} --condition=None --member="serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-yakima.iam.gserviceaccount.com" --role=roles/billing.admin
	@gcloud organizations add-iam-policy-binding ${ORGANIZATION_ID} --condition=None --member="serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-yakima.iam.gserviceaccount.com" --role=roles/compute.xpnAdmin
	@gcloud organizations add-iam-policy-binding ${ORGANIZATION_ID} --condition=None --member="serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-yakima.iam.gserviceaccount.com" --role=roles/resourcemanager.folderAdmin
	@gcloud organizations add-iam-policy-binding ${ORGANIZATION_ID} --condition=None --member="serviceAccount:service-${PROJECT_NUMBER}@gcp-sa-yakima.iam.gserviceaccount.com" --role=roles/resourcemanager.organizationAdmin	

# AD HOC
create-org-policies:
	sh .hack/org-policy/create.sh ${PROJECT_NUMBER}

enable-argolis-org-policies: create-org-policies
	@gcloud org-policies set-policy .hack/org-policy/shieldedVm.yaml
	@gcloud org-policies set-policy .hack/org-policy/vmCanIpForward.yaml
	@gcloud org-policies set-policy .hack/org-policy/vmExternalIpAccess.yaml
	@gcloud org-policies set-policy .hack/org-policy/restrictVpcPeering.yaml

.PHONY: replace-project-id
replace-project-id:
	@sed -i s/PROJECT_ID/${PROJECT_ID}/g environments/${ENV}/terraform.tfvars
	@sed -i s/PROJECT_ID/${PROJECT_ID}/g environments/${ENV}/backend.tf