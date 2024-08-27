# Neo4j Aura/Enterprise to Community Edition Downgrade

Neo4j's data dumps can be in the following formats:


| Format     | Introduced | Deprecated | Description                                                                |
|------------|------------|------------|----------------------------------------------------------------------------|
| Block      | Neo4j 5.16 |            | Only available in Enterprise Edition                                       |
| Aligned    | Neo4j 5.0  |            | Default format for Community and Enterprise Edition versions prior to 5.22 |
| Standard   | Neo4j 3.0  | Neo4j 5.23 |                                                                            |
| High limit | Neo4j 3.0  | Neo4j 5.23 | Supports up to 1 Quadrillion Nodes & Relationships                         |

Neo4j Enterprise and Aura by default export data in the `block` format. This format is not compatible with the Community Edition. This format includes some Enterprise features as well which are not supported in the Community Edition. This script will convert the `block` format to the `aligned` format, which is compatible with the Community Edition.

Under the hoods what it does is the following:

1. Load the data dump in the Enterprise Edition in a Docker container 
2. Copy the database to a new one in the `aligned` format
3. Make a pre-export list of all constraints and indexes from the new database
4. Remove all Enterprise only constraints and indexes from the new database
5. Make another post-export list of all constraints and indexes
6. Export the new database
7. Load the new database in the Community Edition in a Docker container
8. Allow you to run the creation of the constraints and indexes from the pre-export list and the logs 

## Prerequisites

- Data dump from the Neo4j Aura/Enterprise Edition database
- Docker installed on your machine

## What it does

The script will take the data dump from the Aura/Enterprise Edition database and convert it to the Community Edition database. When you provide 

## Steps

1. Clone this repository
2. Copy the data dump to the `dumps` directory
3. Run the following command to start the process:

```bash
./scripts/convert.sh <data-dump-file> <neo4j-version>
```

Note that the script only needs the file name of the dump without the full extension. For example if your dump file is from Neo4j Aura, it's name will be `neo4j.dump` and you only need to provide `neo4j` as the first argument. The second argument is the version of Neo4j Community Edition you want to use. This has to match with the version of the Neo4j Aura/Enterprise Edition database the dump was taken from. For example, if the dump was taken from a Neo4j 4.3.1 database, you need to provide `4.3.1` as the second argument. That makes the command look like this:

```bash
./scripts/convert.sh neo4j 4.3.1
```

4. The script will create a new file in the `dumps` directory with the name `<data-dump-file>_aligned.dump`.
5. Once you load the new database in the Community Edition, you will see a list of constraints and indexes that need to be created. This file will be found in the same `dumps` directory with the name `<data-dump-file>_post_delete_constraints_and_indexes.txt`.
6. You can run the creation of the constraints and indexes by running the following command:

```bash
bash export_constraints.sh <data-dump-file>
```