FROM quay.io/keycloak/keycloak:latest AS base

FROM base AS builder

ARG KC_DB_PASSWORD
ARG KC_DB_URL
ARG KC_DB_USERNAME

ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true
ENV KC_FEATURES=token-exchange
ENV KC_DB=postgres
ENV KC_PROXY=edge
ENV KC_DB_PASSWORD=$KC_DB_PASSWORD
ENV KC_DB_URL=$KC_DB_URL
ENV KC_DB_USERNAME=$KC_DB_USERNAME
# Make sure to save the data before the container is stopped
ENV QUARKUS_TRANSACTION_MANAGER_ENABLE_RECOVERY=true

# Custom providers
ADD --chown=keycloak:keycloak https://github.com/klausbetz/apple-identity-provider-keycloak/releases/download/1.7.1/apple-identity-provider-1.7.1.jar /opt/keycloak/providers/apple-identity-provider-1.7.1.jar
ADD --chown=keycloak:keycloak https://github.com/wadahiro/keycloak-discord/releases/download/v0.5.0/keycloak-discord-0.5.0.jar /opt/keycloak/providers/keycloak-discord-0.5.0.jar

# Custom theme (keywind)
COPY /theme/keywind /opt/keycloak/themes/keywind

RUN /opt/keycloak/bin/kc.sh build 

FROM base AS final

ARG KC_DB_PASSWORD
ARG KC_DB_URL
ARG KC_DB_USERNAME
ARG HOSTNAME

ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true
ENV KC_DB=postgres
ENV KC_PROXY=edge
ENV KC_DB_PASSWORD=$KC_DB_PASSWORD
ENV KC_DB_URL=$KC_DB_URL
ENV KC_DB_USERNAME=$KC_DB_USERNAME
ENV HOSTNAME=$HOSTNAME
# Make sure to save the data before the container is stopped
ENV QUARKUS_TRANSACTION_MANAGER_ENABLE_RECOVERY=true

COPY java.config /etc/crypto-policies/back-ends/java.config

WORKDIR /opt/keycloak

COPY --from=builder /opt/keycloak/ ./

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]

CMD ["start", "--log-level=ALL", "--spi-dblock-jpa-lock-wait-timeout", "3000", "--optimized", "--hostname", "${HOSTNAME}"]