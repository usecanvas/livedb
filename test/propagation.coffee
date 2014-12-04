assert = require 'assert'
sinon = require 'sinon'
json0 = require('ot-json0').type
text = require('ot-text').type

{createClient, createDoc, setup, teardown} = require './util'

describe 'operation propagation granularity', ->
  beforeEach setup
  beforeEach ->
    @cName = '_test'

  beforeEach ->
    sinon.stub @db, 'queryNeedsPollMode', -> no

  afterEach teardown
  afterEach ->
    @db.query.restore() if @db.query.restore
    @db.queryDoc.restore() if @db.queryDoc.restore
    @db.queryNeedsPollMode.restore() if @db.queryNeedsPollMode.restore

  # Do these tests with polling turned on and off.
  for poll in [false, true] then do (poll) -> describe "poll:#{poll}", ->
    beforeEach ->
      @client.publishOperationsToDriver = false

    it 'throttles publishing operations when publishOperationsToDriver === false', (done) ->
      result = c:@cName, docName:@docName, v:1, data:{x:5}, type:json0.uri

      @collection.queryPoll {'x':5}, {poll:poll, pollDelay:0}, (err, emitter) =>
        emitter.on 'diff', (diff) =>
          throw new Error 'should not propagate operation to query'

        sinon.stub @db, 'query', (db, index, query, options, cb) -> cb null, [result]
        sinon.stub @db, 'queryDoc', (db, index, cName, docName, query, cb) -> cb null, result

        @create {x:5}, () -> done()

  # Do these tests with polling turned on and off.
  for poll in [false, true] then do (poll) -> describe "poll:#{poll}", ->
    beforeEach ->
      @client.publishOperationsToDriver = true

    it 'does not throttle publishing operations with publishOperationsToDriver === true', (done) ->
      result = c:@cName, docName:@docName, v:1, data:{x:5}, type:json0.uri

      @collection.queryPoll {'x':5}, {poll:poll, pollDelay:0}, (err, emitter) =>
        emitter.on 'diff', (diff) =>
          assert.deepEqual diff, [index: 0, values: [result], type: 'insert']
          emitter.destroy()
          done()

        sinon.stub @db, 'query', (db, index, query, options, cb) -> cb null, [result]
        sinon.stub @db, 'queryDoc', (db, index, cName, docName, query, cb) -> cb null, result

        @create {x:5}
