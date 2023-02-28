import os
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
headers = { "X-Auth-Token": os.environ['DGC_ADMIN_KEY'] }

# Synchronous request
data = client.execute(query=query, variables=variables, headers=headers)
print(json.dumps(data, indent=2))