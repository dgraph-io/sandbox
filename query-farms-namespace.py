import os
import jwt
import json

from python_graphql_client import GraphqlClient

# Instantiate the client with an endpoint.
client = GraphqlClient(endpoint="http://localhost:8080/admin")

# login thru ACL
query = """
mutation {
  login(userId: "bob-in-ns", password: "supersecret", namespace: 1) {
    response {
      accessJWT
      refreshJWT
    }
  }
}
"""
data = client.execute(query=query, variables={})
print(data)
accessJWT = data['data']['login']['response']['accessJWT']

client = GraphqlClient(endpoint="http://localhost:8080/graphql")

# Create the query string and variables required for the request.
query = """
query {
  queryFarmNS {
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