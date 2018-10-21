#!/bin/bash

# set -e

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

PASSWORD=`choose() { echo ${1:RANDOM%${#1}:1} $RANDOM; }
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
  if [[ ! -z "$STACK_TEMPLATE_PATH" ]]; then
    STACK_DIR=$STACK_TEMPLATE_PATH
  fi
  echo "Stack directory: ${STACK_DIR}"

  if [[ ! "$(ls -A $PROJECT_DIR)" ]]; then
    echo "Creating new project: ${PROJECT_NAME} to ${PROJECT_DIR}"
    echo $PASSWORD > ${PROJECT_DIR}/passwrd
  else
    echo "Updating project: ${PROJECT_NAME} to ${PROJECT_DIR}"
  fi

  cp ${STACK_DIR}/wordpress/*.* ${PROJECT_DIR}/
  cp ${STACK_DIR}/wordpress/.env ${PROJECT_DIR}/

  sed -i -e "s/__PROJECT_NAME__/${PROJECT_NAME}/g" ${PROJECT_DIR}/.env
  sed -i -e "s/__PROJECT_BASE_URL__/${PROJECT_URL}/g" ${PROJECT_DIR}/.env
  PROJECT_ADMINER_URL=`echo $PROJECT_URL | cut -d "," -f 1`
  sed -i -e "s/__PROJECT_ADMINER_URL__/${PROJECT_ADMINER_URL}/g" ${PROJECT_DIR}/.env

  sed -i -e "s/__DB_HOST__/${PROJECT_NAME}_mysql/g" ${PROJECT_DIR}/.env
  sed -i -e "s/__DB_NAME__/wp_${PROJECT_NAME}/g" ${PROJECT_DIR}/.env
  sed -i -e "s/__DB_USER__/${PROJECT_NAME}/g" ${PROJECT_DIR}/.env

  DB_PASSWORD=`cat ${PROJECT_DIR}/passwrd`
  sed -i -e "s/__DB_PASSWORD__/${DB_PASSWORD}/g" ${PROJECT_DIR}/.env

  sed -i -e "s/__PROJECT_NAME__/${PROJECT_NAME}/g" ${PROJECT_DIR}/docker-compose.yaml

  if [[ ! -z "$AUTO_START_CONTAINER" ]]; then
    echo "Starting docker app.."
    cd ${PROJECT_DIR} && docker-compose up -d
  fi

  echo "Done"
}

copy_tpl

# exit process
exit;
