#!/bin/bash

rm -rf .terraform* run tmp zarf-sbom extract-terraform.sh kubeconfig.yaml

terraform init -upgrade

terraform destroy --auto-approve
