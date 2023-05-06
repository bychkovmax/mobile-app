#!/bin/bash

RED='\033[0;31m'
NC='\033[0m' # No Color


DPG_PATH=$( readlink -f "${0}" )
CURRENT_DIR=$( dirname "${0}" )
BACKUPS_DIR="$CURRENT_DIR/db/backups"
DOCKER_NAME=glissues_db

DB_HOST=android
DB_PORT=6666
DB_NAME=android
DB_USER=android
DB_SCHEMAS=public
DB_PASSWORD=android

DEFAULT_TABLE=""

help() {
  me=`basename "$0"`

  printf "Утилита для упрощения работы с контейнером БД ${DOCKER_NAME}

  Использование: ${me} КОМАНДА\n
  Команды:
   -c, --connect                   делает подключение к БД через psql
   -d, --dump                      делает бэкап БД в папку ${BACKUPS_DIR} проекта
   -t, --dump-table [<table>]      делает бэкап указанной таблицы (по умолчанию '${DEFAULT_TABLE}') БД в папку ${BACKUPS_DIR} проекта
   -r, --restore <file>            восстановление БД из файла
   -f, --file <file>               выполняет произвольный SQL скрипт из файла в БД контейнера
   -c, --clean-older-dumps [<n>]   удаляет старые бэкап файлы из папки ${BACKUPS_DIR}, которые старше указанного числа дней (по умолчанию n = 14)
   -S, --save                      сохраняет состояние контейнера ${DOCKER_NAME} в tar, в папку ${BACKUPS_DIR}
   -L, --load <file>               загружает ранее созданный контейнер из tar архива

       --add-to-cron [<period>]    добавляет в crontab 3 задачи: clean-older-dumps, dump и dump-table dw.form

   -i, --info                      печатает предустановленные переменные, которые используются в скрипте
   -s, --setup                     wizard для генерации файлов .env и flyway.conf
   -h, --help                      печатает это сообщение

   \n"
}


info() {
  printf "
  DB_HOST=${DB_HOST}
  DB_PORT=${DB_PORT}
  DB_NAME=${DB_NAME}
  DB_USER=${DB_USER}
  DB_SCHEMAS=${DB_SCHEMAS}
  DB_PASSWORD=${DB_PASSWORD}

  BACKUPS_DIR=${BACKUPS_DIR}         (has `ls ${BACKUPS_DIR}  | wc -l` files)
  DEFAULT_TABLE=${DEFAULT_TABLE}

  DOCKER_NAME=${DOCKER_NAME}
  Container status:
  ------------------------------
  "
  docker ps -a --filter name=${DOCKER_NAME}
  echo
}

setup() {
  date=`date`
  evn_file=".env"
  replace_evn_file='n'
  flyway_file="flyway.conf"
  replace_flyway_file='n'
  files=2


  if [ -f ${evn_file} ]; then
    def_ans='N'
    read -r -p "Файл ${evn_file} уже существует, переписать его? N/y:" replace_evn_file ; [ -z "${replace_evn_file}" ] && replace_evn_file=${def_ans}
    if [ ! "${replace_evn_file}" = "Y" ] && [ ! "${replace_evn_file}" = "y" ]; then
       files=$((files-1))
    fi
  else
    replace_evn_file='y'
    touch "${evn_file}"
  fi

  if [ -f ${flyway_file} ]; then
    def_ans='N'
    read -r -p "Файл ${flyway_file} уже существует, переписать его? N/y:" replace_flyway_file ; [ -z "${replace_flyway_file}" ] && replace_flyway_file=${def_ans}
    if [ ! "${replace_flyway_file}" = "Y" ] && [ ! "${replace_flyway_file}" = "y" ]; then
       files=$((files-1))
    fi
  else
    replace_flyway_file='y'
    touch "${flyway_file}"
  fi

#  echo "files = ${files}"
  if [ $files -lt 1 ]; then
    exit
  fi

  read -r -p "  > DB Host [${DB_HOST}]: " ans ; [ -z "${ans}" ] && ans=${DB_HOST} || DB_HOST=${ans}
  read -r -p "  > DB Port [${DB_PORT}]: " ans ; [ -z "${ans}" ] && ans=${DB_PORT} || DB_PORT=${ans}
  read -r -p "  > DB Name [${DB_NAME}]: " ans ; [ -z "${ans}" ] && ans=${DB_NAME} || DB_NAME=${ans}
  read -r -p "  > DB Schemas [${DB_SCHEMAS}]: " ans ; [ -z "${ans}" ] && ans=${DB_SCHEMAS} || DB_SCHEMAS=${ans}
  read -r -p "  > DB User [${DB_USER}]: " ans ; [ -z "${ans}" ] && ans=${DB_USER} || DB_USER=${ans}
  read -r -p "  > DB Password [${DB_PASSWORD}]: " ans ; [ -z "${ans}" ] && ans=${DB_PASSWORD} || DB_PASSWORD=${ans}
  echo ""

  if [ "${replace_evn_file}" = "Y" ] || [ "${replace_evn_file}" = "y" ]; then
      {
        echo "#Rewrited configuration ${date}
POSTGRES_USER=${DB_USER}
POSTGRES_DB=${DB_NAME}
POSTGRES_PASSWORD=${DB_PASSWORD}
  "
      } > "${evn_file}"
      echo "Файл ${evn_file} успешно создан."
    fi


    if [ "${replace_flyway_file}" = "Y" ] || [ "${replace_flyway_file}" = "y" ]; then
      {
        echo "flyway.url=jdbc:postgresql://${DB_HOST}:${DB_PORT}/${DB_NAME}
flyway.user=${DB_USER}
flyway.password=${DB_PASSWORD}
flyway.schemas=${DB_SCHEMAS}
flyway.locations=filesystem:./db/migration
"
      } > "${flyway_file}"
      echo "Файл ${flyway_file} успешно создан."
    fi
}

