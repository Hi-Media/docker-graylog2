#!/bin/bash

ES_CLUSTER_NAME=${ES_CLUSTER_NAME:-graylog2}
ES_CLUSTER_HOSTS=${ES_CLUSTER_HOSTS:-127.0.0.1:9300}
echo "ES_CLUSTER_NAME=$ES_CLUSTER_NAME"
echo "ES_CLUSTER_HOSTS=$ES_CLUSTER_HOSTS"

echo -n 'Waiting for mongodb… '
while [[ $(mongo --eval "db.stats().ok" --quiet 2>/dev/null) != 1 ]]; do echo -n '.'; sleep 1; done
echo

graylog2_conf='/etc/graylog2/server/server.conf'
sed -i -e "s/#elasticsearch_cluster_name = graylog2/elasticsearch_cluster_name = ${ES_CLUSTER_NAME}/" "$graylog2_conf"
sed -i -e "s/elasticsearch_discovery_zen_ping_unicast_hosts = 127.0.0.1:9300/elasticsearch_discovery_zen_ping_unicast_hosts = ${ES_CLUSTER_HOSTS}/" "$graylog2_conf"

/etc/init.d/graylog2-server start

