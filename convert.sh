DUMP_FILE="$1" # 20240821_moriarty_self
NEW_DB=aligneddb

if [ -z "$DUMP_FILE" ]; then
  echo "Usage: $0 <dump_file>"
  exit 1
fi

# Step 0: Clean slate
docker compose down -v --remove-orphans
echo "Importing dump file $DUMP_FILE"

# Step 1: Import to enterprise DB
echo ">>> Step 1: Import to enterprise DB"
docker compose run -it neo4j-enterprise neo4j-admin load --from=/dumps/"$DUMP_FILE".dump --database=neo4j --force

# Step 2: Delete constraints
echo ">>> Step 2: Delete constraints"
docker compose up -d neo4j-enterprise
sleep 20
docker compose exec -it neo4j-enterprise bash /scripts/drop_constraints.sh "$DUMP_FILE" "$NEW_DB"
docker compose down --remove-orphans

# Step 3: Copy to new DB as ALIGNED
echo ">>> Step 3: Copy to new DB as ALIGNED"

docker compose run -it neo4j-enterprise \
  neo4j-admin copy \
  --to-format=aligned \
  --to-database="$NEW_DB" \
  --from-database=neo4j

# Step 4: Export from new DB
echo ">>> Step 4: Export from new DB"
rm ./dumps/"$DUMP_FILE"_aligned.dump
docker compose run -it neo4j-enterprise \
  neo4j-admin dump \
  --database="$NEW_DB" \
  --to=/dumps/"$DUMP_FILE"_aligned.dump


# Step 5: Import to community DB
echo ">>> Step 5: Import to community DB"
docker compose run -it neo4j-community \
neo4j-admin load \
--from=/dumps/"$DUMP_FILE"_aligned.dump \
--database=neo4j \
--force

#echo "Shutting down neo4j-enterprise"
echo "Done"
