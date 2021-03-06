expect = require('expect.js')

{
  visit
  login
  logout
  saveViewportScreenshot
  headlessRequestOptions
  debug
} = require('../../src')(browser, {
  logins:
    admin:
      password: 'password'
})

chai = require('chai')
global.expect = chai.expect
chai.Should()

debug(true)

describe 'Check websites with webdriver.io by it\'s test description (only format, status and title)', ->

  beforeEach ->
    saveViewportScreenshot(true)

  it 'expect to visit http://www.google.de/ as html with 200 including taking a snapshot ![google_homepage]', ->
    { browser } = visit(this)
    browser.getTitle().should.be.equal('Google')

  it 'expect to visit http://www.google.de/someurlthatwillneverexists1930_899fsd with 404', ->
    { browser } = visit(this)
    browser.getTitle().should.match(/404/)

describe 'Perform unathorized request on website ', ->

  it 'expect to visit /authorized (not authorized) -> 401', ->
    { browser } = visit(this)
    browser.getTitle().should.be.equal 'unauthorized'

  it 'should throw an error by (unauthorized) visiting /authorized and expecting a status code of 200', (done) ->
    try
      { browser } = visit(this)
    catch error
      'only catch the error'
    error.message.should.be.equal 'Expected value is 200 but actually got 401'

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

    it 'expect to visit /authorized with a 200 status code, logged in as admin', (done) ->
      visit this, (browser) ->
        browser.getTitle().should.be.equal 'authorized'
        done()

    it 'expect to get /json as json -> 200 and to receive a headless response object', (done) ->
      visit this, (res) ->
        res.statusCode.should.be.equal 200
        JSON.parse(String(res.body)).should.be.eql {"format":"JSON","valid":true}
        done()

    it 'expect to get /html as html -> 200', (done) ->
      visit this, -> done()

    it 'expect to get /xml as xml -> 200', (done) ->
      visit this, -> done()

describe 'Perform a custom headless requests on website', ->


  it 'expect to perform a headless request with custom header by visiting /header -> 200', ->

    headlessRequestOptions (options, cookies, browser) ->
      cookies.constructor.should.be.equal Array
      browser.should.be.not.null
      options.headers = {
        'x-custom-header': 'customValue'
      }
      options

    { res } = visit(this)
    body = JSON.parse(String(res.body))
    body['x-custom-header'].should.be.equal 'customValue'
