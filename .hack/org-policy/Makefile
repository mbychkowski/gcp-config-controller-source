CUR_DIR=$(shell pwd)/.hack/org-policy/

-include .env.make

policy-yaml:
	@sh ${CUR_DIR}/create.sh ${CONFIG_CONTROLLER_PROJECT_NUMBER}

argolis-policy: policy-yaml
	@gcloud org-policies set-policy ${CUR_DIR}requireOsLogin.yaml
	@gcloud org-policies set-policy ${CUR_DIR}shieldedVm.yaml
	@gcloud org-policies set-policy ${CUR_DIR}vmCanIpForward.yaml
	@gcloud org-policies set-policy ${CUR_DIR}vmExternalIpAccess.yaml
	@gcloud org-policies set-policy ${CUR_DIR}restrictVpcPeering.yaml
