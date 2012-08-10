render = ({host}) ->

  presentation = STYLE type: "text/css",

    CSS "body"
      backgroundColor: "#eee"
      color: "#333"
      fontFamily: "'Merriweather', serif"
      fontSize: "130%"
      lineHeight: "150%"

    CSS "a"
      color: "#C90707"

    CSS ".hostlink"
      textAlign: "center"

    CSS "p, table, .hostlink, pre, li"
      marginTop: "1em"

    CSS ".container"
      width: 600
      margin: "50px auto"

    CSS ".header"
      textAlign: "center"
      marginTop: 120
      marginBottom: 70

      CSS ".logo"
        marginBottom: 100
        fontSize: 300

      CSS "h1"
        fontSize: 72
        fontWeight: 900

    CSS ".well"
      borderRadius: 10
      padding: 15
      border: "2px solid #999"
      backgroundColor: "#fff"

  content = BODY {},
    A href: "https://github.com/jed/browserver-client",
      IMG
        style: "position: absolute; top: 0; right: 0; border: 0;"
        src: "https://s3.amazonaws.com/github/ribbons/forkme_right_gray_6d6d6d.png"
        alt: "Fork me on GitHub"

    DIV class: "container",
      DIV class: "header",
        DIV class: "logo",
          "෴"
        H1 "browserver"

      P {},
        "Hello! I've got some good news for you: your web browser has just been upgraded to a web "
        EM "server"
        ". It's responding to HTTP requests on the Internet as you read this."

      P "True story. You can try it yourself here:"

      DIV class: "hostlink well",
        A
          href: "http://#{host}"
          target: "_blank"

          "http://#{host}"

      P "Well, truth be told, the link above only returns a 404. But it was served by this very browser. Here's a list of the few requests it's served so far:"

      TABLE class: "well", width: "100%",
        TBODY id: "requests",
          TR {},
            TD "1."
            TD "PUT /localhost"
            TD new Date().toLocaleTimeString()

      P "Still don't believe me? Open up your (OS X) terminal and try any of the following commands:"

      PRE class: "well",
        "curl #{host}/geolocation"

      PRE class: "well",
        """
          BROWSERVER=#{host}
          curl $BROWSERVER/prompt?q=#{encodeURIComponent 'Who are you?'} | say
        """

      PRE class: "well", id: "blurry",
        """
          curl -X PATCH #{host}/style \
            -d color=transparent \
            -d text-shadow='0 0 5px rgba(0,0,0,0.5)'
        """

      PRE class: "well",
        "curl -X POST #{host}/roll"

      P "Here's what just happened:"

      OL {},
        LI {},
          "You used curl to request a resource from "

          A
            href: "http://#{host}"
            target: "_blank"
            host

          "."

        LI {},
          "A "
          A href: "https://github.com/jed/browserver-node", "browserver server"
          " received your request, and figured out that you wanted to talk to client "
          EM host.split('.')[0]
          ", which is actually your browser."

        LI {},
          "The server then used an already-established websocket-like connection (thanks to "
          A href: "https://github.com/learnboost/engine.io", "engine.io"
          ") to forward the request."

        LI {},
          "The "
          A href: "https://github.com/jed/browserver-client", "browserver client"
          " in this page responded, getting any necessary input from the browser (or from you). The server then forwarded this response back to you."

      P "In other words, the open-source browserver server and client worked together to give your browser a real address on the Internet."

      P "So?"

      P "Well, this means that you don't need to roll your own custom code to connect the various pieces of your web architecture to your end clients."

      P "Instead, you can move the complexity of your app to the edges by making your end clients first-class HTTP servers, and then use your existing HTTP-related infrastructure to communicate with them."

      P "For example, you could:"

      UL {},
        LI "Subscribe them directly to any webhook-capable API, such as Amazon SNS."
        LI "Send notifications to other decoupled web services whenever a client connects/disconnects."
        LI "Simplify development by using the same familiar node.js HTTP API on both the client and server."

      P {},
        "To learn more about how browserver works, head on over to GitHub and check out the "
        A href: "https://github.com/jed/browserver-node", "browserver server"
        " and "
        A href: "https://github.com/jed/browserver-client", "browserver client"
        "."

      SMALL style: "margin-top: 100;",
        "browserver was brought to you by "
        A href: "https://github.com/jed", "Jed Schmidt"
        "."

  dom =
    HTML lang: "en",
      HEAD {},
        TITLE "෴ browserver: a node.js HTTP server in your browser ෴"

        LINK
          href: "http://fonts.googleapis.com/css?family=Merriweather:400,900"
          rel:  "stylesheet"
          type: "text/css"

        presentation

      content

  document.replaceChild dom, document.documentElement

server = http.createServer (req, res) ->
  [pathname, search] = req.url.split "?"

  if log = document.getElementById "requests"
    log.appendChild TR {},
      TD (log.childNodes.length + 1) + "."
      TD "#{req.method} #{pathname}"
      TD new Date().toLocaleTimeString()

  route = server.routes[pathname]

  unless route
    res.writeHead 404, "Content-Type": "text/plain"
    return res.end "Not found. You should probably close this window."

  handler = route[req.method]

  unless handler
    res.writeHead 405, "Content-Type": "text/plain"
    return res.end "Method not allowed"

  handler.call @, req, res

server.routes =

  "/localhost":
    PUT: (req, res) ->
      render host: req.body

      res.writeHead 204
      res.end ""

  "/prompt":
    GET: (req, res) ->
      [pathname, search] = req.url.split "?"

      match    = search.match /(?:^|&)q=(.+?)(?:$|&)/
      question = match && decodeURIComponent match[1]
      answer   = prompt question

      res.writeHead 200, "Content-Type": "text/plain"
      res.end "#{answer}\n"

  "/geolocation":
    GET: (req, res) ->
      if "geolocation" of navigator
        navigator.geolocation.getCurrentPosition(
          (position) ->
            res.writeHead 200, "Content-Type": "text/plain"
            res.end """
              Latitude: #{position.coords.latitude}
              Longitude: #{position.coords.longitude}
            """

          ->
            res.writeHead 403, "Content-Type": "text/plain"
            res.end "Forbidden"
        )

      else
        res.writeHead 501, "Content-Type": "text/plain"
        return res.end "Not implemented"

  "/style":
    PATCH: (req, res) ->
      for style in req.body.split "&"
        [name, value] = style.split "="

        name = name.replace /-[a-z]/g, (str) ->
          do str[1..].toUpperCase

        value = decodeURIComponent value

        document.getElementById("blurry").style[name] = value

      res.writeHead 204
      res.end ""

  "/roll":
    POST: (req, res) ->
      if open "http://www.youtube.com/watch?v=oHg5SJYRHA0"
        res.writeHead 204
        res.end ""

      else
        res.writeHead 403, "Content-Type": "text/plain"
        res.end "Forbidden"

server.listen new eio.Socket host: "browserver.org"
