#!/bin/bash
VAULT_NAMESPACE="template"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
vaultInstallDir="../../install-vault-raft"

export KUBECONFIG=${DIR}/${vaultInstallDir}/tmp/k8s_config
#export KUBECONFIG=/Users/patrickpresto/Projects/AKS-Sandbox/install-vault/scripts/../tmp/k8s_config
export VAULT_ADDR="http://127.0.0.1:8200"

# AppRole for Terraform Vault provider authentication
export TF_VAR_app_role_mount_point=$(terraform output -state=../terraform.tfstate approle_path_${VAULT_NAMESPACE})
export TF_VAR_approle_path=$(terraform output -state=../terraform.tfstate approle_path_${VAULT_NAMESPACE})
export TF_VAR_role_name=$(terraform output -state=../terraform.tfstate role_name_${VAULT_NAMESPACE})
export TF_VAR_role_id=$(terraform output -state=../terraform.tfstate role_id_${VAULT_NAMESPACE})
export TF_VAR_secret_id=$(terraform output -state=../terraform.tfstate secret_id_${VAULT_NAMESPACE})

# Namespace
export TF_VAR_namespace=$(terraform output -state=../terraform.tfstate namespace_${VAULT_NAMESPACE})

# Policy
export TF_VAR_policy_name="k8s"
export TF_VAR_policy_code=$(cat <<EOF
path "kv/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
path "secret/data/apikey" {
  capabilities = ["read","list"]
}
path "db/creds/dev" {
  capabilities = ["read"]
}
path "pki_int/issue/*" {
  capabilities = ["create", "update"]
}
path "sys/leases/renew" {
  capabilities = ["create"]
}
path "sys/leases/revoke" {
  capabilities = ["update"]
}
path "sys/renew/*" {
  capabilities = ["update"]
}
EOF
)

# KV
export TF_VAR_kv_path=$(terraform output -state=../terraform.tfstate kv_path_${VAULT_NAMESPACE})
export TF_VAR_secret_path="${TF_VAR_kv_path}/demo"

# Kubernetes
export TF_VAR_k8s_path=$(terraform output -state=../terraform.tfstate k8s_path_${VAULT_NAMESPACE})
export TF_VAR_kubernetes_host=$(kubectl config view -o yaml | grep server | awk '{ print $NF }')
export VAULT_SA_NAME=$(kubectl get sa vault -o jsonpath="{.secrets[*]['name']}")
export TF_VAR_token_reviewer_jwt=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data.token}" | base64 --decode; echo)
export TF_VAR_kubernetes_ca_cert=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data['ca\.crt']}" | base64 --decode; echo)

# GCP Auth backend
export TF_VAR_gcp_credentials=$(cat <<EOF
<GOOGLE CLOUD CREDENTIALS HERE>
EOF
)
export TF_VAR_gcp_role_name="gce" 
export TF_VAR_gcp_bound_zones='["<YOUR_GCP_ZONE>"]'
export TF_VAR_gcp_bound_projects='["<YOUR_GCP_PROJECT>"]'
export TF_VAR_gcp_token_policies='["terraform"]'
export TF_VAR_gcp_token_ttl=1800
export TF_VAR_gcp_token_max_ttl=86400

# SSH Secret Engine
export TF_VAR_ssh_ca_allowed_users="ubuntu"
export TF_VAR_ssh_otp_allowed_users="ubuntu"

# Setup kubectl port forward to access vault with localhost
if [[ ! $(ps -ef | grep "kubectl port-forward"| grep -v grep) ]]; then
    kubectl port-forward vault-0 8200:8200 > /dev/null 2>&1 &
else
    echo "kubectl port-forward running"
fi
