const fs = require("fs");

function getPrediction(predictionContext, events, done) {
	predictionContext.vars.example_id = Math.round(Math.random() * 18);
	// random user
	predictionContext.vars.user_id = Math.round(Math.random() * 10000) + 1;
	done();
}

function printStatus(requestParams, response, context, ee, next) {
	if (response.statusCode > 300) {
		console.log(`${response.statusCode}: ${response.body}`);
		// console.log(requestParams);
		fs.appendFileSync(
			"errors.txt",
			`${response.statusCode}: ${response.body}, ${JSON.stringify(requestParams.json)} \n`,
		);
	}
	return next();
}

module.exports = { getPrediction, printStatus };
