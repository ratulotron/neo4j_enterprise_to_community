#!/bin/bash

NEO4J_URI="neo4j://localhost:7687"
#NEO4J_USER=""
#NEO4J_PASSWORD=""

cypher-shell -a $NEO4J_URI "SHOW CONSTRAINTS " > /dumps/pre_delete_constraints.txt

echo "Deleting constraints"

function run_cypher() {
  stmt=$(echo "$1" | sed -e 's/^"//' -e 's/"$//')
  echo "Running: $stmt"
  cypher-shell -a $NEO4J_URI "$stmt"
}

# Generate and execute DROP statements
cypher-shell -a $NEO4J_URI \
  "SHOW CONSTRAINTS YIELD name, type \
   WHERE type = 'NODE_PROPERTY_EXISTENCE' \
   RETURN 'DROP CONSTRAINT ' + name + ' IF EXISTS;' AS dropStatement" |
  grep 'DROP CONSTRAINT' |
  while read -r stmt; do
    run_cypher "$stmt"
  done

cypher-shell -a $NEO4J_URI "SHOW CONSTRAINTS" > /dumps/post_delete_constraints.txt
