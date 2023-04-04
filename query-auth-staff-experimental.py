import os
import jwt
import json

from python_graphql_client import GraphqlClient

# Instantiate the client with an endpoint.
client = GraphqlClient(endpoint="http://localhost:8080/admin")

# login thru ACL
query = """
mutation {
  login(userId: "alice", password: "supersecret") {
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
query QueryTurbine {
  queryTurbine {
    id
    model
    number_of_blades
    accessGroup
  }
}"""
variables = {}
with open('./jwt-experimental.json', 'r') as file:
    jwtRawToken = json.load(file)

encoded = jwt.encode(jwtRawToken, "vDK59uv+QxbuRpwdcFyYdTlLahaFDG0g2rf7+pc+jkk=", algorithm='HS256')
headers = {
    "X-Dgraph-AccessToken": accessJWT,
    "X-myapp": encoded
}


# Synchronous request
data = client.execute(query=query, variables=variables, headers=headers)
print(json.dumps(data, indent=2))