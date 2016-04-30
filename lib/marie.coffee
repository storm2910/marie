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
			storage = @args[6]
			@add name, cssPreProcessor, viewEngine, storage
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
	@param [String] storage app storage
	###
	new: (name, cssPreProcessor, viewEngine, storage) ->
		id = utils.configureId name
		config =
			id: id
			name: name
			path: utils.path.join @root, id
			cssPreProcessor: cssPreProcessor or 'less'
			viewEngine: viewEngine or 'jade'
			live: 0
			storage: storage or 'localDisk'
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
	@exmaple `npm install sails -g`
	###
	configureSails: ->
		ui.write 'Configuring Sails...'
		utils.exe 'sails', ['--version', @app.id], (error, stdout, stderr) =>
			if error
				utils.exe 'npm', ['install', utils.sails, '-g'], (error, stdout, stderr) =>
					if error 
						ui.error 'An error occured.'
						ui.notice "Run `sudo npm #{utils.sails} sails -g` then try again."
					else
						@configureSails()
			else
				version = utils.trim stdout
				isSails = version == utils.sailsVersion
				if isSails
					utils.exe 'sails', ['generate', 'new', @app.id], (error, stdout, stderr) =>
						if error
							utils.throwError error
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
	Also configure coffee files importer module + setup for assets coffee files in `/assets/js`
	@param [App] 
	@example #import User
	@example #import Page.coffee
	###
	configureTasManager: (app) ->
		ui.write 'Configuring Grunt...'
		App.configureTasManager app, (err, app) =>
			if err then utils.throwError err 
			if app 
				ui.ok 'Grunt configuration done.'
				@configureCoffeeScript app

	###
	Configure coffeScript as the default js compiler
	@param [App] 
	###
	configureCoffeeScript: (app) ->
		ui.write 'Configuring CoffeeScript...'
		App.configureCoffeeScript app, (err, app) =>
			if err then utils.throwError err 
			else 
				ui.ok 'CoffeeScript configuration done.'
				@configureViewEngine app

	###
	Configure app template engine
	@param [App] 
	###
	configureViewEngine: (app) ->
		engines =
			'jade': @configureJade
			'ejs': @configureEJS
			'handlebars': @configureHandlerbars
		engines[app.viewEngine.toLowerCase()] app

	###
	Configure jade as the default view templating engine
	Disable `ejs` + add the default jade template files
	@param [App] 
	@example /views/partials/partial.jade
	###
	configureJade: (app) =>
		ui.write 'Configuring Jade...'
		App.configureJade app, (err, app) =>
			if err then utils.throwError err 
			else 
				ui.ok 'Jade configuration done.'
				@configureCssPreProcessor app

	###
	Configure jade as the default view templating engine
	Disable `ejs` + add the default jade template files
	@param [App] 
	@example /views/partials/partial.jade
	###
	configureEJS: (app) =>
		ui.write 'Configuring EJs...'
		App.configureEJS app, (err, app) =>
			if err then utils.throwError err 
			else 
				ui.ok 'EJs configuration done.'
				@configureCssPreProcessor app

	###
	Configure jade as the default view templating engine
	Disable `ejs` + add the default jade template files
	@param [App] 
	@example /views/partials/partial.jade
	###
	configureHandlerbars: (app) =>
		ui.write 'Configuring Handlebars...'
		App.configureHandlebars app, (err, app) =>
			if err then utils.throwError err 
			else 
				ui.ok 'Handlebars configuration done.'
				@configureCssPreProcessor app

	###
	Configure css pre-processor
	@param [App] 
	###
	configureCssPreProcessor: (app) ->
		processors =
			'less': @configureLess
			'sass': @configureScss
			'scss': @configureScss
			'stylus': @configureStylus
		processors[app.cssPreProcessor.toLowerCase()] app

	###
	Configure less as css pre-processor
	@param [App] 
	###
	configureLess:(app) =>
		ui.write 'Configuring Less...'
		App.configureLess app, (err, app) =>
			if err then utils.throwError err 
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
			if err then utils.throwError err 
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
			if err then utils.throwError err 
			else
				ui.ok 'Stylus configuration done.'
				@configureBundles app

	###
	Configure default bundle files
	@param [App] 
	@example /assets/styles/bundles/default.ext
	@example /assets/styles/bundles/admin.ext
	###
	configureBundles: (app, skip) ->
		ui.ok "configure bundles"
		App.configureBundles app, (err, app) =>
			if err then utils.throwError err 
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
	@example localDisk/mongo
	###
	configureDB: (app, skip) ->
		@configureNativeDB app, skip
		# ui.warn 'Choose your database.'
		# utils.prompt.start()
		# input = ' Mongo/Disk'
		# ui.line()
		# utils.prompt.get [input], (err, result) =>
		# 	ui.line()
		# 	if result[input].match(/^m/i) then @configureMongoDB(app, skip) else @configureNativeDB(app, skip)

	###
	Configure localDisk as the default data storage
	@param [App] 
	###
	configureNativeDB: (app, skip) ->
		App.configureNativeDB app, (err, app) =>
			if err then utils.throwError err 
			else
				ui.ok "Local disk database configuration done."
				@save app

	###
	Configure mongoDB as the default data storage and choose between local or remote mongo
	@param [App] 
	###
	configureMongoDB: (app, skip) ->

	###
	Local mongodb database configuration
	@param [App] 
	###
	configureLocalMongoDB: (app, skip) ->
		ui.write "Configuring MongoDB..."
		App.configureLocalMongoDB app, (err, app) =>
			if err then utils.throwError err 
			else
				ui.ok "Local MongoDB database configuration done."
				@save app

	###
	Remote mongodb database configuration
	@todo
	@param [App] 
	###
	configureRemoteMongoDB: (app, skip) ->
		# input = [' mongodb uri']
		# utils.prompt.get input, (err, result) =>
		# 	ui.line()
		# 	uri = utils.trim result[input]
		# 	if uri.match(/\:|@/g)
		# 		ui.write "Configuring MongoDB..."
		# 		App.configureMongoDB app, uri, (err, app) =>
		# 			if err then utils.throwError err 
		# 			else
		# 				ui.ok "MongoDB database configuration done."
		# 				@save app
		# 	else
		# 		@configureRemoteMongoDBWithConfig app, skip

	###
	Remote mongodb database configuration
	@todo
	@param [App] 
	###
	configureRemoteMongoDBWithConfig: (app, skip) ->
		# inputs = [' host', ' port', ' user', ' password', ' database']
		# utils.prompt.get inputs, (err, result) =>
		# 	ui.line()
		# 	config =
		# 		host: result[' host'] or ''
		# 		port: result[' port'] or ''
		# 		user: result[' user'] or ''
		# 		password: result[' password'] or ''
		# 		database: result[' database'] or ''
		# 	ui.write "Configuring MongoDB..."
		# 	App.configureMongoDB app, config, (err, app) =>
		# 		if err then utils.throwError err 
		# 		else
		# 			ui.ok "MongoDB database configuration done."
		# 			@save app

	###
	If something goes really bad. Stop everything, remove everything and exit process
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
	@example marie list some-app
	###
	save: (app) ->
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
	@pparam [String] arg or app name
	@example `marie add dc-web`
	@example `marie new dc-web`
	###
	add: (name, cssPreProcessor, viewEngine, storage) =>
		if not not name then @new name, cssPreProcessor, viewEngine, storage
		else
			utils.throwError 'Missing field: app name.'
			return false

	###
	Configure `list` app command handler. Retrive and List all apps or single app method
	@param [String] arg 
	@param [String] key
	@param [String] opt
	@example `marie list`
	@example `marie list dc-web`
	@returns [Array<App>, App] apps return apps or app
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
						app = new App JSON.parse data
						for k of app
							_k = k.toLowerCase()
							if key is _k then ui.notice app[k]
				else console.log data

	###
	Configure `live` app command handler. Get all live app
	@example `marie live`
	@returns [App] app return live app
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
	@example `marie remove dc-web`
	###
	remove: (arg, opt) =>
		if not not arg then @_remove arg
		else @missingArgHandler()

	###
	remove
	###
	_remove: (arg) =>
		App.remove arg, (err, success) =>
			if err then utils.throwError err
			else ui.ok success

	###
	Configure `start` app command handler. start app
	@example `marie start dc-web`
	###
	start: (arg) =>
		App.live (err, data) =>
			if err then utils.throwError err
			else if data
				@stop()
				@_run 'start', arg
			else
				return @_run 'start', arg

	###
	Configure `stop` app command handler. Stops app or stop all apps
	@example `marie stop dc-web`
	@example `marie stop`
	###
	stop: (arg) =>
		App.live (err, data) =>
			if err then utils.throwError err
			else if data 
				app = new App JSON.parse data
				@_stop app
			else return @_run 'stop', arg

	###
	Configure `restart` app command handler. Restarts current live app
	@example `marie restart`
	###
	restart: (arg) =>
		App.live (err, data) =>
			if err then utils.throwError err
			else if data
				app = new App JSON.parse data
				@_stop app
				@_start app
			else
				if not arg then ui.notice 'No app is live.'

	###
	Configure system start app method
	@param [App] app app to start
	@example `_start app`
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
	_stop: (app) ->
		ui.write "Stopping #{app.name}..."
		App.stop app, (err, app) =>
			if err then utils.throwError err else ui.ok "#{app.name} stopped."

	###
	Configure system run app method.
	@param [String] arg 
	@param [String] cmd command sart/stop/restart
	###
	_run: (cmd, arg) ->
		if not not arg
			App.find arg, (err, data) =>
				if err then utils.throwError err
				if data
					app = new App JSON.parse data
					if cmd.match /^stop/i
						@_stop app
						app.stop()
					else if cmd.match /^start/i
						@_stop app
						@_start app
					else if cmd.match /^restart/i
						@_stop app
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
	@example `marie dc-web add api user`
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
	@example `marie dc-web remove api user`
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
	@example `marie dc-web add module bower`
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
	@example `marie dc-web remove module bower`
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
	@example `marie dc-web remove module bower`
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
	@example `marie dc-web remove module bower`
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
	@example `marie dc-web remove module bower`
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
	configureMore: (arg, key, opt) =>
		App.find arg, (error, data) =>
			if error then utils.throwError error
			else if data
				@app = new App JSON.parse data
				if key.match /storage/i
					@configureDB @app, true
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