# zarf-k3d

This repo is for experimenting with using ephemeral k3d clusters on an AWS EC2 instance in a CI/CD pipeline to test DUBBD deployments on.

## Overview

1. A pipeline is triggered by a git commit

1. An EC2 instance and S3 bucket are created

1. On launch, a k3d cluster is created on the EC2 instance using a [user data script](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html#user-data-shell-scripts). Once the k3d cluster has created successfully, the user data script then uploads the kubeconfig to the S3 bucket.

1. Once the EC2 instance reaches a `running` state, the kubeconfig is then downloaded from the S3 bucket to the GitHub runner at `~/.kube/config`.

1. Zarf can now connect to the cluster using the kubeconfig at `~/.kube/config`.

1. Initialize the cluster with zarf.

1. Deploy DUBBD to the cluster with zarf.

1. Teardown the cluster.
