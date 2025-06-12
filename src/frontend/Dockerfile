# ------------------- Stage 1: Build Stage ------------------------------
FROM node:22 AS frontend-builder

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

# ------------------- Stage 2: Final Stage ------------------------------
FROM node:22-slim 

WORKDIR /app

COPY --from=frontend-builder /app .

COPY .env.docker .env

EXPOSE 5173

CMD ["npm", "run", "dev", "--", "--host"]