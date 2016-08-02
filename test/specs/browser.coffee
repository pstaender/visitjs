chai = require('chai')
global.expect = chai.expect
chai.Should()

webdriverio = require('webdriverio')
serverProcess = null

{ visit, login, logout, saveViewportScreenshot } = require('../../src') browser, logins: { admin: { password: 'password' } }

# headlessRequest (options) ->
#   {
#     headers:
#       'user-agent': "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36"
#   }

describe 'Check websites with webdriver.io by it\'s test description (only format, status and title)', ->

  beforeEach ->
    saveViewportScreenshot(true)# (i, test) -> "images/#{i}_#{test}.png"

  it 'expect to visit http://www.google.de/ as html with 200', ->
    { browser } = visit(this)
    browser.getTitle().should.be.equal('Google')

  it 'expect to visit http://www.google.de/someurlthatwillneverexists1930_899fsd with 404', ->
    { browser } = visit(this)
    browser.getTitle().should.match(/404/)

describe 'Perform various requests on (local) website unathorized', ->

  it 'expect to visit /authorized -> 401', ->
    { browser } = visit(this)
    browser.getTitle().should.be.equal 'unauthorized'


describe 'Perform various requests on (local) website', ->

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

    it 'expect to visit /authorized -> 200 logged in as admin', ->
      { browser } = visit(this)
      browser.getTitle().should.be.equal 'authorized'

    it 'expect to get /json as json -> 200', ->
      visit(this)

    it 'expect to get /html as html -> 200', ->
      visit(this)

    it 'expect to get /xml as xml -> 200', ->
      visit(this)
