FROM node:20-bookworm-slim

WORKDIR /app

RUN apt-get update && apt-get install -y python3 make g++ gcc && rm -rf /var/lib/apt/lists/*

COPY package.json ./
RUN npm install --production

COPY . .

EXPOSE 3000

ENV PORT=3000
ENV NODE_ENV=production
ENV DATA_DIR=/app/data
ENV UPLOADS_DIR=/app/uploads

CMD ["node", "server.js"]
