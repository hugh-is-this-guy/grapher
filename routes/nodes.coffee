request = require("superagent")

dbURL = process.env.GRAPHENEDB_URL or "http://localhost:7474"
dbURL += "/db/data/cypher"


getNodes = (q, callback, params) ->
  message = {
    query: q
  }
  message.params = params if params?

  request.post(dbURL).send(message).end (neo4jRes) ->

    results = JSON.parse neo4jRes.text

    people = if results.data? then (
      {
        id  : result[0].data.id,
        name: result[0].data.name
      } for result in results.data
    ) else []

    response = {
      meta: {
        number_of_people: people.length
      }
      people: people 
    }

    callback response

getRelationships = (q, callback, params) ->
  message = {
    query: q
  }
  message.params = params if params?

  request.post(dbURL).send(message).end (neo4jRes) ->

    console.log neo4jRes.text

    results = JSON.parse neo4jRes.text

    relationships = if results.data? then (
      {
        weight: result[0]
        node: {
          id:   result[1]
          name: result[2]
        }
      } for result in results.data
    ) else []

    response = {
      meta: {
        node: {
          id: params.id
        }
        number_of_relationships: relationships.length
      }
      relationships: relationships 
    }

    callback response

exports.findAll = (req, res) ->
  console.log 'All nodes requested.'
  query = "MATCH (n) RETURN n ORDER BY n.name;"
  getNodes query, (response) ->
    res.json response

exports.findByName = (req, res) ->
  name = req.params.name
  console.log "Search for name: #{name}"
  query = "MATCH (n) WHERE n.name =~ { regex } RETURN n ORDER BY n.name;"
  params =
    regex : "(?i).*#{ name }.*"

  callback = (response) ->
    res.json response
  getNodes query, callback, params

exports.getLocalGraph = (req, res) ->
  console.log "Search for id: #{req.params.id}"

  query = "MATCH (n)-[r]-(f) WHERE n.id = { id } RETURN r.weight, f.id, f.name;"
  params =
    id: +req.params.id

  callback = (response) ->
    res.json response

  getRelationships query, callback, params

exports.getOutwardsLocalGraph = (req, res) ->
  console.log "Search for id: #{req.params.id}"

  query = "MATCH (n)-[r]->(f) WHERE n.id = { id } RETURN r.weight, f.id, f.name;"
  params =
    id: +req.params.id

  callback = (response) ->
    res.json response

  getRelationships query, callback, params

exports.getInwardsLocalGraph = (req, res) ->
  console.log "Search for id: #{req.params.id}"

  query = "MATCH (n)<-[r]-(f) WHERE n.id = { id } RETURN r.weight, f.id, f.name;"
  params =
    id: +req.params.id

  callback = (response) ->
    res.json response

  getRelationships query, callback, params