// web.js
var express = require("express");
var logfmt = require("logfmt");
var neo4j = require("neo4j");

var app = express();
var db = new neo4j.GraphDatabase("GRAPHENEDB_URL");


app.use(logfmt.requestLogger());

app.get('/', function(req, res) {
  res.send(db + 'Hello Manthan!');
});

var port = Number(process.env.PORT || 5000);
app.listen(port, function() {
  console.log("Listening on " + port);
});
