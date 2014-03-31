# Module dependencies.
express     = require("express")
path        = require("path")
neo4j       = require("neo4j")
routes      = require("./routes")
nodes       = require("./routes/nodes")

app     = express()
port    = process.env.PORT or 3000
db      = new neo4j.GraphDatabase process.env.GRAPHENEDB_URL or "http://localhost:7474"


app.set "views", path.join(__dirname, "views")
app.set "view engine", "jade"
app.use express.favicon()
app.use app.router
app.use express.static(path.join(__dirname, "public"))

app.use require("connect-assets")()
app.locals.css = css
app.locals.js = js

app.get "/", routes.index
app.get "/nodes", nodes.findAll
app.get "/nodes/:id", nodes.getNode
app.get "/nodes/search/name/:name", nodes.findByName
app.get "/nodes/relations/:id/:minimum?", nodes.getRelations
app.get "/paths/:from/:to/:max?", nodes.getPaths


app.listen port, ->
  console.log "Listening on port " + port
  console.log "Database url: " + db.url
