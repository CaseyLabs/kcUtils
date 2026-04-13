#!/bin/bash

set -euo pipefail

secrets_file="./devtest.env"
sops_config_file="./.sops.yaml"

if ! command -v aws >/dev/null 2>&1; then
	echo "aws CLI is required to generate the demo SOPS config."
	exit 1
fi

if [ -e "$secrets_file" ]; then
	echo "Refusing to overwrite existing file: $secrets_file"
	exit 1
fi

if [ -e "$sops_config_file" ]; then
	echo "Refusing to overwrite existing file: $sops_config_file"
	exit 1
fi

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
	if [ -z "$key_id" ] || [ "$key_id" = "None" ]; then
		echo "No AWS KMS key found for alias: $key_alias"
		exit 1
	fi

	# Construct the ARN for the KMS key
	region=$(aws configure get region)
	account_id=$(aws sts get-caller-identity --query Account --output text)
	key_arn="arn:aws:kms:${region}:${account_id}:key/${key_id}"

	# Build the sops configuration for the environment
	sops_config+="
  # Encrypt devtest env files with ${environment} KMS key
  - path_regex: .*devtest(\.encrypted)?\.env$
    kms: '${key_arn}'
  
  "
done

cat <<EOT >"$secrets_file"
KC_VAR1="value1"
KC_VAR2="value2"
KC_VAR3="value3"
KC_VAR4="value4"
EOT

# Write the configuration to .sops.yaml
echo "$sops_config" >"$sops_config_file"
