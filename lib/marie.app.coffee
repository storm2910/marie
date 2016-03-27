fs = require 'fs'
fs = require 'fs-extra'
path = require 'path'
sqlite3 = require('sqlite3').verbose()
db_path = path.join __dirname.replace('/marie/lib', '/marie/config'), '/marie.sqlite'
db = new sqlite3.Database db_path
ui = require './marie.ui'

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


	constructor: ({@name, @path, @cssProcessor, @frontEndFramework, @storage, @templateEnegine, @live, @created, @lastActive}) ->
		@configureCollection()
		@save()


	configureCollection: ->
		db.serialize =>
			fs.stat db_path, (err, stats) ->
				if err
					db.run 'CREATE TABLE app(name varchar(255) primary key not null, path varchar(255), cssProcessor varchar(255), frontEndFramework varchar(255), storage varchar(255), templateEnegine varchar(255), live bool, created varchar(255), lastActive varchar(255), pid smallint)'


	save: ->
		db.serialize =>
			stmt = db.prepare 'INSERT INTO app (name, path, cssProcessor, frontEndFramework, storage, templateEnegine, live, created, lastActive) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)' 
			stmt.run @name, @path, @cssProcessor, @frontEndFramework, @storage, @templateEnegine, @live, @created, @lastActive
			stmt.finalize()
		ui.ok "#{@name} was successfully created."


	@find: (name, cb) ->
		if not not name
			db.each 'SELECT * FROM app WHERE name = ?', name, (err, row) ->
				cb err, row
		else
			db.all 'SELECT * FROM app', (err, row) ->
				cb err, row


	@remove:(name, cb) ->
		db.serialize =>
			@find name, (err, row) =>
				if err then cb err, row
				if row
					path = row['path']
					cb err, path
					db.run 'DELETE FROM app WHERE name = ?', name, (err, success) ->
						if not err
							fs.removeSync path
							cb null, "#{name} was successfully removed."
						else
							cb "#{name} was not removed.", null


# export app module
module.exports = App