

chai = require('chai')
global.expect = chai.expect
chai.Should()

webdriverio = require('webdriverio')

{ visit, login, logout, saveViewportScreenshot } = require('../../src') browser, logins: { admin: { password: 'password' } }

# Define logout procedure
logout (browser) ->
  browser.url('/mysite/Security/logout')

# Define logout procedure
# alternatively you can define login in specific
# suites (`beforeEach`) or tests
# but it get's executed while running the tests anyway
login (browser, user, password) ->
  browser.url('/mysite/Security/login')
  browser.element('#MemberLoginForm_LoginForm_Email').setValue user
  browser.element('#MemberLoginForm_LoginForm_Password').setValue password
  browser.submitForm('#MemberLoginForm_LoginForm')

describe 'Check websites with webdriver.io by it\'s test description (only format, status and title)', ->

  beforeEach ->
    saveViewportScreenshot(true)# (i, test) -> "images/#{i}_#{test}.png"

  it 'expect to visit http://www.google.de/ as html with 200', ->
    browser = visit(this)
    browser.getTitle().should.be.equal('Google')

  it 'expect to visit http://www.google.de/someurlthatwillneverexists1930_899fsd with 404', ->
    browser = visit(this)
    browser.getTitle().should.match(/404/)

describe 'login to a website', ->

  beforeEach ->
    saveViewportScreenshot(true)

  xit 'expect to visit http://localhost/mysite/admin , logged in as admin', ->
    browser = visit(this)
    console.log browser.getTitle()

  xit 'expect to visit http://localhost/mysite/member/edit/me , logged in as admin', ->
    browser = visit(this)
    console.log browser.getTitle()
