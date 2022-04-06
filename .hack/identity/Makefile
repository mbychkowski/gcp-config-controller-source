# Source important environmental variables that need to be persisted and are easy to forget about
-include .env.make

google-identity-groups:
	gcloud beta identity groups create ${GKE_SECURITY_GROUP} --quiet \
		--display-name="GKE Security Group" \
		--description="Google Group used to provide GCP users with GKE RBAC permissions" \
		--with-initial-owner=with-initial-owner \
		--organization=${ORGANIZATION_ID}