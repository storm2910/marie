###
@namespace marie
@extend marie
@property [Array<String>] args
@property [String] root
@author Teddy Moussignac (teddy.moussignac@gmail.com)
@version 0.0.3
@copyright March 2016
@note Marie controller class. Maps routes and commands to app methods.
###

utils = require './marie.utils'
ui = require './marie.ui'
Marie = require './marie'
App = require './marie.app'

class MarieCLI extends Marie
	@args
	@root

	###
	Construct app
	###
	constructor: ->
		@root = process.cwd()
		@configureRoutes()
		@route()

	###
	Configure application routes and commands
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
	Process app route
	###
	route: ->
		@args = process.argv
		len = @args.length - 1
		if len >= 2
			route = @args[2]
			if @routes[route]? then @routes[route](@args[3]) else @add route
		else
			@add null

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
				ui.header 'Creating', arg
				path = utils.path.join @root, arg
				utils.fs.stat path, (err, stats) =>
					if err
						@app = new App { 
							name: arg 
							path: path
							cssProcessor: 'stylus'
							templateEngine: 'jade'
							created: new Date()
						}
						@configureSails()
					else ui.warn "#{arg} app exists."
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

# export controller module
module.exports = new MarieCLI