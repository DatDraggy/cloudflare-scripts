#!/bin/bash

auth_email=""
auth_key="" # found in cloudflare account settings
zone_identifier=""
record25_name="_25._tcp.mail.example.com"
record465_name="_465._tcp.mail.example.com"

log_file="/var/log/update_ssl.log"
log() {
    if [ "$1" ]; then
        echo -e "[$(date)] - $1" >> $log_file
    fi
}
fingerprint=$(./tlsagen.sh)

record25_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?name=$record25_name&type=TLSA" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json"  | grep -Po '(?<="id":")[^"]*')
record465_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?name=$record465_name&type=TLSA" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json"  | grep -Po '(?<="id":")[^"]*')

update=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records/$record25_identifier" \
                 -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json" \
                 --data "{\"type\":\"TLSA\",\"name\":\"$record25_name\",\"data\":{\"usage\":3,\"selector\":1,\"matching_type\":1,\"certificate\":\"$fingerprint\"}}")
if [[ $update == *"\"success\":false"* ]]; then
    message="API UPDATE FAILED. DUMPING RESULTS:\n$update"
        log "$message"
        echo -e "$message"
        exit 1
else
    message="TLSA Updated"
    log "$message"
fi

update=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records/$record465_identifier" \
                 -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json" \
                 --data "{\"type\":\"TLSA\",\"name\":\"$record465_name\",\"data\":{\"usage\":3,\"selector\":1,\"matching_type\":1,\"certificate\":\"$fingerprint\"}}")
if [[ $update == *"\"success\":false"* ]]; then
    message="API UPDATE FAILED. DUMPING RESULTS:\n$update"
        log "$message"
        echo -e "$message"
        exit 1
else
    message="TLSA Updated"
    log "$message"
fi
