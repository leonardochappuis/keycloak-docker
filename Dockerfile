# Compiles a small provider that hands JGroups' JDBC_PING the same CDI-managed DataSource
# Keycloak already uses, instead of letting JDBC_PING load the Postgres driver itself
# (its classloader can't see the driver bundled in Quarkus' runtime classloader).
FROM eclipse-temurin:21-jdk AS jgroups-jdbc-ping-builder

COPY --from=quay.io/keycloak/keycloak:25.0.6 /opt/keycloak/lib/lib/main/jakarta.enterprise.jakarta.enterprise.cdi-api-4.0.1.jar /deps/
COPY --from=quay.io/keycloak/keycloak:25.0.6 /opt/keycloak/lib/lib/main/jakarta.inject.jakarta.inject-api-2.0.1.jar /deps/
COPY --from=quay.io/keycloak/keycloak:25.0.6 /opt/keycloak/lib/lib/main/org.jgroups.jgroups-5.3.10.Final.jar /deps/
COPY jgroups-jdbc-ping/src/main/java /src
RUN mkdir /out \
    && javac -cp "/deps/*" -d /out $(find /src -name '*.java') \
    && jar cf /jgroups-jdbc-ping-datasource.jar -C /out .

FROM quay.io/keycloak/keycloak:25.0.6 AS builder

ARG KC_HEALTH_ENABLED KC_METRICS_ENABLED KC_FEATURES KC_DB KC_HTTP_ENABLED PROXY_ADDRESS_FORWARDING QUARKUS_TRANSACTION_MANAGER_ENABLE_RECOVERY KC_HOSTNAME KC_LOG_LEVEL KC_DB_POOL_MIN_SIZE KC_CACHE KC_CACHE_STACK

ADD --chown=keycloak:keycloak https://github.com/klausbetz/apple-identity-provider-keycloak/releases/download/1.7.1/apple-identity-provider-1.7.1.jar /opt/keycloak/providers/apple-identity-provider-1.7.1.jar
ADD --chown=keycloak:keycloak https://github.com/wadahiro/keycloak-discord/releases/download/v0.5.0/keycloak-discord-0.5.0.jar /opt/keycloak/providers/keycloak-discord-0.5.0.jar
COPY /theme/keywind /opt/keycloak/themes/keywind
COPY cache-ispn.xml /opt/keycloak/conf/cache-ispn.xml
COPY --from=jgroups-jdbc-ping-builder --chown=keycloak:keycloak /jgroups-jdbc-ping-datasource.jar /opt/keycloak/providers/jgroups-jdbc-ping-datasource.jar

# Multi-stage COPY can bump provider jar mtimes past what `kc.sh build` records, and
# --optimized then thinks providers changed since the build and misconfigures the
# datasource on startup (keycloak#41268). Pinning mtimes to a fixed epoch before build
# keeps them stable across the COPY --from=builder into the final stage below.
RUN find /opt/keycloak/providers -type f -exec touch -a -m --date=@0 {} + \
    && /opt/keycloak/bin/kc.sh build

FROM quay.io/keycloak/keycloak:25.0.6

COPY java.config /etc/crypto-policies/back-ends/java.config

COPY --from=builder /opt/keycloak/ /opt/keycloak/
COPY --chown=keycloak:keycloak --chmod=0755 docker-entrypoint.sh /opt/keycloak/bin/docker-entrypoint.sh

ENTRYPOINT ["/opt/keycloak/bin/docker-entrypoint.sh"]

CMD ["start", "--optimized", "--import-realm", "--cache-config-file=cache-ispn.xml"]