#!/bin/bash

[[ -z $DEBUG ]] || set -o xtrace

set -o errexit

log() {
    echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $@"
}

err() {
    log "$@" >&2
}

usage() {
    echo "usage: $( basename $0 ) groupId artifactId version"
    exit 1
}

JAVA_OPTS="-Dspring.profiles.active=prod"
NEXUS_URL="${RD_OPTION_NEXUSURL:-$NEXUS_URL}"
GROUP_ID="${RD_OPTION_GROUPID:-$1}"
ARTIFACT_ID="${RD_OPTION_ARTIFACTID:-$2}"
VERSION="${RD_OPTION_VERSION:-$3}"

if [[ -z "${GROUP_ID}" ]]; then
    err "Missing groupID"
    usage
fi

if [[ -z "${ARTIFACT_ID}" ]]; then
    err "Missing artifactId"
    usage
fi

if [[ -z "${VERSION}" ]]; then
    err "Missing version"
    usage
fi

ARTIFACT_URL="${NEXUS_URL}/${GROUP_ID/.//}/${ARTIFACT_ID}/${VERSION}/${ARTIFACT_ID}-${VERSION}.jar"

mkdir -p /srv/deploy/${GROUP_ID/.//}/${ARTIFACT_ID}

wget ${ARTIFACT_URL} -O /srv/deploy/${GROUP_ID/.//}/${ARTIFACT_ID}/${ARTIFACT_ID}.jar 

# run microservice

if [[ -f "/srv/deploy/${GROUP_ID/.//}/${ARTIFACT_ID}/${ARTIFACT_ID}.pid" ]]; then
	# kill it
	kill -9 $( cat "/srv/deploy/${GROUP_ID/.//}/${ARTIFACT_ID}/${ARTIFACT_ID}.pid" )
fi

nohup java ${JAVA_OPTS} -jar /srv/deploy/${GROUP_ID/.//}/${ARTIFACT_ID}/${ARTIFACT_ID}.jar 2>&1 >/dev/null &
echo $! > "/srv/deploy/${GROUP_ID/.//}/${ARTIFACT_ID}/${ARTIFACT_ID}.pid"

