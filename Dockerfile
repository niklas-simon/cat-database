FROM node
RUN mkdir -p /home/node/app/node_modules && mkdir -p /home/node/app/images && chown -R node:node /home/node/app
WORKDIR /home/node/app
COPY package*.json ./
RUN npm install
COPY --chown=node:node . .
USER node
EXPOSE 8080
ENV DB_HOST 172.17.0.1
ENV DB_USER root
ENV DB_PASSWORD root
ENV DB_NAME cats

CMD [ "node", "index.js" ]
