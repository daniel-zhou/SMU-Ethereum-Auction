let express = require('express');

let server = express();
server.use('/', express.static(__dirname + '/'));
server.use('/contracts/', express.static(__dirname + '/../build/contracts/'));
server.listen(8080);
