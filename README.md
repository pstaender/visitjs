# visitjs
## BDD with mocha, webdriver.io and less pain

[![Build Status](https://api.travis-ci.org/pstaender/visitjs.png)](https://travis-ci.org/pstaender/visitjs)

For what visitjs is made for:

  * enables you to writer (nicer to read) BDD tests in coffee-script using mocha, chai (or whatever assertation tool you prefer) and webdriver.io / selenium.
  * acting as helper between mocha, lower-level request and high-level front end testing (via webdriver.io)
  * guesses basic request information of the test description and does the spadework for you (opening site, check status and format)
  * reduces repeating actions (like login, checking initial http status code, taking screenshots of the site …)
  * helps to keep test code dryer so that you can spend more time on writing useful and easy to understand test scenarios

The technology stack is set after my own preferences, that's why visitjs is made for use with mocha and wedriver.io exclusively for now.

## Usage

As stated before, visitjs guesses basic request information of the test description and preparing an initial stage for starting your test scenario.

The following examples are normally written in tests like `it('expect to visit … ', function() { … })`.

Let's start simple by visting a site:

```
  expect to visit http://mysite/home**
```

If we want to proof a certain http status code (which I recommended in any test), a headless http request (via `sync_request`) is triggered to the selenium test in parallel:

```
  expect to visit /home -> 200
```

Additionally we can ensure that we receive a specific format (only body will be validated, no format check in headers):

```
  expect to get /myapi/v1/person/1 as json -> 200
```

By using authorization (via `login` and `logout`), we can describe tests for different users:

```
  expect to get /my/profile -> 200 authorized as admin
```

If you want to name screenshot images for tests by your own definition, do:

```
  expect to get /my/profile -> 200 authorized as admin ![my_profile_as_admin]
```

**

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

## Custom headless request options

You can set your own options for the headless request. This enables you to set specific header / cookie data. For Example:

```coffee-script
  headlessRequestOptions (options, cookie) ->
    options.headers = {
      'x-custom-header': 'customValue'
    }
    options.followRedirects = true
    return options
```

Ensure that you return the options object.

## Taking Screenshots

```coffee-script
  describe 'my test suite', ->
    beforeEach ->
      saveViewportScreenshot(true)
```

or define your own name pattern (order and number of arguments is free):

```coffee-script
  describe 'my test suite', ->
    beforeEach ->
      saveViewportScreenshot (i, k, test, safeTitle, desiredCapabilities, imageTitle) ->
        # i: visits count
        # k: screen shots count
        # test: testTitle
        # safeTitle: filename safe title
        # desiredCapabilities: access browser name, etc
        # imageTitle: optional, custom name for screenshot image 
        "images/#{desiredCapabilities.browserName}_#{k}_#{imageTitle || safeTitle}.png"
```

It's using `wdio-screenshot`, which requires:

```sh
  $ brew install graphicsmagick           # max os x
  $ sudo apt-get install graphicsmagick   # ubuntu
```

## Debug Request

You can enable / disable debugging of the headless request by calling `debug(true)` and `debug(false)` respectively.

## Requirements

  * test suite using `wdio` (webdriver.io) with selenium and mocha (by executing `./node_modules/.bin/wdio`)
