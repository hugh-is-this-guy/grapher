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
app.get "/nodes/name/:name", nodes.findByName
app.get "/nodes/:id", nodes.findById


app.listen port, ->
  console.log "Listening on port " + port
  console.log "Database url: " + db.url
