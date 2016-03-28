utils = require './marie.utils'
ui = require './marie.ui'
Marie = require './marie'
App = require './marie.app'


class MarieController extends Marie
	@root

	constructor: ->
		@root = process.cwd()
		@configureRoutes()
		@route()
		return false


	configureRoutes: ->
		@routes =
			'new': @add
			'add': @add
			'remove': @remove
			'ls': @list
			'list': @list
			'live': @live
			'start': @start
			'stop': @stop
			'restart': @restart


	route: ->
		@args = process.argv
		len = @args.length
		if len >= 3
			route = @args[2]
			if @routes[route]? then @routes[route](@args[3]) else @add route
		else
			@add null


	add: (arg) =>
		if not not arg
			ui.header 'Creating', arg
			path = utils.path.join @root, arg
			utils.fs.stat path, (err, stats) =>
				if err
					@app = new App { 
						name: arg 
						path: path
						cssProcessor: 'stylus'
						templateEnegine: 'jade'
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


	list: =>
		App.find @args[3], (err, app) =>
			if err then utils.throwError err
			if app
				if not not @args[4] then ui.notice app[@args[4]] else console.log app


	live: =>
		App.live (err, apps) =>
			if err then utils.throwError err
			else console.log apps


	remove: =>
		if not not @args[3]
			App.remove @args[3], (err, success) =>
				if err then utils.throwError err
				if success then ui.ok success
		else
			ui.error 'argument missing.'


	start: =>
		App.live (err, apps) =>
			if err then utils.throwError err
			else if apps
				@stop()
				@_run 'start'
			else
				return @_run 'start'


	stop: =>
		App.live (err, apps) =>
			if err then utils.throwError err
			else if apps
				@_stop app for app in apps
			else
				return @_run 'stop'


	restart: =>
		App.live (err, apps) =>
			if err then utils.throwError err
			else if apps
				@_stop app for app in apps
				@_start apps[0]
			else
				return @_run 'start'


	_start: (app) ->
		App.start app, (err, app) =>
			if err then utils.throwError err
			else
				ui.write "Starting #{app.name}..."
				setTimeout =>
					ui.ok "#{app.name} started."
					ui.ok "url: http://localhost:1337"
					ui.notice "path: #{app.path}"
					process.exit()
				, 1000


	_stop: (app) ->
		ui.write "Stopping #{app.name}..."
		App.stop app, (err, app) =>
			if err then utils.throwError err else ui.ok "#{app.name} stopped."


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
			ui.error 'argument missing.'



# export marie module
module.exports = new MarieController