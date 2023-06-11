# zarf-k3d

This repo is for experimenting with using ephemeral k3d clusters on an AWS EC2 instance in a CI/CD pipeline to test DUBBD deployments on.

## Problem Statement

Typically, Kubernetes platforms are made up of a collection of applications that provide a variety of different capabilities that are necessary for running applications in production.

Some of the different capabilities that the applications provide include:

- logging
- monitoring
- service mesh capabilities (ingress, load balancing, mutual TLS, etc.)
- container runtime security

Running these applications often demands a lot of compute resources (CPU/RAM).

If you're running Kubernetes in AWS, EKS is a great option for running your platform and applications in production.
While EKS is a great option for production use-cases, it is not a great option for developing and testing your platform and application(s).
The primary reason why it is not a great option for developing and testing is that it takes a long time to create an EKS cluster.
Writing the Infrastrucure as Code to build an EKS cluster is a well-documented use-case, and there are convenient options out there that make it easy and convenient to create EKS clusters, such as `eksctl`.

The problem of time occurs during cluster creation and teardown. Spinning up an EKS cluster with 2-3 worker nodes typically takes anywhere from 15-20 minutes. It typically takes somewhere between 5-10 minutes to teardown/delete an EKS cluster.

When testing your changes during local development, and in a pipeline, you don't want to have to wait this long for standing up and tearing down your test environment.

Using a persistent cluster for testing locally and in a pipeline saves a lot of time by not having to provision and teardown a cluster every test run, but this also can also come with many problems. When deploying a platform composed of many different applications, it is usually ideal to start from a clean state, and deploy the platform to a fresh cluster every time. This allows you to test your platform and applications in a clean test environment every test run. There are also security risks with using persistent infrastructure for test environments. There is a higher risk of your build infrastrucure being compromised when compared to spinning up and tearing down ephemeral infrastructure on every test run.

## Overview

1. A pipeline is triggered by a git commit

1. An EC2 instance and S3 bucket are created

1. On launch, a k3d cluster is created on the EC2 instance using a [user data script](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html#user-data-shell-scripts). Once the k3d cluster has created successfully, the user data script then uploads the kubeconfig to the S3 bucket.

1. Once the EC2 instance reaches a `running` state, the kubeconfig is then downloaded from the S3 bucket to the GitHub runner at `~/.kube/config`.

1. Zarf can now connect to the cluster using the kubeconfig at `~/.kube/config`.

1. Initialize the cluster with zarf.

1. Deploy DUBBD to the cluster with zarf.

1. Teardown the cluster.
