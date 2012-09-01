render = ({host}) ->
  dom =

  HTML lang: "en",
    HEAD {},
      TITLE "෴ browserver: a node.js HTTP server in your browser ෴"

      LINK
        href: "//fonts.googleapis.com/css?family=Merriweather:400,900"
        rel:  "stylesheet"
        type: "text/css"

      STYLE type: "text/css",
        CSS "body"
          backgroundColor: "#eee"
          color: "#333"
          fontFamily: "'Merriweather', serif"
          fontSize: "130%"
          lineHeight: "150%"
          margin: "0 0 2em"
          padding: 0

        CSS ".header"
          textAlign: "center"
          marginTop: 120
          marginBottom: 70
          fontSize: 40

          CSS ".logo"
            marginBottom: 100
            fontSize: 300

        CSS "h1, h2, h3, p, ul, ol, pre"
          width: 600
          margin: "1em auto"

        CSS "a"
          color: "#C90707"
          fontWeight: "bold"

        CSS ".sub"
          background: "#fff"
          margin: ".5em 0 0"
          padding: ".5em 0"
          borderTop: "1px solid #ccc"
          borderBottom: "1px solid #ccc"

        CSS "pre, code"
          fontSize: "0.9em"
          fontFamily: "Monaco, Courier New, monospace"
          overflow: "hidden"

    BODY {},
      A href: "https://github.com/jed/browserver-client",
        IMG
          style: "position: absolute; top: 0; right: 0; border: 0;"
          src: "https://s3.amazonaws.com/github/ribbons/forkme_right_gray_6d6d6d.png"
          alt: "Fork me on GitHub"

      DIV class: "header",
        DIV class: "logo",
          "෴"
        H1 "browserver"

      P {},
        "Hello! I've got some good news for you: your web browser has just been upgraded to a web "
        EM "server"
        ". It's responding to HTTP requests on the Internet as you read this."

      P "True story. Here's the last request that came in:"

      DIV class: "sub",
        PRE id: "lastRequest",
          ""

      P "And here's the response your browser served:"

      DIV class: "sub",
        PRE id: "lastResponse",
          ""

      P "Don't believe me? Just send any HTTP request to the following host, which is your browserver's own temporary address on the Internet:"

      DIV class: "sub",
        PRE style: "text-align: center; font-size: 150%;",
          host

      P {},
        "Any requests sent to this host will be reverse-proxied via WebSocket by a "
        A href: "https://github.com/jed/browserver-node", "browserver server"
        " and handled by the "
        A href: "https://github.com/jed/browserver-client", "browserver client"
        " in this browser."

      H2 "Examples"

      P "Hit the following URL to redirect to a google map based on the location returned by your browser's geolocation functionality:"

      DIV class: "sub",
        P style: "text-align: center;",

          IMG
            width: 300
            height: 300
            src: "http://chart.googleapis.com/chart?cht=qr&chs=300x300&chl=http://#{host}/where"

          BR {}

          A
            href: "http://#{host}/where"
            target: "_blank"

            "http://#{host}/where"

      P "Or, enter a question to ask your browser here:"

      P {},
        INPUT
          style: "width: 100%; font-size: 1.5em; text-align: center;"
          id: "question"
          type: "text"
          value: "What is your name?"
          onkeyup: """
            var url = "http://#{host}/ask?q=" + encodeURIComponent(this.value)
            var src = "http://chart.googleapis.com/chart?cht=qr&chs=300x300&chl=" + url

            document.getElementById("questionImg").src = src
            document.getElementById("questionAnchor").href = url
            document.getElementById("questionAnchor").firstChild.nodeValue = url
          """

      P "And then hit the following URL to get the answer:"

      DIV class: "sub",
        P style: "text-align: center;",

          IMG
            id: "questionImg"
            width: 300
            height: 300
            src: "http://chart.googleapis.com/chart?cht=qr&chs=300x300&chl=http://#{host}/ask?q=What%20is%20your%20name%3F"

          BR {}

          A
            id: "questionAnchor"
            href: "http://#{host}/ask?q=What%20is%20your%20name%3F"
            target: "_blank"

            "http://#{host}/ask?q=What%20is%20your%20name%3F"

      H2 "So, what this good for?"

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

      P {},
        SMALL style: "margin-top: 100;",
          "browserver was brought to you by "
          A href: "https://github.com/jed", "Jed Schmidt"
          "."

  document.replaceChild dom, document.documentElement

server = http.createServer()

server.once "request", (req) ->
  render host: req.headers.host

server.on "request", (req, res) ->
  msg = document.createTextNode req.serialize()
  el = document.getElementById "lastRequest"

  el.replaceChild msg, el.firstChild

  res.once "end", ->
    msg = document.createTextNode res.serialize()
    el = document.getElementById "lastResponse"
    el.replaceChild msg, el.firstChild

server.on "request", Router
  "/where":
    GET: (req, res) ->
      if "geolocation" of navigator
        navigator.geolocation.getCurrentPosition(
          (position) ->
            {latitude, longitude} = position.coords
            url = "//maps.google.com/?q=#{latitude},#{longitude}"

            res.writeHead 302, Location: url
            res.end()

          ->
            res.writeHead 403, "Content-Type": "text/plain"
            res.end "Forbidden"
        )

      else
        res.writeHead 501, "Content-Type": "text/plain"
        res.end "Not implemented"

  "/ask":
    GET: (req, res) ->
      [pathname, search] = req.url.split "?"

      match    = search.match /(?:^|&)q=(.+?)(?:$|&)/
      question = match and decodeURIComponent match[1]

      res.writeHead 200, "Content-Type": "text/html"
      res.end """
        <!doctype html>
        <body style="margin: 2em; font-size: 3em; text-align: center">
          #{prompt question}
        </body>
      """

  "/server-count":
    PUT: (req, res) ->
      if el = document.getElementById "browserverCount"
        el.innerHTML = req.body

      res.writeHead 204
      res.end()

server.listen new eio.Socket host: location.host
