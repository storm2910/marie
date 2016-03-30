###
@namespace marie.app
@include marie.query
@property [String] name app name
@property [String] path app path
@property [String] cssProcessor app css processor
@property [String] frontEndFramework  app frontEnd framework
@property [String] storage  app storage
@property [String] templateEngine app template Engine
@property [Bool] live boolean showing if app is running
@property [String] created app creation date
@property [String, Date] lastActive app last active date
@property [Number] pid app pid
@author Teddy Moussignac (teddy.moussignac@gmail.com)
@version 0.0.3
@copyright March 2016
@note Marie app model class
###

utils = require './marie.utils'
sqlite3 = require('sqlite3').verbose()
db_path = utils.path.join __dirname.replace('/marie/lib', '/marie/config'), '/.db'
db = new sqlite3.Database db_path

class App
	@name
	@path
	@cssProcessor
	@frontEndFramework 
	@storage
	@templateEngine
	@live
	@created
	@lastActive
	@pid

	query: require './marie.query'

	###
	Construct App
	@param [String] name app name
	@param [String] path app path
	@param [String] cssProcessor app css processor
	@param [String] frontEndFramework  app frontEnd framework
	@param [String] storage  app storage
	@param [String] templateEngine app template Engine
	@param [Bool] live boolean showing if app is running
	@param [String] created app creation date
	@param [String, Date] lastActive app last active date
	@param [Number] pid app pid
	###
	constructor: ({@name, @path, @cssProcessor, @frontEndFramework, @storage, @templateEngine, @live, @created, @lastActive, @pid}) ->

	###
	Add app shim method 
	@param [Function] cb callback function 
	###
	add: (cb) ->
		return @store 'add', cb

	###
	Save app shim method 
	@param [Function] cb callback function 
	###
	save: (cb) ->
		return @store 'save', cb

	###
	Store app to databse function
	@param [String] cmd  command add or save
	@param [Function] cb callback function
	###
	store: (cmd, cb) ->
		db.serialize =>
			db.run App::query.INIT
			if cmd.match /save/
				stmt = db.prepare App::query.SAVE
				stmt.run @path, @cssProcessor, @frontEndFramework, @storage, @templateEngine, @live, @created, @lastActive, @pid, @name 
			else
				stmt = db.prepare App::query.ADD
				stmt.run @name, @path, @cssProcessor, @frontEndFramework, @storage, @templateEngine, @live, @created, @lastActive, @pid
			stmt.finalize()
			if cb then cb null, @

	###
	Get file path in app directory
	@param [String] path to file 
	###
	file: (path) ->
		return utils.path.join @path, path

	###
	Set app properties to `off` on stop
	###
	stop: ->
		@live = false
		@lastActive = new Date().getTime()
		@pid = 0

	###
	Set app properties to `on` on start
	@param [Number] pid process id numer
	###
	start: (pid) ->
		@live = true
		@lastActive = new Date().getTime()
		@pid = pid

	###
	Get which app is currently live.
	@param [Function] cb callback function
	###
	@live: (cb) ->
		db.serialize =>
			db.all App::query.LIVE, (err, rows) ->
				if cb and rows
					apps = []
					apps.push new App row for row in rows
					cb err, apps
				else if cb and not rows
					cb err, null

	###
	Find app by name in db or get all apps from db
	@param [String] name app id name
	@param [Function] cb callback function
	###
	@find: (name, cb) ->
		db.serialize =>
			db.run App::query.INIT
			if not not name
				db.each App::query.FIND_ONE, name, (err, row) ->
					if cb then cb err, new App row
			else
				db.all App::query.FIND, (err, rows) ->
					if cb and rows
						apps = []
						apps.push new App row for row in rows
						cb err, apps
					else if cb and not rows
						cb err, null

	###
	Remove app by name from db
	@param [String] name app id name
	@param [Function] cb callback function
	###
	@remove:(name, cb) ->
		@find name, (err, row) =>
			if err then cb err, row
			if row
				path = row['path']
				db.run App::query.REMOVE, name, (err, success) ->
					if not err
						utils.fs.removeSync path
						if cb then cb null, "#{name} was successfully removed."
					else
						if cb then cb "#{name} was not removed.", null

	###
	Start app method
	@param [App] app 
	@param [Function] cb callback function
	###
	@start: (app, cb) ->
		file = app.file '/app.js'
		log = "#{utils.root}/config/.log"
		out = utils.fs.openSync log, 'a'
		err = utils.fs.openSync log, 'a'
		start = utils.spawn 'node', [file], {
			detached: true
			stdio: ['ignore', out, err]
		}
		app.start start.pid 
		app.save (err, app) =>
			if cb then cb err, app

	###
	Stop app method
	@param [App] app 
	@param [Function] cb callback function
	###
	@stop: (app, cb) ->
		if app.live
			utils.spawnSync 'kill', ['-SIGTERM', app.pid]
			app.stop()
			app.save (err, app) =>
				if cb then cb err, app
		else return true

	###
	Add api to app
	@param [String] name app id name
	@param [String] api api name to add
	@param [Function] cb callback function
	###
	@addApi: (name, api, cb) ->
		@find name, (err, row) =>
			if err then cb err, row
			if row
				app = new App row
				utils.installApi api, app, (error, stdout, stderr) ->
					cb error, app

	###
	Remove api to app
	@param [String] name app id name
	@param [String] api api name to add
	@param [Function] cb callback function
	###
	@removeApi: (name, api, cb) ->
		@find name, (err, row) =>
			if err then cb err, row
			if row
				app = new App row
				utils.uninstallApi api, app, (error, stdout, stderr) ->
					cb error, app

	###
	Add package to app
	@param [String] name app id name
	@param [String] pkg packge name to add
	@param [Function] cb callback function
	###
	@addModule: (name, pkg, cb) ->
		@find name, (err, row) =>
			if err then cb err, row
			if row
				app = new App row
				process.chdir app.path
				utils.install [pkg], '--save', (error, stdout, stderr) ->
					cb error, app

	###
	Remove package to app
	@param [String] name app id name
	@param [String] pkg packge name to add
	@param [Function] cb callback function
	###
	@removeModule: (name, pkg, cb) ->
		@find name, (err, row) =>
			if err then cb err, row
			if row
				app = new App row
				process.chdir app.path
				utils.uninstall [pkg], (error, stdout, stderr) ->
					cb error, app

# export app module
module.exports = App