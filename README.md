# Kubernetes on Cumulus

All instructions were designed to be run on CITC topology as `cumulus@oob-mgmt-server`.

## Requirements

Ansible 2.10+ needs to be installed:

```
sudo apt update 
sudo apt install python3-pip -y
sudo python3 -m pip install ansible~=2.10
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