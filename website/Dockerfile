FROM node:22.23.4-alpine

WORKDIR /workspace/website
RUN mkdir -p /workspace/website/.astro /workspace/website/dist && chown -R node:node /workspace
COPY --chown=node:node package.json package-lock.json ./
USER node
RUN npm ci

EXPOSE 4321
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0", "--port", "4321"]
