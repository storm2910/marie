###
@namespace marie
@include marie.app
@property [Array<String>] args encoding action commands and routes
@property [App] app app being modified
@property [String] root process root directory
@author Teddy Moussignac (teddy.moussignac@gmail.com)
@version 0.0.3
@copyright March 2016 
@note Marie core class. Marie app logic definition
###

utils = require './marie.utils'
ui = require './marie.ui'
App = require './marie.app'

class Marie
	@app
	@args
	@config
	@root
	@routes

	###
	Construct App
	@param [Array<String>] args encoding action commands and routes
	@param [String] root directory 
	###
	constructor: (@args, @root) ->
		@config = JSON.parse(utils.fs.readFileSync(utils.path.join(utils.root, 'package.json'), utils.encoding.UTF8))
		@configureRoutes()
		@configureCommands()
		@route()

	###
	Configure application routes
	###
	configureRoutes: ->	
		@routes =
			'add': @add
			'doc': @doc
			'list': @list
			'log': @log
			'live': @live
			'remove': @remove
			'restart': @restart
			'start': @start
			'stop': @stop
			'version': @version

	###
	Configure application route commands
	###
	configureCommands: ->	
		@commands =
			'api':
				'add': @addApi
				'remove': @removeApi
			'module':
				'add': @addModule
				'remove': @removeModule

	###
	Process app route
	###
	route: ->
		len = @args.length - 1
		route = @args[2]
		if route == 'add'
			name = @args[3]
			cssPreProcessor = @args[4]
			viewEngine = @args[5]
			jsCompiler = @args[6]
			@add name, cssPreProcessor, viewEngine, jsCompiler
		else if @routes[route]?
			arg = @args[3] or null
			opt = @args[4] or null
			@routes[route] arg, opt
		else
			cmd = @args[3] or null
			arg = @args[4] or null
			key = @args[5] or null
			opt = @args[6] or null
			if cmd and cmd is 'list' then @list route, arg, key, opt
			else if cmd and cmd is 'set' then @configureMore route, arg, key, opt
			else if cmd and arg and @commands[arg][cmd]? then @commands[arg][cmd] route, key, opt
			else @listHelp()

	###
	Confgiure the default express/sails application framework
	will try to install sails if not already installed. 
	@param [String] name app name
	@param [String] cssPreProcessor app cssPreProcessor
	@param [String] viewEngine app viewEngine
	@param [String] jsCompiler app compiler
	###
	new: (name, cssPreProcessor, viewEngine, jsCompiler) ->
		id = utils.configureId name
		config =
			id: id
			name: name
			path: utils.path.join @root, id
			jsCompiler: jsCompiler
			cssPreProcessor: cssPreProcessor
			viewEngine: viewEngine
			live: 0
			storage: utils.storage.DISK.name
			created: utils.now()
			lastActive: null
			pid: null
		utils.fs.stat config.path, (err, stats) =>
			if err
				App.find config.id, (err, exists) =>
					if not exists
						ui.header 'Creating', config.name
						@app = new App config
						@configureSails()
					else 
						ui.notice "#{exists.name} already exists."
						ui.notice "Path: #{exists.path}"
						ui.notice "Name Suggestion: #{exists.name}-2"
			else 
				ui.notice "#{config.name} already exists."
				ui.notice "Path: #{config.path}"
				ui.notice "Name Suggestion: #{config.name}-2"

	###
	Confgiure the default express/sails application framework
	will try to install sails if not already installed. 
	###
	configureSails: ->
		ui.write 'Configuring Sails...'
		utils.exe 'sails', ['--version', @app.id], (error, stdout, stderr) =>
			if error
				utils.exe 'npm', ['install', "sails@#{utils.sailsVersion}", '-g'], (error, stdout, stderr) =>
					if error 
						ui.error 'An error occured.'
						ui.notice "Run `sudo npm install sails@#{utils.sailsVersion} -g` then try again."
					else
						@configureSails()
			else
				version = utils.trim stdout
				isSails = version == utils.sailsVersion
				if isSails
					utils.exe 'sails', ['generate', 'new', @app.id], (error, stdout, stderr) =>
						if error
							@throwFatalError error
						else
							ui.ok 'Sails configuration done.'
							process.chdir @app.path
							@configureTasManager @app
				else
					utils.exe 'npm', ['uninstall', 'sails', '-g'], (error, stdout, stderr) =>
						if error 
							utils.throwError error
						else
							@configureSails()

	###
	Configure grunt as the default task manager
	Also configure coffee files importer module
	Setup for assets coffee files in `/assets/js`
	@param [App] 
	###
	configureTasManager: (app) ->
		ui.write 'Configuring Grunt...'
		App.configureTasManager app, (err, app) =>
			if err then @throwFatalError err 
			if app 
				ui.ok 'Grunt configuration done.'
				@configureJsCompiler app

	###
	Configure app js Compiler
	@param [App] 
	###
	configureJsCompiler: (app) ->
		if utils.isCoffee(app) then @configureCoffeeScript app
		else @configureViewEngine app

	###
	Configure coffeScript as the default js compiler
	@param [App] 
	###
	configureCoffeeScript: (app) =>
		ui.write 'Configuring CoffeeScript...'
		App.configureCoffeeScript app, (err, app) =>
			if err then @throwFatalError err 
			else 
				ui.ok 'CoffeeScript configuration done.'
				@configureViewEngine app

	###
	Configure app template engine
	@param [App] 
	###
	configureViewEngine: (app) ->
		switch app.viewEngine
			when utils.engines.EJS.id then @configureEJS app
			when utils.engines.HANDLEBARS.id then @configureHandlerbars app
			else @configureJade app

	###
	Configure jade as the default view templating engine
	Disable `ejs` + add the default jade template files
	@param [App] 
	###
	configureJade: (app) =>
		ui.write 'Configuring Jade...'
		App.configureJade app, (err, app) =>
			if err then @throwFatalError err 
			else 
				ui.ok 'Jade configuration done.'
				@configureCssPreProcessor app

	###
	Configure jade as the default view templating engine
	Disable `ejs` + add the default jade template files
	@param [App] 
	###
	configureEJS: (app) =>
		ui.write 'Configuring EJs...'
		App.configureEJS app, (err, app) =>
			if err then @throwFatalError err 
			else 
				ui.ok 'EJs configuration done.'
				@configureCssPreProcessor app

	###
	Configure jade as the default view templating engine
	Disable `ejs` + add the default jade template files
	@param [App] 
	###
	configureHandlerbars: (app) =>
		ui.write 'Configuring Handlebars...'
		App.configureHandlebars app, (err, app) =>
			if err then @throwFatalError err 
			else 
				ui.ok 'Handlebars configuration done.'
				@configureCssPreProcessor app

	###
	Configure css pre-processor
	@param [App] 
	###
	configureCssPreProcessor: (app) ->
		switch app.cssPreProcessor
			when utils.processors.SCSS.id then @configureScss app
			when utils.processors.STYLUS.id then @configureStylus app
			else @configureLess app

	###
	Configure less as css pre-processor
	@param [App] 
	###
	configureLess:(app) =>
		ui.write 'Configuring Less...'
		App.configureLess app, (err, app) =>
			if err then @throwFatalError err 
			else
				ui.ok 'Less configuration done.'
				@configureBundles app

	###
	Configure less as css pre-processor
	@param [App] 
	###
	configureScss:(app) =>
		ui.write 'Configuring Sass...'
		App.configureScss app, (err, app) =>
			if err then @throwFatalError err 
			else
				ui.ok 'Sass configuration done.'
				@configureBundles app

	###
	Configure stylus as css pre-processor
	@param [App] 
	###
	configureStylus:(app) =>
		ui.write 'Configuring Stylus...'
		App.configureStylus app, (err, app) =>
			if err then @throwFatalError err 
			else
				ui.ok 'Stylus configuration done.'
				@configureBundles app

	###
	Configure default bundle files
	@param [App] 
	@param [Boolean] skip 
	###
	configureBundles: (app, skip) ->
		ui.ok "configure bundles"
		App.configureBundles app, (err, app) =>
			if err then @throwFatalError err 
			else
				ui.ok 'Frontend configuration done.'
				if not not skip
					app.save (err, app) =>
						@restart()
					return false
				else @configureDB app

	###
	Let you choose between localDisk and a mongo database
	@param [App] 
	@param [Boolean] skip 
	###
	configureDB: (app, db, url, skip) ->
		if db then app.storage = db
		switch app.storage
			when utils.storage.MONGODB.name then @configureMongoDb url, app, skip
			when utils.storage.MYSQL.name then @configureMySQL url, app, skip
			when utils.storage.POSTGRESQL.name then @configurePostgreSQL url, app, skip
			when utils.storage.REDIS.name then @configureRedis url, app, skip
			else @configureLocalDisk url, app, skip

	###
	Configure localDisk as the default data storage
	@param [App] 
	@param [Boolean] skip 
	###
	configureLocalDisk: (url, app, skip) =>
		ui.write "Configuring Local Disk..."
		@configureStorage null, app, skip

	###
	Generic db configuration method
	@param [String] url 
	@param [App] app
	@param [Boolean] skip 
	###
	configureMongoDb: (url, app, skip) =>
		ui.write "Configuring MongoDb..."
		@configureStorage url, app, skip

	###
	Generic db configuration method
	@param [String] url 
	@param [App] app
	@param [Boolean] skip 
	###
	configureMySQL: (url, app, skip) =>
		ui.write "Configuring MySQL..."
		@configureStorage url, app, skip
	
	###
	Generic db configuration method
	@param [String] url 
	@param [App] app
	@param [Boolean] skip 
	###
	configurePostgreSQL: (url, app, skip) =>
		ui.write "Configuring PostgreSQL..."
		@configureStorage url, app, skip

	###
	Generic db configuration method
	@param [String] url 
	@param [App] app
	@param [Boolean] skip 
	###
	configureRedis: (url, app, skip) =>
		ui.write "Configuring Redis..."
		@configureStorage url, app, skip

	###
	Generic db configuration method
	@param [String] url 
	@param [App] app
	@param [Boolean] skip 
	###
	configureStorage:(url, app, skip) =>
		App.configureStorage app, url, (err, app) =>
			if err then utils.throwError err 
			else
				ui.ok "#{app.storage} database configuration done."
				@save app, skip

	###
	If something goes really bad. Stop everything
	Remove everything and exit process
	@param [Object, String] error 
	###
	throwFatalError: (error) ->
		utils.fs.stat @app.path, (err, stats) =>
			if not err
				utils.fs.removeSync @app.path
				App.remove @app.id
				utils.throwError error
			else
				utils.throwError error

	###
	Save app to marie database
	@param [App] 
	###
	save: (app, skip) ->
		if not not skip
			app.save (err, app) =>
				if err then utils.throwError err 
				else @restart()
			return false
		else
			app.add (err, app) =>
				if err then @throwFatalError err
				else @onSave app

	###
	App creation callback method
	Will ask to start newly created app
	###
	onSave: (app) ->
		ui.notice "#{app.name} was successfully created."
		ui.notice "Id: #{app.id}"
		ui.notice "Path: #{app.path}"
		ui.notice "Done."

	###
	Configure `add` app method. Creates new app
	@param [String] name app name
	@param [String] cssPreProcessor app cssPreProcessor
	@param [String] viewEngine app viewEngine
	@param [String] jsCompiler app compiler
	###	
	add: (name, cssPreProcessor, viewEngine, jsCompiler) ->
		valid = true
		if not name
			ui.error 'Missing field: app name.'
			valid = false
		if cssPreProcessor and not utils.getProcessor cssPreProcessor
			ui.error 'Invalid css pre-processor argument.'
			ui.notice "Supported pre-processors: #{utils.processorList().join(', ')}"
			valid = false
		if viewEngine and not utils.getEngine viewEngine
			ui.error 'Invalid view engine argument.'
			ui.notice "Supported engines: #{utils.engineList().join(', ')}"
			valid = false
		if jsCompiler and not utils.getCompiler jsCompiler
			ui.error 'Invalid JS compiler argument.'
			ui.notice "Supported compilers: #{utils.compilerList().join(', ')}"
			valid = false
		preocessor = utils.getProcessor(cssPreProcessor).id or utils.processors.LESS.id
		engine = utils.getEngine(viewEngine).id or utils.engines.JADE.id
		compiler = utils.getCompiler(jsCompiler).name or utils.compilers.NATIVE.name
		if valid then @new name, preocessor, engine, compiler

	###
	Configure `list` app command handler. 
	Retrive and List all apps or single app method
	@param [String] arg 
	@param [String] key
	@param [String] opt
	###
	list: (arg, key, opt) =>
		App.find arg, (err, data) =>
			if err then utils.throwError err
			else
				if not not key
					if key is 'api' then @listApis arg
					else if key is 'module' then @listModules arg, opt
					else if key is 'config' then @listConfig arg, opt
					else
						app = new App data
						for k of app
							_k = k.toLowerCase()
							if key is _k then ui.notice app[k]
				else console.log data

	###
	Configure `live` app command handler. Get all live app
	@example `marie live`
	###
	live: =>
		App.live (err, app) =>
			if err then utils.throwError err
			else if app then console.log app
			else ui.notice 'No app is live.'

	###
	Configure `doc` method
	###
	doc: =>
		ui.notice @config.homepage

	###
	Configure `version` method
	###
	version: =>
		ui.notice @config.version

	###
	Configure `remove` app command handler. Remove app from system
	###
	remove: (arg, opt) =>
		# if not not arg then @_remove arg
		# else @missingArgHandler()
		if not not arg
			if arg == '--reset'
				App.reset (err, success) =>
					if err then utils.throwError err
					else ui.ok success
			else
				App.remove arg, (err, success) =>
					if err then utils.throwError err
					else ui.ok success
		else @missingArgHandler()

	###
	Configure `start` app command handler. start app
	@param [String] arg app id
	###
	start: (id) =>
		App.live (err, data) =>
			if err then utils.throwError err
			else if data
				@stop null, =>
					@_run 'start', id
			else
				return @_run 'start', id

	###
	Configure `stop` app command handler. Stops app or stop all apps
	@param [String?] arg optional app id
	###
	stop: (id, cb) =>
		App.live (err, data) =>
			if err then utils.throwError err
			else if data 
				app = new App data
				@_stop app, cb
			else return @_run 'stop', id, cb

	###
	Configure `restart` app command handler. Restarts current live app
	@param [String?] arg optional app id
	###
	restart: (arg) =>
		App.live (err, data) =>
			if err then utils.throwError err
			else if data
				app = new App data
				@_stop app, =>
					@_start app
			else
				if not arg then ui.notice 'No app is live.'

	###
	Configure system start app method
	@param [App] app app to start
	###
	_start: (app) ->
		App.start app, (err, app) =>
			if err then utils.throwError err
			else
				ui.write "Starting #{app.name}..."
				setTimeout =>
					ui.ok "#{app.name} started."
					ui.notice "Url: http://localhost:1337"
					ui.notice "Path: #{app.path}"
					process.exit()
				, 1000

	###
	Configure system stop app method
	@param [App] app app to stop
	@example `_stop app`
	###
	_stop: (app, cb) ->
		ui.write "Stopping #{app.name}..."
		App.stop app, (err, app) =>
			if err then utils.throwError err 
			else 
				ui.ok "#{app.name} stopped."
				if cb then cb()

	###
	Configure system run app method.
	@param [String] arg 
	@param [String] cmd command sart/stop/restart
	###
	_run: (cmd, arg, cb) ->
		if not not arg
			App.find arg, (err, data) =>
				if err then utils.throwError err
				if data
					app = new App data
					if cmd.match /^stop/i
						@_stop app, =>
							app.stop()
							if cb then cb()
					else if cmd.match /^start/i
						@_start app
					else if cmd.match /^restart/i
						@_stop app, =>
							@_start app
		else
			if cmd.match /^stop/i
				ui.notice 'No app is live.'
			else
				@missingArgHandler()

	###
	Configure add api method
	@param [String] arg 
	@param [String] api api to add
	###
	addApi: (arg, api) =>
		if not not api 
			App.addApi arg, api, (err, app) =>
				if err then utils.throwError err
				else
					@app = app
					@restart()
					ui.ok "Added api #{api}"
		else @missingArgHandler()

	###
	Configure remove api method
	@param [String] arg 
	@param [String] api api to remove
	###
	removeApi: (arg, api) =>
		if not not api 
			App.removeApi arg, api, (err, app) =>
				if err then utils.throwError err
				else
					@app = app
					@restart()
					ui.ok "Removed api #{api}"
		else @missingArgHandler()

	###
	Configure add module method
	@param [String] arg 
	@param [String] pkg module to remove
	@param [String] opt
	###
	addModule: (arg, pkg, opt) =>
		if not not pkg
			ui.write "Adding `#{pkg}` module..."
			App.addModule arg, pkg, opt, (err, app) =>
				if err then utils.throwError err
				else
					@app = app
					@restart()
					ui.ok "Added module #{pkg}"
		else @missingArgHandler()

	###
	Configure remove module method
	@param [String] arg 
	@param [String] pkg module to remove
	@param [String] opt
	###
	removeModule: (arg, pkg, opt) =>
		if not not pkg
			ui.write "Removing `#{pkg}` module..."
			App.removeModule arg, pkg, opt, (err, app) =>
				if err then utils.throwError err
				else
					@app = app
					@restart()
					ui.ok "Removed module #{pkg}"
		else @missingArgHandler()

	###
	Configure list module method
	@param [String] arg 
	@param [String] key
	###
	listConfig: (arg, key) =>
		App.getConfig arg, key, (err, config) =>
			if err then utils.throwError err
			else
				if config.constructor == String then ui.notice config
				else console.log config

	###
	Configure list module method
	@param [String] arg 
	@param [String] opt
	###
	listModules: (arg, opt) =>
		App.getModules arg, opt, (err, config) =>
			if err then utils.throwError err
			else
				if config.constructor == String then ui.notice config
				else console.log config

	###
	Configure list module method
	@param [String] arg 
	###
	listApis: (arg) =>
		App.getApis arg, (err, config) =>
			if err then utils.throwError err
			else console.log config

	###
	Display system log method 
	###
	log: (arg) =>
		file = "#{utils.root}/config/.log"
		if arg and arg.match /clear/i
			utils.fs.stat file, (err, stats) ->
				if err then ui.notice 'Log is empty'
				else
					utils.fs.unlinkSync file
					ui.notice 'Log is empty'
		else
			utils.fs.stat file, (err, stats) ->
				if err then ui.notice 'Log is empty'
				else
					log = utils.fs.readFileSync file, utils.encoding.UTF8
					console.log '%s', log

	###
	cli configure command handler
	@param [String] arg 
	@param [String] key
	@param [String] opt
	###
	configureMore: (arg, key, opt, value) =>
		if not not key
			App.find arg, (error, data) =>
				if error then utils.throwError error
				else if data
					@app = new App data
					if key.match /db/i
						if not not opt
							if utils.storage[opt.toUpperCase()]
								if opt.toLowerCase() == 'disk'
									@configureDB @app, opt, null, true
								else
									if not not value
										@configureDB @app, opt, value, true
									else
										@missingArgHandler()
							else
								ui.error 'Invalid storage argument.'
								ui.notice "Supported databases: #{utils.storageList().join(', ')}"
						else
							@missingArgHandler()
					else
						@missingArgHandler()
		else
			@missingArgHandler()

	###
	configure missing/invalid arg handler
	###
	missingArgHandler: ->
		ui.notice 'invalid or missing argument.'

	###
	display help
	###
	listHelp: =>
		help = utils.fs.readFileSync utils.path.join(utils.root, 'help.txt'), utils.UTF8
		ui.notice 'Valid commands:'
		console.log '%s', help
		console.log '  %s', @config.homepage
		console.log ''

# export marie module
module.exports = Marie