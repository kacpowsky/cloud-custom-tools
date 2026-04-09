#!/usr/bin/env bash
set -e


echo "Setting up Scaleway CLI config"
# Scaleway CLI config (expects env vars)
: "${SCW_ACCESS_KEY:?missing}"
: "${SCW_SECRET_KEY:?missing}"
: "${SCW_DEFAULT_ORGANIZATION_ID:?missing}"
: "${SCW_DEFAULT_PROJECT_ID:?missing}"
: "${SCW_DEFAULT_REGION:?missing}"   # e.g. fr-par
: "${SCW_DEFAULT_ZONE:?missing}"     # e.g. fr-par-1

SCW_CONFIG_DIR="${HOME}/.config/scw"
SCW_CONFIG_FILE="${SCW_CONFIG_DIR}/config.yaml"

mkdir -p "${SCW_CONFIG_DIR}"
chmod 700 "${SCW_CONFIG_DIR}"

umask 077
cat > "${SCW_CONFIG_FILE}" <<EOF
access_key: ${SCW_ACCESS_KEY}
secret_key: ${SCW_SECRET_KEY}
default_organization_id: ${SCW_DEFAULT_ORGANIZATION_ID}
default_project_id: ${SCW_DEFAULT_PROJECT_ID}
default_region: ${SCW_DEFAULT_REGION}
default_zone: ${SCW_DEFAULT_ZONE}
EOF



echo "Retrieving Docker Credentials for the AWS ECR Registry ${AWS_ACCOUNT}"
DOCKER_REGISTRY_SERVER=https://${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com
DOCKER_USER=AWS
DOCKER_PASSWORD=$(aws ecr get-login-password --region ${AWS_REGION})

IFS=';' read -r -a SUFFIXES <<< "$NAMESPACE_SUFFIX"

for suffix in "${SUFFIXES[@]}"; do
  echo "Processing namespaces with suffix: ${suffix}"

  while read namespace
  do
    echo ${namespace}

    echo "Removing previous secret in namespace ${namespace}"
    kubectl --context ${KUBE_CONTEXT} --namespace=${namespace} delete secret aws-ecr-credentials || true

    echo "Creating new secret in namespace ${namespace}"
    kubectl --context ${KUBE_CONTEXT} --namespace=${namespace} create secret docker-registry aws-ecr-credentials \
      --docker-server=${DOCKER_REGISTRY_SERVER} \
      --docker-username=${DOCKER_USER} \
      --docker-password=${DOCKER_PASSWORD} \
      --docker-email=srv+ecr@starbeta.net

  # done < <(kubectl get ns --no-headers -o custom-columns=":metadata.name" | grep ${suffix})
  done < <(kubectl --context ${KUBE_CONTEXT} get ns --no-headers -o custom-columns=":metadata.name" | grep ${suffix})

done