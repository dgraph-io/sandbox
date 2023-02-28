DGRAPH_VERSION = latest

current_dir = $(shell pwd)

check-env:
ifndef DGC_ENDPOINT
	$(error DGC_ENDPOINT is undefined, see the README.md for instructions)
endif
ifndef DGC_ADMIN_KEY
	$(error DGC_ADMIN_KEY is undefined, see the README.md for instructions)
endif

schema-gql: check-env ## Load/update a GraphQL schema
ifneq (,$(wildcard ./schema.graphql))
	curl --data-binary '@./schema.graphql' --header 'content-type: application/octet-setream' --header 'Dg-Auth: $(DGC_ADMIN_KEY)' $(DGC_ENDPOINT)/admin/schema
else
	@echo "No schema.graphql found"
endif

schema-gql-auth: check-env ## Load/update the auth'd GraphQL schema
ifneq (,$(wildcard ./schema-auth.graphql))
	curl --data-binary '@./schema-auth.graphql' --header 'content-type: application/octet-stream' --header 'Dg-Auth: $(DGC_ADMIN_KEY)' $(DGC_ENDPOINT)/admin/schema
else
	@echo "No schema-auth.graphql found"
endif

schema-gql-auth-mutate: check-env ## Load/update query and mutation auth'd GraphQL schema
ifneq (,$(wildcard ./schema-auth-mutate.graphql))
	curl --data-binary '@./schema-auth-mutate.graphql' --header 'content-type: application/octet-stream' --header 'Dg-Auth: $(DGC_ADMIN_KEY)' $(DGC_ENDPOINT)/admin/schema
else
	@echo "No schema-auth.graphql found"
endif

drop-data: check-env ## Drops all data (but not the schema)
	curl -X POST $(DGC_ENDPOINT)/alter --header 'Dg-Auth: $(DGC_ADMIN_KEY)' -d '{"drop_op": "DATA"}'

load-data-dql-json: check-env  ## Loads data from the dql-data.json file
ifneq (,$(wildcard ./dql-data.json))
	curl --data-binary '@./dql-data.json' --header 'content-type: application/json' --header 'Dg-Auth: $(DGC_ADMIN_KEY)' $(DGC_ENDPOINT)/mutate?commitNow=true
else
	@echo "No dql-data.json file found"
endif

load-data-dql-rdf: check-env ## Loads data from the dql-data.rdf file
ifneq (,$(wildcard ./dql-data.rdf))
	curl --data-binary '@./dql-data.rdf' --header 'content-type: application/rdf' --header 'Dg-Auth: $(DGC_ADMIN_KEY)' $(DGC_ENDPOINT)/mutate?commitNow=true
else
	@echo "No dql-data.rdf file found"
endif

query-dql: check-env ## Runs the query present in query.dql
ifneq (,$(wildcard ./query.dql))
	@curl --data-binary '@./query.dql' --header 'Content-Type: application/dql' --header 'Dg-Auth: $(DGC_ADMIN_KEY)' -X POST $(DGC_ENDPOINT)/query
else
	@echo "No query.dql file found"
endif

mutation-gql: check-env ## Runs the mutation present in mutation.gql
ifeq (, $(shell which gql))
	@echo "No gql in $(PATH), download from https://github.com/matthewmcneely/gql/tree/feature/add-query-and-variables-from-file/builds"
else
	@gql file --query-file mutation.gql --variables-file variables.json --header Dg-Auth=$(DGC_ADMIN_KEY) --endpoint $(DGC_ENDPOINT)/graphql
endif

mutation-gql-auth: check-env ## Runs the mutation present in mutation.gql with the JWT token in the header
ifeq (, $(shell which jwt))
	@echo "No jwt in $(PATH), download from https://github.com/mike-engel/jwt-cli"
else
	@echo "Encoding claims in jwt.json"
	$(eval CLAIMS := $(shell cat jwt.json))
	$(eval TOKEN := $(shell jwt encode --secret vDK59uv+QxbuRpwdcFyYdTlLahaFDG0g2rf7+pc+jkk= '$(CLAIMS)'))
	@echo "Issuing query with JWT token in header"
	@gql file --query-file mutation.gql --variables-file variables.json --header Dg-Auth=$(DGC_ADMIN_KEY) --header X-myapp=$(TOKEN) --endpoint $(DGC_ENDPOINT)/graphql
endif

