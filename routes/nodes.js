/*
	GET all nodes.		
*/
request = require("superagent");

exports.list = function(req, res) {
	dbURL = process.env.GRAPHENEDB_URL || "http://localhost:7474";
	request.post(dbURL + '/db/data/cypher').send({
		query: 'MATCH (n) RETURN n;'
	}).end(function(neo4jRes) {
		res.send(neo4jRes.text);
	});
};