#!/usr/bin/env bash

DUMP_FILE="$1"
NEW_DB=aligneddb
export NEO4J_VERSION="$2"
NEO4J_ENTERPRISE_SERVICE=enterprise
NEO4J_COMMUNITY_SERVICE=community

DUMP_FILE_PATH=/dumps/"$DUMP_FILE".dump
ALIGNED_DUMP_FILE_PATH=/dumps/"$DUMP_FILE"_aligned.dump

#########
# Setup #
#########
# Check if first argument is empty
if [ -z "$DUMP_FILE" ]; then
  echo "Usage: $0 <dump_file> <optional neo4j_version>"
  exit 1
fi

if [ -z "$NEO4J_VERSION" ]; then
  export NEO4J_VERSION=4.4
fi

#############
# Functions #
#############

function usage() {
  echo "Usage: $0 <dump_file>"
  exit 1
}

########
# Main #
########
# Step 0: Clean slate
echo ">>> Step 0: Clean slate"

function clean_slate() {
  docker compose down -v --remove-orphans
}

clean_slate >> /dev/null 2>&1

# Step 1: Import to enterprise DB
echo ">>> Step 1: Import to enterprise DB:  $DUMP_FILE"

function import_to_enterprise() {
  docker compose run -it "$NEO4J_ENTERPRISE_SERVICE" \
    neo4j-admin load \
    --from="$DUMP_FILE_PATH" \
    --database=neo4j \
    --force
}

import_to_enterprise >> /dev/null 2>&1


# Step 2: Delete constraints
echo ">>> Step 2: Delete constraints"

function delete_constraints() {
  docker compose up -d "$NEO4J_ENTERPRISE_SERVICE"
  sleep 20
  docker compose exec -it "$NEO4J_ENTERPRISE_SERVICE" bash -c "/scripts/drop_constraints.sh $DUMP_FILE $NEW_DB"
  docker compose down --remove-orphans
}

delete_constraints >> /dev/null 2>&1

# Step 3: Copy to new DB as ALIGNED
echo ">>> Step 3: Copy to new DB as ALIGNED"

function copy_to_new_db() {
  docker compose run -it "$NEO4J_ENTERPRISE_SERVICE" \
    neo4j-admin copy \
    --to-format=aligned \
    --to-database="$NEW_DB" \
    --from-database=neo4j
}

copy_to_new_db >> /dev/null 2>&1


# Step 4: Export from new DB
echo ">>> Step 4: Export from new DB"
function export_from_new_db() {
  rm .."$ALIGNED_DUMP_FILE_PATH"
  docker compose run -it "$NEO4J_ENTERPRISE_SERVICE" \
    neo4j-admin dump \
    --database="$NEW_DB" \
    --to="$ALIGNED_DUMP_FILE_PATH"
}

export_from_new_db >> /dev/null 2>&1


# Step 5: Import to community DB
echo ">>> Step 5: Import to community DB"

function import_to_community() {
  docker compose run -it "$NEO4J_COMMUNITY_SERVICE" \
    neo4j-admin load \
    --from="$ALIGNED_DUMP_FILE_PATH" \
    --database=neo4j \
    --force
}

import_to_community >> /dev/null 2>&1


# Step 6: Export constraints
echo ">>> Step 6: Export constraints"
./scripts/export_constraints.sh "$DUMP_FILE"


#
##echo "Shutting down "$NEO4J_ENTERPRISE_SERVICE""
#echo "Done"
