# visitjs
## BDD with mocha, webdriver.io and less pain

[![Build Status](https://api.travis-ci.org/pstaender/visitjs.png)](https://travis-ci.org/pstaender/visitjs)

This is a demonstration of writing (nice to read) BDD tests in coffee-script using mocha, chai (or whatever assertation tool you prefer) and webdriver.io / selenium.

The technology stack is set after my own preferences and therefore of course not the ultimate toolset.

`Visitjs` is a helper between mocha, lower-level request and high-level front end testing via webdriver.io. The goal is to reduce repeating  actions (like login, http status code, response format, screenshot of the site …).

## Idea and Usage

Describe your test scenario and let visitjs guess the basic request information and do the spadework for you. Letting visitjs doing the initial setup for your tests keeps your test code dry and gives you more time to focus on writing detailed scenarios.

Let's start simple:

**expect to visit http://mysite/home**

Now we also want to proof a certain http status code (here 200) which will trigger a headless http request to the selenium test in parallel:

**expect to visit /home -> 200**

Additionally we can ensure that receiving expected format (only body will be validated, no format check in headers):

**expect to get /myapi/v1/person/1 as json -> 200**

By using authorization (via `login` and `logout`), we can describe tests for different users:

**expect to get /my/profile -> 200 authorized as admin**

### Login and Logout

Example: (see `test/specs/browser.coffee` for further examples).

```coffee-script
  { visit, login, logout } = require('visitjs')(browser, logins: {
    admin: {
      user: 'admin@server.local'
      password: 'password'
    },
    user: {
      user: 'user@somewhere.local'
      password: 'secret'
    }
  })

  describe 'my testsuite', ->

    # Define logout procedure
    logout (browser) ->
      browser.url('/logout')

    # Define logout procedure
    login (browser, user, password) ->
      browser.url('/login')
      browser.element('#username').setValue user
      browser.element('#password').setValue password
      browser.submitForm('#login-form')

    it 'expect to visit /my/profile with a 200 status code, logged in as admin', ->
      { browser } = visit(this)
      browser.getTitle().should.be.equal 'welcome back, admin'

    it 'expect to visit /my/profile with a 200 status code, logged in as user', ->
      { browser } = visit(this)
      browser.getTitle().should.be.equal 'welcome back, user'
```

### Basic Syntax

```coffee-script
  it 'expect to visit /mysite/home', ->
    { browser } = visit(this)
```

```coffee-script
  it 'expect to visit /mysite/home', ->
    { browser, res, req, requestOptions, testTitle } = visit(this)
```

Or in plain newer js:

```js
  it('expect to visit /mysite/home', function() {
    let browser = visit(this).browser;
  })
```

You only have to mention the verb ( visit | visiting | get | getting | post | posting … ) followed by an url (absolute or relative), optional with a format (supported are html, xml and json) and a (numeric) http status code. The http status code enables the headless request and is recommended in every test description.

## Example

This test could be located in `test/spec/mytest.coffe` (or whatever is defined in your `wdio.conf.js`):

```coffee-script
# the `browser` reference is global available via wdio
{ visit } = require('visitjs')(browser)

describe 'Check some google pages', ->

  it 'expect to visit http://www.google.com/ as html with a status code of 200', ->
    { browser } = visit(this)
    expect(browser.getTitle()).to.be.equal('Google')

```

**The described processes are - according to webdriver.io's browser feature - synchronously.**

## Taking Screenshots

Using `wdio-screenshot`, which requires:

```sh
  $ brew install graphicsmagick           # max os x
  $ sudo apt-get install graphicsmagick   # ubuntu
```

## Requirements

  * test suite using `wdio` (webdriver.io) with selenium and mocha (by executing `./node_modules/.bin/wdio`)
