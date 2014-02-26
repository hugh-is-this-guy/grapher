request = require("superagent")

dbURL = process.env.GRAPHENEDB_URL or "http://localhost:7474"
dbURL += "/db/data/cypher"


queryDatabase = (q, callback) ->
  request.post(dbURL).send(
    query: q
  ).end (neo4jRes) ->
    results = JSON.parse neo4jRes.text

    console.log "text" + neo4jRes.text
    console.log "parsed text" + results

    people = (
      {
        'id'  : result[0].data.id,
        'name': result[0].data.name
      } for result in results.data
    )

    console.log "people:" +  people

    response = {  
      meta:   people.length,
      people: people 
    }

    console.log "my JSON" + JSON.stringify response

    callback response

exports.findAll = (req, res) ->
  query = "MATCH (n) RETURN n;"
  queryDatabase query, (response) ->
    console.log response
    res.json response

exports.findByName = (req, res) ->
  query = "MATCH (n) WHERE n.name =~ '(?i).*" + req.params.name + ".*' RETURN n;"
  queryDatabase query, (response) ->
    console.log response
    console.log 'HELLO'
    res.json response

exports.findById = (req, res) ->
  query = "MATCH (n) WHERE n.id = " + req.params.id + " RETURN n;"
  queryDatabase query, (response) ->
    console.log response
    res.json response



