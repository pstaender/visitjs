# visitjs
## BDD with mocha, webdriver.io and less pain

This is a demonstration of writing (nice to read) BDD tests in coffee-script using mocha, chai (or whatever assertation tool you prefer) and webdriver.io / selenium.

The technology stack is set after my own preferences and therefore of course not the ultimate toolset.

`Visitjs` acts as wrapper between mocha, lower-level request and high-level frontend testing via webdriver.io. The goal is to reduce repeating  actions (like login, http status code, response format, screenshot of the site …).

## Usage

After installation (see below), define your project's tests in `test/spec` (or wherever is defined in your `wdio.conf.js`):

```coffee-script
{ visit } = require('visitjs')(browser)

describe 'Check some google pages', ->

  it 'expect to visit http://www.google.com/ as html with a status code of 200', ->
    browser = visit(this)
    expect(browser.getTitle()).to.be.equal('Google')

  it 'expect to visit http://www.google.de/someurlthatwillneverexists1930_899fsd with a 404', ->
    browser = visit(this)
```

You can define test scenarios by describing the test title:

  * `expect to visit http://www.google.com/ as html with a status code of 200`, means:
    - url: http://www.google.com/
    - expected format: html
    - (explicitly) expected status code: 200
  * `expect to visit /mysite/my/profile logged in as admin`, means:
    - url: $baseUrl/mysite/my/profile
    - login process (has to be defined), using user `admin`
  * `get /mysite/my/profile as html -> 200 (authenticated as admin)`, as example for a more technical description

After calling `browser = visit(this)` you may proceed with more sophisticated frontend tests (e.g. manipulation dom / forms …).

**All processes are - according to webdriver.io's browser feature - synchronously.**

## Login / Logout

## Taking Screenshots

Using `npm install wdio-screenshot`, which requires

```sh
  $ brew install graphicsmagick           # max os x
  $ sudo apt-get install graphicsmagick   # ubuntu
```

## Idea

Keep testing as dry as possible. For that, visitjs reduces the basic setup before further expecting a website just by saying `browser = visit(this)` and defining a describing test title.

More examples will follow. For now, checkout visitjs own tests for deeper understanding.

## Install

```sh
  $ npm install .
  $ npm install -g mocha
  $ npm install -g webdriverio
```

# Run unit tests

```sh
  $ mocha
```

## Run integration tests

Ensure you've installed and running selenium:

```sh
  $ ./node_modules/.bin/wdio
```

## Run Selenium

```sh
  $ npm install selenium-standalone@latest -g
  $ selenium-standalone install
  $ selenium-standalone start
```
