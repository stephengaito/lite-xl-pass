#!/usr/bin/env bash
# pass key - Password Store Extension (https://www.passwordstore.org/)
#

cmd_key_usage() {
	cat <<-ENDOFUSAGE
Usage:

  $PROGRAM key url <PassEntryPath>
    copies the URL key:value (if found) to the clipboard

  $PROGRAM key userName <PassEntryPath>
    copies the UserName key:value (if found) to the clipboard

ENDOFUSAGE
  exit 0
}

cmd_key_userName() {
  pass show ${@%.*} | grep -i username | cut -d':' -f2 | xargs | xsel -i -b
  echo copied userName for $@
}

cmd_key_url() {
  pass show ${@%.*} | grep -i url | cut -d':' -f2,3 | xargs | xsel -i -b
	echo copied url for $@
}

cmd_key_unknown() {
  echo ""
	echo [$1] is not a known Key:Value
	echo ""
	cmd_key_usage $@
}

case "$1" in
  help|--help|-h) shift; cmd_key_usage $@    ;;
  UR*| Ur*|ur*|-ur*|--ur*) shift; cmd_key_url $@      ;;
  U*|u*|-u*|--u*)    shift; cmd_key_userName $@ ;;
  *)                     cmd_key_unknown $@   ;;
esac
exit 0