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
		@::db.serialize =>
			@::db.run @::query.INIT
			if cmd.match /save/
				stmt = @::db.prepare @::query.SAVE
				stmt.run @path, @cssProcessor, @frontEndFramework, @storage, @templateEngine, @live, @created, @lastActive, @pid, @name 
			else
				stmt = @::db.prepare @::query.ADD
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
		@::db.serialize =>
			@::db.all @::query.LIVE, (err, rows) ->
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
		@::db.serialize =>
			@::db.run @::query.INIT
			if not not name
				@::db.each @::query.FIND_ONE, name, (err, row) ->
					if cb then cb err, new App row
			else
				@::db.all @::query.FIND, (err, rows) ->
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
			else if row
				app = new App row
				remove = =>
					@::db.run @::query.REMOVE, app.name, (err, success) =>
						if not err
							utils.fs.removeSync app.path
							if cb then cb null, "#{name} was successfully removed."
						else
							if cb then cb "#{name} was not removed.", null
				if not not app.pid
					@stop app, (err, app) ->
						remove()
				else  remove()
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
				app.cwd()
				utils.installApi api, (error, stdout, stderr) ->
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
				app.cwd()
				option = '--save'
				if not not opt
					if opt.match /\-d/ then option = '--save-dev'
					else if opt.match /\-f/ then option = '--front-end'
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
				if not not opt
					if opt.match /\-d/ then option = '--save-dev'
					else if opt.match /\-f/ then option = '--front-end'
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
				file = app.file 'package.json'
				config = JSON.parse utils.fs.readFileSync file, utils.encoding.UTF8
				if key then config = config[key]
				cb null, config

	###
	Remove package to app
	@param [String] name app id name
	@param [Function] cb callback function
	###
	@getModules: (name, key, cb) ->
		@find name, (err, row) =>
			if err then cb err, row
			if row
				app = new App row
				file = app.file 'package.json'
				config = JSON.parse utils.fs.readFileSync file, utils.encoding.UTF8
				modules = 
					save: config.dependencies 
					dev: config.devDependencies
				if not not key
					if key.match /\-d/ then modules = config.devDependencies
					else if key.match /\-s/ then modules = config.dependencies
					else if key.match /\-f/
						modules = {}
						assets = 'assets/modules'
						dirs = utils.fs.readdirSync app.file assets
						for dir in dirs
							file = app.file "#{assets}/#{dir}/.bower.json"
							config = JSON.parse utils.fs.readFileSync file, utils.encoding.UTF8
							modules["#{config.name}@#{config.version}"] = "/modules/#{dir}/#{config.main}"
				cb null, modules

	###
	@param [String] name app id name
	@param [Function] cb callback function
	###
	@getApis: (name, cb) ->
		@find name, (err, row) =>
			if err then cb err, row
			else if row
				app = new App row
				apis = []
				file = app.file '/api/controllers'
				ctrls = utils.fs.readdirSync file
				for ctrl in ctrls
					if not ctrl.match /^\./
						api = (ctrl.replace /controller|\.coffee/gi, '').toLowerCase()
						apis.push api
				cb null, apis

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

	###
	Remove package to app
	@param [String] name app id name
	@param [Function] cb callback function
	###
	@configureApis: (app, apis, cb) ->
		app.cwd()
		utils.installApis apis, @app
		cb null, app
			
# export ap module
module.exports = App