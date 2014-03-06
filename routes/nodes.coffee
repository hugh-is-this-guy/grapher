request = require("superagent")

dbURL = process.env.GRAPHENEDB_URL or "http://localhost:7474"
dbURL += "/db/data/cypher"


queryDatabase = (q, callback, params) ->
  message = {
    query: q
  }
  message.params = params if params?

  request.post(dbURL).send(message).end (neo4jRes) ->

    results = JSON.parse neo4jRes.text

    people = if results.data? then (
      {
        'id'  : result[0].data.id,
        'name': result[0].data.name
      } for result in results.data
    ) else []

    response = {
      meta: {
        number_of_people: people.length
      }
      people: people 
    }

    callback response

exports.findAll = (req, res) ->
  console.log 'All nodes requested.'
  query = "MATCH (n) RETURN n ORDER BY n.name;"
  queryDatabase query, (response) ->
    res.json response

exports.findByName = (req, res) ->
  name = req.params.name
  console.log "Search for name: #{name}"
  query = "MATCH (n) WHERE n.name =~ { regex } RETURN n ORDER BY n.name;"
  params =
    regex : "(?i).*#{ name }.*"

  callback = (response) ->
    res.json response
  queryDatabase query, callback, params

exports.findById = (req, res) ->
  console.log "Search for id: #{req.params.id}"

  query = "MATCH (n) WHERE n.id = { id } RETURN n ORDER BY n.name;"
  params =
    id: +req.params.id

  callback = (response) ->
    res.json response

  queryDatabase query, callback, params



