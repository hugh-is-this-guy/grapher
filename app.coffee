
# Module dependencies.
express = require("express")
routes = require("./routes")
user = require("./routes/user")
http = require("http")
path = require("path")
neo4f = require("neo4j")

app = express()
port = process.env.PORT or 3000

# all environments
app.set "views", path.join(__dirname, "views")
app.set "view engine", "jade"
app.use express.favicon()
app.use express.logger("dev")
app.use express.json()
app.use express.urlencoded()
app.use express.methodOverride()
app.use app.router
app.use require("stylus").middleware(path.join(__dirname, "public"))
app.use express.static(path.join(__dirname, "public"))

# development only
app.use express.errorHandler()  if "development" is app.get("env")
app.get "/", routes.index
app.get "/users", user.list

app.listen port, ->
  console.log "Listening on port" + port
