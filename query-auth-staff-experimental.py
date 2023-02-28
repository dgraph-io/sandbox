import os
import jwt
import json

from python_graphql_client import GraphqlClient

# Instantiate the client with an endpoint.
client = GraphqlClient(endpoint=os.environ['DGC_ENDPOINT']+"/graphql")

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
    "X-Auth-Token": os.environ['DGC_ADMIN_KEY'],
    "X-myapp": encoded
}


# Synchronous request
data = client.execute(query=query, variables=variables, headers=headers)
print(json.dumps(data, indent=2))