# Kubernetes on Cumulus

All instructions were designed to be run on CITC topology as `cumulus@oob-mgmt-server`.

This repository contains ansible code to bootstrap a small 3-node [k3s](https://rancher.com/docs/k3s/latest/en/) cluster, with control plane running on `oob-mgmt-server` and two worker nodes on `leaf01` and `leaf02`.

In addition to that, the [`docker`](./docker) directory contains a sample application that watches a given directory (via `inotify`), synchronizes all files with `/etc/network/interfaces.d` and triggers `ifreload -a`.

This sample application is deployed on both leaf switches and interface configuration is injected via a [ConfigMap](https://kubernetes.io/docs/concepts/configuration/configmap/) mounted as a volume. Therefore, any changes to this configmap get propagated to individual leaf switches and trigger a config reload. 

The goal is to demonstrate the following: 

* ability to deploy kubernetes cluster over network devices
* ability to manage software running on a switch as standard Kubernetes deployments
* ability to manage switch configuration via a central API server
* with an extra CD system, these changes can pulled from a git repository, enabling declarative GitOps-style network management.


## Requirements

Ansible 2.9+ needs to be installed:

```
sudo apt update 
sudo apt install python3-pip -y
sudo python3 -m pip install ansible~=2.9
```

Install extra dependencies:

```
sudo ansible-galaxy collection install -r collections/requirements.yml
```

4. Bootstrap the kubernetes cluster

```
ansible-playbook bootstrap.yml
```

5. Manage configuration of bond1 via k8s API

Modify the contents of the [bond1.conf](./manifests/bond1.conf) and run
```
kubectl apply -k manifests/
```

6. Observe how the change gets propagated and applied to leaf switches

Some notes about ConfigMap propagation delay: https://kubernetes.io/docs/concepts/configuration/_print/#mounted-configmaps-are-updated-automatically

## Improvement ideas

* Add FluxCD manifests to demonstrate pull-based GitOps workflow
* Build a new CRD API + Kubernetes Controller to speed up configuration update propagation and implement custom configuration update logic.