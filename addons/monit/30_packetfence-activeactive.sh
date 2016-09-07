#!/bin/bash

ALERT_EMAIL=$1

if [ -z "$ALERT_EMAIL" ]; then
    echo 'Missing parameter(s)\n'
    echo 'Syntax should be: ./30_packetfence-activeactive.sh "alerting@email.address"'
    exit 1;
fi

# OS specific binaries declarations
if [ -e "/etc/debian_version" ]; then
    FREERADIUS_BIN=freeradius
else
    FREERADIUS_BIN=radiusd
fi


cat >> /etc/monit.d/packetfence.monit << EOF



# PacketFence active-active clustering checks

check program master with path /usr/local/pf/addons/monit/testactiveip.sh
       noalert $ALERT_EMAIL
       if status != 0 then exec "/usr/bin/monit unmonitor packetfence-pfmon"
       if status = 0 then exec "/usr/bin/monit monitor packetfence-pfmon"

check process packetfence-haproxy with pidfile /usr/local/pf/var/run/haproxy.pid
    group PacketFence
    start program = "/usr/local/pf/bin/pfcmd service haproxy start" with timeout 60 seconds
    stop program  = "/usr/local/pf/bin/pfcmd service haproxy stop"
    if failed host 127.0.0.1 port 3306 protocol mysql then alert

check process packetfence-keepalived with pidfile /usr/local/pf/var/run/keepalived.pid
    group PacketFence
    start program = "/usr/local/pf/bin/pfcmd service keepalived start" with timeout 60 seconds
    stop program  = "/usr/local/pf/bin/pfcmd service keepalived stop"

check process packetfence-radiusd-load_balancer with pidfile /usr/local/pf/var/run/radiusd-load_balancer.pid
    group PacketFence
    start program = "/usr/sbin/$FREERADIUS_BIN -d /usr/local/pf/raddb -n load_balancer" with timeout 60 seconds
    stop program  = "/bin/kill /usr/local/pf/var/run/radiusd-load_balancer.pid"

EOF
