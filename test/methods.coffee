expect = require('expect.js')

visitor = { extractRequestFromTitle } = require('../src')()

describe 'unit tests for visitjs', ->

  it 'expect to convert a title to request options', ->
    # get /mysite as JSON with status code 200
    match = visitor.extractRequestFromTitle 'get /mysite as json with status code 301'
    expect(match).to.eql {
      method: 'get'
      url: '/mysite'
      format: 'json'
      statusCode: 301
      user: null
      imageTitle: null
    }

    match = visitor.extractRequestFromTitle 'should get an error by visiting /mysite as json with status code 200 because it is unauthroized (401) by default'
    expect(match).to.eql {
      method: 'get'
      url: '/mysite'
      format: 'json'
      statusCode: 200
      user: null
      imageTitle: null
    }

    # get /mysite.json -> 200
    match = visitor.extractRequestFromTitle 'get /mysite.json -> 200'
    expect(match).to.eql {
      method: 'get'
      url: '/mysite.json'
      format: null
      statusCode: 200
      user: null
      imageTitle: null
    }
    match = visitor.extractRequestFromTitle 'visit /mysite.json'
    expect(match).to.eql {
      method: 'get'
      url: '/mysite.json'
      format: null
      statusCode: null
      user: null
      imageTitle: null
    }
    # post /mysite with status 200
    match = visitor.extractRequestFromTitle 'post /mysite.html with status 404'
    expect(match).to.eql {
      method: 'post'
      url: '/mysite.html'
      format: null
      statusCode: 404
      user: null
      imageTitle: null
    }

    match = visitor.extractRequestFromTitle 'it expects to visit http://localhost/mysite.html with 401, authenticated as me@home.com'
    expect(match).to.eql {
      method: 'get'
      url: 'http://localhost/mysite.html'
      format: null
      statusCode: 401
      user: 'me@home.com'
      imageTitle: null
    }

    match = visitor.extractRequestFromTitle 'it expects to visit /mysite.html having xml with 401 (logged in as admin)'
    expect(match).to.eql {
      method: 'get'
      url: '/mysite.html'
      format: 'xml'
      user: 'admin'
      statusCode: 401
      imageTitle: null
    }

    match = visitor.extractRequestFromTitle 'expect to visit http://localhost/mysite/admin , login as admin'
    expect(match).to.eql {
      method: 'get'
      url: 'http://localhost/mysite/admin'
      format: null
      user: 'admin'
      statusCode: null
      imageTitle: null
    }

  it 'expect to convert a title to request options with image title', ->
    match = visitor.extractRequestFromTitle 'expect to visit /mysite/settings -> 404 (authenticated as admin) ![my_settings_admin]'
    expect(match).to.eql {
      method: 'get'
      url: '/mysite/settings'
      format: null
      user: 'admin'
      statusCode: 404
      imageTitle: 'my_settings_admin'
    }
