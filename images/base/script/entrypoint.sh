#!/usr/bin/env bash

TRY_LOOP="20"

: "${REDIS_HOST:="redis"}"
: "${REDIS_PORT:="6379"}"
: "${REDIS_PASSWORD:=""}"

# : "${DB_HOST:="postgres"}"
: "${DB_PORT:="3306"}"
: "${DB_USER:="airflow"}"
: "${DB_PASSWORD:="airflow"}"
: "${DB_NAME:="airflow"}"

# Defaults and back-compat
: "${AIRFLOW__CORE__EXECUTOR:=${EXECUTOR:-Sequential}Executor}"

export \
  AIRFLOW__CELERY__BROKER_URL \
  AIRFLOW__CELERY__CELERY_RESULT_BACKEND \
  AIRFLOW__CORE__EXECUTOR \  
  AIRFLOW__CORE__LOAD_EXAMPLES \
  AIRFLOW__CORE__SQL_ALCHEMY_CONN \


# Load DAGs exemples (default: Yes)
if [[ -z "$AIRFLOW__CORE__LOAD_EXAMPLES" && "${LOAD_EX:=n}" == n ]]
then
  AIRFLOW__CORE__LOAD_EXAMPLES=False
fi

# Install custom python package if requirements.txt is present
if [ -e "/requirements.txt" ]; then
    $(which pip) install --user -r /requirements.txt
fi

if [ -n "$REDIS_PASSWORD" ]; then
    REDIS_PREFIX=:${REDIS_PASSWORD}@
else
    REDIS_PREFIX=
fi

wait_for_port() {
  local name="$1" host="$2" port="$3"
  local j=0
  while ! nc -z "$host" "$port" >/dev/null 2>&1 < /dev/null; do
    j=$((j+1))
    if [ $j -ge $TRY_LOOP ]; then
      echo >&2 "$(date) - $host:$port still not reachable, giving up"
      exit 1
    fi
    echo "$(date) - waiting for $name... $j/$TRY_LOOP"
    sleep 5
  done
}

wait_for_redis() {
  # Wait for Redis if we are using it
  if [ "$AIRFLOW__CORE__EXECUTOR" = "CeleryExecutor" ]
  then
    wait_for_port "Redis" "$REDIS_HOST" "$REDIS_PORT"
  fi
}

AIRFLOW__CORE__SQL_ALCHEMY_CONN="mysql://$DB_USER:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_NAME"
AIRFLOW__CELERY__BROKER_URL="redis://$REDIS_PREFIX$REDIS_HOST:$REDIS_PORT/1"
AIRFLOW__CELERY__CELERY_RESULT_BACKEND="db+mysql://$DB_USER:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_DB"

case "$1" in
  webserver)
    # wait_for_port "Postgres" "$DB_HOST" "$DB_PORT"
    if [ "$AIRFLOW__CORE__EXECUTOR" = "LocalExecutor" ];
    then
      wait_for_redis
    fi
    
    airflow initdb
    sleep 10
    if [ "$AIRFLOW__CORE__EXECUTOR" = "LocalExecutor" ];
    then
      # With the "Local" executor it should all run in one container.
      airflow scheduler &
    fi
    exec airflow webserver
    ;;
  worker|scheduler)
    # wait_for_port "Postgres" "$DB_HOST" "$DB_PORT"
    wait_for_redis
    # To give the webserver time to run initdb.
    sleep 10
    exec airflow "$@"
    ;;
  flower)
    wait_for_redis
    exec airflow "$@"
    ;;
  version)
    exec airflow "$@"
    ;;
  *)
    # The command is something like bash, not an airflow subcommand. Just run it in the right environment.s something like bash, not an airflow subcommand. Just run it in the right environment.
    exec "$@"
    ;;
esac