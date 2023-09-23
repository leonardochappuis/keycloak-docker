# ------------------------------------------------------------------------------------
# Keycloak image built for postgresql support with theme handling customisation
# to always fallback to standard openremote theme.
# ------------------------------------------------------------------------------------
ARG VERSION=:22.0.3
FROM quay.io/keycloak/keycloak:${VERSION}

WORKDIR /opt/keycloak

# Configure runtime options
ARG TZ
ARG KC_DB_URL
ARG KC_DB_URL_PORT
ARG KC_DB_URL_DATABASE
ARG KC_DB_SCHEMA
ARG KC_DB_USERNAME
ARG KC_DB_PASSWORD
ARG KC_HOSTNAME
ARG KC_PROXY
ARG KEYCLOAK_ADMIN
ARG KEYCLOAK_ADMIN_PASSWORD

ENV TZ=$TZ
ENV KC_DB_URL_HOST=$KC_DB_URL
ENV KC_DB_URL_PORT=$KC_DB_URL_PORT
ENV KC_DB_URL_DATABASE=$KC_DB_URL_DATABASE
ENV KC_DB_SCHEMA=$KC_DB_SCHEMA
ENV KC_DB_USERNAME=$KC_DB_USERNAME
ENV KC_DB_PASSWORD=$KC_DB_PASSWORD
ENV KC_HOSTNAME=$KC_HOSTNAME
ENV KEYCLOAK_ADMIN=$KEYCLOAK_ADMIN
ENV KEYCLOAK_ADMIN_PASSWORD=$KEYCLOAK_ADMIN_PASSWORD
ENV KEYCLOAK_START_COMMAND=start

EXPOSE 8080

ENTRYPOINT /opt/keycloak/bin/kc.sh ${KEYCLOAK_START_COMMAND:-start} ${KEYCLOAK_START_OPTS:-}