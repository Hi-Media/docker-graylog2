#!/usr/bin/env bash

# Treat unset variables and parameters other than the special parameters ‘@’ or ‘*’ as an error
# when performing parameter expansion. An error message will be written to the standard error,
# and a non-interactive shell will exit.
set -o nounset

# The return value of a pipeline is the value of the last (rightmost) command to exit with a non-zero status,
# or zero if all commands in the pipeline exit successfully:
set -o pipefail

DISPLAY_HELP=0
DATA_MONGODB=''
DATA_ES=''

function run () {
    # Some Bash colors:
    c_normal='\x1B[0;37m'
    c_container='\x1B[1;37m'
    tab='\x1B[0;30m┆\x1B[0m   '$c_normal
    c_id='\x1B[1;33m'
    c_ip='\x1B[1;36m'
    c_cmd='\x1B[0;36m'

    # ElasticSearch:
    [ ! -z "$DATA_ES" ] && data=" -v $DATA_ES:/data" || data=''
    ES_ID=$(docker run -d -p 9200:9200 -p 9300:9300${data} himedia/elasticsearch)
    ES_IP=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' ${ES_ID})
    echo -e "${c_normal}New container ${c_container}himedia/elasticsearch${c_normal} launched:\n" \
            "${tab}ID: ${c_id}${ES_ID:0:12}\n" \
            "${tab}IP: ${c_ip}$ES_IP${c_normal}\n" \
            "${tab}⇒ ElasticSearch: ${c_cmd}http://localhost:9200/_cluster/health?pretty=true\n"

    # Kibana:
    KI_ID=$(docker run -d -p 8080:80 -e "ES_HOST=localhost" -e "ES_PORT=9200" arcus/kibana)
    KI_IP=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' ${KI_ID})
    echo -e "${c_normal}New container ${c_container}arcus/kibana${c_normal} launched:\n" \
            "${tab}ID: ${c_id}${KI_ID:0:12}\n" \
            "${tab}IP: ${c_ip}$KI_IP${c_normal}\n" \
            "${tab}⇒ Kibana: ${c_cmd}http://localhost:8080/index.html#/dashboard/file/default.json\n"

    # MongoDB + Graylog2:
    [ ! -z "$DATA_MONGODB" ] && data=" -v $DATA_MONGODB:/var/lib/mongodb" || data=''
    GR_ID=$(docker run -d -p 9000:9000 -p 12201:12201 -p 12201:12201/udp -p 12900:12900 -p 27017:27017 -p 28017:28017 \
      -e "ES_CLUSTER_NAME=graylog" -e "ES_CLUSTER_HOSTS=$ES_IP:9300"${data} himedia/graylog2)
    GR_IP=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' ${GR_ID})
    echo -e "${c_normal}New container ${c_container}himedia/graylog2${c_normal} launched:\n" \
            "${tab}ID: ${c_id}${GR_ID:0:12}\n" \
            "${tab}IP: ${c_ip}$GR_IP${c_normal}\n" \
            "${tab}⇒ MongoDB: ${c_cmd}http://localhost:28017/\n" \
            "${tab}⇒ Graylog2 web (admin/admin): ${c_cmd}http://localhost:9000/\n"

    echo -e "${c_normal}Stop all these containers: ${c_cmd}docker stop ${c_id}${ES_ID:0:12} ${KI_ID:0:12} ${GR_ID:0:12}"
}

function displayHelp () {
    # Some Bash colors:
    local normal='\033[0;37m'
    local title='\033[1;37m'
    local tab='\033[0;30m┆\033[0m   '$normal
    local opt='\033[1;33m'
    local param='\033[1;36m'
    local cmd='\033[0;36m'

    echo -e "
${title}Description
${tab}Launch 3 Docker containers:
${tab}  1. himedia/elasticsearch
${tab}  2. arcus/kibana
${tab}  3. himedia/graylog2
${tab}and display URL to locally access to services.

${title}Usage
$tab${cmd}$(basename $0) $normal[${opt}OPTION$normal]…

${title}Options
$tab$opt--es-data$normal=$param<host-dir>
$tab${tab}Add data volume to ElasticSearch container.
$tab
$tab$opt--mongodb-data$normal=$param<host-dir>
$tab${tab}Add data volume to Graylog2 container for MongoDB persistence.
$tab
$tab$opt-h$normal, $opt--help
$tab${tab}Display this help.
"
}

# Command line parameters:
for i in "$@"; do
    case "$i" in
        --es-data=*)      DATA_ES=${i#*=} ;;
        --mongodb-data=*) DATA_MONGODB=${i#*=} ;;
        -h | --help)      DISPLAY_HELP=1 ;;
    esac
done

# Do action:
if [ "$DISPLAY_HELP" -eq 1 ]; then
    displayHelp
else
    run
fi
