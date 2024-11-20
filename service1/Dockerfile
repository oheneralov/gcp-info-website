FROM node:18
WORKDIR /app
COPY package*.json ./
RUN npm i -g @nestjs/cli
RUN npm install
COPY . .
EXPOSE 3000

# Creates a "dist" folder with the production build
RUN npm run build

# Start the server using the production build
CMD [ "node", "dist/main.js" ]

