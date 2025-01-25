FROM node:16-alpine

WORKDIR /usr/src/app

# Copy package files first to leverage Docker cache
COPY app/package*.json ./

# Install dependencies with cache mounted to reduce installation time
RUN --mount=type=cache,target=/root/.npm \
    npm install

# Copy application code
COPY app/ .

EXPOSE 3000

CMD [ "npm", "start" ] 