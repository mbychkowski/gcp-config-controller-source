## 1) Initialize project

```
make authenticate

make create-project

make enable-apis

make cloud-build-sa
```

## 2) Create TF infra

```
cd landing-zone/

gcloud builds submit --region=us-central1 --config cloudbuild.yaml --substitutions=BRANCH_NAME="main"
```

## 3) Destroy TF infra

```
gcloud builds submit --region=us-central1 --config cloudbuild-destroy.yaml --substitutions=BRANCH_NAME="main",_DESTROY="false"
```