add_to_crontab() {
  [ ! -z "$1" ] && PERIOD=$1 || PERIOD="01 01 * * *"
  BACKUPS_FULL_PATH=$(readlink -f "${BACKUPS_DIR}")
  echo "${PERIOD} ${DPG_PATH} --clean-older-dumps >> ${BACKUPS_FULL_PATH}/crontab.log 2>&1"
  exit
  (crontab -l ; echo "${PERIOD} ${DPG_PATH} --clean-older-dumps >> ${BACKUPS_FULL_PATH}/crontab.log 2>&1") | crontab -
  (crontab -l ; echo "${PERIOD} ${DPG_PATH} --dump >> ${BACKUPS_FULL_PATH}/crontab.log 2>&1") | crontab -
  (crontab -l ; echo "${PERIOD} ${DPG_PATH} --dump-table dw.form >> ${BACKUPS_FULL_PATH}/crontab.log 2>&1") | crontab -
}

connect() {
  docker exec -it ${DOCKER_NAME} psql -U ${DB_USER} -d ${DB_NAME}
}

clean_older_dumps() {
  days=$1
  [ -z "$days" ] && days=14
  find backups -type f -mtime +${days} -name '*.gz' -execdir rm -- '{}' \;
}

dump() {
  [ -d "$BACKUPS_DIR" ] || mkdir "$BACKUPS_DIR"
  FILE="$BACKUPS_DIR/dump.$(date +"%Y-%m-%d_%H_%M_%S").gz"
  echo "Started dumping the database, please wait ..."
  docker exec -t ${DOCKER_NAME} pg_dumpall -c -U ${DB_USER} | gzip > "${FILE}"
  FILE=$( readlink -f "${FILE}")
  echo "DB dump was saved to file: ${FILE}"
}

dump_table() {
  [ ! -z "$1" ] && TABLE=$1 || TABLE=${DEFAULT_TABLE}
  [ -d "$BACKUPS_DIR" ] || mkdir "$BACKUPS_DIR"
  FILE="$BACKUPS_DIR/$TABLE.$(date +"%Y-%m-%d_%H_%M_%S").sql"
  docker exec -t "${DOCKER_NAME}" pg_dump --table="${TABLE}" --data-only --column-inserts -U "${DB_USER}" -d "${DB_NAME}" > "${FILE}"
  echo "Dump of table ${TABLE} was saved to file: $FILE"
}

restore() {
  if [ ! -z "$1" ]; then
    FILE=$1
    if [ ! -f "$FILE" ]; then
      if [ -f "$BACKUPS_DIR/$FILE" ]; then
        FILE="$BACKUPS_DIR/$FILE"
      else
        echo "No such file: $FILE"
        exit 2
      fi
    fi
  else
    echo "File must be specified."
    exit 1
  fi


  def_ans='N'
  read -r -p "The current database '${DB_NAME}' will be droped. Are you sure? y/[N]: " ans ; [ -z "${ans}" ] && ans=${def_ans}

  if [ "$ans" = "Y" ] || [ "$ans" = "y" ]; then
    docker exec -i ${DOCKER_NAME} dropdb -U ${DB_USER} ${DB_NAME}
    rc=$?
    if [ $rc -ne 0 ]; then
        echo "${RED}Aborted. Could not perform 'docker exec -i ${DOCKER_NAME} dropdb -U ${DB_USER} ${DB_NAME}', exit code [$rc].${NC}"; exit $rc
    fi
    docker exec -i ${DOCKER_NAME} createdb -U ${DB_USER} ${DB_NAME}
    gunzip < $FILE | docker exec -i ${DOCKER_NAME} psql -U ${DB_USER} -d ${DB_NAME}
  fi
}

execute_file() {
  if [ ! -z "$1" ]; then
    FILE=$1
    if [ ! -f "$FILE" ]; then
      echo "No such file: $FILE"
      exit 2
    fi
  else
    echo "File must be specified."
    exit 1
  fi

  cat "$FILE" | docker exec -i "$DOCKER_NAME" psql -U "$DB_USER" -d "$DB_NAME"
}


if [ $# -gt 0 ]; then
  key="$1"

  case $key in
    -i|--info)
      info
      ;;

    -s|--setup)
      setup
      ;;

    -c|--connect)
      connect
      ;;

    --add-to-cron)
      add_to_crontab "$2"
      ;;

    -d|--dump)
      dump
      ;;

    -t|--dump-table)
      dump_table "$2"
      ;;

    -r|--restore)
      restore "$2"
      ;;

    -f|--file)
      execute_file "$2"
      ;;

    -C|--clean-older-dumps)
      clean_older_dumps "$2"
      ;;

    -l|--load)
      load
      ;;

    -h|--help)
      help
      ;;

    *)
      help
      ;;
  esac
fi

exit 0
