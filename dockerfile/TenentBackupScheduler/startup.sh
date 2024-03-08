#!/bin/sh

APP_NAME="$(basename "$(dirname "$PWD/file")")"
JAVA_CMD=java
# JAVA_OPTS="-Dspring.profiles.active=prod"

${JAVA_CMD} ${JAVA_OPTS} \
		-jar ${APP_NAME}.jar
