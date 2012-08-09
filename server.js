var http = require("http")
var fs = require("fs")

var brow       = require("brow")
var browClient = require("brow-client")
var engine     = require("engine.io")

var httpServer = http.createServer(onRequest)
var wsServer   = engine.attach(httpServer)
var browServer = new brow.Server({
  http: httpServer,
  ws: wsServer,
  host: "*.browserver.org"
})

var client = new Buffer(
  "<!doctype html>\n" +
    "<head>" +
      "<script>" + fs.readFileSync(__dirname + "/node_modules/engine.io-client/dist/engine.io.js", "utf8") + "</script>\n" +
      "<script>" + fs.readFileSync(__dirname + "/domo.js", "utf8") + "</script>\n" +
      "<script>" + browClient.source + "</script>\n" +
      "<script>" + fs.readFileSync(__dirname + "/client.js", "utf8") + "</script>\n" +
    "</head>" +
    "<body>LOADING...</body>" +
  "</html>"
)

browServer.on("connection", function(client) {
  var hostname = client.id + ".browserver.org"

  var opts = {
    method: "PUT",
    headers: {host: hostname},
    port: process.env.PORT,
    path: "/localhost"
  }

  var req = http.request(opts)
  req.write(hostname)
  req.end()
})

function onRequest(req, res) {
  if (req.url == "/") {
    res.writeHead(200, {
      "Content-Type": "text/html; charset=utf8",
      "Content-Length": client.length
    })

    return res.end(client)
  }

  res.writeHead(404, {
    "Content-Type": "text/plain",
    "Content-Length": 10
  })

  res.end("Not found\n")
}

httpServer.listen(process.env.PORT || 8001)
