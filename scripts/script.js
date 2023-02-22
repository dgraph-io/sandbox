async function newAuthor({args, graphql}) {
    if (!args.name || args.name.length < 3) {
        console.log("Error: Author name must be at least 3 characters long.")
        return null
    }
    if (!args.reputation || args.reputation == 0.0) {
        console.log("Error: Author reputation must be greater than 0.")
        return null
    }
    const results = await graphql(`mutation ($name: String!, $reputation: Float!) {
        addAuthor(input: [{name: $name, reputation: $reputation}]) {
            author {
                id
                name
                reputation
            }
        }
    }`, {
        "name": args.name, 
        "reputation": args.reputation
    })
    return results.data.addAuthor.author[0]
}

async function authorsByName({args, dql}) {
    const results = await dql.query(`query queryAuthor($name: string) {
        queryAuthor(func: type(Author)) @filter(eq(Author.name, $name)) {
            name: Author.name
            reputation: Author.reputation
        }
    }`, {"$name": args.name})
    console.log('results--------------\n', results)
    return results.data.queryAuthor
}

const authorBio = ({parent: {name, reputation}}) => `My name is ${name} and my reputation is ${reputation}.`

self.addGraphQLResolvers({
    "Author.bio": authorBio,
    "Mutation.newAuthor": newAuthor,
    "Query.authorsByName": authorsByName,
})
