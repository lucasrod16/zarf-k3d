#!/bin/bash

function checkError() {
    if [ $? -ne 0 ]
    then
        echo "Terraform exited with error"
        exit 1
    fi
}

function waitInstanceReady() {
    timeout="$(( $(date +%s) + 600 ))"  # Set the timeout to 10 minutes (600 seconds)
    while true
    do
        echo "Waiting for EC2 instance to be ready"
        instance_state="$(aws ec2 describe-instances --instance-ids "$1" --query "Reservations[].Instances[].State.Name" --output text)"

        if [[ $instance_state == "running" ]]
        then
            instance_status="$(aws ec2 describe-instance-status --instance-ids "$1" --query "InstanceStatuses[].InstanceStatus[].Status" --output text)"

            if [[ $instance_status == "ok" ]]
            then
                echo "Instance is ready!"
                break
            fi
        fi

        current_time="$(date +%s)"
        if (( current_time >= timeout ))
        then
            echo "Timed out waiting for EC2 instance to be ready"
            exit 1
        fi

        sleep 5
    done
}

client_ip="$(curl -s "https://checkip.amazonaws.com")"

terraform init -upgrade
checkError

terraform plan -var="client_ip=$client_ip"
checkError

terraform apply -var="client_ip=$client_ip" --auto-approve
checkError

instance_id="$(terraform output -raw instance_id)"
s3_bucket="$(terraform output -raw s3_bucket)"

waitInstanceReady "$instance_id"

rm -rf ~/.kube/config

aws s3 cp s3://"$s3_bucket"/kubeconfig.yaml ~/.kube/config

zarf tools kubectl get nodes -o wide
