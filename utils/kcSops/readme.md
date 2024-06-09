# `kcSops`
  
**A demo of [Mozilla SOPS](https://github.com/getsops/sops) for file encryption, using AWS KMS and/or GCP KMS.**

<!-- TOC -->

- [What is SOPS?](#what-is-sops)
- [Setup](#setup)
  - [Requirements](#requirements)
  - [Installation](#installation)
- [Usage](#usage)
  - [Example: Encrypting with AWS KMS](#example-encrypting-with-aws-kms)
  - [Example: Encrypt with Google Cloud Platform (GCP KMS)](#example-encrypt-with-google-cloud-platform-gcp-kms)
  - [Configure `.gitignore`](#configure-gitignore)

<!-- /TOC -->

---

## What is SOPS?

Mozilla SOPS ("_secrets operations_") is an open-source tool written in Go. `sops` is used to easily encrypt and decrypt sensitive data in a config files, such as `.env` files. 

SOPS integrates seamlessly with cloud-managed key management systems (such as AWS KMS or GCP KMS), and provides a straightforward way to securely distribute your application's secrets with team members.

### Key Features

- **File-based encryption**: Encrypt sensitive key values in config files, such as `.env` files.
  
- **Multiple file forrmat support**: Works with JSON, YAML, ENV, and INI files.
  
- **KMS Integration**: Supports AWS KMS, GCP KMS, Azure Key Vault, Hashicorp Vault, and PGP.
  
- **Git Integration**: Ideal for storing encrypted secrets in version control systems like Git.

- **CI/CD and Kubernetes Integration**: Can be easily implemented with existing code delivery systems.
  
---

## Setup
  
### Requirements

- If using AWS KMS: [AWS CLI must be installed](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

- If using GCP KMS: [gcloud CLI must be installed](https://cloud.google.com/sdk/docs/install)

### Installation

#### Linux/MacOS

<details>
<summary>Linux/MacOS install</summary>

In your Terminal, run the following commands:

```
./config/build/install-sops.sh
```
</details>

#### Windows

<details>
<summary>Windows install</summary>

In a Powershell terminal, run:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
.\config\build\install-sops.ps1
```
</details>
 
---

## Usage

### Example: Encrypting with AWS KMS

In this demo, we will encrypt a file for a `devtest` environment, using AWS KMS as our external key management service.

![Demo GIF](./demo.gif)

_Run these examples in a Linux/MacOS/WSL terminal._

### Create a Secrets File (`secrets.env`)

<details>
<summary>Secrets File setup</summary>

Create an environment variable file for the `devtest` environment with the following script:

```sh
secrets_file="./devtest.env"

cat <<EOT > "${secrets_file}"
KC_VAR1="value1"
KC_VAR2="value2"
KC_VAR3="value3"
KC_VAR4="value4"
EOT
```
</details>

### Create an AWS KMS key

<details>
<summary>AWS KMS setup</summary>

Create a multi-region AWS KMS key for a `devtest` environment:

```sh
export environment="devtest"

# Create the AWS KMS key
output=$(aws kms create-key --description "${environment}" \
    --tags TagKey=Name,TagValue="${environment}" \
    --multi-region \
    --output json)

# Get the ARN value for the generated KMS key
export kms_arn=$(echo "${output}" | grep -o '"Arn": *"[^"]*"' | head -n 1 | awk -F'"' '{print $4}')

# Get the KeyId from the JSON output
export key_id=$(echo "${output}" | grep -o '"KeyId": *"[^"]*"' | head -n 1 | awk -F'"' '{print $4}')

# Create an alias for the key:
aws kms create-alias --alias-name "alias/${environment}" --target-key-id "$key_id"
```

_Pro-Tip:_ Consider creating a secondary Disaster Recovery (DR) AWS KMS key in a backup AWS account.
</details>

### Create a Config File (`.sops.yaml`)

<details>
<summary>Config File setup</summary>

In your repo, you can create a `.sops.yaml` configuration file at the root directory. The config file will specify what KMS key to automatically use for encrypting/decrypting specific filetypes.

For example:

- Files that contain `*devtest.env` should use the `devtest` AWS KMS key

We can genereate the config file using a script like this:

```sh
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
  - path_regex: .*devtest(\.encrypted)?\.env$
    kms: '${key_arn}'
  
  "
done

# Write the configuration to .sops.yaml
echo "$sops_config" > .sops.yaml
```

And the genereated `.sops.yaml` will look like this:

```yaml
creation_rules:
  # Encrypt devtest env files with devtest KMS key
  - path_regex: .*devtest(\.encrypted)?\.env$
    kms: 'arn:aws:kms:us-west-2:123456789:key/mrk-123456789'
```
</details>

#### Encrypt the File

<details>
<summary>Encryption steps</summary>

**Encrypted env file names must be in this format: `${name}.encrypted.env`**

```sh
# Encrypt the file with devtest environment's AWS KMS key
sops --encrypt devtest.env > devtest.encrypted.env
```

Verify the new file is encrypted:

```sh
❯ cat devtest.encrypted.env

KC_VAR1=ENC[AES256_GCM,data:I0Jlkv3HaMA=,iv:GHBfxz2a5R9tX+61eZz1spi7VChatKkpWVEozqFUuu4=,tag:iK/FSwRjlA6fHQVQi+dVkA==,type:str]
KC_VAR2=ENC[AES256_GCM,data:2qDsfdr4MtA=,iv:K6h76s+deyyS7Vx8XLhdccyN5UsGYSi8r2MbY55mtMg=,tag:h8onJ+oTpmNGoqolZO8ixA==,type:str]
KC_VAR3=ENC[AES256_GCM,data:MAwj7EvVJ74=,iv:8ugmNO6EY99MZkxAKCyvHQMeWrV0wfKsT2Z5907JR1U=,tag:1FS7MlPx39MJVGCO10YPLA==,type:str]
KC_VAR4=ENC[AES256_GCM,data:WKH2jUseqdc=,iv:Qg04P/XEgRH3B5BHaCiZq4/WP4oG/MQbxBsfzB8qC5U=,tag:3oOJFlR19P2gvHZykAIsdA==,type:str]
sops_kms__list_0__map_arn=arn:aws:kms:us-west-2:123456789:key/mrk-123456789
[...]
```

Now delete the unencrypted file from the repo:

```sh
rm devtest.env
```
</details>

#### Decrypt the File

<details>
<summary>Decryption steps</summary>


**Edit the encrypted file in-place with the SOPS text editor:**

```sh
sops devtest.encrypted.env
```

Or decrypt to an unencrypted file (_Warning: don't commit that unecrypted file to the repo!_):

```sh
sops --decrypt devtest.encrypted.env > devtest.env.unencrypted

cat devtest.env.unencrypted
rm devtest.env.unencrypted
```

##### Results

```sh
❯ cat config/secrets.env.unencrypted

KC_VAR1="value1"
KC_VAR2="value2"
KC_VAR3="value3"
KC_VAR4="value4"
```

</details>

---

### Example: Encrypt with Google Cloud Platform (GCP KMS)

Create a GCP KMS keyring for a `devtest` environment.

<details>

<summary>GCP KMS Steps</summary>

```sh
export environment="devtest"
export location="global"
export keyring="${environment}-keyring"
export key="${environment}-key"

gcloud kms keyrings create "${keyring}" --location "${location}"

gcloud kms keys create "${key}" --location "${location}" --keyring "${keyring}" --purpose "encryption"
```

Encrypt the file with SOPS using the GCP KMS key:

```sh
export environment="devtest"
export location="global"
export keyring="${environment}-keyring"
export key="${environment}-key"
export secrets_file="./secrets.env"
export encrypted_file="./secrets.encrypted.env"

key_id="projects/$(gcloud config get-value project)/locations/${location}/keyRings/${keyring}/cryptoKeys/${key}"

echo "Encrypting file with key_id: ${key_id}"

if sops --encrypt --gcp-kms "${key_id}" "${secrets_file}" > "${encrypted_file}.tmp"; then
    mv "${encrypted_file}.tmp" "${encrypted_file}"
else
    echo "Encryption failed. No file was created."
    rm -f "${encrypted_file}.tmp"
    exit 1
fi
```

Decrypt the file with SOPS using the GCP KMS key:

```sh
export environment="devtest"
export location="global"
export keyring="${environment}-keyring"
export key="${environment}-key"
export encrypted_file="./secrets.encrypted.env"
export decrypted_file="./secrets.decrypted.env"

key_id="projects/$(gcloud config get-value project)/locations/${location}/keyRings/${keyring}/cryptoKeys/${key}"

if sops --decrypt --gcp-kms "${key_id}" "${encrypted_file}" > "${decrypted_file}.tmp"; then
    mv "${decrypted_file}.tmp" "${decrypted_file}"
else
    echo "Decryption failed. No file was created."
    rm -f "${decrypted_file}.tmp"
    exit 1
fi
```
</details>

---

### Configure `.gitignore`

In your repo, ensure that files that contain secrets (such as `.env` files) are not accidentally commited, but do allow encrypted files (`*.encrypted.*`) to be commited.

```
cat <<EOT > ".gitignore"
# Don't commit sensitive files
.env
*.env
*.env.*
*.decrypted
*.decrypted.*
*.unencrypted
*.unencrypted.*

# But allow SOPS encrypted files
!*.encrypted.*
EOT
```
