#!/bin/bash

if [ $# -ne 2 ]; then
  >&2 echo -e "Usage: $0 email pin\n\nExample: $0 john.doe@gmail.com 1234"
  exit 1
fi

EMAIL=$1
PIN=$2
DATA_TIME_ZONE="Europe/Madrid"
CURRENT_TIME_ZONE="Europe/London"

# Sign in to get token
TOKEN=$(curl -XPOST -s --data "user=$EMAIL&pin=$PIN" 'https://newapi.intratime.es/api/user/login' 2>&1 | jq -r .USER_TOKEN)

# Get time of last check
WHEN=$(curl -s -H 'token: '$TOKEN 'https://newapi.intratime.es/api/user/clockings?last=true&type=0,1,2,3' | jq -r .[].INOUT_DATE)

WHEN_IN_SECONDS=$(TZ="$DATA_TIME_ZONE" date -j -f " %Y-%m-%d %H:%M:%S" "$WHEN" "+%s")

NOW=$(TZ="$CURRENT_TIME_ZONE" date +%s)
SECONDS_SINCE_LAST_ACTION=$(($NOW-$WHEN_IN_SECONDS))

printf '%02d days, %02dh %02dm %02ds since your last status change.\n' \
    $(($SECONDS_SINCE_LAST_ACTION/86400)) \
    $(($SECONDS_SINCE_LAST_ACTION%86400/3600)) \
    $(($SECONDS_SINCE_LAST_ACTION%3600/60)) \
    $(($SECONDS_SINCE_LAST_ACTION%60))
