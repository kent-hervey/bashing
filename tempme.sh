#!/bin/bash
echo "hello"

host=${TARGET_DB_HOST:-localhost}
port=${TARGET_DB_PORT:-5432}
username=${TARGET_DB_USERNAME:-root}
password=${TARGET_DB_PASSWORD:-password}
database=${TARGET_DB_NAME:-locationmanager}
schema=${TARGET_SCHEMA_NAME:-public}

BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'


echo -e "${BLUE}"
echo "            _"
echo "__ __ _____| |__ ___ _ __  ___"
echo "\ V  V / -_) / _/ _ \ '  \/ -_)"
echo "\_/\_/\___|_\__\___/_|_|_\___|"
echo -e "${NC}"


echo -e "${GREEN}2 - Query the database to see if the container is locked"

connectionString="-U ${username}  -d ${database} -h ${host} -p ${port}"

export PGPASSWORD="${TARGET_DB_PASSWORD:-password}"

if pg_isready ${connectionString} &> /dev/null; then
  echo "The database instance is ready!"
else
  echo >&2 "The database instance isn't ready to connect using: ${connectionString}"
  exit 1;
fi

# returns
# 0 -> the newrelic returned that the container is there
# 1 -> there was an error
# 2 -> the newrelic returned that the container is not there
function doTheNewRelicCheck {
  echo "Doing the new relic check for container: ${0}"
}

# returns
# 0 -> there are no locks found
# 1 -> there was an error
# 2 -> there was a locked record found
function queryForLocks() {
  queryResult=$(psql ${connectionString} -q -c 'SELECT lockedby FROM '"${schema}"'.databasechangeloglock WHERE locked = true;' -t | tr -d '\t ')
  echo "The queryResult is: ${queryResult}"

  if [[ "x${queryResult}" == "x" ]]; then echo "There are no locked records"; else "The locked records are: \"${result}\"" && lockedRecordsFound="true"; fi

  if [[ "${lockedRecordsFound}" == "true" ]]; then

    echo "${queryResult}" | while read -r lockedBy; do 
      echo "The user: ${lockedBy} has a lock on the db"; 
      newRelicCheckResult="$(doTheNewRelicCheck "${lockedBy}")"
      if [[ "${newRelicCheckResult}" == "0" ]]; then
        echo "Found that the container: ${lockedBy} was found by new relic, so going to sleep and loop again."
        sleep 5
      elif [[ "${newRelicCheckResult}" == "1" ]]; then
        echo "There was an error when trying to query new relic, going to return with error"
        return 1
      elif [[ "${newRelicCheckResult}" == "2" ]]; then
        echo "Found that the container: ${lockedBy} is not found by new relic, so going to remove the lock."
        # do the lock removal query
      else
        echo "Shouldn't have reached this section for container \"${lockedBy}\" from the new relic query"
        return 1
      fi
    done

    return 2
  fi

  return 0
}

locksResult=queryForLocks
while "${locksResult}" == "2"; do
  echo "Locks where found, going to need to try again"
  locksResult=queryForLocks
done
white_check_mark
eyes
raised_hands














