FROM mongo:8.0

ARG RELEASE_VERSION=development
ARG GIT_SHA=unknown

ENV RELEASE_VERSION=$RELEASE_VERSION
ENV GIT_SHA=$GIT_SHA

LABEL org.opencontainers.image.title="AgriMarket MongoDB Runner" \
      org.opencontainers.image.version="$RELEASE_VERSION" \
      org.opencontainers.image.revision="$GIT_SHA"

WORKDIR /lab

COPY . /lab/

RUN chmod +x /lab/run.sh

ENTRYPOINT ["/bin/bash", "/lab/run.sh"]

CMD ["init"]