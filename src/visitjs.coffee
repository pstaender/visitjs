sanitize = require("sanitize-filename")
request = require('sync-request')
isHtml = require('is-html')
isXML = require('is-xml')
isJSON = require('is-json')
expect = require('expect.js')

VisitorJS = (browser, options = {}) ->

  baseUrl = options.baseUrl || ''
  visitsCount = 0
  responseObject = null

  # e.g.:
  # admin:
  #   passsword: 'password'
  # default_user:
  #   password: '…'
  logins = options.logins || {}

  saveViewportScreenshotPattern = null

  saveViewportScreenshot = (pattern) ->
    if pattern is true
      saveViewportScreenshotPattern = (i, test) -> "images/#{test}.png"
    else if pattern isnt undefined
      saveViewportScreenshotPattern = pattern
    saveViewportScreenshotPattern

  loginProcedure = null
  logoutProcedure = null
  headlessRequestProcedure = null

  login = (loginFunction) ->
    loginProcedure = loginFunction if loginFunction isnt undefined
    loginProcedure

  logout = (logoutFunction) ->
    logoutProcedure = logoutFunction if logoutFunction isnt undefined
    logoutProcedure

  headlessRequest = (func) ->
    headlessRequestProcedure = func if func isnt undefined
    headlessRequestProcedure

  extractRequestFromTitle = (title) ->
    match = title.match ///
      (post|posting|posts|get|getting|gets|
      delete|deleting|deletes|put|putting|puts|
      patch|patching|patches|visit|visiting|visits)   # (1) verb / method
      [\s\:]+                                         #     devider (space or :), get:https://…
      (.+?)(\s|$)                                     # (2) url / http address
      (.*)                                            # (3) optional: format, user, status code
      $///i
    unless match
      null
    else
      statusCode = null
      format = null
      user = null
      url = match[2]
      if match[4]
        s = match[4]
        statusCode = s.match(/\d{3}/)?[0] || statusCode
        format = s.match(/json|xml|html|js/i)?[0] || format
        # e.g.: logged in as admin, auth. as admin
        user = s.match(/(log in|login|logged in|auth|authenticate[d]*) as ([a-zA-Z0-9\_\-@\.]+)/)?[2] || user
      statusCode = Number(statusCode) if statusCode
      #match[3]?.match(/(json|xml)/i)?[1] or null
      method = match[1]
      method = if /^delet/.test(method)
        'delete'
      else if /^post/.test(method)
        'post'
      else if /^put/.test(method)
        'post'
      else if /^patch/.test(method)
        'post'
      else
        'get'
      { url, method, format, statusCode, user }


  getTestFromContext = (context) -> context?.currentTest || context?.test || null

  _callMethodWithArgs = (func, argsMapping) ->
    # gets the arguments of a funct (dependency injection like)
    getArgs = (func) ->
      # First match everything inside the function argument parens.
      args = func.toString().match(/function\s.*?\(([^)]*)\)/)[1]
      # Split the arguments string into an array comma delimited.
      args.split(',').map((arg) ->
        # Ensure no inline comments are parsed and trim the whitespace.
        arg.replace(/\/\*.*\*\//, '').trim()
      ).filter (arg) ->
        # Ensure no undefined values are added.
        arg

    args = getArgs(func).map (arg) ->
      argsMapping[arg]

    func.apply(this, args)

  getNameForScreenshot = (opts = { }, namePattern) ->
    { title, ext } = opts
    ext ?= '.png'

    safe_filename = (name) -> sanitize(name.replace(/http[s]*\:\/\//i,'').replace(/\//g, '%')).toLowerCase().replace(/\s+/g, '_') if name
    zfill = (num, len) -> (Array(len).join('0') + num).slice -len

    if typeof namePattern is 'function'
      filename = _callMethodWithArgs namePattern, {
        'i': String(zfill(visitsCount, 3))
        'test': safe_filename(title)
      }
    else
      filename = safe_filename(title)
    filename

  visit = (context, opts = {}, cb = null) ->
    visitsCount++
    test = getTestFromContext(context)
    # return throw Error("Expecting context (i.e. a test context) here") unless test
    requestObject = extractRequestFromTitle(test.title)

    url = opts?.url || requestObject?.url
    return throw Error("No url given; use test decription -or- { url: '…' } to specify the url which should be requested") unless url

    if requestObject.user
      if typeof logout() is 'function'
        { user } = requestObject
        logoutFunc = logout()
        _callMethodWithArgs logoutFunc, { browser, user }
      if typeof login() is 'function'
        # login user first
        { user } = requestObject
        password = logins[user].password
        user = logins[user]['user'] || user
        loginFunc = login()
        _callMethodWithArgs loginFunc, { browser, user, password }

    isGetRequest =  requestObject.method.toLowerCase() is 'get'

    browser.url(url)
    absoluteUrl = browser.getUrl()

    if requestObject.statusCode

      # extract cookies
      requestOptions = {
        followRedirects: false
      }
      requestOptions = _callMethodWithArgs(headlessRequest(), { cookie: browser.cookie().value, options: requestOptions }) if typeof headlessRequest() is 'function'

      # reverse engineer baseUrl (workaround), TODO: get from webdriver.io
      #parsedURL = require('url').parse(absoluteUrl)
      #urlForRequest = [ parsedURL.protocol, '//', parsedURL.auth || '', parsedURL.host, url ].join('')
      urlForRequest = browser.requestHandler.defaultOptions.baseUrl + url
      responseObject = request(requestObject.method, urlForRequest, requestOptions)
      expect(responseObject.statusCode).to.be.equal requestObject.statusCode
      # TODO: check more format (yml, cson, …)
      if requestObject.format
        expectedFormat = requestObject.format.toLowerCase()
        body = responseObject.body.toString()

        format = if isHtml(body)
          'html'
        if isXML(body)
          'xml'
        if isJSON(body)
          'json'
        else
          'unknown format'

        expect(format).to.be.equal expectedFormat


    if isGetRequest and saveViewportScreenshot()

      filename = getNameForScreenshot({ title: test.title }, saveViewportScreenshot())#(s, t, test, suite) -> true) + '.png'
      browser.saveViewportScreenshot filename
      # has to be enabled explicity every time
      saveViewportScreenshotPattern = null

    browser


  { visit, login, logout, saveViewportScreenshot, extractRequestFromTitle, getNameForScreenshot, headlessRequest }

module.exports = VisitorJS
