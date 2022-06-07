SHELL := /bin/bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

# Source important environmental variables that need to be persisted and are easy to forget about
-include .env.make
-include .hack/network/Makefile
-include .hack/identity/Makefile
-include .hack/config-controller/Makefile
-include .hack/org-policy/Makefile

authenticate:
	@gcloud auth login
	@gcloud auth application-default print-access-token > access-token-file.txt

create-project: 
  # Create a GCP landing zone project
	@gcloud projects create ${CONFIG_CONTROLLER_PROJECT_ID} --folder=${ORG_OR_FOLDER_ID} --set-as-default --access-token-file ${ACCESS_TOKEN_FILE}
	@gcloud beta billing projects link ${CONFIG_CONTROLLER_PROJECT_ID} --billing-account=${BILLING_ACCOUNT_ID} --access-token-file ${ACCESS_TOKEN_FILE}
	@gcloud config set project ${CONFIG_CONTROLLER_PROJECT_ID}

# One time landing zone setup
super-user:
	# Assign Org and Project-level IAM permissions to your Argolis super-user
	@gcloud organizations add-iam-policy-binding ${ORG_OR_FOLDER_ID} --condition=None --member="user:${GCP_SUPER_USER}" --role="roles/resourcemanager.organizationAdmin" ${ACCESS_TOKEN_FILE}
	@gcloud organizations add-iam-policy-binding ${ORG_OR_FOLDER_ID} --condition=None --member="user:${GCP_SUPER_USER}" --role="roles/orgpolicy.policyAdmin" ${ACCESS_TOKEN_FILE}	

initial-roles:
	# Assign Org and Project-level IAM permissions to your Argolis Org's GCP Workspace 'admin-group' and 'billing-admin-group'
	@gcloud organizations add-iam-policy-binding ${ORG_OR_FOLDER_ID} --condition=None --member="group:${GCP_ORGANIZATION_ADMIN}" --role="roles/resourcemanager.organizationAdmin" ${ACCESS_TOKEN_FILE}
	@gcloud organizations add-iam-policy-binding ${ORG_OR_FOLDER_ID} --condition=None --member="group:${GCP_ORGANIZATION_ADMIN}" --role="roles/resourcemanager.folderAdmin" ${ACCESS_TOKEN_FILE}
	@gcloud organizations add-iam-policy-binding ${ORG_OR_FOLDER_ID} --condition=None --member="group:${GCP_ORGANIZATION_ADMIN}" --role="roles/resourcemanager.projectCreator" ${ACCESS_TOKEN_FILE}
	@gcloud organizations add-iam-policy-binding ${ORG_OR_FOLDER_ID} --condition=None --member="group:${GCP_ORGANIZATION_ADMIN}" --role="roles/orgpolicy.policyAdmin" ${ACCESS_TOKEN_FILE}
	@gcloud organizations add-iam-policy-binding ${ORG_OR_FOLDER_ID} --condition=None --member="group:${GCP_BILLING_ADMIN}" 	 --role="roles/billing.admin" ${ACCESS_TOKEN_FILE}
	@gcloud organizations add-iam-policy-binding ${ORG_OR_FOLDER_ID} --condition=None --member="group:${GKE_SECURITY_GROUP}" 	 --role="roles/viewer" ${ACCESS_TOKEN_FILE}

	# Bind IAM permissions to the default Cloud Build service account
	@gcloud projects      add-iam-policy-binding ${CONFIG_CONTROLLER_PROJECT_ID}  --condition=None --member="serviceAccount:${CONFIG_CONTROLLER_PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" --role=roles/owner
	@gcloud organizations add-iam-policy-binding ${ORG_OR_FOLDER_ID}              --condition=None --member="serviceAccount:${CONFIG_CONTROLLER_PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" --role=roles/resourcemanager.organizationAdmin	
	@gcloud organizations add-iam-policy-binding ${ORG_OR_FOLDER_ID}              --condition=None --member="serviceAccount:${CONFIG_CONTROLLER_PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" --role=roles/resourcemanager.folderAdmin
	@gcloud organizations add-iam-policy-binding ${ORG_OR_FOLDER_ID}              --condition=None --member="serviceAccount:${CONFIG_CONTROLLER_PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" --role="roles/resourcemanager.projectCreator"
	@gcloud organizations add-iam-policy-binding ${ORG_OR_FOLDER_ID}              --condition=None --member="serviceAccount:${CONFIG_CONTROLLER_PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" --role="roles/orgpolicy.policyAdmin"
	@gcloud organizations add-iam-policy-binding ${ORG_OR_FOLDER_ID}              --condition=None --member="serviceAccount:${CONFIG_CONTROLLER_PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" --role=roles/billing.user

# AD HOC
create-org-policies:
	sh .hack/org-policy/create.sh ${CONFIG_CONTROLLER_PROJECT_NUMBER}

ssh-key:
	@export _KEY=GITOPS_DEPLOY_REPO_SSH_KEY
	@ssh-keygen -t ed25519 -f id_ed25519_cloudbuild -C ${GIT_EMAIL} -q -N ""
	@gcloud secrets create $$_KEY \
	--replication-policy="automatic" \
	--data-file=id_ed25519_cloudbuild;
	@rm id_ed25519_cloudbuild

gh-token-secrets:
	@export _KEY_1=GITOPS_DEPLOY_GH_TOKEN
	@export _KEY_2=GITOPS_DEPLOY_GH_USERNAME
	@echo -n ${GH_TOKEN} | gcloud secrets create $$_KEY_1 \
	--replication-policy="automatic" \
	--data-file=-;
	@echo -n ${GH_USERNAME} | gcloud secrets create $$_KEY_2 \
	--replication-policy="automatic" \
	--data-file=-;

enable-argolis-org-policies: create-org-policies
	@gcloud org-policies set-policy .hack/org-policy/shieldedVm.yaml
	@gcloud org-policies set-policy .hack/org-policy/vmCanIpForward.yaml
	@gcloud org-policies set-policy .hack/org-policy/vmExternalIpAccess.yaml
	@gcloud org-policies set-policy .hack/org-policy/restrictVpcPeering.yaml

.PHONY: replace-project-id
replace-project-id:
	@sed -i s/CONFIG_CONTROLLER_PROJECT_ID/${CONFIG_CONTROLLER_PROJECT_ID}/g environments/${ENV}/terraform.tfvars
	@sed -i s/CONFIG_CONTROLLER_PROJECT_ID/${CONFIG_CONTROLLER_PROJECT_ID}/g environments/${ENV}/backend.tf