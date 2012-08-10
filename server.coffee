http   = require "http"
fs     = require "fs"
brow   = require "brow"
engine = require "engine.io"

clientLibs =
  spin:       fs.readFileSync "#{__dirname}/lib/spin.min.js"
  coffee:     fs.readFileSync "#{__dirname}/lib/coffee-script.js"
  engine:     fs.readFileSync "#{__dirname}/node_modules/engine.io-client/dist/engine.io.js"
  domo:       fs.readFileSync "#{__dirname}/lib/domo.js"
  browserver: fs.readFileSync "#{__dirname}/node_modules/brow-client/browserver.js"
  app:        fs.readFileSync "#{__dirname}/app.coffee"

client = Buffer """
  <!doctype html>
  <html>
  <head>
  <title>෴ browserver: a node.js HTTP server, in your browser</title>
  </head>
  <body>
  <script>#{clientLibs.coffee}</script>
  <script>#{clientLibs.engine}</script>
  <script>#{clientLibs.domo}</script>
  <script>#{clientLibs.browserver}</script>
  <script type="text/coffeescript">
  #{clientLibs.app}
  </script>
  </body>
  </html>
"""

httpServer = http.createServer()
wsServer   = engine.attach httpServer
browServer = new brow.Server
  http: httpServer
  ws: wsServer
  host: "*.browserver.org"

browServer.on "connection", (client) ->
  host = "#{client.id}.browserver.org"

  opts =
    method: "PUT"
    headers: {host}
    port: process.env.PORT
    path: "/localhost"

  req = http.request opts
  req.write host
  req.end()

httpServer.on "request", (req, res) ->
  if req.url is "/"
    res.writeHead 200
      "Content-Type": "text/html; charset=utf8"
      "Content-Length": client.length

    return res.end client

  res.writeHead 404
    "Content-Type": "text/plain"
    "Content-Length": 10

  res.end "Not found\n"

httpServer.listen process.env.PORT || 8000
