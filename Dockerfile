FROM composer:2.4.4 as composer

FROM php:8.1.11-alpine3.15 as build
COPY --from=composer /usr/bin/composer /usr/bin/composer
WORKDIR /app/
COPY app/ /app/
RUN chmod a+rx /usr/bin/composer && /usr/bin/composer install --no-interaction --no-scripts --no-progress --optimize-autoloader

FROM pipelinecomponents/base-entrypoint:0.5.0 as entrypoint

FROM php:8.1.11-alpine3.15
COPY --from=entrypoint /entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
ENV DEFAULTCMD security-checker

ENV PATH "$PATH:/app/vendor/bin/"
COPY --from=build /app/ /app/

# hadolint ignore=DL3018
RUN apk add --no-cache 	libzip unzip \
    && apk add --virtual build-dependencies --no-cache build-base autoconf libzip-dev \
    && docker-php-source extract \
    && docker-php-ext-install zip \
    && docker-php-source delete \
    && apk del build-dependencies

WORKDIR /code/
# Build arguments
ARG BUILD_DATE
ARG BUILD_REF

# Labels
LABEL \
    maintainer="Robbert Müller <dev@pipeline-components.dev>" \
    org.label-schema.description="PHP Security checker in a container for gitlab-ci" \
    org.label-schema.build-date=${BUILD_DATE} \
    org.label-schema.name="PHP Security checker" \
    org.label-schema.schema-version="1.0" \
    org.label-schema.url="https://pipeline-components.gitlab.io/" \
    org.label-schema.usage="https://gitlab.com/pipeline-components/php-security-checker/blob/master/README.md" \
    org.label-schema.vcs-ref=${BUILD_REF} \
    org.label-schema.vcs-url="https://gitlab.com/pipeline-components/php-security-checker/" \
    org.label-schema.vendor="Pipeline Components"
