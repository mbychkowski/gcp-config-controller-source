#!/bin/sh

cat > .hack/org-policy/requireOsLogin.yaml << ENDOFFILE
name: projects/$1/policies/compute.requireOsLogin
spec:
  rules:
  - enforce: false
ENDOFFILE

cat > .hack/org-policy/shieldedVm.yaml << ENDOFFILE
name: projects/$1/policies/compute.requireShieldedVm
spec:
  rules:
  - enforce: false
ENDOFFILE

cat > .hack/org-policy/vmCanIpForward.yaml << ENDOFFILE
name: projects/$1/policies/compute.vmCanIpForward
spec:
  rules:
  - allowAll: true
ENDOFFILE

cat > .hack/org-policy/vmExternalIpAccess.yaml << ENDOFFILE
name: projects/$1/policies/compute.vmExternalIpAccess
spec:
  rules:
  - allowAll: true
ENDOFFILE

cat > .hack/org-policy/restrictVpcPeering.yaml << ENDOFFILE
name: projects/$1/policies/compute.restrictVpcPeering
spec:
  rules:
  - allowAll: true
ENDOFFILE
