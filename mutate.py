import datetime

from python_graphql_client import GraphqlClient

# Instantiate the client with an endpoint.
client = GraphqlClient(endpoint="http://localhost:8080/graphql")

# Create the query string and variables required for the request.
query = """
mutation AddSensor($input: [AddSensorInput!]!) {
  addSensor(input: $input) {
    sensor {
      id
    }
  }
}
"""

list = []
for i in range(1, 1001):
    list.append({"xid": "xid" + str(i), "value": i*i, "timestamp": "2019-01-03", "unit": "C"})

start = datetime.datetime.now()
data = client.execute(query=query, variables={"input": list})
end = datetime.datetime.now()
elapsed = end - start

print(len(list), "records in", elapsed.microseconds / 1000, "milliseconds")