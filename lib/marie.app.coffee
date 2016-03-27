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


	save: (cb) ->
		if not not @name
			db.each App::query.FIND_ONE, @name, (err, row) =>
				stmt = null
				if err or not row or row.length == 0
					db.run App::query.INIT
					stmt = db.prepare App::query.SAVE
					stmt.run @name, @path, @cssProcessor, @frontEndFramework, @storage, @templateEnegine, @live, @created, @lastActive, @pid
				else
					stmt = db.prepare App::query.UPDATE
					stmt.run @path, @cssProcessor, @frontEndFramework, @storage, @templateEnegine, @live, @created, @lastActive, @pid, @name
				stmt.finalize()
				if cb then cb err, @


	@find: (name, cb) =>
		db.serialize =>
			db.run App::query.INIT
			if not not name
				db.each App::query.FIND_ONE, name, (err, row) ->
					if cb then cb err, new App row
			else
				db.all App::query.FIND, (err, row) ->
					if cb then cb err, row


	@remove:(name, cb) ->
		@find name, (err, row) =>
			if err then cb err, row
			if row
				path = row['path']
				if cb then cb err, path
				db.run App::query.REMOVE, name, (err, success) ->
					if not err
						fs.removeSync path
						if cb then cb null, "#{name} was successfully removed."
					else
						if cb then cb "#{name} was not removed.", null


# export app module
module.exports = App