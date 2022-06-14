#### Stage Base ####

FROM debian:stable-slim AS base

LABEL version="1.0" maintainer="Axel ROTTHIER <axel@rj-it.fr>"

RUN apt-get update -y && \
    apt-get install wget xz-utils -y -q && \
    mkdir -p /usr/src/node-red /data && \
    useradd -d /usr/src/node-red/ -M node-red -u 1000 && \
    chown -R node-red:root /data && chmod -R g+rwX /data && \
    chown -R node-red:root /usr/src/node-red && chmod -R g+rwX /usr/src/node-red && \
    wget https://nodejs.org/dist/v18.3.0/node-v18.3.0-linux-x64.tar.xz && \
    tar -xJf "node-v18.3.0-linux-x64.tar.xz" -C /usr/src/node-red --strip-components=1 --no-same-owner && \
    rm -f "node-v18.3.0-linux-x64.tar.xz" && \
    ln -s /usr/src/node-red/bin/node /usr/bin/node && \
    ln -s /usr/src/node-red/bin/npm /usr/bin/npm && \
    # test
    node --version && \
    npm --version

WORKDIR /usr/src/node-red

COPY package.json .
COPY flows.json /data
COPY settings.js /data
COPY flows_cred.json /data

#### Stage Build ####

FROM base AS build

RUN apt-get update && apt-get install -y build-essential python && \
    npm install --unsafe-perm --no-update-notifier --no-fund --only=production && \
    npm uninstall node-red-node-gpio && \
    cp -R node_modules prod_node_modules

#### Stage Release ####

FROM base AS release

COPY --from=build /usr/src/node-red/prod_node_modules ./node_modules

RUN chown -R node-red:root /usr/src/node-red && \
    apt-get update && apt-get install -y build-essential python-dev python3

USER node-red

# Env variables
ENV NODE_RED_VERSION=$NODE_RED_VERSION \
    NODE_PATH=/usr/src/node-red/node_modules:/data/node_modules \
    PATH=/usr/src/node-red/node_modules/.bin:${PATH} \
    FLOWS=flows.json
    
VOLUME /data

EXPOSE 1880

ENTRYPOINT ["npm", "start", "--cache", "/data/.npm", "--", "--userDir", "/data"]