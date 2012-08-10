http   = require "http"
fs     = require "fs"
brow   = require "brow"
engine = require "engine.io"
coffee = require "coffee-script"

appCoffee = fs.readFileSync "#{__dirname}/app.coffee", "utf8"

clientLibs =
  engine:     fs.readFileSync "#{__dirname}/node_modules/engine.io-client/dist/engine.io.js"
  domo:       fs.readFileSync "#{__dirname}/domo.js"
  browserver: fs.readFileSync "#{__dirname}/node_modules/brow-client/browserver.js"
  app:        coffee.compile appCoffee

client = Buffer """
  <!doctype html>
  <html>
  <head>
  <title>෴ browserver: a node.js HTTP server, in your browser</title>
  <script>#{clientLibs.engine}</script>
  <script>#{clientLibs.domo}</script>
  <script>#{clientLibs.browserver}</script>
  <script>
  #{clientLibs.app}
  </script>
  </head>
  <body style="background-color:#eee">
    Loading the app... If this message doesn't go away within 10 seconds, it means that the server crashed under heavy load. Please refresh mercilessly.
  </body>
  </html>
"""

httpServer = http.createServer()

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

wsServer = engine.attach httpServer

browServer = new brow.Server
  http: httpServer
  ws: wsServer
  host: "*.browserver.org"

browServer.on "connection", (client) ->
  console.log "#{Object.keys(this.clients).length} connected."

  client.socket.on "timeout", ->
    console.log "client timeout", client

  client.on "error", console.log

  host = "#{client.id}.browserver.org"

  opts =
    method: "PUT"
    headers: {host}
    path: "/localhost"

  req = http.request opts
  req.write host
  req.end()

httpServer.listen process.env.PORT, ->
  console.log "now running at http://localhost:#{@address().port}/"

process.on "uncaughtException", console.log
