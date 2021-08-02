1. build a new CITC lab

2. Login the OOB server and sudo -i

11. Install docker-ce on OOB server # https://docs.docker.com/engine/install/ubuntu/

sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update && apt-get install docker-ce docker-ce-cli containerd.io -y

systemctl restart docker


3. Download and install k3s

curl -LO https://github.com/k3s-io/k3s/releases/download/v1.21.3%2Bk3s1/k3s
chmod +x k3s
mv k3s /usr/local/bin/

4. Download and install CNI plugins

curl -LO https://github.com/containernetworking/plugins/releases/download/v0.9.1/cni-plugins-linux-amd64-v0.9.1.tgz

mkdir -p /opt/cni/bin

tar -xvf cni-plugins-linux-amd64-v0.9.1.tgz -C /opt/cni/bin/

mkdir -p /etc/cni/net.d

cat > /etc/cni/net.d/10-bridge.conf << EOF
{
    "cniVersion": "0.3.1",
    "name": "mynet",
    "type": "bridge",
    "bridge": "docker0",
    "isDefaultGateway": true,
    "forceAddress": false,
    "ipMasq": true,
    "hairpinMode": true,
    "ipam": {
        "type": "host-local",
        "subnet": "172.17.0.0/16"
    }
}
EOF

5. Create a systemd file for k3s (server side)

cat > /etc/default/k3s << EOF
DISABLE_FLANNEL=--no-flannel
NODE_IP=--node-ip 192.168.200.1
K3S_NODE_NAME=master
EOF

cat > /etc/systemd/system/k3s.service << EOF

[Unit]
Description=k3s on cumulus
Documentation=https://k3s.io
Wants=network-online.target
After=network-online.target

[Install]
WantedBy=multi-user.target

[Service]
Type=notify
EnvironmentFile=-/etc/default/k3s
KillMode=process
Delegate=yes
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
TimeoutStartSec=0
Restart=always
RestartSec=5s
ExecStart=/usr/local/bin/k3s server $NODE_IP $DISABLE_FLANNEL 

EOF

systemctl enable k3s
systemctl start k3s 

6. Install arkade and kubectl

curl -sLS https://get.arkade.dev | sudo sh
arkade get kubectl

export PATH=$PATH:$HOME/.arkade/bin/
KUBECONFIG=/etc/rancher/k3s/k3s.yaml kubectl get node

7. Capture the node join token
$ cat /var/lib/rancher/k3s/server/node-token
K104b584a25457c7428c5a9380cb25f2c886ec47d1b23db390bde2a7daa8ed284cd::server:60fbda793e6b97773b06b316a237d506

8. Repeat steps 3-4 on leaf01

9. Create k3s agent systemd files

cat > /etc/default/k3s << EOF
DISABLE_FLANNEL=--no-flannel
NODE_IP=--node-ip 192.168.200.11
KUBELET_ARG=--kubelet-arg="feature-gates=SupportPodPidsLimit=true"
K3S_TOKEN=K104b584a25457c7428c5a9380cb25f2c886ec47d1b23db390bde2a7daa8ed284cd::server:60fbda793e6b97773b06b316a237d506
K3S_NODE_NAME=leaf01
K3S_URL=https://192.168.200.1:6443
EOF

cat > /etc/systemd/system/k3s.service << EOF

[Unit]
Description=k3s on cumulus
Documentation=https://k3s.io
Wants=network-online.target
After=network-online.target

[Install]
WantedBy=multi-user.target

[Service]
Type=exec
EnvironmentFile=-/etc/default/k3s
KillMode=process
Delegate=yes
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
TimeoutStartSec=0
Restart=always
RestartSec=5s
ExecStart=ip vrf exec mgmt /usr/local/bin/k3s agent $DISABLE_FLANNEL $KUBELET_ARG

EOF


systemctl enable k3s@mgmt
systemctl start k3s@mgmt

10. Taint cumulus node to prevent it accidental scheduling

kubectl taint nodes leaf01 cumulus=leaf01:NoSchedule


12. Confirm that all pods are up

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
kubectl get pod









