sanitize = require("sanitize-filename")
request = require('request')
isHtml = require('is-html')
isXML = require('is-xml')
isJSON = require('is-json')

# syncRequest = (options) ->
#   response = undefined
#   error = null
#   body = undefined
#
#   request options, (err, res, b) ->
#     error = err
#     body = b
#     response = res
#
#   # spare timeout
#   setTimeout ->
#     response = null
#   , 10000
#
#   while response is undefined
#     require('deasync').runLoopOnce()
#
#   return { response, error, body }

VisitorJS = (browser, options = {}) ->

  baseUrl = options.baseUrl || ''
  visitsCount = 0
  screenShotsCount = 0
  responseObject = null

  # e.g.:
  # admin:
  #   passsword: 'password'
  # default_user:
  #   password: '…'
  options.logins ?= {}

  { expect } = options

  _saveViewportScreenshotPattern = null

  saveViewportScreenshot = (pattern) ->
    if pattern is true
      _saveViewportScreenshotPattern = (i, test, desiredCapabilities, safeTitle, imageTitle) ->
        "images/#{desiredCapabilities?.browserName}_#{imageTitle || safeTitle}.png"
    else if pattern isnt undefined
      _saveViewportScreenshotPattern = pattern
    _saveViewportScreenshotPattern

  _debug = false

  debug = (enable) ->
    _debug = enable || false
    _debug

  _loginProcedure = null
  _logoutProcedure = null

  login = (loginFunction) ->
    _loginProcedure = loginFunction if loginFunction isnt undefined
    _loginProcedure

  logout = (logoutFunction) ->
    _logoutProcedure = logoutFunction if logoutFunction isnt undefined
    _logoutProcedure

  _headlessRequestProcedure = null

  headlessRequestOptions = (func) ->
    _headlessRequestProcedure = func if func isnt undefined
    _headlessRequestProcedure

  extractRequestFromTitle = (title) ->
    match = title.match ///
      ((post|posting|posts|get|getting|gets|
      delete|deleting|deletes|put|putting|puts|
      patch|patching|patches|visit|visiting|visits)   # (1) verb / method
      [\s\:]+                                         # devider (space or get:… )
      ((http[s]*\:\/\/|\/).+?)(\s|$)                  # (2) url / http address
      )
      (.*)                                            # (3) optional: format, user, status code
      $///i
    unless match
      null
    else
      imageTitle = null
      statusCode = null
      format = null
      user = null
      url = match[3]
      method = match[2]
      #return null unless /^()/i.test url
      if match[6]
        s = match[6]
        statusCode = s.match(/\d{3}/)?[0] || statusCode
        format = s.match(/json|xml|html|js/i)?[0] || format
        # e.g.: logged in as admin, auth. as admin
        user = s.match(/(log in|login|logged in|auth|authenticate[d]*) as ([a-zA-Z0-9\_\-@\.]+)/)?[2] || user
        imageTitle = s.match(/\!\[(.+?)\]/)?[1] || null
      statusCode = Number(statusCode) if statusCode
      #match[3]?.match(/(json|xml)/i)?[1] or null

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
      { url, method, format, statusCode, user, imageTitle }


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

  strictAssertationOfValues = (expected, actual) ->
    if typeof expect is 'function'
      expect(actual).to.be.equal expected
    else if expected isnt actual
      throw Error("Expected value is #{expected} but actually got #{actual}")

  verifyResponse = (opts, cb) ->

    { requestOptions, statusCode, url, method, format } = opts

    console.log "🚀  [headless request] #{method}:#{url} #{JSON.stringify(requestOptions)}" if _debug

    requestOptions ?= {}
    requestOptions.uri = url
    requestOptions.method = method

    request requestOptions, (err, res, body) ->#syncRequest(method, url, requestOptions)

      body = body.toString()

      #console.log '!!!', body

      strictAssertationOfValues(statusCode, res.statusCode)

      #throw Error('Expected status code is ')
      #expect(res.statusCode).to.be.equal statusCode

      # TODO: check more format (yml, cson, …)
      if format
        expectedFormat = format.toLowerCase()

        format = 'unknown format'

        if isHtml(body)
          format = 'html'
        if expectedFormat is 'xml' and isXML(body)
          format = 'xml'
        if isJSON(body)
          format = 'json'

        strictAssertationOfValues(expectedFormat, format)
        #expect(format).to.be.equal expectedFormat

      if _debug
        console.log "🚀  [headless response] " + JSON.stringify({
          statusCode: res.statusCode
          format
          headers: res.headers
        })

      cb(res)

  visit = (context, opts = {}, cb = null) ->
    visitsCount++
    if typeof context is 'string'
      testObject = null
      testTitle = context
      requestObject = extractRequestFromTitle(testTitle)
    else# if typeof context is 'object' and context isnt null
      testObject = getTestFromContext(context)
      # in case visit is called from describe(), this will stop proceeding visit()
      return {} unless testObject
      testTitle = testObject.title
      # return throw Error("Expecting context (i.e. a test context) here") unless test
      requestObject = extractRequestFromTitle(testTitle)

    if typeof opts is 'function'
      cb = opts
      opts = {}

    if typeof cb isnt 'function'
      throw Error('visitjs expects a cb as last argument')


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

    requestObject.absoluteUrl = absoluteUrl

    # via selenium
    if isGetRequest and saveViewportScreenshot()
      # take screenshot
      screenShotsCount++
      filename = _callMethodWithArgs saveViewportScreenshot(), {
        i: visitsCount
        k: screenShotsCount
        test: testTitle
        safeTitle: sanitize(testTitle.replace(/(http[s]*)\:\/\//i,"[$1]").replace(/\//g, '%')).trim()
        desiredCapabilities: browser.requestHandler.defaultOptions.desiredCapabilities
        imageTitle: requestObject.imageTitle
      }

      #filename = getNameForScreenshot({ title: test.title, desiredCapabilities: browser.requestHandler.desiredCapabilities }, saveViewportScreenshot())
      browser.saveViewportScreenshot filename
      # has to be enabled explicity every time
      _saveViewportScreenshotPattern = null


    final_cb = (err, res, body) ->
      _callMethodWithArgs cb, { browser, res, req: requestObject, body, requestOptions, testTitle, err }

    if not requestObject.statusCode
      final_cb(null, null)
    else
      # perform headless request as well

      # extract cookies
      requestOptions = {
        followRedirects: false
      }

      requestOptions = _callMethodWithArgs(headlessRequestOptions(), {
        cookies: browser.cookie().value,
        options: requestOptions
        browser
      }) if typeof headlessRequestOptions() is 'function'

      throw Error("You have to leave options as an object literal") if typeof requestOptions isnt 'object'

      # reverse engineer baseUrl (workaround), TODO: get from webdriver.io
      #parsedURL = require('url').parse(absoluteUrl)
      #urlForRequest = [ parsedURL.protocol, '//', parsedURL.auth || '', parsedURL.host, url ].join('')
      urlForRequest = if /^http[s]*\:\/\//.test(url)
        url
      else
        browser.requestHandler.defaultOptions.baseUrl + url

      verifyResponse {
        method: requestObject.method
        url: urlForRequest
        requestOptions
        format: requestObject.format || null
        statusCode: requestObject.statusCode || null
      }, (err, responseObject, body) ->
        final_cb(err, responseObject, body)



  { visit, login, logout, saveViewportScreenshot, extractRequestFromTitle, headlessRequestOptions, debug }

module.exports = VisitorJS
