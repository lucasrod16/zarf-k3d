#!/bin/bash

function check_error {
    if [[ $? -eq 0 ]]
    then
        echo "Terraform exited with error"
        exit 1
    fi
}

client_ip="$(curl -s "https://checkip.amazonaws.com")"

terraform init -upgrade
check_error

terraform plan
check_error

terraform apply -var="client_ip=$client_ip" --auto-approve
check_error

instance_id="$(terraform output -raw instance_id)"
s3_bucket="$(terraform output -raw s3_bucket)"

while true
do
    echo "Waiting for EC2 instance to be ready"
    instance_state="$(aws ec2 describe-instances --instance-ids "$instance_id" --query "Reservations[].Instances[].State.Name" --output text)"

    if [[ $instance_state == "running" ]]
    then
        instance_status="$(aws ec2 describe-instance-status --instance-ids "$instance_id" --query "InstanceStatuses[].InstanceStatus[].Status" --output text)"

        if [[ $instance_status == "ok" ]]
        then
            echo "Instance is ready!"
            break
        fi
    fi
    sleep 5
done

aws s3 cp s3://"$s3_bucket"/kubeconfig.yaml .

zarf tools kubectl get nodes -o wide --kubeconfig ./kubeconfig.yaml

export KUBECONFIG="./kubeconfig.yaml"

zarf init -a amd64 --components=git-server --confirm

zarf package deploy zarf-package-* --confirm
