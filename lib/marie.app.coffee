fs = require 'fs'
fs = require 'fs-extra'
path = require 'path'
sqlite3 = require('sqlite3').verbose()
db_path = path.join __dirname.replace('/marie/lib', '/marie/config'), '/.db'
db = new sqlite3.Database db_path

class App
	@name
	@path
	@cssProcessor
	@frontEndFramework 
	@storage
	@templateEnegine
	@live
	@created
	@lastActive
	@pid

	query: require './marie.query'
	ui: require './marie.ui'


	constructor: ({@name, @path, @cssProcessor, @frontEndFramework, @storage, @templateEnegine, @live, @created, @lastActive, @pid}) ->


	save: ->
		db.serialize =>
			db.run App::query.INIT
			stmt = db.prepare App::query.SAVE
			stmt.run @name, @path, @cssProcessor, @frontEndFramework, @storage, @templateEnegine, @live, @created, @lastActive, @pid
			stmt.finalize()
			App::ui.ok "#{@name} was successfully saved."


	@find: (name, cb) =>
		db.serialize =>
			db.run App::query.INIT
			if not not name
				db.each App::query.FIND_ONE, name, (err, row) ->
					app = new App row
					cb err, app
			else
				db.all App::query.FIND, (err, row) ->
					cb err, row


	@remove:(name, cb) ->
		@find name, (err, row) =>
			if err then cb err, row
			if row
				path = row['path']
				cb err, path
				db.run App::query.REMOVE, name, (err, success) ->
					if not err
						fs.removeSync path
						cb null, "#{name} was successfully removed."
					else
						cb "#{name} was not removed.", null


# export app module
module.exports = App