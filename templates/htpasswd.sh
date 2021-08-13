#!/bin/bash

read -p 'What is your desired amount of Openshift users? ' user

for ((i=1; i<=$user; i++))
do
    htpasswd -c -B -b users.htpasswd user$i openshift
done

oc create secret generic htpass-secret --from-file=htpasswd=users.htpasswd -n openshift-config

cat << EOF | oc apply -f -
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
  - name: my_htpasswd_provider 
    mappingMethod: claim 
    type: HTPasswd
    htpasswd:
      fileData:
        name: htpass-secret 
EOF

for ((j=1; j<=$user; j++))
do
    cat << EOF | oc apply -f -
    apiVersion: v1
    kind: Namespace
    metadata:
      labels:
        openshift.io/cluster-monitoring: "true"
      name: user${j}
    spec: {}
EOF
done

for ((h=1; h<=$user; h++))
do
    cat << EOF | oc apply -f -
    apiVersion: rbac.authorization.k8s.io/v1
    kind: RoleBinding
    metadata:
      name: admin
      namespace: user${h}
    subjects:
    - kind: User
      name: user${h}
      apiGroup: rbac.authorization.k8s.io
    roleRef:
      kind: ClusterRole
      name: admin
      apiGroup: rbac.authorization.k8s.io
EOF
done