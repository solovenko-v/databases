import express from 'express'
import { postgraphql } from 'postgraphql'

const compression = require('compression')

const app = express()

const PORT = 4000

const pgql_config = {
  user: 'ac_postgraphql',
  password: 'MAvpHSpoKqsxU5lp6v9y',
  host: 'localhost',
  port: 5432,
  database: 'admission_campaign'
}

const pgql_schemas = ['common', 'main', 'forum']

const pgql_options = {
  graphiql: true,
  pgDefaultRole: 'ac_anonymous',
  jwtSecret: 'keyboard_kitten',
  jwtPgTypeIdentifier: 'common.jwt_token'
}

app.use(compression({ filter: shouldCompress }))
app.use(postgraphql(pgql_config, pgql_schemas, pgql_options))
app.use(express.static('../client/build'))

app.listen(PORT, () =>
  console.log(`GraphQL Server is now running on http://localhost:${PORT}`)
)

function shouldCompress(req, res) {
  if (req.headers['x-no-compression']) {
    // don't compress responses with this request header
    return false
  }
  // fallback to standard filter function
  return compression.filter(req, res)
}
