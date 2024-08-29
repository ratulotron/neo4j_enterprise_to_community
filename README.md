# Neo4j Aura/Enterprise to Community Edition Downgrade

If you want to move your Neo4j database from the Aura/Enterprise Edition to the Community Edition, you might face some
challenges. This script will help you convert the data dump from the Aura/Enterprise Edition to a format compatible with
the Community Edition. 

> Note: Use this script at your own risk. Make sure to back up your data before running this script.

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
7. Export a Cypher script to create the constraints and indexes

## Prerequisites

- Data dump from the Neo4j Aura/Enterprise Edition database
- Docker installed on your machine


## Steps

#### Setup the environment
Clone this repository and put your data dump in the `dumps` directory. Set the environment variable `NEO4J_VERSION` to the version of the Neo4j your database dump is from. For example, if you want to use Neo4j 4.3.1, you can run the following command:  

```bash
export NEO4J_VERSION=4.3.1
```

#### Trigger the process
Run the following command to start the process:

```bash
./scripts/convert.sh <filename> <neo4j-version>
```

For example, if your dump file is `neo4j.dump` and you want to use Neo4j 4.3.1, you can run the following command:

```bash
./scripts/convert.sh neo4j 4.3.1
```

> Note: The script needs only the file name without the extension. 

This command creates these files in the `dumps` directory:

| File                              | Description                                                               |
|-----------------------------------|---------------------------------------------------------------------------|
| `<filename>_aligned.dump`         | Copy of the `<filename>.dump` is a format compatible with Neo4j Community |
| `<filename>_pre_constraints.txt`  | A list of constraints in the original `<filename>.dump`                   |
| `<filename>_post_constraints.txt` | A list of constraints in the new data dump without Enterprise constraints |
| `<filename>_constraints.cypher`   | Cypher script to run to create non Enterprise constraints in the new DB.  |

#### Import
Once you have set up your self-hosted version of Neo4j Community Edition, you can import the new data dump

#### Constraints
The script `convert.sh` will create a list of constraints and indexes in the new database. The constraints and indexes 
that are not supported in the Community Edition will be removed from the new database. This list will be found in the 
`dumps` directory with the name `<filename>_post_constraints.txt`. You will also find a Cypher script in the same 
directory with the name `<filename>_constraints.cypher`. This script can be used to create the constraints and indexes 
in the new database.

## Troubleshooting
If you face any issues, remove the `/dev/null` from the docker commands in the `convert.sh` script to see the logs. I 
do not take any responsibility or liability for any unforeseen data loss or corruption. Please make sure to back up your
data before running this script.