path = require 'path'
sqlite3 = require('sqlite3').verbose()
db_path = path.join __dirname.replace('/marie/lib', '/marie/config'), '/marie.sqlite'
db = new sqlite3.Database db_path

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