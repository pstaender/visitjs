"use strict"

var request = require('request');
var concat = require('concat-stream');
var JSONBuffer = require('json-buffer');
var spawnSync = require('child_process').spawnSync;

var asyncRequest = function(url, method, options, cb) {
  if (!method) method = 'GET';
  method = method.toUpperCase();
  if (!options) options = {};
  if (!options.url) options.uri = url;
  if (!options.method) options.method = method;
  request(options, cb);
};

var syncRequest = function(url, method, options, cb) {
  if (!method) method = 'GET';
  method = method.toUpperCase();
  if (!options) options = {};
  if (!options.url) options.uri = url;
  if (!options.method) options.method = method;
  var params = JSON.stringify({
    url: url,
    method: method,
    options: options
  });
  var spawnRes = spawnSync(process.execPath, [require.resolve('./request.js')], { input: params });
  var res = JSONBuffer.parse(spawnRes.stdout);
  if (res.error) {
    var e = new Error("Error by getting response: \n" + JSON.stringify(res.error, null, '  '));
    e.data = res.error;
    throw e;
  } else {
    return res;
  }
  //return JSONBuffer.parse(spawnRes.stdout);
};

var lastArgument = process.argv[process.argv.length-1];

if (!process.stdin.isTTY) {

  function pipeStdout(data, status) {
    if (typeof status === 'undefined') status = 0;
    process.stdout.write(JSON.stringify(data), function() {
      process.exit(status);
    });
  }

  process.stdin.pipe(concat(function (stdin) {
    var options = JSONBuffer.parse(stdin.toString());
    asyncRequest(options.url, options.method, options.options, function(err, res, body) {
      if (err) {
        pipeStdout({ error: err}, 1);
      } else {
        pipeStdout(res, 0);
      }
    });
  }));

} else {
  exports.syncRequest = syncRequest;
  exports.asyncRequest = asyncRequest;
}
