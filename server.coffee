http   = require "http"
fs     = require "fs"
brow   = require "browserver"
engine = require "engine.io"
coffee = require "coffee-script"
router = require "browserver-router"

app = fs.readFileSync "#{__dirname}/app.coffee", "utf8"

assets =
  engine:      fs.readFileSync "#{__dirname}/node_modules/engine.io-client/dist/engine.io.js"
  domo:        fs.readFileSync "#{__dirname}/domo.js"
  browserver:  fs.readFileSync "#{__dirname}/node_modules/browserver/node_modules/browserver-client/browserver.js"
  router:      fs.readFileSync "#{__dirname}/node_modules/browserver-router/index.js"
  app:         coffee.compile app

client = Buffer """
  <!doctype html>
  <html>
    <head>
      <title>෴ browserver: a node.js HTTP server, in your browser</title>
    </head>
    <body style="background-color:#eee">
      <script>#{assets.engine}</script>
      <script>#{assets.domo}</script>
      <script>#{assets.browserver}</script>
      <script>http.STATUS_CODES = #{JSON.stringify http.STATUS_CODES}</script>
      <script>#{assets.router}</script>
      <script>#{assets.app}</script>
    </body>
  </html>
"""

http.globalAgent?.maxSockets = Infinity
httpServer = http.createServer()

httpServer.on "request", router
  "/":
    GET: (req, res) ->
      res.writeHead 200
        "Content-Type": "text/html; charset=utf8"
        "Content-Length": client.length

      res.end client

wsServer = engine.attach httpServer

browServer = new brow.Server
browServer.listen httpServer, "*.browserver.org"
browServer.listen wsServer

updateCount = ->
  serverCount = String Object.keys(browServer.servers).length

  for name, server of browServer.servers
    req = http.request
      method: "PUT"
      headers:
        host: name
        "content-type": "text/plain"
      path: "/server-count"

    req.end serverCount

browServer.on "connection", updateCount
browServer.on "disconnection", updateCount

httpServer.listen 80, ->
  {port, address} = do @address

  console.log "now running at http://#{address}:#{port}/"

# process.on "uncaughtException", (err) ->
#   console.error err.message, err.stack
