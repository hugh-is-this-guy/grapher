request = require("superagent")
asynch  = require("asynch")

dbURL = process.env.GRAPHENEDB_URL or "http://localhost:7474"
dbURL += "/db/data/cypher"


exports.getNode = (req, res) ->
  console.log "Node #{req.params.id} requested."
  query = "MATCH (n) WHERE n.id = { id } RETURN n.name;"
  params =
    id: +req.params.id
  callback =  (response) ->
    res.json response

  getNode query, callback, params


getNode = (q, callback, params) ->
  message = {
    query : q
    params: params
  }

  request.post(dbURL).send(message).end (neo4jRes) ->

    results = JSON.parse neo4jRes.text

    response = {
      node: {
        id  : params.id
        name: results.data[0][0]
      }
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

  params =
    id  : +req.params.id

  optional = ""

  if req.params.minimum
   optional = " AND r.weight >= { minimum } "
   params.minimum = +req.params.minimum

  query = "MATCH (n)-[r]-(f) 
            WHERE n.id = { id } #{optional}
            RETURN r.weight, f.id, f.name 
            ORDER BY r.weight DESC;"


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
  max   = +req.params.max || 15

  console.log "Get maximum #{max} paths from #{from} to #{to}"

  query = "MATCH (from {id: { from }}), (to { id: { to } }) 
            MATCH p = (from)-[:Knows*0..3]-(to)
            WITH extract(n in nodes(p)| n.id) as ids,
                 extract(n in NODES(p)| n.name) as names,
                 extract(k in relationships(p)| k.weight) as weights,
                 length(p) as length
            RETURN ids, names, weights, length,
                   reduce(total=0, w in weights | total + w) as cost
            ORDER BY length, cost / length DESC
            LIMIT #{max}"
  params =
    from: from
    to  : to

  callback = (response) ->
    res.json response

  getPaths query, callback, params


getPaths = (q, callback, params) ->
  message = {
    query : q
    params: params
  }

  request.post(dbURL).send(message).end (neo4jRes) ->

    results = JSON.parse neo4jRes.text

    response =
      from:   params.from
      to:     params.to
      paths:  []

    for result in results.data
      ids     = result[0]
      names   = result[1]
      weights = result[2]
      length  = result[3]
      cost    = result[4]

      path =
        length        : length
        cost          : cost
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











#---------------THIS WAY DANGER LIES---------------#







getName = (id, callback) ->
  params = {
    id: id
  }
  query = "MATCH (n {id: {id}})
            RETURN n.name"

  message = {
    query : query
    params: params
  }

  request.post(dbURL).send(message).end (neo4jRes) ->
    result = JSON.parse neo4jRes.text
    name   = result.data[0][0]
    callback name



exports.getCluster = (req, res) ->
  id    = +req.params.id
  hasCluster id, (clustered) ->

    if not clustered
      console.log "Not clustered"
      cluster id, ->
        getCluster id, (response) ->
          res.json response
    else
      console.log "Clustered"
      getCluster id, (response) ->
        res.json response



hasCluster = (id, callback) ->

  query = "MATCH (n:Cluster#{id}) RETURN COUNT(n)"

  message = {
    query : query
  }

  request.post(dbURL).send(message).end (neo4jRes) ->
    result = JSON.parse neo4jRes.text
    callback result.data[0][0] > 0


cluster = (rootId, callback) ->
  console.log "Clustering"


  applyLabel = (id, label, callback) ->
    console.log "Applying label #{label} to node #{id}"
    query = "MATCH (n {id: {id}})
              SET n:#{label}"

    params = {
      id    : id
    }

    message = {
      query : query
      params: params
    }

    request.post(dbURL).send(message).end ->
      console.log "Label applied"
      do callback




  getNextNode = (callback) ->
    console.log "Getting next node"

    query = "MATCH (n:Cluster#{rootId})-[r]-(f)
              WHERE not 'Cluster#{rootId}' in LABELS(f)
              RETURN f.id
              ORDER BY r.weight
              LIMIT {limit}"

    params = {
      limit: rejected.length + 2
    }

    message = {
      query : query
      params: params
    }

    request.post(dbURL).send(message).end (neo4jRes)->
      results = JSON.parse neo4jRes.text

      # Return first node not in rejected list
      for result in results.data
        id = result[0]
        if id not in rejected
          callback id
          break


  calculateCoefficient = (callback) ->
    console.log "Calculating coefficient"
    callback 0.5


  initialiseCluster = (callback) ->
    console.log "Init-ing"

    # Add cluster label to root
    applyLabel rootId, label, ->
      console.log "Label applied to root"
    
      # As cluster coefficient can only be calc'ed on clusters 
      # of three or more, add two nodes to cluster
      count = 2
      continueLoop = ->
        console.log "Getting init node"
        getNextNode (id) ->
          applyLabel id, label, ->
            if --count
              do continueLoop 
            else
              do callback

      do continueLoop


  i = 0

  coefficient = 0
  cluster     = [rootId]
  rejected    = []

  label = "Cluster#{rootId}"

  initialiseCluster ->
    console.log "Init-ed"

    continueLoop = ->
      getNextNode (id) ->
        console.log "Next node: #{id}"
        applyLabel id, label, ->
          calculateCoefficient (newCoefficient) ->
            console.log "Coefficient = #{newCoefficient}"
            if newCoefficient >= coefficient
              console.log "Accepted! :)"
              cluster.push id
              coefficient = newCoefficient
            else
              console.log "Rejected :("
              rejected.push id
              removeLabel label, id

            if ++i < 5
              do continueLoop
            else
              console.log "Done! i = #{i}"
              do callback
  
    do continueLoop


getCluster = (id, callback) ->
  console.log "Getting cluster"
  callback {
    pleez: "You can haz cluster"
  }