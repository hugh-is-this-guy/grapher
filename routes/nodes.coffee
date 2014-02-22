#
#   GET all nodes.      
#
request = require("superagent")

dbURL = process.env.GRAPHENEDB_URL or "http://localhost:7474"
dbURL += "/db/data"

exports.findAll = (req, res) ->
  request.post(dbURL + "cypher").send(
    query: "MATCH (n) RETURN n;"
  ).end (neo4jRes) ->
    res.send neo4jRes.text

exports.findByName = (req, res) ->
  dbURL += '/cypher'
  request.post(dbURL + "/cypher").send(
    query: "MATCH (n {name: {name}}) RETURN n;",
    params:
      name: req.params.name
  ).end (neo4jRes) ->
    res.json neo4jRes.text

exports.findById = (req, res) ->
  id = req.params.id
  request.get(dbURL + '/node/' + id)
  .end (neo4jRes) ->
    res.json neo4jRes.text
