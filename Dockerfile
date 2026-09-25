# syntax=docker/dockerfile:1

# Container image that builds the Hypothesis client and serves it with nginx.
#
# Deployment-specific URLs are not baked in at build time. They are rendered
# into the boot script when the container starts (see
# docker/render-boot-script.sh), so the same image can be used in every
# environment.
#
# Build:
#   docker build -t hypothesis-client .
#   docker build --build-arg CLIENT_VERSION=1.1766.0-self.1 -t hypothesis-client .
#
# Run:
#   docker run -p 8080:8080 \
#     -e H_URL=https://h.example.com \
#     -e CLIENT_PUBLIC_URL=https://client.example.com \
#     hypothesis-client
#
# Then set h's CLIENT_URL to https://client.example.com/hypothesis

# ---- Build stage ----
FROM node:24-alpine AS build

WORKDIR /src

# Install dependencies first so that this layer is cached across source changes.
COPY package.json yarn.lock .yarnrc.yml ./
COPY .yarn/releases .yarn/releases
COPY .yarn/plugins .yarn/plugins
RUN node .yarn/releases/yarn-*.cjs install --immutable

COPY . .

# Optionally override the version from package.json. The version is used in the
# asset path and sent to h in the `Hypothesis-Client-Version` header.
ARG CLIENT_VERSION=""
RUN if [ -n "$CLIENT_VERSION" ]; then npm pkg set version="$CLIENT_VERSION"; fi

RUN node .yarn/releases/yarn-*.cjs build

# Lay out the files as /hypothesis/<version>/build/..., mirroring
# cdn.hypothes.is and the dev package server. `current` points at the version
# in this image and is used to serve the stable `/hypothesis` URL.
RUN version="$(node -p "require('./package.json').version")" \
    && mkdir -p "/out/hypothesis/$version" \
    && cp -R build "/out/hypothesis/$version/build" \
    && ln -s "$version" /out/hypothesis/current

# ---- Runtime stage ----
FROM nginxinc/nginx-unprivileged:stable-alpine

# The boot script is rendered at startup by the (non-root) nginx user, so it
# needs write access to the build directory.
COPY --from=build --chown=101:101 /out/hypothesis /usr/share/nginx/html/hypothesis
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY --chmod=0755 docker/render-boot-script.sh /docker-entrypoint.d/40-render-boot-script.sh

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget -q -O /dev/null http://127.0.0.1:8080/healthz || exit 1
