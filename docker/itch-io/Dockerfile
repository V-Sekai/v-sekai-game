FROM debian:stable-slim

ARG INPUT_RELEASE_VERSION
ARG INPUT_API_KEY
ARG INPUT_ITCHIO_PROJECT
ARG INPUT_FILEPATH

ENV BUTLER_API_KEY $INPUT_API_KEY

RUN apt-get update && apt-get install -y ca-certificates curl unzip

# Install Itch.io Butler
RUN curl -L -o butler.zip https://broth.itch.ovh/butler/linux-amd64/LATEST/archive/default

RUN mkdir butler && unzip -d butler/ butler.zip \
      && chmod +x ./butler/butler && mv ./butler/* /usr/bin/ \
      && butler -V 

COPY entrypoint.sh /usr/bin/entrypoint.sh

CMD ["/bin/sh", "/usr/bin/entrypoint.sh"]
