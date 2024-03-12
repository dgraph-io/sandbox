import os
import jwt
import json

from python_graphql_client import GraphqlClient

# Instantiate the client with an endpoint.
client = GraphqlClient(endpoint="http://localhost:8080/admin")

# login thru ACL
query = """
mutation {
  login(userId: "bob", password: "supersecret") {
    response {
      accessJWT
      refreshJWT
    }
  }
}
"""
data = client.execute(query=query, variables={})
accessJWT = data['data']['login']['response']['accessJWT']

client = GraphqlClient(endpoint="http://localhost:8080/graphql")

# Create the query string and variables required for the request.
query = """
query {
  queryFarm {
    id
    name
    turbines {
      id
      model
    }
    status
  }
}"""
variables = {}
headers = {
    "X-Dgraph-AccessToken": accessJWT,
}

# Synchronous request
data = client.execute(query=query, variables=variables, headers=headers)
print(json.dumps(data, indent=2))