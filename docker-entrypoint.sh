#!/bin/sh
set -e

# Railway's private network between replicas of the same service is only routable
# over IPv6 on the railnet0 interface (its IPv4 address on that interface is not
# reachable from sibling replicas). JGroups' TCP transport binds the IPv4 address
# by default on a dual-stack interface, so JOINs between replicas silently time
# out. Resolving and passing the literal IPv6 address scopes the fix to JGroups
# only (see cache-ispn.xml), instead of forcing java.net.preferIPv6Addresses=true
# JVM-wide, which would also break the outbound Postgres connection to Neon.
#
# /proc/net/if_inet6 lines look like:
#   fe80000000000000a0aa6bfffef6f591 03 40 20 80 railnet0
#   fd128aa4453b0001900000426bf6f591 03 40 00 80 railnet0
# scope 00 = global/ULA (fd12:...) -- prefer that one over link-local (fe80::,
# scope 20) since it's the address JGroups can advertise cluster-wide.
RAILNET0_IPV6=$(grep ' railnet0$' /proc/net/if_inet6 2>/dev/null | grep ' 00 80 ' | cut -d' ' -f1 | head -1)

if [ -n "$RAILNET0_IPV6" ]; then
  RAILNET0_IPV6=$(echo "$RAILNET0_IPV6" | sed -E 's/(.{4})/\1:/g; s/:$//')
  export RAILNET0_IPV6
fi

exec /opt/keycloak/bin/kc.sh "$@"
