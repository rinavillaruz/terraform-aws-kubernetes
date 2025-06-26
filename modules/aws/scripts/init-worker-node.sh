#!/bin/bash

set -e

# Disable swap
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab
echo "[1/10] Disable swap" | sudo tee -a /var/log/k8s-install-success.txt > /dev/null

# Enables packet forwarding
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
EOF
echo "[2/10] Enables packet forwarding" | sudo tee -a /var/log/k8s-install-success.txt > /dev/null

# Apply sysctl params without reboot
sysctl --system

# Install containerd and others
# Add Docker's official GPG key:
apt-get update
apt-get install -y ca-certificates curl gnupg lsb-release containerd apt-transport-https unzip

# Create keyring directory if it doesn't exist
mkdir -p /etc/apt/keyrings

# Download and save the Docker GPG key in dearmored format
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
 sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Make the key readable
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  noble stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update

echo "[3/10] Install containerd" | sudo tee -a /var/log/k8s-install-success.txt > /dev/null

mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd
echo "[4/10] Configure containerd" | sudo tee -a /var/log/k8s-install-success.txt > /dev/null

# If the directory `/etc/apt/keyrings` does not exist, it should be created before the curl command, read the note below.
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list

apt-get update
apt-get install -y kubelet kubeadm
apt-mark hold kubelet kubeadm
echo "[5/10] Install kubelet, kubeadm" | sudo tee -a /var/log/k8s-install-success.txt > /dev/null

systemctl enable --now kubelet
echo "[6/10] Worker node is ready. Run your kubeadm join command." | sudo tee -a /var/log/k8s-install-success.txt > /dev/null


# Configure AWS
# 1. Download the AWS CLI v2 installer
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

# Install aws
# 2. Unzip the installer
unzip awscliv2.zip
# 2. Run the install script
sudo ./aws/install
# 4. Verify the installation
aws --version
echo "[7/10] aws --version" | sudo tee -a /var/log/k8s-install-success.txt > /dev/null

# Needs to wait for 2 mins for the current join command in ssm to show
sleep 120
echo "[8/10] Waited 2 minutes before retrieving join command..." | sudo tee -a /var/log/k8s-install-success.txt > /dev/null

JOIN_CMD=$(aws ssm get-parameter \
      --region us-east-1 \
      --name "/k8s/worker-node/join-command" \
      --with-decryption \
      --query "Parameter.Value" \
      --output text \
      --no-cli-pager \
      --cli-read-timeout 10 \
      --cli-connect-timeout 10)

if [[ $? -ne 0 || "$JOIN_CMD" == *"error"* ]]; then
    echo "[9/10] Failed to retrieve the command" | sudo tee -a /var/log/k8s-install-success.txt > /dev/null
    exit 1  
else
  echo "[9/10] Retrieved the command $JOIN_CMD" | sudo tee -a /var/log/k8s-install-success.txt > /dev/null

  # Execute the parameter
  eval "sudo $JOIN_CMD"

  echo "[10/10] Joined the worker node" | sudo tee -a /var/log/k8s-install-success.txt > /dev/null
fi