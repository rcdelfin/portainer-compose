#!/bin/bash

set -e

#!/usr/bin/env bash

usage() {
    cat <<EOF

Version: 0.0.1

Sample usage:

  port-compose.sh -p demo -d demo.127.0.0.1.xip.io

Options:

  --help | -h) Display help

  --project | -p) Project name. ex: -p demo

  --domain | -d) Project domain name. ex: -d demo.127.0.0.1.xip.io

EOF
}

while [ ! $# -eq 0 ]
do
  case "$1" in
    --help | -h)
      usage
      exit
      ;;

    --project | -p)
      PROJECT_NAME=$2
      shift
      ;;

    --domain | -d)
      PROJECT_URL=$2
      shift
      ;;
  esac
  shift
done

for arg in PROJECT_NAME PROJECT_URL
do
  eval value=\$$arg
  if [[ -z $value ]]
  then
  usage
  exit;
  fi
done

# create site directory
PROJECT_DIR=/var/www/vhosts/${PROJECT_NAME}
if [[ ! -z "$CATALOG_PATH" ]]; then
  PROJECT_DIR=${CATALOG_PATH}/${PROJECT_NAME}
fi
mkdir -p ${PROJECT_DIR}

DB_PASSWORD=`choose() { echo ${1:RANDOM%${#1}:1} $RANDOM; }
{
    choose '!@#$%^\&'
    choose '0123456789'
    choose 'abcdefghijklmnopqrstuvwxyz'
    choose 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    for i in $( seq 1 $(( 4 + RANDOM % 8 )) )
    do
        choose '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
    done

} | sort -R | awk '{printf "%s",$1}'`

copy_tpl() {

  STACK_DIR=$(pwd)/stacks
  echo "Stack directory: ${STACK_DIR}"

  if [[ ! "$(ls -A $PROJECT_DIR)" ]]; then
    echo "Creating new project: ${PROJECT_NAME} to ${PROJECT_DIR}"

    cp ${STACK_DIR}/wordpress/*.* ${PROJECT_DIR}/
  else
    echo "Updating project: ${PROJECT_NAME} to ${PROJECT_DIR}"
  fi

  cp ${STACK_DIR}/wordpress/.env ${PROJECT_DIR}/

  sed -i -e "s/__PROJECT_NAME__/${PROJECT_NAME}/g" ${PROJECT_DIR}/.env
  sed -i -e "s/__PROJECT_BASE_URL__/${PROJECT_URL}/g" ${PROJECT_DIR}/.env
  sed -i -e "s/__DB_NAME__/wp_${PROJECT_NAME}/g" ${PROJECT_DIR}/.env
  sed -i -e "s/__DB_USER__/${PROJECT_NAME}/g" ${PROJECT_DIR}/.env
  sed -i -e "s/__DB_PASSWORD__/${DB_PASSWORD}/g" ${PROJECT_DIR}/.env

  rm ${PROJECT_DIR}/.env-e

  echo "Starting docker app.."
  cd ${PROJECT_DIR} && docker-compose up -d

  echo "Done"
}

copy_tpl

# exit process
exit;
