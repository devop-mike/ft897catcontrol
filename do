#!/bin/sh
serialport="/dev/serial0"
tmploc="/var/tmp/"
readdelay=2.75
commanddelay=0.25

readresponse() {
  # test -f ${0%/*}/debug && echo xxd -p -l ${1} ${serialport} \>${tmploc}${2}
  # cat ${serialport} | xxd -p -l ${1} >${tmploc}${2} &
  xxd -p -l ${1} ${serialport} >${tmploc}${2} &
  xxdpid=$!
  # test -f ${0%/*}/debug && ps fx
  # test -f ${0%/*}/debug && echo ${xxdpid}
  sleep ${readdelay}
  # test -f ${0%/*}/debug && ps -ho pid,lstart,cmd ${xxdpid}
  kill ${xxdpid}
}

docat() {
  while [ -n "$1" ]; do
    case "$1" in
    l | ls | list)
      for file in ${0%/*}/commands/*; do
        echo "$(xxd -p $file) ${file##*/}"
      done
      exit
      ;;
    fix)
      stty -F ${serialport} 38400 1:0:800008bf:0:0:0:0:0:0:5:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0
      ;;
    get-freq)
      command="${0%/*}/commands/get-freq"
      echo Sending $(xxd -p ${command})
      cat ${command} >${serialport}
      readresponse 5 catcon-get-freq
      if [ -f ${tmploc}catcon-get-freq ]; then
        echo -n "$(cut -c1-3,4-8 --output-delimiter=. ${tmploc}catcon-get-freq) "
        mode=$(cut -c9-10 ${tmploc}catcon-get-freq)
        case "$mode" in
        00)
          echo LSB
          ;;
        01)
          echo USB
          ;;
        02)
          echo CW
          ;;
        03)
          echo CWR
          ;;
        04)
          echo AM
          ;;
        06)
          echo WFM
          ;;
        08)
          echo FM
          ;;
        88)
          echo FMN
          ;;
        0a)
          echo DIG
          ;;
        0c)
          echo PKT
          ;;
        *)
          echo $mode
          ;;
        esac
      fi
      ;;
    read-rx-status)
      command="${0%/*}/commands/read-rx-status"
      echo Sending $(xxd -p ${command})
      cat ${command} >${serialport}
      readresponse 1 catcon-read-rx-status
      if [ -f ${tmploc}catcon-read-rx-status ]; then
        echo "$(cat ${tmploc}catcon-read-rx-status)"
      fi
      ;;
    read-tx-status)
      command="${0%/*}/commands/read-tx-status"
      echo Sending $(xxd -p ${command})
      cat ${command} >${serialport}
      readresponse 1 catcon-read-tx-status
      if [ -f ${tmploc}catcon-read-tx-status ]; then
        echo "$(cat ${tmploc}catcon-read-tx-status)"
      fi
      ;;
    set-freq)
      if [ -n "$2" -a $2 -gt 0 ]; then
        command="$2"
        if [ ${#command} -eq 6 ]; then
          command="${command}00"
        fi
        if [ ${#command} -eq 8 ]; then
          command="${command}01"
          echo Sendig $(echo ${command} | xxd -r -p | xxd -p)
          echo ${command} | xxd -r -p >${serialport}
        fi
        shift
      fi
      ;;
    *)
      command="${0%/*}/commands/$1"
      if [ -f ${command} ]; then
        echo Sending $(xxd -p ${command})
        cat ${command} >${serialport}
      else
        script="${0%/*}/scripts/$1"
        if [ -f ${script} ]; then
          docat $(cat ${script})
        fi
      fi
      ;;
    esac
    shift
    if [ -n "$1" ]; then
      sleep ${commanddelay}
    fi
  done
}

docat $*
