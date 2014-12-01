var http = require('http'),
    config = require('nconf').argv().env(),
    Radar = require('radar').server;

var httpServer = http.createServer(function(req, res) {
    res.end('Nothing here.');
});

// Radar server
var radar = new Radar();
radar.attach(httpServer, { redis_host: config.get('REDIS_HOST'), redis_port: config.get('REDIS_PORT') });

httpServer.listen(80);
