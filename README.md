# Dgraph Sandbox

This repo serves as a quick start for spinning up a Dgraph cluster, updating a schema and loading data. Everything's 
done with `make`, the only other requirement is Docker and optionally `jq` and `gql`.

#### Requirements
- make
- curl
- gql (optional, for graphql queries, download from [here](https://github.com/matthewmcneely/gql/tree/feature/add-query-and-variables-from-file/builds))
- jq (optional, for queries from the command line)

For this branch, the JWT command line encoder is required, see https://github.com/mike-engel/jwt-cli

## Steps

1. Clone this repo. It's possible I've created a branch for some issue we're collaborating on. If so, check out the branch for the issue.

## ⚠️ Branch-specific Steps ⚠️

This branch demonstrates using custom JWT claims for query and mutation authentication in a GraphQL-based Dgraph **CLOUD** cluster

2. Launch/use a cloud instance at https://cloud.dgraph.io

Locate your GraphQL service endpoint, should be something like `https://foo-bar.us-east-1.aws.cloud.dgraph.io`. This is found on your Dgraph cloud console Overview page, there's a copy-to-paste-buffer icon next to it. **Drop the /graphql suffix when setting the environment variable**

Export that to environment variable DGC_ENDPOINT
```
export DGC_ENDPOINT=<your service endpoint>
```

On the Dgraph cloud console, under Admin - Settings (left menu bar), create an **Admin** key. Export that key thusly:

```
export DGC_ADMIN_KEY=<your admin key>
```

To test the use of the `X-Auth-Token` headers against your graphql endpoint, you should ensure that "Anonymous Access" is turned off. This is done in the Schema page, under the Access tab.

3. Then in another terminal, load the basic schema with no authentication

```
make schema-gql
```

4. Load 5 Turbines across 3 farms. One of the Turbines has the `accessGroup` predicate set to _experimental_

```
make load-data-dql-json
```

5. Query against the un-authenticated cluster:

```
make query-gql
```

6. Restrict query access to Turbines based on the custom groups claim present in a JWT token

```
make schema-gql-auth
```

7. Run the query again, now the query authentication is working (no data returned)
```
make query-gql
```

8. Run the query again, but this time encode the token in [jwt.json](jwt.json) with the "staff" group and include it in the query header

```
make query-gql-auth
```

The four Turbines that match the sole JWT group list are returned

9. Run the query again, but this time encode a token with both "staff" and "experimental" elements in the JWT group

```
make query-gql-auth-experimental
```

Now all five Turbines are returned

10. Run a query starting at the Farms _level_ to demonstrate authentication rules are enforced in traversals

```
make query-gql-farms
```

Because no JWT was present, the traversal of the `turbines` predicates yields empty arrays.

11. Run the same query, this time sending a property encoded JWT with all groups defined.

```
make query-gql-farms-auth-experimental
```

12. Update one of the turbines:

```
make mutation-gql
```

The record is updated, but because the query auth is in place the results cannot be returned

13. Update the schema with `update` auth protection

```
make schema-gql-auth-mutate
```

14. Try to update the Turbine again

```
make mutation-gql
```

No records updated

15. Update the Turbine now with a correct JWT token

```
make mutation-gql-auth-experimental
```

The `update` auth rules allow this update because the correct group was encoded in the JWT custom claims

## ⚠️ End of branch-specific Steps ⚠️

## Make targets

### `make help`
Lists all available make targets and a short description.

### `make up`
Brings up a simple alpha and zero node using docker compose in your local Docker environment.

### `make up-with-lambda`
Brings up the alpha and zero containers along with the dgraph lambda container. Note this lambda container is based on `dgraph/dgraph-lambda:1.4.0`. 

### `make down` and `make down-with-lambda`
Stops the containers.

### `make schema-dql`
Updates dgraph with the schema defined in `schema.dql`.

Example schema.dql:
```
type Person {
    name
    boss_of
    works_for
}

type Company {
    name
    industry
    work_here
}

industry: string @index(term) .
boss_of: [uid] .
name: string @index(exact, term) .
work_here: [uid] .
boss_of: [uid] @reverse .
works_for: [uid] @reverse .
```

### `make schema-gql`
Updates dgraph with the schema defined in `schema.graphql`

Example schema.gql:
```graphql
type Post {
    id: ID!
    title: String!
    text: String
    datePublished: DateTime
    author: Author!
}

type Author {
    id: ID!
    name: String!
    posts: [Post!] @hasInverse(field: author)
}
```

### `make drop-data`
Drops all data from the cluster, but not the schema.

### `make drop-all`
Drops all data and the schema from the cluster.

### `make load-data-gql`
Loads JSON data defined in `gql-data.json`. This target is useful for loading data into schemas defined with GraphQL SDL.

Example gql-data.json:
```json
[
    {
        "uid": "_:katie_howgate",
        "dgraph.type": "Author",
        "Author.name": "Katie Howgate",
        "Author.posts": [
            {
                "uid": "_:katie_howgate_1"
            },
            {
                "uid": "_:katie_howgate_2"
            }
        ]
    },
    {
        "uid": "_:timo_denk",
        "dgraph.type": "Author",
        "Author.name": "Timo Denk",
        "Author.posts": [
            {
                "uid": "_:timo_denk_1"
            },
            {
                "uid": "_:timo_denk_2"
            }
        ]
    },
    {
        "uid": "_:katie_howgate_1",
        "dgraph.type": "Post",
        "Post.title": "Graph Theory 101",
        "Post.text": "https://www.lancaster.ac.uk/stor-i-student-sites/katie-howgate/2021/04/27/graph-theory-101/",
        "Post.datePublished": "2021-04-27",
        "Post.author": {
            "uid": "_:katie_howgate"
        }
    },
    {
        "uid": "_:katie_howgate_2",
        "dgraph.type": "Post",
        "Post.title": "Hypergraphs – not just a cool name!",
        "Post.text": "https://www.lancaster.ac.uk/stor-i-student-sites/katie-howgate/2021/04/29/hypergraphs-not-just-a-cool-name/",
        "Post.datePublished": "2021-04-29",
        "Post.author": {
            "uid": "_:katie_howgate"
        }
    },
    {
        "uid": "_:timo_denk_1",
        "dgraph.type": "Post",
        "Post.title": "Polynomial-time Approximation Schemes",
        "Post.text": "https://timodenk.com/blog/ptas/",
        "Post.datePublished": "2019-04-12",
        "Post.author": {
            "uid": "_:timo_denk"
        }
    },
    {
        "uid": "_:timo_denk_2",
        "dgraph.type": "Post",
        "Post.title": "Graph Theory Overview",
        "Post.text": "https://timodenk.com/blog/graph-theory-overview/",
        "Post.datePublished": "2017-08-03",
        "Post.author": {
            "uid": "_:timo_denk"
        }
    }
]
```

### `make load-data-dql-json`
Loads JSON data defined in `dql-data.json`. This target is useful for loading data into schemas defined with base dgraph types.

Example dql-data.json:
```json
{
    "set": [
        {
            "uid": "_:company1",
            "industry": "Machinery",
            "dgraph.type": "Company",
            "name": "CompanyABC"
        },
        {
            "uid": "_:company2",
            "industry": "High Tech",
            "dgraph.type": "Company",
            "name": "The other company"
        },
        {
            "uid": "_:jack",
            "works_for": { "uid": "_:company1"},
            "dgraph.type": "Person",
            "name": "Jack"
        },
        {
            "uid": "_:ivy",
            "works_for": { "uid": "_:company1"},
            "boss_of": { "uid": "_:jack"},
            "dgraph.type": "Person",
            "name": "Ivy"
        },
        {
            "uid": "_:zoe",
            "works_for": { "uid": "_:company1"},
            "dgraph.type": "Person",
            "name": "Zoe"
        },
        {
            "uid": "_:jose",
            "works_for": { "uid": "_:company2"},
            "dgraph.type": "Person",
            "name": "Jose"
        },
        {
            "uid": "_:alexei",
            "works_for": { "uid": "_:company2"},
            "boss_of": { "uid": "_:jose"},
            "dgraph.type": "Person",
            "name": "Alexei"
        }
    ]
}
```

### `make load-data-dql-rdf`
Loads RDF data defined in `dql-data.rdf`. This target is useful for loading data into schemas defined with base dgraph types.

Example dql-data.rdf:
```rdf
{
  set {
    _:company1 <name> "CompanyABC" .
    _:company1 <dgraph.type> "Company" .
    _:company2 <name> "The other company" .
    _:company2 <dgraph.type> "Company" .

    _:company1 <industry> "Machinery" .

    _:company2 <industry> "High Tech" .

    _:jack <works_for> _:company1 .
    _:jack <dgraph.type> "Person" .

    _:ivy <works_for> _:company1 .
    _:ivy <dgraph.type> "Person" .

    _:zoe <works_for> _:company1 .
    _:zoe <dgraph.type> "Person" .

    _:jack <name> "Jack" .
    _:ivy <name> "Ivy" .
    _:zoe <name> "Zoe" .
    _:jose <name> "Jose" .
    _:alexei <name> "Alexei" .

    _:jose <works_for> _:company2 .
    _:jose <dgraph.type> "Person" .
    _:alexei <works_for> _:company2 .
    _:alexei <dgraph.type> "Person" .

    _:ivy <boss_of> _:jack .

    _:alexei <boss_of> _:jose .
  }
}
```

### `make query-dql`
Runs the query defined in query.dql.

Example query.dql:
```
{
  q(func: eq(name, "CompanyABC")) {
    name
    works_here : ~works_for {
        uid
        name
    }
  }
}
```

### `make query-gql`
Runs the query defined in query.gql and optional variables defined in variables.json.

Example query-gql:
```graphql
query QueryAuthor($order: PostOrder) {
  queryAuthor {
    id
    name
    posts(order: $order) {
      id
      datePublished
      title
      text
    }
  }
}
```

Example variables.json:
```json
{
    "order": {
      "desc": "datePublished"
    }
}
```
