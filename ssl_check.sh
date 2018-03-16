#!/bin/bash

domain=""
send_mail="no"
to_address=""

function send_email()
{
    echo "$1" | mail -s "ssl_check report" "$to_address"
}

function check_ssl()
{
    echo " IP             |  Status" > /tmp/ssl_check
    now_epoch=$( date +%s )

    dig +noall +answer $domain | while read _ _ _ _ ip;
    do
        expiry_date=$( echo | openssl s_client -showcerts -servername $domain -connect $ip:443 2>/dev/null | openssl x509 -inform pem -noout -enddate | cut -d "=" -f 2 )
        expiry_epoch=$( date -d "$expiry_date" +%s )
        expiry_days="$(( ($expiry_epoch - $now_epoch) / (3600 * 24) ))"

        echo "$ip: $expiry_days days" >> /tmp/ssl_check
    done

    if [[ "$send_mail" = "yes" ]]; then
        send_email $result
    else
        cat /tmp/ssl_check
    fi
}

function show_help()
{
    echo "Usage: $0 [option...]"
    echo
    echo "    -d, --domain       Set the domian name to check"
    echo "    -h, ---help        Show this help message"
    echo "    -s, --send-mail    Send results to this email address"
    echo
    exit 1
}

while :
do
    case "$1" in
      -d | --domain)
          if [ $# -ne 0 ]; then
            domain="$2"
          fi
          shift 2
          ;;

      -h | --help)
          show_help
          exit 0
          ;;

      -s | --send-mail)
          send_mail=yes
          to_address="$2"
          shift 2
          ;;

      --) # End of all options
          shift
          break
          ;;

      -*)
          echo "\e[91mError\e[0m: Unknown option: $1" >&2
          show_help
          exit 1 
          ;;

      *)  # No more options
          break
          ;;
    esac
done

if [[ -z $domain ]]; then
    show_help
    exit 1
fi

check_ssl
