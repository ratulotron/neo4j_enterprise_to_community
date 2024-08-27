#!/usr/bin/env bash

# Check if first argument is empty

if [ -z "$1" ]; then
  echo "Usage: $0 <dump_file>"
  exit 1
fi

# Set the following environment variables
LOG_PREFIX=./logs/enterprise
DUMP_FILE="$1"


#############
# Functions #
#############

function extract_query() {
    LOG_FILE="$LOG_PREFIX"/$(ls -t "$LOG_PREFIX" | head -n 1 | cut -d / -f 1)
    # echo "Latest log file: $LOG_FILE"

    # Get the line number of the string "The following can be used to recreate the schema"
    START_LINE_NUMBER=$(grep -n "The following can be used to recreate the schema" "$LOG_FILE" | cut -d: -f1)
    # Get the line number of the line after the line number from step 1
    START_LINE_NUMBER=$((START_LINE_NUMBER + 2))
    # echo "Query starts from line: $START_LINE_NUMBER"
    # The query goes until there is a new log entry. A new log entry is a line that starts with a year.
    END_LINE_NUMBER=$(sed -n "$START_LINE_NUMBER,\$p" "$LOG_FILE" | grep -n "^[0-9][0-9][0-9][0-9]-" | head -n 1 | cut -d: -f1)
    # echo "Query ends at line: $END_LINE_NUMBER"
    # Now we read from $START_LINE_NUMBER to $END_LINE_NUMBER

    CONSTRAINTS_QUERY=$(sed -n "$START_LINE_NUMBER,$END_LINE_NUMBER p" "$LOG_FILE")
    echo "$CONSTRAINTS_QUERY"
}


function save_query() {
    CONSTRAINTS_QUERY=$1
    CYPHER_FILE=./dumps/"$DUMP_FILE"_constraints_creation.cypher
    rm -f "$CYPHER_FILE"
    touch "$CYPHER_FILE"
    echo "$CONSTRAINTS_QUERY" > "$CYPHER_FILE"
    echo "$CYPHER_FILE"
}

########
# Main #
########

echo "Extracting constraints creation cypher from log file"
CONSTRAINTS_QUERY=$(extract_query)
echo "Saving constraints creation cypher to file"
#echo "*** $CONSTRAINTS_QUERY"
save_query "$CONSTRAINTS_QUERY"
