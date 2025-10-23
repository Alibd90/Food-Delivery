# Food Delivery - Documentation d'Infrastructure

## Table des matières
1. [Architecture](#architecture)
2. [Docker](#docker)
3. [Docker Swarm](#docker-swarm)
4. [Kubernetes](#kubernetes)
5. [Maintenance et Opérations](#maintenance-et-opérations)

## Architecture

### Components
- **Frontend** : React/Vite application (Port: 5173)
- **Admin Panel** : React/Vite application (Port: 5174)
- **Backend** : Node.js/Express API (Port: 8000)
- **Database** : MongoDB (Port: 27017)

### Images Docker
```
alibouabidi/food-delivery-frontend:latest
alibouabidi/food-delivery-backend:latest
alibouabidi/food-delivery-admin:latest
mongo:latest
```

## Docker

### Structure des Dockerfiles

#### Backend Dockerfile
```dockerfile
FROM node:16-alpine
WORKDIR /app
RUN apk add --no-cache python3 make g++
COPY package*.json ./
RUN npm install
COPY . .
ENV NODE_ENV=production
EXPOSE 5000
CMD ["npm", "start"]
```

#### Frontend/Admin Dockerfile
```dockerfile
FROM node:18-alpine as build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
```

### Docker Compose
```yaml
services:
  mongo:
    image: mongo:latest
    volumes:
      - mongodb_data:/data/db
    ports:
      - "27017:27017"

  backend:
    image: alibouabidi/food-delivery-backend:latest
    ports:
      - "8000:5000"
    depends_on:
      - mongo

  frontend:
    image: alibouabidi/food-delivery-frontend:latest
    ports:
      - "5173:80"

  admin:
    image: alibouabidi/food-delivery-admin:latest
    ports:
      - "5174:80"
```

## Docker Swarm

### Initialisation
```bash
# Initialiser Swarm
docker swarm init

# Créer réseau overlay
docker network create --driver overlay food-delivery-network
```

### Configuration Swarm
```yaml
services:
  backend:
    deploy:
      replicas: 2
      update_config:
        parallelism: 1
        delay: 10s
      restart_policy:
        condition: on-failure

  frontend:
    deploy:
      replicas: 2

  mongo:
    deploy:
      replicas: 1
      placement:
        constraints:
          - node.role == manager
```

### Commandes Swarm
```bash
# Déployer stack
docker stack deploy -c docker-compose.swarm.yml food-delivery

# Vérifier services
docker service ls

# Scaling
docker service scale food-delivery_backend=3
```

## Kubernetes

### Structure des fichiers
```
kubernetes/
├── 00-namespace.yaml
├── 01-mongodb.yaml
├── 02-backend.yaml
├── 03-frontend.yaml
├── 04-admin.yaml
├── 05-secrets.yaml
└── deploy.sh
```

### Configuration des ressources

#### MongoDB (StatefulSet)
```yaml
kind: StatefulSet
spec:
  replicas: 1
  volumeMounts:
    - name: mongo-data
      mountPath: /data/db
```

#### Backend (Deployment)
```yaml
kind: Deployment
spec:
  replicas: 2
  resources:
    requests:
      memory: "128Mi"
      cpu: "100m"
    limits:
      memory: "256Mi"
      cpu: "200m"
```

### Commandes Kubernetes
```bash
# Déploiement complet
./deploy.sh

# Vérification
kubectl get pods -n food-delivery
kubectl get services -n food-delivery

# Scaling
kubectl scale deployment backend -n food-delivery --replicas=3

# Logs
kubectl logs -n food-delivery deployment/backend

# Redémarrage
kubectl rollout restart deployment frontend -n food-delivery
```

## Maintenance et Opérations

### Backup MongoDB
```bash
# Docker
docker exec -it mongodb mongodump --out /backup

# Kubernetes
kubectl exec -it -n food-delivery mongo-0 -- mongodump --out /backup
```

### Mise à jour des images
```bash
# Docker Compose
docker-compose pull
docker-compose up -d

# Kubernetes
kubectl set image deployment/backend backend=alibouabidi/food-delivery-backend:new-tag -n food-delivery
```

### Surveillance
```bash
# Logs Docker
docker-compose logs -f backend

# Logs Kubernetes
kubectl logs -f -n food-delivery deployment/backend
```

### Accès aux services
- Frontend: http://localhost:5173
- Admin Panel: http://localhost:5174
- Backend API: http://localhost:8000
- MongoDB: mongodb://localhost:27017

### Résolution des problèmes courants

1. **Problème de connexion à MongoDB**
```bash
# Vérifier le service MongoDB
kubectl describe service mongo -n food-delivery

# Vérifier les logs MongoDB
kubectl logs -n food-delivery mongo-0
```

2. **Échec du démarrage des pods**
```bash
# Vérifier les events
kubectl describe pod -n food-delivery [pod-name]

# Vérifier les logs
kubectl logs -n food-delivery [pod-name]
```

3. **Problèmes de réseau**
```bash
# Tester la connectivité
kubectl exec -it -n food-delivery [pod-name] -- wget -qO- http://backend:8000
```

### Bonnes pratiques
1. Toujours utiliser des tags spécifiques pour les images
2. Implémenter des health checks
3. Configurer des limites de ressources
4. Maintenir des backups réguliers
5. Surveiller les métriques clés

### Sécurité
1. Secrets stockés dans Kubernetes
2. Network Policies configurées
3. RBAC pour l'accès au cluster
4. Images scannées pour les vulnérabilités