#!/bin/bash

# Script d'initialisation du cluster Kubernetes
echo "🚀 Démarrage de l'initialisation du cluster Kubernetes..."

# 1. Désactiver le swap (requis pour Kubernetes)
echo "💾 Désactivation du swap..."
sudo swapoff -a
sudo sed -i '/swap/d' /etc/fstab

# 2. Installation des prérequis
echo "📦 Installation des prérequis..."
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

# 3. Ajout de la clé GPG de Kubernetes
echo "🔑 Ajout de la clé GPG de Kubernetes..."
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

# 4. Ajout du repository Kubernetes
echo "📚 Ajout du repository Kubernetes..."
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# 5. Installation de kubelet, kubeadm et kubectl
echo "🛠️ Installation des outils Kubernetes..."
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# 6. Configuration des modules kernel requis
echo "⚙️ Configuration des modules kernel..."
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# 7. Configuration des paramètres réseau
echo "🌐 Configuration des paramètres réseau..."
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system

# 8. Initialisation du master node
echo "👑 Initialisation du master node..."
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=$(hostname -i)

# 9. Configuration de kubectl pour l'utilisateur courant
echo "🔧 Configuration de kubectl..."
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# 10. Installation du réseau overlay (Flannel)
echo "🕸️ Installation du réseau overlay Flannel..."
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# 11. Génération du token pour les worker nodes
echo "🎟️ Génération du token pour les worker nodes..."
JOIN_COMMAND=$(sudo kubeadm token create --print-join-command)
echo "Commande pour joindre les worker nodes:"
echo $JOIN_COMMAND

# 12. Vérification du statut du cluster
echo "🔍 Vérification du statut du cluster..."
kubectl get nodes
kubectl get pods --all-namespaces

echo "✅ Installation terminée!"
echo "Pour ajouter des worker nodes, exécutez la commande suivante sur chaque nœud:"
echo $JOIN_COMMAND