FROM node:16-bullseye-slim

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && \
    apt-get install -y wget gnupg && \
    apt-get install -y fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-kacst fonts-freefont-ttf libxss1 && \
    apt-get install -y libgtk2.0-0 libnss3 libatk-bridge2.0-0 libdrm2 libxkbcommon0 libgbm1 libasound2 && \
    apt-get clean

# Just for development - not required in any way
#RUN apt-get install -y vim bash

WORKDIR /src
COPY ./src /src

# Should be better move this into a package.json?
#RUN npm i puppeteer express body-parser temp
RUN npm install

CMD ["node", "webservices.js"]
