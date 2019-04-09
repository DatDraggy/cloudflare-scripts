#!/bin/bash
auth_email=""
auth_key="" # found in cloudflare account settings
zone_identifier=""

cd /etc/opendkim/keyfiles/mail.summerbo.at
opendkim-genkey -s mail -d mail.summerbo.at
new_dkim=$(cat mail.txt  | cut -d"(" -f2 | cut -d")" -f1 | sed ':a;N;$!ba;s/\n/ /g' |sed 's/\t/     /g' | sed  -e 's/"//g')
dkimrecord_name="mail._domainkey.summerbo.at"
dkimrecordmail_name="mail._domainkey.mail.example.com"

dkimrecord_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?name=$dkimrecord_name&type=TXT" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json"  | grep -Po '(?<="id":")[^"]*')
dkimrecordmail_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?name=$dkimrecordmail_name&type=TXT" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json"  | grep -Po '(?<="id":")[^"]*')

dkimupdate=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records/$dkimrecord_identifier" \
                 -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json" \
                 --data "{\"type\":\"TXT\",\"name\":\"$dkimrecord_name\",\"content\":\"$new_dkim\"}")
if [[ $dkimupdate == *"\"success\":false"* ]]; then
    message="API UPDATE FAILED. DUMPING RESULTS:\n$dkimupdate"
        log "$message"
        echo -e "$message"
        exit 1
else
    message="DKIM Updated"
    log "$message"
fi

dkimupdate=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records/$dkimrecordmail_identifier" \
                 -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json" \
                 --data "{\"type\":\"TXT\",\"name\":\"$dkimrecordmail_name\",\"content\":\"$new_dkim\"}")
if [[ $dkimupdate == *"\"success\":false"* ]]; then
    message="API UPDATE FAILED. DUMPING RESULTS:\n$dkimupdate"
        log "$message"
        echo -e "$message"
        exit 1
else
    message="DKIM Updated"
    log "$message"
fi
