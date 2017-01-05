var express = require('express');
var app = express();
var port = 3000;

app.get('/slow', function (req, res) {
    var seconds = req.query.seconds || 1;

    res.send(`
        <!DOCTYPE html>
        <html>
            <body>
                <h1>Loading for ${seconds} second${seconds > 1 ? 's' : ''}</h1>
                <img alt="I am jack's slow loading resource" src="/loadingFor?seconds=${seconds}" />
            </body>
        </html>
    `);
});


app.get('*', function (req, res) {
	var startTime = Date.now();
	var wait = (req.query.seconds) ? req.query.seconds * 1000 : 1000 * 60;

	var intervalID = setInterval(function () {
		var endTime = Date.now();
		var timeElapsed = endTime - startTime;

		if (timeElapsed > wait) {
			res.send({ hello: 'there', startTime, endTime });
			return clearInterval(intervalID);
		}
	}, 1000);
});



var server = app.listen(port, function () {
	console.log(`Running! on http://localhost:%s`, port);
	console.log(`Invoke like this http://localhost:%s/slow?seconds=10`, port)
});
