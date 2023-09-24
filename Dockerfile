FROM quay.io/keycloak/keycloak:latest AS base

FROM base AS builder

ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true
ENV KC_FEATURES=token-exchange
ENV KC_DB=postgres

ADD --chown=keycloak:keycloak https://github.com/klausbetz/apple-identity-provider-keycloak/releases/download/1.7.0/apple-identity-provider-1.7.0.jar /opt/keycloak/providers/apple-identity-provider-1.7.0.jar

COPY /themes/keywind/theme/keywind /opt/keycloak/themes/keywind

COPY /realms /opt/keycloak/data/import

RUN /opt/keycloak/bin/kc.sh build 

FROM base AS final

COPY java.config /etc/crypto-policies/back-ends/java.config

WORKDIR /opt/keycloak

COPY --from=builder /opt/keycloak/ ./

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]

CMD ["start", "--optimized", "--proxy", "edge", "--hostname", "${RAILWAY_STATIC_URL}", "--import-realm", "--db=postgres", "--db-url", "jdbc:postgresql://${PGHOST}:${PGPORT}/${PGDATABASE}", "--db-username", "${PGUSER}", "--db-password", "${PGPASSWORD}"]