!function() {
  var ws = new eio.Socket({host: location.hostname, port: location.port})

  var server = http.createServer(function(req, res) {
    var parts = req.url.split("?")

    req.pathname = parts[0]
    req.search = parts[1]

    var route = routes[req.pathname]

    if (!route) {
      res.writeHead(404, {"Content-Type": "text/plain"})
      return res.end("Not found")
    }

    var handler = route[req.method]

    if (!handler) {
      res.writeHead(405, {"Content-Type": "text/plain"})
      return res.end("Method not allowed")
    }

    handler.call(this, req, res)
  })

  server.listen(ws)

  function render(data) {
    return HTML({lang: "en"},
      HEAD({},
        TITLE("෴ browserver: a node.js webserver in your browser ෴"),

        LINK({
          href: "//fonts.googleapis.com/css?family=Open+Sans:400,800",
          rel: "stylesheet",
          type: "text/css"
        }),

        STYLE({type: "text/css"},
          CSS("*", {
            margin: 0,
            padding: 0
          }),

          CSS("#container", {
            fontSize: "1.25em",
            width: 700,
            margin: "0 auto"
          }),

          CSS("#brow", {
            marginTop: -250,
            fontSize: 600,
            textAlign: "center"
          }),

          CSS("h1", {
            marginTop: -200,
            textAlign: "center",
            fontFamily: "'Open Sans', sans-serif",
            fontSize: 100,
            fontWeight: 800
          }),

          CSS("h2", {
            marginTop: -20,
            textAlign: "center",
            fontFamily: "'Open Sans', sans-serif",
            fontSize: 32
          }),

          CSS("p", {
            fontFamily: "'Open Sans', sans-serif",
            fontSize: "1.3em"
          })
        )
      ),

      BODY({},
        A({href: "https://github.com/jed/browserver-client"},
          IMG({
            style: "position: absolute; top: 0; right: 0; border: 0;",
            src: "https://s3.amazonaws.com/github/ribbons/forkme_right_gray_6d6d6d.png",
            alt: "Fork me on GitHub"
          })
        ),

        DIV({id: "container"},
          DIV({id: "brow"}, "෴"),

          H1("browserver"),
          H2("a node.js HTTP server in your browser"),

          DIV({}, A({href: "http://" + data.host}, "http://" + data.host)),

          PRE(
            "say `curl " + data.host + "/ask?q=" + encodeURIComponent("What is your name?") + "`"
          ),

          PRE(
            "curl " + data.host + "/geolocation"
          ),

          PRE(
            "curl -X POST " + data.host + "/rickroll"
          ),

          P(
            {id: "blurry"},
            "For example, to blur this text, enter the following in " +
            "your terminal:"
          ),

          PRE(
            "curl -X PATCH " + data.host + "/style \\",
            BR({}),
            "  -d color=transparent \\",
            BR({}),
            "  -d text-shadow=\"0 0 5px rgba(0,0,0,0.5)\""
          )
        )
      )
    )
  }

  var routes = {
    "/localhost": {
      PUT: function(req, res) {
        document.replaceChild(
          render({host: req.body}),
          document.documentElement
        )

        res.writeHead(204)
        res.end()
      }
    },

    "/ask": {
      GET: function(req, res) {
        var match    = req.search.match(/(?:^|&)q=(.+?)(?:$|&)/)
        var question = match && decodeURIComponent(match[1])
        var answer   = window.prompt(question)

        res.writeHead(200, {"Content-Type": "text/plain"})
        res.end(answer + "\n")
      }
    },

    "/geolocation": {
      GET: function(req, res) {
        if ("geolocation" in navigator) {
          navigator.geolocation.getCurrentPosition(success, failure)
        }

        else {
          res.writeHead(501, {"Content-Type": "text/plain"})
          return res.end("Not implemented")
        }

        function success(position) {
          res.writeHead(200, {"Content-Type": "text/plain"})
          res.end(
            "Latitude: " + position.coords.latitude + "\n" +
            "Longitude: " + position.coords.longitude + "\n"
          )
        }

        function failure() {
          res.writeHead(403, {"Content-Type": "text/plain"})
          res.end("Forbidden")
        }
      }
    },

    "/style": {
      PATCH: function(req, res) {
        var styles = req.body.split("&")
        var i = styles.length
        var parts, name, value

        while (i--) {
          parts = styles[i].split("=")

          name = parts[0].replace(/-[a-z]/g, function(str) {
            return str.slice(1).toUpperCase()
          })

          value = decodeURIComponent(parts[1])

          document.getElementById("blurry").style[name] = value
        }

        res.writeHead(204)
        res.end()
      }
    },

    "/rickroll": {
      POST: function(req, res) {
        var win = window.open("http://www.youtube.com/watch?v=oHg5SJYRHA0")

        if (win) {
          res.writeHead(204)
          res.end()
        }

        else {
          res.writeHead(403, {"Content-Type": "text/plain"})
          res.end("Forbidden")
        }
      }
    }
  }
}()
