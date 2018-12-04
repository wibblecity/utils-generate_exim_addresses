#!/bin/bash

DOMAIN_NAME="$1"

TARGET_FILE="/etc/email-addresses"

THIS_ARGS="$@"

### functions
function log_event {
  EVENT_DATA="$1"
  THIS_PID="$$"
  if [ -z "${THIS_PID}" ] ; then
    usage "THIS_PID: variable is empty"
  fi
  LOG_TIMESTAMP=`date "+%F %H:%M:%S %z"`
  echo "${LOG_TIMESTAMP} - ${THIS_PID} - ${SCRIPT_NAME} - ${EVENT_DATA}"
}

function usage {
  ERROR_LOG_EVENT="$1"
  USAGE_INFO="$2"
  THIS_PID="$$"
  EXIT_STATUS="1"
  log_error_line
  log_error "##### ***** ERROR ***** ######"
  log_error
  log_error "CMD: ${SCRIPT_NAME} ${THIS_ARGS}"
  log_error "Message: ${ERROR_LOG_EVENT}"
  if [ ! -z "${USAGE_INFO}" ] ; then
    log_error
    log_error "Usage: ${SCRIPT_NAME} ${USAGE_INFO}"
    log_error
  fi
  log_error "##### ***** ERROR ***** ######"
  log_error "##### Sleeping for 5 seconds then exiting with status: ${EXIT_STATUS}"
  log_error_line
  sleep 5
  exit "${EXIT_STATUS}"
}

function log_error {
  EVENT_DATA="$1"
  THIS_PID="$$"
  LOG_TIMESTAMP=`date "+%F %H:%M:%S %z"`
  echo "${LOG_TIMESTAMP} - ${THIS_PID} - ${SCRIPT_NAME} - ERROR: ${EVENT_DATA}" >&2
}

function log_error_line {
  EVENT_DATA="$1"
  echo "${EVENT_DATA}" >&2
}
#####

SCRIPT_PATH="$(realpath "$0")"
if [ "$?" -ne "0" ] ; then
  usage "SCRIPT_PATH: realpath $0 command exited with errors"
fi

SCRIPT_NAME="$(basename "${SCRIPT_PATH}")"
if [ "$?" -ne "0" ] ; then
  usage "SCRIPT_NAME: basename ${SCRIPT_PATH} command exited with errors"
fi

SCRIPT_DIR="$(dirname "${SCRIPT_PATH}")"
if [ "$?" -ne "0" ] ; then
  usage "SCRIPT_DIR: dirname ${SCRIPT_PATH} command exited with errors"
fi
if [ ! -d "${SCRIPT_DIR}" ] ; then
  usage "SCRIPT_DIR: ${SCRIPT_DIR} does not exist or is not a directory"
fi

if [ -z "${DOMAIN_NAME}" ] ; then
  usage "DOMAIN_NAME: variable is empty"
fi

log_event
log_event "Task Started"
log_event "Generating FROM addresses for local users using domain: ${DOMAIN_NAME}"

USER_LIST="$(compgen -u)"
OUTPUT_CONTENT=""

for USER_NAME in $(echo ${USER_LIST}) ; do
  OUTPUT_CONTENT+="${USER_NAME}: ${USER_NAME}@${DOMAIN_NAME}
"
done

CURRENT_CONTENT=""
if [ -f "${TARGET_FILE}" ] ; then
  CURRENT_CONTENT="$(cat "${TARGET_FILE}")"
fi

echo "${CURRENT_CONTENT}"
echo "vs"
echo "${OUTPUT_CONTENT}"

if [ "${CURRENT_CONTENT}" != "${OUTPUT_CONTENT}" ] ; then
  TIME_STAMP="$(date "+%Y%m%d_%H%M%S")"
  BACKUP_FILE_PATH="${TARGET_FILE}.backup.${TIME_STAMP}"
  log_event "Backup up file: ${TARGET_FILE} to ${BACKUP_FILE_PATH}"
  cp "${TARGET_FILE}" "${BACKUP_FILE_PATH}"
  log_event "Writing generated content to file: ${TARGET_FILE}"
  echo "${OUTPUT_CONTENT}" > ${TARGET_FILE}
fi

log_event "Updating Git workspace"
cd "${SCRIPT_DIR}"
git pull -f --all >/dev/null
if [ "$?" -ne "0" ] ; then
  usage "git pull -f --all command exited with errors"
fi

log_event "Task Complete"
log_event
