from python_graphql_client import GraphqlClient

# Instantiate the client with an endpoint.
client = GraphqlClient(endpoint="http://localhost:8080/graphql")

# Create the query string and variables required for the request.
query = """
query {
	querySensor {
		id
		xid
		value
		timestamp
		unit
	}
}
"""
variables = {}

# Synchronous request
data = client.execute(query=query, variables=variables)
print(data)