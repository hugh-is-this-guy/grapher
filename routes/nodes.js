(function() {
  var dbURL, queryDatabase, request;

  request = require("superagent");

  dbURL = process.env.GRAPHENEDB_URL || "http://localhost:7474";

  dbURL += "/db/data/cypher";

  queryDatabase = function(q) {
    return request.post(dbURL).send({
      query: q
    }).end(function(neo4jRes) {
      var people, response, result, results;
      results = JSON.parse(neo4jRes.text);
      console.log("text" + neo4jRes.text);
      console.log("parsed text" + results);
      people = (function() {
        var _i, _len, _ref, _results;
        _ref = results.data;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          result = _ref[_i];
          _results.push({
            'id': result[0].data.id,
            'name': result[0].data.name
          });
        }
        return _results;
      })();
      console.log("people:" + people);
      response = {
        meta: people.length,
        people: people
      };
      console.log("my JSON" + JSON.stringify(response));
      return response;
    });
  };

  exports.findAll = function(req, res) {
    var query;
    query = "MATCH (n) RETURN n;";
    return res.json(queryDatabase(query));
  };

  exports.findByName = function(req, res) {
    var query;
    query = "MATCH (n) WHERE n.name =~ '(?i).*" + req.params.name + ".*' RETURN n;";
    return res.json(queryDatabase(query));
  };

  exports.findById = function(req, res) {
    var query;
    query = "MATCH (n) WHERE n.id = " + req.params.id + " RETURN n;";
    return res.json(queryDatabase(query));
  };

}).call(this);
