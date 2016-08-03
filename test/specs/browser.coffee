{ visit, login, logout, saveViewportScreenshot, headlessRequestOptions, debug } = require('../../src') browser, logins: { admin: { password: 'password' } }

chai = require('chai')
global.expect = chai.expect
chai.Should()

describe 'Check websites with webdriver.io by it\'s test description (only format, status and title)', ->

  beforeEach ->
    saveViewportScreenshot(true)

  it 'expect to visit http://www.google.de/ as html with 200', ->
    { browser } = visit(this)
    browser.getTitle().should.be.equal('Google')

  it 'expect to visit http://www.google.de/someurlthatwillneverexists1930_899fsd with 404', ->
    { browser } = visit(this)
    browser.getTitle().should.match(/404/)

describe 'Perform unathorized request on website ', ->

  it 'expect to visit /authorized (not authorized) -> 401', ->
    { browser } = visit(this)
    browser.getTitle().should.be.equal 'unauthorized'


describe 'Perform various requests on website', ->

  describe 'via login and logout', ->

    # Define logout procedure
    logout (browser) ->
      browser.url('/logout')

    # Define logout procedure
    # alternatively you can define login in specific
    # suites (`beforeEach`) or tests
    # but it get's executed while running the tests anyway
    login (browser, user, password) ->
      browser.url('/login')
      browser.element('#username').setValue user
      browser.element('#password').setValue password
      browser.submitForm('#login-form')

    beforeEach ->
      saveViewportScreenshot(true)

    it 'expect to visit /authorized with a 200 status code, logged in as admin', ->
      { browser } = visit(this)
      browser.getTitle().should.be.equal 'authorized'

    it 'expect to get /json as json -> 200 and to receive a headless response object', ->
      { res } = visit(this)
      res.statusCode.should.be.equal 200
      JSON.parse(String(res.body)).should.be.eql {"format":"JSON","valid":true}

    it 'expect to get /html as html -> 200', ->
      visit(this)

    it 'expect to get /xml as xml -> 200', ->
      visit(this)

describe 'Perform a custom headless requests on website', ->

  it 'expect to perform a headless request with custom header by visiting /header -> 200', ->

    debug(true)

    headlessRequestOptions (options, cookie) ->
      cookie.constructor.should.be.equal Array
      options.headers = {
        'x-custom-header': 'customValue'
      }
      options

    { res } = visit(this)
    body = JSON.parse(String(res.body))
    body['x-custom-header'].should.be.equal 'customValue'
