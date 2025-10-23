# Utiliser une version plus ancienne de Node.js
FROM node:16-alpine

# Définir le répertoire de travail
WORKDIR /app

# Installer les dépendances nécessaires
RUN apk add --no-cache python3 make g++

# Copier package.json et package-lock.json
COPY package*.json ./

# Installer les dépendances
RUN npm install

# Copier le reste des fichiers
COPY . .

# Variables d'environnement
ENV NODE_ENV=production
ENV PORT=5000
ENV MONGO_URL=mongodb://mongo:27017/food-delivery

# Exposer le port
EXPOSE 5000

# Démarrer l'application
CMD ["node", "server.js"]