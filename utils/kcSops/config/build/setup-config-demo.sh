#!/bin/bash

secrets_file="./secrets.devtest.env"

cat <<EOT > "${secrets_file}"
KC_VAR1="value1"
KC_VAR2="value2"
KC_VAR3="value3"
KC_VAR4="value4"
EOT

# Define environments
environments=("devtest")

# Initialize sops configuration
sops_config="creation_rules:"

# Loop through each environment to get the KMS key and build the sops configuration
for environment in "${environments[@]}"; do
  # Get the alias for the environment
  key_alias="alias/${environment}"

  # Get the KMS key ID for the alias
  key_id=$(aws kms list-aliases --query "Aliases[?AliasName=='${key_alias}'].TargetKeyId" --output text)

  # Construct the ARN for the KMS key
  region=$(aws configure get region)
  account_id=$(aws sts get-caller-identity --query Account --output text)
  key_arn="arn:aws:kms:${region}:${account_id}:key/${key_id}"

  # Build the sops configuration for the environment
  sops_config+="
  # Encrypt devtest env files with 
  - path_regex: .*devtest\.env$
    kms: '${key_arn}'
  
  "
done

# Write the configuration to .sops.yaml
echo "$sops_config" > .sops.yaml