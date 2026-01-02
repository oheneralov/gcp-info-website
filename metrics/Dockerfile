FROM node:18-alpine

WORKDIR /app

# Copy only package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy only necessary application files
COPY index.js .

# Expose port
EXPOSE 3001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD node -e "require('http').get('http://localhost:3001', (r) => {if (r.statusCode !== 200) throw new Error(r.statusCode)})"

# Run application
CMD ["node", "index.js"]
