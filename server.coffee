express = require('express')
app = express()

bodyParser = require('body-parser')

# global session because we have only one user instance testing here
isLoggedIn = false

auth = (username, password) -> username is 'admin' and password is 'password'

app.use(bodyParser.urlencoded({ extended: false }))

messageAsHTMLPage = (msg) -> "<!doctype><html><head><title>#{msg}</title></head><body><h1 id='page_title'>#{msg}</h1></body></html>"

app.get '/html', (req, res) ->
  res.send '<!doctype><html><body><h1 id="page_title">I ❤ html</h1></body></html>'

app.get '/xml', (req, res) ->
  res.send '<?xml version="1.0" standalone="no"?><!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd"><svg></svg>'

app.get '/json', (req, res) ->
  res.send {
    format: 'JSON'
    valid: true
  }

app.get '/login', (req, res) ->
  res.send """
  <!doctype><html><body>
    <form method="post" id="login-form">
      <input type="text" name="username" id="username" placeholder="username"> <br />
      <input type="password" name="password" id="password" placeholder="password"><br />
      <input type="submit">
    </form>
  </body></html>
  """

app.post '/login', (req, res) ->
  { username, password } = req.body
  isLoggedIn = auth(username, password)
  if isLoggedIn
    res.send messageAsHTMLPage('welcome')
  else
    res.sendStatus 401

app.get '/authorized', (req, res) ->
  if isLoggedIn
    res.send messageAsHTMLPage('authorized')
  else
    res.status(401).send messageAsHTMLPage('unauthorized')

app.get '/logout', (req, res) ->
  isLoggedIn = false
  res.send messageAsHTMLPage('logged out')

app.get '/header', (req, res) ->
  res.send req.headers

app.post '/new', (req, res) -> res.send { method: 'POST' }

app.delete '/', (req, res) ->
  res.send { ok: true }
  console.log 'exiting server via delete request'
  process.exit(0)

port = process.env.PORT || 3300

server = app.listen port, ->
  console.log "visitjs test server listening on port #{port}"
  return

module.exports = { server }
