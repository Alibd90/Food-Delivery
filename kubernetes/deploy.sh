#!/bin/bash

# Script de déploiement de l'application Food-Delivery sur Kubernetes
echo "🚀 Déploiement de l'application Food-Delivery..."

# Créer le namespace
echo "📦 Création du namespace..."
kubectl apply -f 00-namespace.yaml

# Appliquer les secrets
echo "🔐 Application des secrets..."
kubectl apply -f 05-secrets.yaml

# Déployer MongoDB
echo "💾 Déploiement de MongoDB..."
kubectl apply -f 01-mongodb.yaml

# Attendre que MongoDB soit prêt
echo "⏳ Attente du démarrage de MongoDB..."
kubectl wait --namespace food-delivery \
  --for=condition=ready pod \
  --selector=app=mongo \
  --timeout=300s

# Déployer le backend
echo "🔧 Déploiement du backend..."
kubectl apply -f 02-backend.yaml

# Attendre que le backend soit prêt
echo "⏳ Attente du démarrage du backend..."
kubectl wait --namespace food-delivery \
  --for=condition=ready pod \
  --selector=app=backend \
  --timeout=300s

# Déployer le frontend
echo "🌐 Déploiement du frontend..."
kubectl apply -f 03-frontend.yaml

# Déployer l'admin
echo "👤 Déploiement de l'interface admin..."
kubectl apply -f 04-admin.yaml

# Vérifier le statut des pods
echo "🔍 Vérification du statut des pods..."
kubectl get pods -n food-delivery

# Afficher les services
echo "🔍 Liste des services et leurs URLs d'accès..."
kubectl get services -n food-delivery

echo "✅ Déploiement terminé!"
echo "URLs d'accès:"
echo "Frontend: http://localhost:5173"
echo "Admin: http://localhost:5174"
echo "Backend API: http://localhost:8000"