package org.keycloak.support.jgroups;

import jakarta.enterprise.inject.spi.CDI;
import org.jgroups.protocols.JDBC_PING;

import javax.sql.DataSource;
import java.util.function.Function;

public class DataSourceProvider implements Function<JDBC_PING, DataSource> {
    @Override
    public DataSource apply(JDBC_PING jdbcPing) {
        return CDI.current().select(DataSource.class).get();
    }
}
