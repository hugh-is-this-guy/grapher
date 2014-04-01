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
    params: params
    query : query
  }

  request.post(dbURL).send(message).end (neo4jRes) ->
    result = JSON.parse neo4jRes.text
    name   = result.data[0][0]
    callback name



exports.getCluster = (req, res) ->
  id    = +req.params.id

  
  callback = (name) ->
    root  = new Node id, name

    graph = new Graph root
    graph.cluster (nodes, links) ->
      res.json {nodes: nodes, links: links}
  

  getName id, callback



class Graph
  constructor: (@root) ->
    @nodes = [root]
    @links = []
    @rejected = []
    self = @

    @factorial = (n) ->
      return 0 if n < 0
      return 1 if n == 0 or n == 1
      return n * @factorial(n - 1)

    @permutations = (n) ->
      top = @factorial n
      bottom = (@factorial(n - 3) * 6)
      top / bottom

    @getStrongestNeighbour = (n, skip, callback) ->
      params =
        id    : n.id
        skip  : skip

      query = "MATCH (a { id: {id}})-[r]-(b)
        RETURN b.id, b.name, r.weight
        ORDER BY r.weight DESC
        SKIP {skip}
        LIMIT 1"

      message = {
        params: params
        query : query
      }

      request.post(dbURL).send(message).end (neo4jRes) ->
        result    = JSON.parse neo4jRes.text
        id        = result.data[0][0]
        name      = result.data[0][1]
        strength  = result.data[0][2]
        node      = new Node id, name
        callback node, strength


    @getNextNode = (callback) ->
      friendof      = 0
      i             = 0
      nextNode      = null
      nextstrength  = 0
      skip          = 0

      continueLoop = ->
        if i == self.nodes.length
          callback nextNode, self.nodes[friendof], nextstrength
          return


        self.getStrongestNeighbour self.nodes[i], skip, (node, strength) ->
          # If returned node already in list, get next strongest
          if not node?
            do continueLoop
            return
          if ((n for n in self.nodes when n.id is node.id)[0])? or ((n for n in self.rejected when n.id is node.id)[0])?
            skip++
            do continueLoop
            return

          skip = 0

          if strength > nextstrength
            nextstrength  = strength
            nextNode      = node
            friendof      = i

          
          i++
          do continueLoop
          return

      # Start loop
      do continueLoop



    @getCoefficientVals = (node, callback) ->
      query = "MATCH (a { id: {id}})--(b)
                WITH a, count(DISTINCT b) AS triplets
                MATCH (a)--()-[r]-()--(a)
                RETURN triplets, count(DISTINCT r) AS triangles"      

      params = {
        id: node.id
      }


      message = {
        query   : query
        params  : params
      }

      request.post(dbURL).send(message).end (neo4jRes) ->
        result    = JSON.parse neo4jRes.text
        if not result.data? or result.data.length == 0
          callback 0, 0
          return
        triplets  = result.data[0][0] 
        triangles = result.data[0][1]
        callback triplets, triangles



    @calcCoefficient = (nodes, callback) ->
      totalTriplets   = 0
      totalTriangles  = 0

      i    = 0
      self = @

      continueLoop = ->
        if i == nodes.length
          coefficient = totalTriangles / totalTriplets
          callback coefficient
          return
        self.getCoefficientVals nodes[i], (triplets, triangles) ->
          triplets = if triplets then self.permutations triplets else triplets
          totalTriplets   += triplets
          totalTriangles  += triangles
          
          i++
          do continueLoop
          return

      do continueLoop        




  cluster: (callback) ->
    self  = @

    coefficient = 0
    count       = 0
    limit       = 30


    continueLoop = ->

      if count == limit 
        callback self.nodes, self.links
        return
      self.getNextNode (newnode, friendof, strength) ->
        newnodes = (n for n in self.nodes)
        newnodes.push newnode

        self.calcCoefficient newnodes, (newcoefficient) ->
          if newcoefficient >= coefficient
            coefficient = newcoefficient
            self.nodes = newnodes
            self.links.push new Link newnode, friendof, strength
          else
            self.rejected.push newnode
          count++
          console.log "count: #{count}"
          do continueLoop
          return

    do continueLoop





class Node
  constructor: (@id, @name) ->



class Link
  constructor: (source, target, @weight) ->
    # Source is always the lower of the two ids, to aid in the comparisson of
    # two links.
    @source = if source.id < target.id then source else target
    @target = if source.id > target.id then source else target