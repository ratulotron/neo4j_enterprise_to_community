#!/bin/bash

############
# Function #
############

function usage() {
  echo "Usage: $0 <dump_file>"
  exit 1
}

function export_constraints() {
  PREFIX="$1"
  cypher-shell -a "$NEO4J_URI" "SHOW CONSTRAINTS " > /dumps/"$DUMP_FILE"_"$PREFIX"_delete_constraints_and_indexes.txt
}

function run_cypher() {
  stmt="$1"
  stmt=$(echo "$stmt" | sed -e 's/^"//' -e 's/"$//')
  echo "Running: $stmt"
  cypher-shell -a "$NEO4J_URI" "$stmt"
}

function drop_constraints() {
  PREFIX="$1"
  GET_CONSTRAINTS="SHOW CONSTRAINTS YIELD name, type \
                   WHERE type = 'NODE_PROPERTY_EXISTENCE' \
                   RETURN 'DROP CONSTRAINT ' + name + ' IF EXISTS;' AS dropStatement"


  echo "Deleting constraints"
  # Generate and execute DROP statements
  run_cypher "$GET_CONSTRAINTS" |
    grep 'DROP CONSTRAINT' |
    while read -r stmt; do
      run_cypher "$stmt"
    done
}

########
# Main #
########

# Check if first argument is empty
if [ -z "$1" ]; then
  usage
fi

# Set the following environment variables
NEO4J_URI="neo4j://localhost:7687"
#NEO4J_USER=""
#NEO4J_PASSWORD=""
# Get file name from first argument
DUMP_FILE="$1"



# Dump constraints before deletion
#cypher-shell -a $NEO4J_URI "SHOW CONSTRAINTS " > /dumps/"$DUMP_FILE"_pre_delete_constraints_and_indexes.txt
echo "Exporting constraints before deletion"
export_constraints "pre"
echo "Deleting constraints"
# Generate and execute DROP statements
drop_constraints "pre"
echo "Exporting constraints after deletion"
export_constraints "post"
