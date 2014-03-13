request = require("superagent")

dbURL = process.env.GRAPHENEDB_URL or "http://localhost:7474"
dbURL += "/db/data/cypher"




exports.findAll = (req, res) ->
  console.log 'All nodes requested.'
  query = "MATCH (n) RETURN n ORDER BY n.name;"
  getNodes query, (response) ->
    res.json response

exports.findByName = (req, res) ->
  name = req.params.name
  console.log "Search for name: #{name}"
  query = "MATCH (n) 
            WHERE n.name =~ { regex } 
            RETURN n 
            ORDER BY n.name;"
  params =
    regex : "(?i).*#{ name }.*"

  callback = (response) ->
    res.json response
  getNodes query, callback, params




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





exports.getRelations = (req, res) ->
  console.log "Get all relations for node #{req.params.id}"

  query = "MATCH (n)-[r]-(f) 
            WHERE n.id = { id } 
            RETURN r.weight, f.id, f.name 
            ORDER BY r.weight DESC;"
  params =
    id: +req.params.id

  callback = (response) ->
    res.json response

  getRelations query, callback, params



getRelations = (q, callback, params) ->
  message = {
    query: q
  }
  message.params = params if params?

  request.post(dbURL).send(message).end (neo4jRes) ->

    results = JSON.parse neo4jRes.text

    relationships = if results.data? then (
      {
        node:
          id:   result[1]
          name: result[2]
        weight: result[0]
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





exports.getPaths = (req, res) ->
  from  = +req.params.from
  to    = +req.params.to
  console.log "Get path from #{from} to #{to}"
  query = "MATCH (from {id: { from } }), (to {id: { to } }) 
            MATCH p = (from)-[r:Knows*0..3]-(to)
            RETURN extract(n in NODES(p)| n.name),
                   extract(n in NODES(p)| n.id),
                   extract(k in RELATIONSHIPS(p)| k.weight)
            ORDER BY length(p)
            LIMIT 10"
  params =
    from: from
    to  : to

  callback = (response) ->
    res.json response

  getPaths query, callback, params


getPaths = (q, callback, params) ->
  message = {
    query: q
  }
  message.params = params

  request.post(dbURL).send(message).end (neo4jRes) ->

    results = JSON.parse neo4jRes.text
    console.log results

    response =
      from:   params.from
      to:     params.to
      paths:  []

    for result in results.data
      names   = result[0]
      ids     = result[1]
      weights = result[2]

      path = 
        nodes         : []
        relationships : []

      for name, i in names
        node =
          name: name
          id  : ids[i]
        
        path.nodes.push node

      for weight, i in weights
        relationship = 
          source : ids[i]
          target : ids[i+1]
          weight : weight

        path.relationships.push relationship
        
      response.paths.push path

    callback response
