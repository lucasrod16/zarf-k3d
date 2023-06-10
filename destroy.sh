#!/bin/bash

client_ip="$(curl -s "https://checkip.amazonaws.com")"

terraform init -upgrade

terraform destroy -var="client_ip=$client_ip" --auto-approve
