#!/bin/bash

[[ -z $DEBUG ]] || set -o xtrace

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

APP_DIR="/srv/deploy/${GROUP_ID/.//}/${ARTIFACT_ID}"
JAR_FILE="${APP_DIR}/${ARTIFACT_ID}.jar"

wget ${ARTIFACT_URL} -O ${JAR_FILE}

# run microservice
if [[ -f "${APP_DIR}/${ARTIFACT_ID}.pid" ]]; then
	PID="$( cat ${APP_DIR}/${ARTIFACT_ID}.pid )"
	# kill it
	kill -9 ${PID} 2>&1 >/dev/null
	if [[ ! "$?" ]]; then
		echo "No process killed"
	fi
fi

cd ${APP_DIR}

exec nohup java ${JAVA_OPTS} -jar ${JAR_FILE} </dev/null &>/dev/null &
echo $! > "${ARTIFACT_ID}.pid"

