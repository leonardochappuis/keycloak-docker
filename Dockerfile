ARG KEYCLOAK_USER
ARG KEYCLOAK_PASSWORD
ARG PROXY_ADDRESS_FORWARDING
ARG DATABASE_URL	
ARG DB_USERNAME
ARG DB_PASSWORD
ARG KEYCLOAK_VERSION=22.0.3

FROM docker.io/maven:3.8.6-jdk-11 as mvn_builder
COPY . /tmp
RUN cd /tmp && mvn clean install

FROM quay.io/keycloak/keycloak:${KEYCLOAK_VERSION} as builder
COPY --from=mvn_builder /tmp/target/*.jar /opt/keycloak/providers/
COPY --from=mvn_builder /tmp/target/*.jar /opt/keycloak/deployments/

ENV KC_PROXY_ADDRESS_FORWARDING=true

USER 1000

RUN /opt/keycloak/bin/kc.sh build --health-enabled=true

FROM quay.io/keycloak/keycloak:${KEYCLOAK_VERSION}
COPY --from=builder /opt/keycloak/ /opt/keycloak/
WORKDIR /opt/keycloak

ENV KEYCLOAK_ADMIN=$KEYCLOAK_USER
ENV KEYCLOAK_ADMIN_PASSWORD=$KEYCLOAK_PASSWORD
ENV KEYCLOAK_PASSWORD=$KEYCLOAK_PASSWORD
ENV KEYCLOAK_USER=$KEYCLOAK_USER
ENV PROXY_ADDRESS_FORWARDING=true
ENV DB_URL=$DB_URL
ENV DB_USERNAME=$DB_USERNAME
ENV DB_PASSWORD=$DB_PASSWORD
		
CMD ["start-dev", "--hostname-strict=false", "--http-port=$PORT", "--proxy=edge", "--db=postgres", "--db-url=$DB_URL", "--db-username=$DB_USERNAME", "--db-password=$DB_PASSWORD", "--features=\"preview,scripts\""]