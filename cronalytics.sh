#!/usr/bin/env bash

##################
# Usage: cronalytics.sh <private-hash> [<command>]
# Version: 0.2
# https://github.com/cronalytics/bash
#
# This script is used to run a command and report the start, end and result to https://cronalytics.io where reoccuring
# tasks can be monitored by anyone.
#
##################

#readonly API_URL="http://api.cronalytics.io"
readonly API_URL="http://localhost:8080"
readonly DEBUG=true

log() {
    local ARGS=$*

    if $DEBUG; then
        echo -- "$ARGS"
        echo -- "$ARGS" >> /tmp/cronalytics.log
    fi
}

log "> Manager starting"

escape_json() {
    local JSON_TOPIC_RAW=$*;

    JSON_TOPIC_RAW=${JSON_TOPIC_RAW//\\/\\\\} # \
    JSON_TOPIC_RAW=${JSON_TOPIC_RAW//\//\\\/} # /
    JSON_TOPIC_RAW=${JSON_TOPIC_RAW//\'/\\\'} # ' (not strictly needed ?)
    JSON_TOPIC_RAW=${JSON_TOPIC_RAW//\"/\\\"} # "
    JSON_TOPIC_RAW=${JSON_TOPIC_RAW//   /\\t} # \t (tab)
    JSON_TOPIC_RAW=${JSON_TOPIC_RAW//
/\\\n} # \n (newline)
    JSON_TOPIC_RAW=${JSON_TOPIC_RAW//^M/\\\r} # \r (carriage return)
    JSON_TOPIC_RAW=${JSON_TOPIC_RAW//^L/\\\f} # \f (form feed)
    JSON_TOPIC_RAW=${JSON_TOPIC_RAW//^H/\\\b} # \b (backspace)

    echo "$JSON_TOPIC_RAW"
}

# Get the private cron has which is the first argument.
HASH=$1
shift

# Check that a hash was passed in
if [[ -z $HASH ]]; then
    log Hash not found in first argument, exiting
    >&2 echo "Usage: cronalytics.sh <private-hash> [<command>]"
    exit;
fi
log Hash found ["$HASH"]

#check if a command has been passed in, if not we just record the start time
START_ONLY=false;
if [[ -z "$@" ]]; then
    START_ONLY=true;
    log "args empty, only the start time will be logged [START_ONLY=true]"
fi

# Get the time the cron started
START=$(date +%Y-%m-%dT%H:%M:%S%z)


# Tell the API the cron is starting. and get the end point to say it is finished
START_PAYLOAD="{\"start\": \"$START\"}"
END_ENDPOINT=$(curl -s -S -X POST -d "$START_PAYLOAD" --header "Content-type:  application/json" --header "Accept: text/plain" "$API_URL/cron/$HASH?fields=links:end:url")
log "Start time recorded [$START], endpoint for completion [$END_ENDPOINT]"

if ! ${START_ONLY}; then

    log "Running user script";

    # Execute the cron and grab the result.
    SCRIPT_RESULT=$("$@" 2> /tmp/cron-error)
    SCRIPT_EXIT_CODE=$?
    SCRIPT_ERROR=$(</tmp/cron-error)

    #`rm /tmp/cron-error`

    SUCCESS=true
    if [[  ! -z "$SCRIPT_ERROR" || $SCRIPT_EXIT_CODE -gt 0 ]] ; then
        SUCCESS=false
        log "-- Error in User script [$SCRIPT_ERROR]"
        if [ ! -z "$SCRIPT_RESULT" ] ; then
            SCRIPT_RESULT="$SCRIPT_RESULT n ";
        fi
    fi
    log "Script result [$SCRIPT_RESULT]";
    SCRIPT_RESULT=$(escape_json "$SCRIPT_RESULT$SCRIPT_ERROR");
    log "encoded Script result [$SCRIPT_RESULT]";

    # Tell the API the script finished
    END=$(date +%Y-%m-%dT%H:%M:%S%z)

    log End time ["$END"]

    PAYLOAD="{\"end\": \"$END\", \"result\":\"$SCRIPT_RESULT\", \"success\": $SUCCESS}"

    log "Script result being sent to server [$PAYLOAD]"

    END_RESULT=$(curl -s -S -X PATCH -d "$PAYLOAD" --header "Content-type:  application/json" "$END_ENDPOINT")
    log End sent  ["$END_RESULT"]


    # Finally output result for user to log if they want
    echo "$SCRIPT_RESULT"
fi

log Manager end
exit;