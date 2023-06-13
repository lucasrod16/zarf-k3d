#!/bin/bash

public_ip="$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
instance_id="$(curl -s http://169.254.169.254/latest/meta-data/instance-id)"

# Create k3d cluster
k3d cluster create \
    --servers 1 \
    --agents 3 \
    --k3s-arg "--disable=traefik@server:*" \
    --k3s-arg "--disable=metrics-server@server:*" \
    --k3s-arg "--disable=servicelb@server:*" \
    --k3s-arg "--tls-san=${public_ip}@server:*" \
    --port 443:443@loadbalancer \
    --port 80:8080@loadbalancer \
    --api-port 6443

# Edit kubeconfig
k3d kubeconfig get k3s-default > kubeconfig.yaml
sed -i 's/0\.0\.0\.0/'"$public_ip"'/g' kubeconfig.yaml

# Upload kubeconfig to S3 bucket
s3_bucket="$(aws s3api list-buckets --query "Buckets[?starts_with(Name, ${instance_id}) == true].Name" --output text)"
aws s3 cp kubeconfig.yaml s3://"$s3_bucket"