mutation-gql-auth-experimental: check-env ## Runs the mutation present in mutation.gql with the experimental group JWT token in the header
ifeq (, $(shell which jwt))
	@echo "No jwt in $(PATH), download from https://github.com/mike-engel/jwt-cli"
else
	@echo "Encoding claims in jwt-experimental.json"
	$(eval CLAIMS := $(shell cat jwt-experimental.json))
	$(eval TOKEN := $(shell jwt encode --secret vDK59uv+QxbuRpwdcFyYdTlLahaFDG0g2rf7+pc+jkk= '$(CLAIMS)'))
	@echo "Issuing query with JWT token in header"
	@gql file --query-file mutation.gql --variables-file variables.json --header Dg-Auth=$(DGC_ADMIN_KEY) --header X-myapp=$(TOKEN) --endpoint $(DGC_ENDPOINT)/graphql
endif

query-gql: check-env ## Runs the query present in query.gql and variables in variables.json (requires gql)
ifeq (, $(shell which gql))
	@echo "No gql in $(PATH), download from https://github.com/matthewmcneely/gql/tree/feature/add-query-and-variables-from-file/builds"
else
	@gql file --query-file query.gql --variables-file variables.json --header Dg-Auth=$(DGC_ADMIN_KEY) --endpoint $(DGC_ENDPOINT)/graphql
endif

# Runs the query present in query.graphql with the JWT token in the header
# Note the 32 byte secret was generated for this demo only. Do not use this in production (generate your own).
query-gql-auth: check-env
ifeq (, $(shell which jwt))
	@echo "No jwt in $(PATH), download from https://github.com/mike-engel/jwt-cli"
else
	@echo "Encoding claims in jwt.json"
	$(eval CLAIMS := $(shell cat jwt.json))
	$(eval TOKEN := $(shell jwt encode --secret vDK59uv+QxbuRpwdcFyYdTlLahaFDG0g2rf7+pc+jkk= '$(CLAIMS)'))
	@echo "Issuing query with JWT token in header"
	@gql file --query-file query.gql --endpoint $(DGC_ENDPOINT)/graphql --header X-myapp=$(TOKEN) --header Dg-Auth=$(DGC_ADMIN_KEY)
endif

# Runs the query present in query.graphql with the JWT token in the header
# Note the 32 byte secret was generated for this demo only. Do not use this in production (generate your own).
query-gql-auth-experimental: check-env
ifeq (, $(shell which jwt))
	@echo "No jwt in $(PATH), download from https://github.com/mike-engel/jwt-cli"
else
	@echo "Encoding claims in jwt.json"
	$(eval CLAIMS := $(shell cat jwt-experimental.json))
	$(eval TOKEN := $(shell jwt encode --secret vDK59uv+QxbuRpwdcFyYdTlLahaFDG0g2rf7+pc+jkk= '$(CLAIMS)'))
	@echo "Issuing query with JWT token in header"
	@gql file --query-file query.gql --endpoint $(DGC_ENDPOINT)/graphql --header X-myapp=$(TOKEN) --header X-Auth-Token=$(DGC_ADMIN_KEY)
endif

query-gql-farms: check-env ## Runs the query present in query-farms.gql
ifeq (, $(shell which gql))
	@echo "No gql in $(PATH), download from https://github.com/matthewmcneely/gql/tree/feature/add-query-and-variables-from-file/builds"
else
	@gql file --query-file query-farms.gql --variables-file variables.json --header Dg-Auth=$(DGC_ADMIN_KEY) --endpoint $(DGC_ENDPOINT)/graphql
endif

query-gql-farms-auth-experimental: check-env
ifeq (, $(shell which jwt))
	@echo "No jwt in $(PATH), download from https://github.com/mike-engel/jwt-cli"
else
	@echo "Encoding claims in jwt-experimental.json"
	$(eval CLAIMS := $(shell cat jwt-experimental.json))
	$(eval TOKEN := $(shell jwt encode --secret vDK59uv+QxbuRpwdcFyYdTlLahaFDG0g2rf7+pc+jkk= '$(CLAIMS)'))
	@echo "Issuing query with JWT token in header"
	@gql file --query-file query-farms.gql --endpoint $(DGC_ENDPOINT)/graphql --header X-myapp=$(TOKEN) --header Dg-Auth=$(DGC_ADMIN_KEY)
endif

help: ## Print target help
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'