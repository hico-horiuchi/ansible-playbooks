#!/bin/bash

SCHEME=`hostname`

usage()
{
  cat <<EOF
usage: $0 options

This plugin produces CPU usage (%)

OPTIONS:
   -h      Show this message
   -s      Metric naming scheme, text to prepend to cpu.usage (default: $SCHEME)
EOF
}

while getopts "hs:" OPTION
  do
    case $OPTION in
      h)
        usage
        exit 1
        ;;
      s)
        SCHEME="$OPTARG"
        ;;
      ?)
        usage
        exit 1
        ;;
    esac
done

get_idle_total()
{
  CPU=(`sed -n 's/^cpu \+//p' /proc/stat`)
  IDLE=${CPU[3]}
  TOTAL=0
  for VALUE in ${CPU[@]}; do
    let "TOTAL=$TOTAL+$VALUE"
  done
}

get_idle_total

PREV_TOTAL=$TOTAL
PREV_IDLE=$IDLE

sleep 1

get_idle_total

let "DIFF_IDLE=$IDLE-$PREV_IDLE"
let "DIFF_TOTAL=$TOTAL-$PREV_TOTAL"
let "CPU_USAGE=(($DIFF_TOTAL-$DIFF_IDLE)*1000/$DIFF_TOTAL+5)/10"

echo "$SCHEME.cpu.usage $CPU_USAGE `date +%s`"
