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
TOKEN=$(curl -v -s  -H 'Host: panel.intratime.es' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.13; rv:66.0) Gecko/20100101 Firefox/66.0' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' -H 'Accept-Language: en-GB,en-US;q=0.7,en;q=0.3' -H 'Referer: https://panel.intratime.es/login/fichaje_web/'-H 'Upgrade-Insecure-Requests: 1' --data "user_EMAIL=$EMAIL&user_PIN=$PIN" --compressed 'https://panel.intratime.es/login/fichaje_web' 2>&1 | grep 'Set-Cookie' | tail -1 | sed -e 's/.*ci_session=\(.*\)\; expires.*/\1/')

# Get status
CURRENT_STATUS=$(curl -s -H 'Host: panel.intratime.es' -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.13; rv:66.0) Gecko/20100101 Firefox/66.0' -H 'Accept: application/json, text/javascript, */*; q=0.01' -H 'Accept-Language: en-GB,en-US;q=0.7,en;q=0.3' -H 'Referer: https://panel.intratime.es/login/fichaje_web' -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' -H 'X-Requested-With: XMLHttpRequest' -H 'Cookie:  ci_session='$TOKEN';' --data-binary "iDisplayLength=1&iSortCol_0=3&sSortDir_0=desc" --compressed 'https://panel.intratime.es/login/list_datatables/' | jq .aaData[0])

ACTION=$(echo $CURRENT_STATUS | tr -d '" ' | awk -F "," '{print $2}')
WHEN=$(echo $CURRENT_STATUS | tr -d '"' | awk -F "," '{print $4}')
WHEN_IN_SECONDS=$(TZ="$DATA_TIME_ZONE" date -j -f " %Y-%m-%d %H:%M:%S" "$WHEN" "+%s")
NOW=$(TZ="$CURRENT_TIME_ZONE" date +%s)
SECONDS_SINCE_LAST_ACTION=$(($NOW-$WHEN_IN_SECONDS))

printf '%02d days, %02dh %02dm %02ds since you set status %s.\n' \
    $(($SECONDS_SINCE_LAST_ACTION/86400)) \
    $(($SECONDS_SINCE_LAST_ACTION%86400/3600)) \
    $(($SECONDS_SINCE_LAST_ACTION%3600/60)) \
    $(($SECONDS_SINCE_LAST_ACTION%60)) \
    $ACTION
