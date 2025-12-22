FROM node:18-slim
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci --legacy-peer-deps
COPY . .
RUN npx hardhat compile
CMD ["npx", "hardhat", "test"]
