sanitize = require("sanitize-filename")
syncRequest = require('sync-request')
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
  options.logins ?= {}

  _saveViewportScreenshotPattern = null

  saveViewportScreenshot = (pattern) ->
    if pattern is true
      _saveViewportScreenshotPattern = (i, test, desiredCapabilities, safeTitle) -> "images/#{desiredCapabilities?.browserName}_#{i}_#{safeTitle}.png"
    else if pattern isnt undefined
      _saveViewportScreenshotPattern = pattern
    _saveViewportScreenshotPattern

  _loginProcedure = null
  _logoutProcedure = null

  login = (loginFunction) ->
    _loginProcedure = loginFunction if loginFunction isnt undefined
    _loginProcedure

  logout = (logoutFunction) ->
    _logoutProcedure = logoutFunction if logoutFunction isnt undefined
    _logoutProcedure

  _headlessRequestProcedure = null

  headlessRequest = (func) ->
    _headlessRequestProcedure = func if func isnt undefined
    _headlessRequestProcedure

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

  verifyResponse = (opts) ->

    { requestOptions, statusCode, url, method, format } = opts

    res = syncRequest(method, url, requestOptions)
    expect(res.statusCode).to.be.equal statusCode

    # TODO: check more format (yml, cson, …)
    if format
      expectedFormat = format.toLowerCase()
      body = res.body.toString()

      format = if isHtml(body)
        'html'
      if isXML(body)
        'xml'
      if isJSON(body)
        'json'
      else
        'unknown format'
      expect(format).to.be.equal expectedFormat

    res

  visit = (context, opts = {}, cb = null) ->
    visitsCount++
    test = getTestFromContext(context)
    # return throw Error("Expecting context (i.e. a test context) here") unless test
    requestObject = extractRequestFromTitle(test.title)

    url = opts?.url || requestObject?.url
    return throw Error("No url given; use test decription -or- { url: '…' } to specify the url which should be requested") unless url

    if requestObject.user
      # perform logout and login
      if typeof logout() is 'function'
        { user } = requestObject
        logoutFunc = logout()
        _callMethodWithArgs logoutFunc, { browser, user }
      if typeof login() is 'function'
        # login user first
        { user } = requestObject
        password = options.logins[user].password
        user = options.logins[user]['user'] || user
        loginFunc = login()
        _callMethodWithArgs loginFunc, { browser, user, password }

    isGetRequest =  requestObject.method.toLowerCase() is 'get'

    browser.url(url)
    absoluteUrl = browser.getUrl()

    if requestObject.statusCode
      # perform headless request as well

      # extract cookies
      requestOptions = {
        followRedirects: false
      }
      requestOptions = _callMethodWithArgs(headlessRequest(), {
        cookie: browser.cookie().value,
        options: requestOptions
      }) if typeof headlessRequest() is 'function'

      # reverse engineer baseUrl (workaround), TODO: get from webdriver.io
      #parsedURL = require('url').parse(absoluteUrl)
      #urlForRequest = [ parsedURL.protocol, '//', parsedURL.auth || '', parsedURL.host, url ].join('')
      urlForRequest = if /^http[s]*\:\/\//.test(url)
        url
      else
        browser.requestHandler.defaultOptions.baseUrl + url

      responseObject = verifyResponse {
        method: requestObject.method
        url: urlForRequest
        requestOptions
        format: requestObject.format || null
        statusCode: requestObject.statusCode || null
      }

    if isGetRequest and saveViewportScreenshot()
      # take screenshot

      filename = _callMethodWithArgs saveViewportScreenshot(), {
        i: visitsCount
        test: test.title
        safeTitle: sanitize(test.title.replace(/(http[s]*)\:\/\//i,"[$1]").replace(/\//g, '%')).trim()
        desiredCapabilities: browser.requestHandler.defaultOptions.desiredCapabilities
      }

      #filename = getNameForScreenshot({ title: test.title, desiredCapabilities: browser.requestHandler.desiredCapabilities }, saveViewportScreenshot())
      browser.saveViewportScreenshot filename
      # has to be enabled explicity every time
      _saveViewportScreenshotPattern = null

    browser


  { visit, login, logout, saveViewportScreenshot, extractRequestFromTitle, headlessRequest }

module.exports = VisitorJS
