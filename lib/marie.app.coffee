###
@namespace marie
@include marie.query
@property [String] name app name
@property [String] path app path
@property [String] cssPreProcessor app css processor
@property [String] id app id
@property [String] storage  app storage
@property [String] viewEngine app template Engine
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
query = require './marie.query'
storage = utils.configureStorage()

class App
	@created
	@cssPreProcessor
	@id
	@lastActive
	@live
	@name
	@path
	@pid
	@storage
	@viewEngine

	db: new storage.Database utils.path.join process.env.HOME, '.marie_db'
	query: query

	###
	Construct App
	@param [String] name app name
	@param [String] path app path
	@param [String] jsCompiler app js compiler
	@param [String] cssPreProcessor app css processor
	@param [String] storage  app storage
	@param [String] viewEngine app template Engine
	@param [Bool] live boolean showing if app is running
	@param [String] created app creation date
	@param [String, Date] lastActive app last active date
	@param [Number] pid app pid
	###
	constructor: ({@id, @name, @path, @jsCompiler, @cssPreProcessor, @storage, @viewEngine, @live, @created, @lastActive, @pid}) ->

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
		@db.serialize =>
			@db.run @.query.INIT
			if cmd.match /save/
				stmt = @db.prepare @.query.SAVE
				stmt.run @path, @jsCompiler, @cssPreProcessor, @storage, @viewEngine, @live, @created, @lastActive, @pid, @id 
			else
				stmt = @db.prepare @.query.ADD
				stmt.run @id, @name, @path, @jsCompiler, @cssPreProcessor, @storage, @viewEngine, @live, @created, @lastActive, @pid
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
		@lastActive = utils.now()
		@pid = 0

	###
	Set app properties to `on` on start
	@param [Number] pid process id numer
	###
	start: (pid) ->
		@live = true
		@lastActive = utils.now()
		@pid = pid

	###
	Get which app is currently live.
	@param [Function] cb callback function
	###
	@live: (cb) ->
		@::db.serialize =>
			@::db.all @::query.LIVE, (err, rows) =>
				if cb and rows and rows.length > 0
					cb err, rows[0]
				else
					cb err, null

	###
	Find app by id in db or get all apps from db
	@param [String] id app id
	@param [Function] cb callback function
	###
	@find: (id, cb) ->
		@::db.serialize =>
			@::db.run @::query.INIT
			if not not id
				@::db.all @::query.FIND_ONE, id, (err, rows) =>
					if err then utils.throwError err 
					else if not not rows.length
						cb err, rows[0]
					else
						if cb then cb err, null
			else
				@::db.all @::query.FIND, (err, rows) =>
					if err then utils.throwError err 
					else if cb and rows
						apps = []
						apps.push row for row in rows
						cb err, apps
					else if cb and not rows
						cb err, null

	###
	Reset database. Remove all apps
	@param [Function] cb callback function
	###
	@reset:(cb) ->
		@find null, (err, rows) =>
			if err then utils.throwError err 
			else if rows
				for row in rows
					@remove row.id, cb

	###
	Remove app by id from db
	@param [String] id app id
	@param [Function] cb callback function
	###
	@remove:(id, cb) ->
		@find id, (err, row) =>
			if err then cb err, row
			else if row
				app = new @ row
				remove = =>
					@::db.run @::query.REMOVE, app.id, (err, success) =>
						if not err
							utils.fs.removeSync app.path
							if cb then cb null, "#{app.name} was successfully removed."
						else
							if cb then cb "#{app.name} was not removed.", null
				if not not app.pid
					@stop app, (err, app) ->
						remove()
				else  remove()
			else
				if cb then cb "#{id} was not removed.", null

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
		else
			if cb then cb null, app

	###
	Add api to app
	@param [String] id app id
	@param [String] api api name to add
	@param [Function] cb callback function
	###
	@addApi: (id, api, cb) ->
		@find id, (err, row) =>
			if err then cb err, row
			if row
				app = new @ row
				app.cwd()
				utils.installApi api, app, (error, stdout, stderr) ->
					cb error, app

	###
	Remove api to app
	@param [String] id app id
	@param [String] api api name to add
	@param [Function] cb callback function
	###
	@removeApi: (id, api, cb) ->
		@find id, (err, row) =>
			if err then cb err, row
			if row
				app = new @ row
				app.cwd()
				utils.uninstallApi api, app, (error, stdout, stderr) ->
					cb error, app

	###
	Add package to app
	@param [String] id app id
	@param [String] pkg packge name to add
	@param [String] opt
	@param [Function] cb callback function
	###
	@addModule: (id, pkg, opt, cb) ->
		@find id, (err, row) =>
			if err then cb err, row
			if row
				app = new @ row
				app.cwd()
				option = '--save'
				if not not opt
					if opt.match /\-d/ then option = '--save-dev'
					else if opt.match /\-f/ then option = '--front-end'
				utils.install [pkg], option, (error, stdout, stderr) ->
					cb error, app

	###
	Remove package to app
	@param [String] id app id
	@param [String] pkg packge name to add
	@param [String] opt
	@param [Function] cb callback function
	###
	@removeModule: (id, pkg, opt, cb) ->
		@find id, (err, row) =>
			if err then cb err, row
			if row
				app = new @ row
				process.chdir app.path
				option = '--save'
				if not not opt
					if opt.match /\-d/ then option = '--save-dev'
					else if opt.match /\-f/ then option = '--front-end'
				utils.uninstall [pkg], option, (error, stdout, stderr) ->
					cb error, app

	###
	Get app config
	@param [String] id app id
	@param [String] key to get
	@param [Function] cb callback function
	###
	@getConfig: (id, key, cb) ->
		@find id, (err, row) =>
			if err then cb err, row
			if row
				app = new @ row
				file = app.file 'package.json'
				config = JSON.parse utils.fs.readFileSync file, utils.encoding.UTF8
				if key then config = config[key]
				else config = JSON.stringify config
				cb null, config

	###
	Get app modules
	@param [String] name app id name
	@param [String] key to get
	@param [Function] cb callback function
	###
	@getModules: (id, key, cb) ->
		@find id, (err, row) =>
			if err then cb err, row
			if row
				app = new @ row
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
	@param [String] id app id
	@param [Function] cb callback function
	###
	@getApis: (id, cb) ->
		@find id, (err, row) =>
			if err then cb err, row
			else if row
				app = new @ row
				apis = []
				file = app.file '/api/controllers'
				ctrls = utils.fs.readdirSync file
				for ctrl in ctrls
					if not ctrl.match /^\./
						if utils.isCoffee(app)
							api = (ctrl.replace /controller|\.coffee/gi, '').toLowerCase()
						else
							api = (ctrl.replace /controller|\.js/gi, '').toLowerCase()
						apis.push api
				cb null, apis

	###
	Remove package to app
	@param [String] app
	@param [Function] cb callback function
	###
	@configureTasManager: (app, cb) ->
		app.cwd()
		utils.configureTasManagerFor app, cb

	###
	Remove package to app
	@param [String] app
	@param [Function] cb callback function
	###
	@configureCoffeeScript: (app, cb) ->
		app.cwd()
		utils.configureCoffeeScriptFor app, cb

	###
	Remove package to app
	@param [String] app
	@param [Function] cb callback function
	###
	@configureEJS: (app, cb) ->
		app.cwd()
		utils.configureEJSFor app, cb

	###
	Remove package to app
	@param [String] app
	@param [Function] cb callback function
	###
	@configureJade: (app, cb) ->
		app.cwd()
		utils.configureJadeFor app, cb

	###
	Remove package to app
	@param [String] app
	@param [Function] cb callback function
	###
	@configureHandlebars: (app, cb) ->
		app.cwd()
		utils.configureHandlebarsFor app, cb

	###
	Remove package to app
	@param [String] app
	@param [Function] cb callback function
	###
	@configureLess: (app, cb) ->
		app.cwd()
		utils.configureLessFor app, cb

	###
	Remove package to app
	@param [String] app
	@param [Function] cb callback function
	###
	@configureScss: (app, cb) ->
		app.cwd()
		utils.configureScssFor app, cb

	###
	Remove package to app
	@param [String] app
	@param [Function] cb callback function
	###
	@configureStylus: (app, cb) ->
		app.cwd()
		utils.configureStylusFor app, cb

	###
	Remove package to app
	@param [String] app
	@param [Function] cb callback function
	###
	@configureBundles: (app, cb) ->
		app.cwd()
		utils.configureBundlesFor app, cb

	###
	Remove package to app
	@param [String] app
	@param [Object, String] config
	@param [Function] cb callback function
	###
	@configureStorage: (app, url, cb) ->
		app.cwd()
		utils.configureStorageFor app, url, cb

# export ap module
module.exports = App