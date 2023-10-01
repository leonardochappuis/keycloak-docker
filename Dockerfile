FROM quay.io/keycloak/keycloak:latest AS base

FROM base AS builder

ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true
ENV KC_FEATURES=token-exchange
ENV KC_DB=postgres
ENV QUARKUS_TRANSACTION_MANAGER_ENABLE_RECOVERY=true

ADD --chown=keycloak:keycloak https://github.com/klausbetz/apple-identity-provider-keycloak/releases/download/1.7.1/apple-identity-provider-1.7.1.jar /opt/keycloak/providers/apple-identity-provider-1.7.1.jar
ADD --chown=keycloak:keycloak https://github.com/wadahiro/keycloak-discord/releases/download/v0.5.0/keycloak-discord-0.5.0.jar /opt/keycloak/providers/keycloak-discord-0.5.0.jar
COPY /theme/keywind /opt/keycloak/themes/keywind

RUN /opt/keycloak/bin/kc.sh build 

FROM base AS final

ENV QUARKUS_TRANSACTION_MANAGER_ENABLE_RECOVERY=true

COPY java.config /etc/crypto-policies/back-ends/java.config
WORKDIR /opt/keycloak
COPY --from=builder /opt/keycloak/ ./

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]

CMD ["start", "--log-level=WARN", "--spi-dblock-jpa-lock-wait-timeout", "3000", "--optimized", "--proxy", "edge", "--hostname", "${RAILWAY_STATIC_URL}", "--import-realm", "--db=postgres", "--db-url", "jdbc:postgresql://${PGHOST}:${PGPORT}/${PGDATABASE}", "--db-username", "${PGUSER}", "--db-password", "${PGPASSWORD}"]