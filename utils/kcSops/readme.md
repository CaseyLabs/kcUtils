# `kcSops`

A demo of **[Mozilla SOPS](https://github.com/getsops/sops)** for file encryption, using AWS KMS and/or GCP KMS.
---

<!-- TOC -->

- [What is SOPS?](#what-is-sops)
  - [Key Features](#key-features)
- [Setup](#setup)
  - [Requirements](#requirements)
  - [Installation](#installation)
    - [Linux/MacOS](#linuxmacos)
    - [Windows Powershell](#windows-powershell)
- [Usage](#usage)
  - [Create a Secrets File (`secrets.env`)](#create-a-secrets-file-secretsenv)
  - [Example: Encrypt with Amazon Web Services (AWS KMS)](#example-encrypt-with-amazon-web-services-aws-kms)
    - [Encrypt the File](#encrypt-the-file)
    - [Results](#results)
    - [Decrypt the File](#decrypt-the-file)
  - [Example: Encrypt with Google Cloud Platform (GCP KMS)](#example-encrypt-with-google-cloud-platform-gcp-kms)
    - [Encrypt the file](#encrypt-the-file)
    - [Decrypt the file](#decrypt-the-file)
- [Setup `.ignore` files](#setup-ignore-files)
  - [`.gitignore`](#gitignore)

<!-- /TOC -->

---

## What is SOPS?

Mozilla SOPS ("_secrets operations_") is an open-source tool to encrypt sensitive values in a configuration file, such as `.env` files. 

It integrates seamlessly with cloud-managed key management systems (such as AWS KMS), and provides a straightforward way to secure and distribute your secrets with team members.

### Key Features

- **File-Based Encryption**: Encrypt entire files, or just the values (leaving the key names unencrypted).
  
- **Support for Multiple Formats**: Works with JSON, YAML, ENV, and INI files.
  
- **KMS Integration**: Supports AWS KMS, GCP KMS, Azure Key Vault, and PGP.
  
- **Git Integration**: Ideal for storing encrypted secrets in version control systems like Git.
  
---

## Setup
  
### Requirements

For AWS KMS:
- [AWS CLI installed](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

For GCP KMS:
- [gcloud CLI installed](https://cloud.google.com/sdk/docs/install)

### Installation

#### Linux/MacOS

In your Terminal, run the following commands:

```
  cd kc-utils/utils/kcSops

  ./misc/install-sops.sh
```

#### Windows Powershell

In a Powershell terminal, run:

```powershell
  cd kc-utils/utils/kcSops

  .\misc\install-sops.ps1
```

---

## Usage

_Run these examples in a Linux/MacOS/WSL terminal._

### Create a Secrets File (`secrets.env`)

Create an environment variable file named `secrets.env` with the following content:

```sh
  secrets_file="./secrets.env"

  cat <<EOT > "${secrets_file}"
  KC_VAR1="value1"
  KC_VAR2="value2"
  KC_VAR3="value3"
  KC_VAR4="value4"

  EOT
```


### Example: Encrypt with Amazon Web Services (AWS KMS)

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

#### Encrypt the File

Encrypt the file with SOPS with the AWS KMS key (in this example, using the KMS key alias we created earlier called "devtest"):

```sh
  export environment="devtest"
  export secrets_file="./secrets.env"
  export encrypted_file="./secrets.encrypted.env"

  key_alias="$(aws kms list-aliases --query "Aliases[?AliasName=='alias/${environment}'].TargetKeyId" --output text | tr -d '\r\n')"

  export key_id="arn:aws:kms:$(aws configure get region):$(aws sts get-caller-identity --query Account --output text):key/${key_alias}"

  echo "Encrypting file with key_id: ${key_id}"

  if sops --encrypt --kms "${key_id}" "${secrets_file}" > "${encrypted_file}.tmp"; then
      mv "${encrypted_file}.tmp" "${encrypted_file}"
  else
      echo "Encryption failed. No file was created."
      rm -f "${encrypted_file}.tmp"
      exit 1
  fi
```

#### Results

```sh
  ❯ cat config/secrets.env

  KC_VAR1="value1"
  KC_VAR2="value2"
  KC_VAR3="value3"
  KC_VAR4="value4"

  ❯ cat config/secrets.encrypted.env

  KC_VAR1=ENC[AES256_GCM,data:2DucRAzTBFs=,iv:aKw7fI8X6qHT/Kex8L4z7z8aPucXenfNuzvJyILfwAo=,tag:Lr2M1k3aklelsZnXS4wecQ==,type:str]
  KC_VAR2=ENC[AES256_GCM,data:uwq0d67C8NU=,iv:0RQ68vho/3Z0XtmZ260u5l/ZhBViOh1k=,tag:tvzOrPx1xm9HaWrLosXvgw==,type:str]
  KC_VAR3=ENC[AES256_GCM,data:6z43P2sDtKo=,iv:ySIlax+IBo1NG+VFj1J+rdbl/n/1uZBg=,tag:x2laIB3at3rxfE9EEXaw7g==,type:str]
  KC_VAR4=ENC[AES256_GCM,data:bEsM2yUPQPw=,iv:lo93y3xdcFelkCOTTimkPML+9ZWchLWlGfkHdm0=,tag:9vfktRbWrj38pRHJWgPxUw==,type:str]
  sops_kms__list_0__map_arn=arn:aws:kms:us-west-2:123456789:key/mrk-1234566789
  sops_kms__list_0__map_aws_profile=
  sops_kms__list_0__map_created_at=2024-06-09T05:14:49Z
  sops_kms__list_0__map_enc=AQICAHivIpyV1nDqrP3iBKwogoe/AN+auULmxzsAH/h5xvXybjkJOIdMWr/1B37EvlsycyzWzefxeGwEnOx51Y0xztlJC4NRT4j+btlRYjrtqNoguiznggrG42Aw6MD87tokjgpg==
  sops_lastmodified=2024-06-09T05:14:49Z
  sops_mac=ENC[AES256_GCM,data:x4P3H1if3lZV7WvQKm3DZcuR313S/NiWM0ybt4xlgyxgTOG+NN6kK5qOHYgQy53Cs77Rm/oWkEBJye9THnKwnBX7nteLhAMk/Oig=,iv:hZPqBTOWfLJmQXX5ZTL4T9t9h/5YAcoJjtiM49UM9hE=,tag:hcxmLuHh1tBzaw/wnzfHcg==,type:str]
  sops_unencrypted_suffix=_unencrypted
  sops_version=3.8.1
```

#### Decrypt the File

```sh
  export environment="devtest"
  export encrypted_file="./secrets.encrypted.env"
  export decrypted_file="./secrets.decrypted.env"

  key_alias="$(aws kms list-aliases --query "Aliases[?AliasName=='alias/${environment}'].TargetKeyId" --output text | tr -d '\r\n')"

  export key_id="arn:aws:kms:$(aws configure get region):$(aws sts get-caller-identity --query Account --output text):key/${key_alias}"

  if sops --decrypt --kms "${key_id}" "${encrypted_file}" > "${decrypted_file}.tmp"; then
      mv "${decrypted_file}.tmp" "${decrypted_file}"
  else
      echo "Decryption failed. No file was created."
      rm -f "${decrypted_file}.tmp"
      exit 1
  fi
```

##### Results

```sh
  ❯ cat config/secrets.decrypted.env

  KC_VAR1="value1"
  KC_VAR2="value2"
  KC_VAR3="value3"
  KC_VAR4="value4"
```

---

### Example: Encrypt with Google Cloud Platform (GCP KMS)

Create a GCP KMS kering for a `devtest` environment:

```sh
  export environment="devtest"
  export location="global"
  export keyring="${environment}-keyring"
  export key="${environment}-key"

  gcloud kms keyrings create "${keyring}" --location "${location}"

  gcloud kms keys create "${key}" --location "${location}" --keyring "${keyring}" --purpose "encryption"
```

#### Encrypt the file

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

#### Decrypt the file

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

---

## Setup `.ignore` files

In your repo, ensure that files that contain secrets (such as `.env` files) are not accidentally commited, but do allow encrypted files (`*.encrypted.*`) to be commited.

### `.gitignore`

```
# Don't commit sensitive files
.env
*.env
*.decrypted.*

# But allow SOPS encrypted files
!*.encrypted.*
```

