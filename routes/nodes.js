/*
	GET all nodes.		
*/
request = require("superagent");

exports.list = function(req, res) {
	dbURL = process.env.GRAPHENEDB_URL + "db/data" || "http://localhost:7474/db/data";
	console.log(dbURL);
	request.post(dbURL + '/cypher').send({
		query: 'MATCH (n) RETURN n;'
	}).end(function(neo4jRes) {
		console.log(neo4jRes);
		res.send(neo4jRes.text);
	});
};