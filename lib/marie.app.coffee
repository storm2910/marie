###
@namespace marie
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
storage = utils.configureStorage()

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

	db: new storage.Database utils.path.join __dirname.replace('/marie/lib', '/marie/config'), '/.db'
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
		App::db.serialize =>
			App::db.run App::query.INIT
			if cmd.match /save/
				stmt = App::db.prepare App::query.SAVE
				stmt.run @path, @cssProcessor, @frontEndFramework, @storage, @templateEngine, @live, @created, @lastActive, @pid, @name 
			else
				stmt = App::db.prepare App::query.ADD
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
	Change process to app root directory
	###
	cwd: ->
		if process.cwd() != @path then process.chdir @path
		return @path

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
		App::db.serialize =>
			App::db.all App::query.LIVE, (err, rows) ->
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
		App::db.serialize =>
			App::db.run App::query.INIT
			if not not name
				App::db.each App::query.FIND_ONE, name, (err, row) ->
					if cb then cb err, new App row
			else
				App::db.all App::query.FIND, (err, rows) ->
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
				App::db.run App::query.REMOVE, name, (err, success) ->
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
	@addModule: (name, pkg, opt, cb) ->
		@find name, (err, row) =>
			if err then cb err, row
			if row
				app = new App row
				process.chdir app.path
				option = '--save'
				if opt and opt.match(/\-dev/gi) then option = '--save-dev'
				utils.install [pkg], option, (error, stdout, stderr) ->
					cb error, app

	###
	Remove package to app
	@param [String] name app id name
	@param [String] pkg packge name to add
	@param [Function] cb callback function
	###
	@removeModule: (name, pkg, opt, cb) ->
		@find name, (err, row) =>
			if err then cb err, row
			if row
				app = new App row
				process.chdir app.path
				option = '--save'
				if opt and opt.match(/\-dev/gi) then option = '--save-dev'
				utils.uninstall [pkg], option, (error, stdout, stderr) ->
					cb error, app

	###
	Remove package to app
	@param [String] name app id name
	@param [Function] cb callback function
	###
	@getConfig: (name, key, cb) ->
		@find name, (err, row) =>
			if err then cb err, row
			if row
				app = new App row
				pkg_file = app.file 'package.json'
				config = JSON.parse utils.fs.readFileSync pkg_file, @utf8
				if key then config = config[key]
				cb null, config

	###
	Remove package to app
	@param [String] name app id name
	@param [Function] cb callback function
	###
	@configureTasManager: (app, cb) ->
		app.cwd()
		utils.configureTasManagerFor app, cb

	###
	Remove package to app
	@param [String] name app id name
	@param [Function] cb callback function
	###
	@configureCoffeeScript: (app, cb) ->
		app.cwd()
		utils.configureCoffeeScriptFor app, cb

	###
	Remove package to app
	@param [String] name app id name
	@param [Function] cb callback function
	###
	@configureJade: (app, cb) ->
		app.cwd()
		utils.configureJadeFor app, cb

	###
	Remove package to app
	@param [String] name app id name
	@param [Function] cb callback function
	###
	@configureStylus: (app, cb) ->
		app.cwd()
		utils.configureStylusFor app, cb

	###
	Remove package to app
	@param [String] name app id name
	@param [Function] cb callback function
	###
	@configureFrontEndFramework: (app, framework, cb) ->
		app.frontEndFramework = framework
		utils.configureFrontEndFrameworkFor app, cb

	###
	Remove package to app
	@param [String] name app id name
	@param [Function] cb callback function
	###
	@configureBundles: (app, cb) ->
		utils.configureBundlesFor app, cb

	###
	Remove package to app
	@param [String] name app id name
	@param [Function] cb callback function
	###
	@configureNativeDB: (app, cb) ->
		app.storage = utils.storageType.LOCAL
		utils.setupDBWithConfigFor app, null, cb

	###
	Remove package to app
	@param [String] name app id name
	@param [Function] cb callback function
	###
	@configureMongoDB: (app, config, cb) ->
		app.cwd()
		if config.constructor == String 
			utils.configureRemoteMongoDBWithURIFor app, config, cb
		else 
			utils.configureRemoteMongoDBWithConfigFor app, config, cb

	###
	Remove package to app
	@param [String] name app id name
	@param [Function] cb callback function
	###
	@configureLocalMongoDB: (app, cb) ->
		app.cwd()
		utils.configureLocalMongoDBFor app, cb
			
# export ap module
module.exports = App