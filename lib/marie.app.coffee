path = require 'path'
sqlite3 = require('sqlite3').verbose()
db = new sqlite3.Database path.join(__dirname.replace('/marie/lib', '/marie/config')), '/marie.sqlite'

class App
	@name
	@path
	@cssProcessor
	@frontEndFramework
	@storage
	@templateEnegine
	@status
	@created
	@lastActive
	@pid


	constructor: ({@name, @path, @cssProcessor, @frontEndFramework, @storage, @templateEnegine, @status, @created, @lastActive}) ->
		@configureStorage()


	configureStorage: ->
		db.serialize ->


	find: ->


	save: ->


	remove: ->


module.exports = App