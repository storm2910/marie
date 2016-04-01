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
	@args
	@app
	@root
	@commands
	@routes

	###
	Construct App
	@param [Array<String>] args encoding action commands and routes
	###
	constructor: (@args, @root) ->
		@configureRoutes()
		@configureCommands()
		@route()

	###
	Configure application routes
	###
	configureRoutes: ->	
		@routes =
			'add': @add
			'new': @add
			'ls': @list
			'list': @list
			'live': @live
			'start': @start
			'stop': @stop
			'restart': @restart
			'remove': @remove

	###
	Configure application route commands
	###
	configureCommands: ->	
		@commands =
			'api':
				'add': @addApi
				'remove': @removeApi
				'delete': @removeApi
			'module':
				'add': @addModule
				'remove': @removeModule
				'delete': @removeModule
			'list': 
				'config': @listConfig

	###
	Confgiure the default express/sails application framework
	will try to install sails if not already installed. 
	@param [String] app app name
	###
	new: (app) ->
		ui.header 'Creating', app
		path = utils.path.join @root, app
		utils.fs.stat path, (err, stats) =>
			if err
				@app = new App { 
					name: app 
					path: path
					cssProcessor: 'stylus'
					templateEngine: 'jade'
					created: new Date()
				}
				@generateFiles()
			else ui.warn "#{app} app exists."

	###
	Confgiure the default express/sails application framework
	will try to install sails if not already installed. 
	@exmaple `npm install sails -g`
	###
	generateFiles: ->
		ui.write 'Configuring Sails...'
		utils.exe 'sails', ['generate', 'new', @app.name], (error, stdout, stderr) =>
			if error
				utils.exe 'npm', ['install', 'sails', '-g'], (error, stdout, stderr) =>
					if error 
						ui.error 'An error occured.'
						ui.notice "Run `sudo npm install sails -g` then try again."
					else
						@configureSails()
			else
				ui.ok 'Sails configuration done.'
				process.chdir @app.path
				@configureTasManager @app

	###
	Configure grunt as the default task manager
	Also configure coffee files importer module + setup for assets coffee files in `/assets/js`
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
	###
	configureCoffeeScript: (app) ->
		ui.write 'Configuring CoffeeScript...'
		App.configureCoffeeScript app, (err, app) =>
			if err then utils.throwError err 
			if app 
				ui.ok 'CoffeeScript configuration done.'
				@configureJade app

	###
	Configure jade as the default view templating engine
	Disable `ejs` + add the default jade template files
	@example /views/partials/partial.jade
	###
	configureJade: (app) ->
		ui.write 'Configuring Jade...'
		App.configureJade app, (err, app) =>
			if err then utils.throwError err 
			if app 
				ui.ok 'Jade configuration done.'
				@configureStylus app

	###
	Configure stylus as the default css pre-processor
	###
	configureStylus:(app) ->
		ui.write 'Configuring Stylus...'
		App.configureStylus app, (err, app) =>
			if err then utils.throwError err 
			if app
				ui.ok 'Stylus configuration done.'
				@configureFrontEndFramework app

	###
	Frontend framework form prompt configuration
	Let you choose betwen bootstrap and foundation
	@example foundation/bootstrap
	###
	configureFrontEndFramework: (app) ->
		ui.warn 'Choose your style framework.'
		utils.prompt.start()
		ui.line()
		input = ' Foundation/Bootstrap/None'
		utils.prompt.get [input], (err, result) =>
			ui.line()
			if result[input].match(/^f/i)
				@configureFramework app, utils.framework.FOUNDATION
			else if result[input].match(/^b/i)
				@configureFramework app, utils.framework.BOOTSTRAP
			else
				@configureBundles app
			
	###
	Configure foundation or bootstrap as the default frontend framewok
	@param [String] framework bootstrap or foundation
	###
	configureFramework: (app, framework) ->
		App.configureFrontEndFramework app, framework, (err, app) =>
			if err then utils.throwError err 
			if app then @configureBundles app

	###
	Configure default bundle files
	@example /assets/styles/bundles/default.styl
	@example /assets/styles/bundles/admin.styl
	###
	configureBundles: (app) ->
		App.configureBundles app, (err, app) =>
			if err then utils.throwError err 
			if app
				ui.ok 'Frontend configuration done.'
				@configureDB app

	###
	Data storage form prompt configuration
	Let you choose between localDisk and a mongo database
	@example localDisk/mongo
	###
	configureDB: (app) ->
		ui.warn 'Choose your database.'
		utils.prompt.start()
		input = ' Mongo/Disk'
		ui.line()
		utils.prompt.get [input], (err, result) =>
			ui.line()
			if result[input].match(/^m/i) then @configureMongoDB(app) else @configureNativeDB(app)

	###
	Configure localDisk as the default data storage
	###
	configureNativeDB: (app) ->
		App.configureNativeDB app, (err, app) =>
			if err then utils.throwError err 
			if app
				ui.ok "Local disk database configuration done."
				@configureAPIs app

	###
	Configure mongoDB as the default data storage and choose between local or remote mongo
	###
	configureMongoDB: (app) ->
		ui.warn 'Configure MongoDB database.'
		input = [' Local/Remote']
		ui.line()
		utils.prompt.get input, (err, result) =>
			ui.line()
			if result[input].match(/^r/i) then @configureRemoteMongoDB(app) else @configureLocalMongoDB(app)

	# ###
	# Local mongodb database configuration
	# ###
	configureLocalMongoDB: (app) ->
		ui.write "Configuring MongoDB..."
		App.configureLocalMongoDB app, (err, app) =>
			if err then utils.throwError err 
			if app
				ui.ok "Local MongoDB database configuration done."
				@configureAPIs app

	###
	Remote mongodb database configuration
	###
	configureRemoteMongoDB: (app) ->
		input = [' mongodb uri']
		utils.prompt.get input, (err, result) =>
			ui.line()
			uri = utils.trim result[input]
			if uri.match(/\:|@/g)
				ui.write "Configuring MongoDB..."
				App.configureMongoDB app, uri, (err, app) =>
					if err then utils.throwError err 
					if app
						ui.ok "MongoDB database configuration done."
						@configureAPIs app
			else
				@configureRemoteMongoDBWithConfig app

	###
	Remote mongodb database configuration
	###
	configureRemoteMongoDBWithConfig: (app) ->
		inputs = [' host', ' port', ' user', ' password', ' database']
		utils.prompt.get inputs, (err, result) =>
			ui.line()
			config =
				host: if result[' host']? then result[' host'] else ''
				port: if result[' port']? then result[' port'] else ''
				user: if result[' user']? then result[' user'] else ''
				password: if result[' password']? then result[' password'] else ''
				database: if result[' database']? then result[' database'] else ''
			ui.write "Configuring MongoDB..."
			App.configureMongoDB app, config, (err, app) =>
				if err then utils.throwError err 
				if app
					ui.ok "MongoDB database configuration done."
					@configureAPIs app

	###
	Configure default app APIs
	A `user` api will create both a user model and a user conftroller
	file in the api directory
	@example user, article, image
	@example /api/models/User.coffee
	@example /api/controllers/UserController.coffee
	###
	configureAPIs: (app) ->
		ui.warn 'Configure APIs.'
		utils.prompt.start()
		input = ' APIs'
		ui.line()
		utils.prompt.get [input], (err, result) =>
			ui.line()
			res = if result[input].length > 0 then result[input] else null
			if not not res
				apis = res.split ','
				utils.installApis apis, @app
				ui.ok "APIs configuration done."
				@save()
			else
				@save()

	###
	If something goes really bad. Stop everything, remove everything and exit process
	@param [Object, String] error 
	###
	throwFatalError: (error) ->
		utils.fs.stat @app.path, (err, stats) =>
			if not err
				utils.fs.removeSync @app.path
				App.remove @app.name
				utils.throwError error
			else
				utils.throwError error

	###
	Save app to marie database
	@example marie list some-app
	###
	save: ->
		@endTime = new Date 
		@app.add (err, app) =>
			if err then @throwFatalError err
			else
				ui.ok "#{app.name} was successfully added."
		total = (@endTime - @app.created) / 1000
		if total < 60 
			@initTime = "#{Math.round(total)} seconds" 
		else
			@initTime = "#{Math.round(total / 60)} minutes #{Math.round(total % 60)} seconds"
		ui.notice "Path: #{@app.path}"
		ui.notice "Creation Time: #{@initTime}"
		@onSave()

	###
	App creation callback method
	Will ask to start newly created app
	###
	onSave: ->
		ui.warn 'Start app?'
		utils.prompt.start()
		input = ' Yes/No'
		ui.line()
		utils.prompt.get [input], (err, result) =>
			ui.line()
			if result[input].match(/^y/i)
				App.live (err, apps) =>
					if apps
						@stop()
						@_start @app
					else
						return @_start @app


		###
	Configure `add` app method. Creates new app
	@pparam [String] arg or app name
	@example `marie add dc-web`
	@example `marie new dc-web`
	@example `marie dc-web
	###
	add: (arg) =>
		if not not arg
			len = @args.length - 1
			if len >= 5
				if @commands[@args[4]][@args[3]]? then @commands[@args[4]][@args[3]] @args[5]
			else if len > 2 and len < 5
				ui.error 'Missing. argument.'
			else
				@new arg
		else
			ui.warn 'Enter app name.'
			utils.prompt.start()
			ui.line()
			utils.prompt.get ['name'], (error, result) =>
				if error 
					ui.error 'An error occured.'
				else
					@add result.name

	###
	Configure `list` app command handler. Retrive and List all apps or single app method
	@example `marie list`
	@example `marie list dc-web`
	@returns [Array<App>, App] apps return apps or app
	###
	list: =>
		App.find @args[3], (err, apps) =>
			if err then utils.throwError err
			if apps
				if not not @args[4] 
					if @commands.list[@args[4]] then @commands.list[@args[4]]()
					else ui.notice apps[@args[4]] 
				else console.log apps

	###
	Configure `live` app command handler. Get all live app
	@example `marie live`
	@returns [App] app return live app
	###
	live: =>
		App.live (err, apps) =>
			if err then utils.throwError err
			else console.log apps

	###
	Configure `remove` app command handler. Remove app from system
	@example `marie remove dc-web`
	###
	remove: =>
		if not not @args[3]
			ui.warn 'Are you sure?'
			utils.prompt.start()
			input = ' Yes/No'
			ui.line()
			utils.prompt.get [input], (err, result) =>
				ui.line()
				if result[input].match(/^y/i)
					App.remove @args[3], (err, success) =>
						if err then utils.throwError err
						if success then ui.ok success
		else
			ui.error 'Missing argument.'

	###
	Configure `start` app command handler. start app
	@example `marie start dc-web`
	###
	start: =>
		App.live (err, apps) =>
			if err then utils.throwError err
			else if apps
				@stop()
				@_run 'start'
			else
				return @_run 'start'

	###
	Configure `stop` app command handler. Stops app or stop all apps
	@example `marie stop dc-web`
	@example `marie stop`
	###
	stop: =>
		App.live (err, apps) =>
			if err then utils.throwError err
			else if apps
				@_stop app for app in apps
			else
				return @_run 'stop'

	###
	Configure `restart` app command handler. Restarts current live app
	@example `marie restart`
	###
	restart: =>
		App.live (err, apps) =>
			if err then utils.throwError err
			else if apps and apps.length > 0
				@_stop app for app in apps
				@_start apps[0]
			else
				return @_run 'start'

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
	@param [String] cmd command sart/stop/restart
	###
	_run: (cmd) ->
		if not not @args[3]
			App.find @args[3], (err, app) =>
				if err then utils.throwError err
				if app
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
			ui.error 'Missing argument.'

	###
	Configure add api method
	@param [String] api api to add
	@example `marie dc-web add api user`
	###
	addApi: (api) =>
		App.addApi @args[2], api, (err, app) =>
			if err then utils.throwError err
			if app
				@app = app
				@restart()
				ui.ok "Added api #{api}"

	###
	Configure remove api method
	@param [String] api api to remove
	@example `marie dc-web remove api user`
	###
	removeApi: (api) =>
		App.removeApi @args[2], api, (err, app) =>
			if err then utils.throwError err
			if app
				@app = app
				@restart()
				ui.ok "Removed api #{api}"

	###
	Configure add module method
	@param [String] pkg module to add
	@example `marie dc-web add module bower`
	###
	addModule: (pkg) =>
		ui.write "Adding `#{pkg}` module..."
		App.addModule @args[2], pkg, @args[6], (err, app) =>
			if err then utils.throwError err
			if app
				@app = app
				@restart()
				ui.ok "Added module #{pkg}"

	###
	Configure remove module method
	@param [String] pkg module to remove
	@example `marie dc-web remove module bower`
	###
	removeModule: (pkg) =>
		ui.write "Removing `#{pkg}` module..."
		App.removeModule @args[2], pkg, @args[6], (err, app) =>
			if err then utils.throwError err
			if app
				@app = app
				@restart()
				ui.ok "Removed module #{pkg}"

	###
	Configure list module method
	@example `marie dc-web remove module bower`
	###
	listConfig: =>
		App.getConfig @args[3], @args[5], (err, config) =>
			if err then utils.throwError err
			if config
				if config.constructor == String then ui.notice config
				else console.log config

	###
	Process app route
	###
	route: ->
		len = @args.length - 1
		if len >= 2
			route = @args[2]
			if @routes[route]? then @routes[route](@args[3]) else @add route
		else
			@add null

# export marie module
module.exports = Marie