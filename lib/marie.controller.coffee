utils = require './marie.utils'
ui = require './marie.ui'
Marie = require './marie'
App = require './marie.app'


class MarieController extends Marie
	@args
	@root

	constructor: ->
		@root = process.cwd()
		@configureRoutes()
		@route()


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


	route: ->
		@args = process.argv
		len = @args.length - 1
		if len >= 2
			route = @args[2]
			if @routes[route]? then @routes[route](@args[3]) else @add route
		else
			@add null


	add: (arg) =>
		if not not arg
			len = @args.length - 1
			if len == 5
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
					ui.notice "Url: http://localhost:1337"
					ui.notice "Path: #{app.path}"
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
			ui.error 'Missing argument.'


	addApi: (api) =>
		App.addApi @args[2], api, (err, app) =>
			if err then utils.throwError err
			if app
				@add = app
				@restart()
				ui.ok "Added api #{api}"


	removeApi: (api) =>
		App.removeApi @args[2], api, (err, app) =>
			if err then utils.throwError err
			if app
				@add = app
				@restart()
				ui.ok "Removed api #{api}"


	addModule: (pkg) =>
		App.addModule @args[2], pkg, (err, app) =>
			if err then utils.throwError err
			if app
				@add = app
				@restart()
				ui.ok "Added module #{pkg}"


	removeModule: (pkg) =>
		App.removeModule @args[2], pkg, (err, app) =>
			if err then utils.throwError err
			if app
				@add = app
				@restart()
				ui.ok "Removed module #{pkg}"


# export controller module
module.exports = new MarieController