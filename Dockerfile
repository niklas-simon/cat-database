# use latest nodejs image
FROM node
# create directories node_modules, images in app directory
# make user node own app directory
RUN mkdir -p /home/node/app/node_modules && mkdir -p /home/node/app/images && chown -R node:node /home/node/app
# do stuff in app directory from now on
WORKDIR /home/node/app
# copy package.json, package-lock.json to app directory
COPY package*.json ./
# set npm proxy settings
RUN npm config set proxy $HTTP_PROXY && \
    npm config set https-proxy $HTTPS_PROXY
# install nodejs dependencies
RUN npm install
# copy everything not in .dockerignore to app directory
COPY --chown=node:node . .
# do stuff as node user from now on
USER node
# expose port 80 to outside of container
EXPOSE 80

# execute this when starting app
CMD [ "node", "index.js" ]
