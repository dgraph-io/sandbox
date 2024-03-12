DGRAPH_VERSION = latest

current_dir = $(shell pwd)

keys:
	mkdir -p ~/test-dgraph-data/acl
	openssl rand -out ~/test-dgraph-data/acl/enc_key_file 32
	openssl rand -hex -out ~/test-dgraph-data/acl/hmac_secret_file 16

up: ## Start the zero and alpha containers
	DGRAPH_VERSION=$(DGRAPH_VERSION) docker-compose up zero alpha

down: ## Stop the containers
	DGRAPH_VERSION=$(DGRAPH_VERSION) docker-compose stop

login-groot: ## Login to the alpha container
	$(eval TOKEN := $(shell gql file --query-file login-groot.gql --endpoint http://localhost:8080/admin | jq -r '.login.response.accessJWT'))

login-alice: ## Login to the alpha container as a user
	$(eval TOKEN := $(shell gql file --query-file login-alice.gql --endpoint http://localhost:8080/admin | jq -r '.login.response.accessJWT'))

login-bob: ## Login to the alpha container as a user
	$(eval TOKEN := $(shell gql file --query-file login-bob.gql --endpoint http://localhost:8080/admin | jq -r '.login.response.accessJWT'))

acl-accounts: login-groot
ifneq (,$(wildcard ./acl-accounts.gql))
	@gql file --query-file acl-accounts.gql \
		--header 'X-Dgraph-AccessToken=$(TOKEN)' --endpoint http://localhost:8080/admin
else
	@echo "No acl-accounts.gql found"
endif

schema-gql: login-groot ## Load/update a GraphQL schema
ifneq (,$(wildcard ./schema.graphql))
	@curl -sS --data-binary '@./schema.graphql' \
		--header 'X-Dgraph-AccessToken: $(TOKEN)' \
		--header 'content-type: application/octet-stream' \
		http://localhost:8080/admin/schema | jq '.data.code'
else
	@echo "No schema.graphql found"
endif

schema-gql-auth: login-groot ## Load/update the auth'd GraphQL schema
ifneq (,$(wildcard ./schema-auth.graphql))
	@curl -sS --data-binary '@./schema-auth.graphql' \
		--header 'X-Dgraph-AccessToken: $(TOKEN)' \
		--header 'content-type: application/octet-stream' \
		http://localhost:8080/admin/schema | jq '.data.code'
else
	@echo "No schema-auth.graphql found"
endif

schema-gql-auth-mutate: login-groot ## Load/update query and mutation auth'd GraphQL schema
ifneq (,$(wildcard ./schema-auth-mutate.graphql))
	@curl -sS --data-binary '@./schema-auth-mutate.graphql' \
		--header 'X-Dgraph-AccessToken: $(TOKEN)' \
		--header 'content-type: application/octet-stream' \
		http://localhost:8080/admin/schema | jq '.data.code'
else
	@echo "No schema-auth.graphql found"
endif

drop-data: login-groot ## Drops all data (but not the schema)
	@curl -sS -X POST http://localhost:8080/alter --header 'X-Dgraph-AccessToken: $(TOKEN)' -d '{"drop_op": "DATA"}' | jq '.data.code'

load-data-dql-json: login-groot ## Loads data from the dql-data.json file
ifneq (,$(wildcard ./dql-data.json))
	curl --data-binary '@./dql-data.json' \
		--header 'content-type: application/json' \
		--header 'X-Dgraph-AccessToken: $(TOKEN)' \
		http://localhost:8080/mutate?commitNow=true
else
	@echo "No dql-data.json file found"
endif

update-farm-status-bob: login-bob ## Updates the status of a farm as bob
ifneq (,$(wildcard ./mutation-farm.status.gql))
	@echo "This should fail"
	@gql file --query-file mutation-farm.status.gql \
		--header 'X-Dgraph-AccessToken=$(TOKEN)' \
		--endpoint http://localhost:8080/graphql
else
	@echo "No mutation-farm.status.gql file found"
endif

update-farm-status-alice: login-alice ## Updates the status of a farm as alice
ifneq (,$(wildcard ./mutation-farm.status.gql))
	@gql file --query-file mutation-farm.status.gql --header 'X-Dgraph-AccessToken=$(TOKEN)' --endpoint http://localhost:8080/graphql
else
	@echo "No mutation-farm.status.gql file found"
endif

query-gql: ## Runs the query present in query.gql and variables in variables.json (requires gql)
ifeq (, $(shell which gql))
	@echo "No gql in $(PATH), download from https://github.com/matthewmcneely/gql/tree/feature/add-query-and-variables-from-file/builds"
else
	@echo "This should fail"
	@gql file --query-file query.gql --variables-file variables.json --endpoint http://localhost:8080/graphql
endif

query-gql-acl-auth: login-alice ## Runs the query present in query.gql with the JWT token in the header
ifeq (, $(shell which gql))
	@echo "No gql in $(PATH), download from https://github.com/matthewmcneely/gql/tree/feature/add-query-and-variables-from-file/builds"
else
	@echo "Issuing query with ACL-returned JWT token in header"
	@gql file --query-file query.gql --endpoint http://localhost:8080/graphql --header 'X-Dgraph-AccessToken=$(TOKEN)'
endif

# Runs the query present in query.graphql with the JWT token in the header
# Note the 32 byte secret was generated for this demo only. Do not use this in production (generate your own).
query-gql-auth-just-staff: login-bob
ifeq (, $(shell which jwt))
	@echo "No jwt in $(PATH), download from https://github.com/mike-engel/jwt-cli"
else
	@echo "Encoding claims in jwt.json"
	$(eval CLAIMS := $(shell cat jwt.json))
	$(eval JWT_TOKEN := $(shell jwt encode --secret vDK59uv+QxbuRpwdcFyYdTlLahaFDG0g2rf7+pc+jkk= '$(CLAIMS)'))
	@echo "Issuing query with JWT token in header"
	@gql file --query-file query.gql \
		--header X-myapp=$(JWT_TOKEN) \
		--header 'X-Dgraph-AccessToken=$(TOKEN)' \
		--endpoint http://localhost:8080/graphql 
endif

# Runs the query present in query.graphql with the JWT token in the header
# Note the 32 byte secret was generated for this demo only. Do not use this in production (generate your own).
query-gql-auth-experimental: login-bob
ifeq (, $(shell which jwt))
	@echo "No jwt in $(PATH), download from https://github.com/mike-engel/jwt-cli"
else
	@echo "Encoding claims in jwt.json"
	$(eval CLAIMS := $(shell cat jwt-experimental.json))
	$(eval JWT_TOKEN := $(shell jwt encode --secret vDK59uv+QxbuRpwdcFyYdTlLahaFDG0g2rf7+pc+jkk= '$(CLAIMS)'))
	@echo "Issuing query with JWT token in header"
	@gql file --query-file query.gql \
		--header X-myapp=$(JWT_TOKEN) \
		--header 'X-Dgraph-AccessToken=$(TOKEN)' \
		--endpoint http://localhost:8080/graphql 
endif

query-farms: login-bob ## Runs the query present in query-farms.gql
ifeq (, $(shell which gql))
	@echo "No gql in $(PATH), download from https://github.com/matthewmcneely/gql/tree/feature/add-query-and-variables-from-file/builds"
else
	@gql file --query-file query-farms.gql --header 'X-Dgraph-AccessToken=$(TOKEN)' --endpoint http://localhost:8080/graphql
endif


help: ## Print target help
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'