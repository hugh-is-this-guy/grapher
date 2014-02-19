#
#   GET all nodes.      
#
request = require("superagent")

dbURL = process.env.GRAPHENEDB_URL or "http://localhost:7474"
dbURL += "/db/data/cypher"

exports.findAll = (req, res) ->
  request.post(dbURL).send(
    query: "MATCH (n) RETURN n;"
  ).end (neo4jRes) ->
    res.send neo4jRes.text

exports.findByName = (req, res) ->
  request.post(dbURL).send(
    query: "MATCH (node {name: {name}}) RETURN node;",
    params:
      name: req.params.name
  ).end (neo4jRes) ->
    nodes = neo4jRes.text
    res.json neo4jRes.text
#  res.send name:req.params.name