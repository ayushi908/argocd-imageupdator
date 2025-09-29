# Use lightweight Node.js image
FROM node:18-alpine

# Set working directory
WORKDIR /usr/src/app

# Copy package files and install dependencies
COPY app/package*.json ./
RUN npm install --only=production

# Copy app source code
COPY app/ ./

# Expose the app port
EXPOSE 3000

# Start the app
CMD ["node", "server.js"]
