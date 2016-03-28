utils = require './marie.utils'
ui = require './marie.ui'
App = require './marie.app'

class Marie
	@app
	@args
	@root
	@commands
	@frontEndFramework
	@mongoType

	utf8: 'utf8'
	frameworks:
		BOOTSTRAP: 'bootstrap'
		FOUNDATION: 'foundation'
	mongoTypes:
		LOCAL: 'localMongodbServer'
		REMOTE: 'someMongodbServer'
		URL: 'someMongodbServerWithURL'


	constructor: ->
		@root = process.cwd()
		@configureCommands()
		@configureArgs()
		return false


	configureCommands: ->
		@commands =
			'new': @add
			'add': @add
			'remove': @remove
			'ls': @list
			'list': @list
			'live': @live
			'start': @start
			'stop': @stop
			'restart': @restart


	configureArgs: ->
		@args = process.argv
		len = @args.length
		if len >= 3
			cmd = @args[2]
			if @commands[cmd]? then @commands[cmd](@args[3]) else @add cmd
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
			if err then @throwError err
			if app
				if not not @args[4] then ui.notice app[@args[4]] else console.log app


	live: =>
		App.live (err, apps) =>
			if err then @throwError err
			else console.log apps


	remove: =>
		if not not @args[3]
			App.remove @args[3], (err, success) =>
				if err then @throwError err
				if success then ui.ok success
		else
			ui.error 'argument missing.'


	start: =>
		App.live (err, apps) =>
			if err then @throwError err
			else if apps
				@stop()
				@_run 'start'
			else
				return @_run 'start'


	stop: =>
		App.live (err, apps) =>
			if err then @throwError err
			else if apps
				@_stop app for app in apps
			else
				return @_run 'stop'


	restart: =>
		App.live (err, apps) =>
			if err then @throwError err
			else if apps
				@_stop app for app in apps
				@_start apps[0]
			else
				return @_run 'start'


	_start: (app) ->
		App.start app, (err, app) =>
			if err then @throwError err
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
			if err then @throwError err else ui.ok "#{app.name} stopped."


	_run: (cmd) ->
		if not not @args[3]
			App.find @args[3], (err, app) =>
				if err then @throwError err
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


	configureSails: ->
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
				@configureTasManager()


	configureTasManager: ->
		ui.write 'Configuring Grunt...'
		utils.install 'grunt-includes', '--save-dev', =>
			utils.fs.copySync utils.config('/tasks/compileAssets'), @app.file('/tasks/register/compileAssets.js'), { clobber: true }
			utils.fs.copySync utils.config('/tasks/syncAssets'), @app.file('/tasks/register/syncAssets.js'), { clobber: true }
			utils.fs.copySync utils.config('/tasks/includes'), @app.file('/tasks/config/includes.js'), { clobber: true }
			ui.ok 'Grunt configuration done.'
			@configureCoffeeScript()


	configureCoffeeScript: ->
		ui.write 'Configuring CoffeeScript...'
		utils.install 'coffee-script', '--save-dev', =>
			pkgs = ['sails-generate-controller-coffee', 'sails-generate-model-coffee']
			utils.installPackages pkgs
			utils.fs.copySync utils.config('/tasks/coffee'), @app.file('/tasks/config/coffee.js'), { clobber: true }
			utils.fs.writeFileSync @app.file('/assets/js/app.coffee'), ''
			ui.ok 'CoffeeScript configuration done.'
			@configureJade()


	configureJade: ->
		ui.write 'Configuring Jade...'
		utils.install 'jade', '--save-dev', =>
			viewSrc = @app.file '/config/views.js'
			stream = utils.fs.readFileSync viewSrc, @utf8
			stream = stream.replace(/ejs/gi, 'jade').replace(/'layout'/gi, false)
			utils.fs.writeFileSync viewSrc, stream
			
			dirs = ['/views/modules', '/views/partials', '/views/layouts']
			for dir in dirs then utils.fs.mkdirSync @app.file dir
			
			files = ['views/403', 'views/404', 'views/500', 'views/layout', 'views/homepage']
			utils.fs.unlinkSync @app.file "/#{file}.ejs" for file in files
			files.splice files.indexOf('views/layout'), 1
			partial = 'views/partial'
			files.push partial 
			for file in files
				sfile = utils.config "/templates/#{file}.jade"
				dfile = @app.file(if file == partial then '/views/partials/partial.jade' else "/#{file}.jade")
				utils.fs.copySync sfile, dfile

			masterPath = utils.config '/templates/views/master.jade'
			masterData = utils.fs.readFileSync masterPath, @utf8
			masterData = masterData.replace /\$APP_NAME/gi, @app.name
			utils.fs.writeFileSync @app.file('/views/layouts/master.jade'), masterData
			ui.ok 'Jade configuration done.'
			@configureStylus()


	configureStylus: ->
		ui.write 'Configuring Stylus...'
		utils.install 'stylus', '--save-dev', =>
			pkgs = ['grunt-contrib-stylus']
			utils.installPackages pkgs
			stream = utils.fs.readFileSync @app.file('/tasks/config/less.js'), @utf8
			stream = stream.replace(/less/gi, 'stylus').replace(/importer.stylus/gi,'bundles\/*')
			utils.fs.writeFileSync @app.file('/tasks/config/stylus.js'), stream
			configs = [
				'/tasks/register/compileAssets'
				'/tasks/register/syncAssets'
				'/tasks/config/sync'
				'/tasks/config/copy'
			]
			for config in configs
				stream = utils.fs.readFileSync @app.file("#{config}.js"), @utf8
				if config.match /register/
					stream = stream.replace(/less:dev/gi, 'stylus:dev')
				else
					stream = stream.replace(/less/gi, 'stylus')
				utils.fs.writeFileSync @app.file("#{config}.js"), stream
			ui.ok 'Stylus configuration done.'
			@configureStyleFramework()


	configureStyleFramework: ->
		ui.warn 'Choose your style framework.'
		utils.prompt.start()
		ui.line()
		input = ' Foundation/Bootstrap/None'
		utils.prompt.get [input], (err, result) =>
			ui.line()
			if result[input].match(/^f/i)
				@configureFrontend @frameworks.FOUNDATION
			else if result[input].match(/^b/i)
				@configureFrontend @frameworks.BOOTSTRAP
			else
				@configureBundles()
			

	configureFrontend: (framework) ->
		@frontEndFramework = framework
		cpath = "#{utils.root}/config/#{@frontEndFramework}-#{@app.cssProcessor}"
		jpath = "#{utils.root}/config/#{@frontEndFramework}-js"
		utils.fs.copySync cpath, @app.file("/assets/styles/#{@frontEndFramework}"), { clobber: true }
		utils.fs.copySync jpath, @app.file("/assets/js/dependencies/#{@frontEndFramework}"), { clobber: true }
		@configureBundles()


	configureBundles: ->
		ext = '.styl'
		styles = if not not @frontEndFramework then "@import '../#{@frontEndFramework}'" else ''
		utils.fs.mkdirSync @app.file('/assets/styles/bundles')
		utils.fs.removeSync @app.file('/assets/styles/importer.less')
		utils.fs.writeFileSync @app.file("/assets/styles/bundles/default#{ext}"), styles
		utils.fs.writeFileSync @app.file("/assets/styles/bundles/admin#{ext}"), styles
		ui.ok 'Frontend configuration done.'
		@configureDB()


	configureDB: ->
		ui.warn 'Choose your database.'
		utils.prompt.start()
		input = ' Mongo/Disk'
		ui.line()
		utils.prompt.get [input], (err, result) =>
			ui.line()
			if result[input].match(/^m/i) then @configureMongoDB() else @configureNativeDB()


	configureNativeDB: ->
		@mongoType = 'localDisk'
		@setupDBWithConfig 'The local disk'


	configureMongoDB: ->
		ui.warn 'Configure MongoDB database.'
		input = [' local/remote']
		ui.line()
		utils.prompt.get input, (err, result) =>
			ui.line()
			ui.write "Configuring MongoDB..."
			utils.install 'sails-mongo', '--save', (error, stdout, stderr) =>
				ui.clear()
				if result[input].match(/^r/i) then @configureRemoteMongoDB() else @configureLocalMongoDB()


	configureLocalMongoDB: ->
		@mongoType = @mongoTypes.LOCAL
		lconfig = utils.fs.readFileSync utils.config "/databases/#{@mongoTypes.LOCAL}.js", @utf8
		cconfig = utils.fs.readFileSync utils.config('/databases/connections.js'), @utf8
		cconfig = cconfig.replace /\$MONGO\.CONNECTION/, lconfig
		@setupDBWithConfig 'Local MongoDB', cconfig


	configureRemoteMongoDB: ->
		input = [' mongodb uri']
		utils.prompt.get input, (err, result) =>
			ui.line()
			if result[input].length > 0 
				@configureRemoteMongoDBWithURI result[input]
			else
				@configureRemoteMongoDBWithConfig() 


	configureRemoteMongoDBWithConfig: ->
		@mongoType = @mongoTypes.REMOTE
		inputs = [' host', ' port', ' user', ' password', ' database']
		utils.prompt.get inputs, (err, result) =>
			ui.line()
			sconfig = utils.fs.readFileSync utils.config "/databases/#{@mongoTypes.REMOTE}.js", @utf8
			cconfig = utils.fs.readFileSync utils.config('/databases/connections.js'), @utf8
			cconfig = cconfig.replace /\$MONGO\.CONNECTION/, sconfig
			cconfig = cconfig.replace /\$MONGO\.HOST/gi, result[' host'] if result[' host']? 
			cconfig = cconfig.replace /\$MONGO\.PORT/gi, result[' port'] if result[' port']? 
			cconfig = cconfig.replace /\$MONGO\.USER/gi, result[' user'] if result[' user']? 
			cconfig = cconfig.replace /\$MONGO\.PASSWORD/gi, result[' password'] if result[' password']? 
			cconfig = cconfig.replace /\$MONGO\.DATABASE/gi, result[' database'] if result[' database']? 
			@setupDBWithConfig 'Remote MongoDB', cconfig


	configureRemoteMongoDBWithURI: (uri) ->
		@mongoType = @mongoTypes.URL
		uconfig = utils.fs.readFileSync utils.config "/databases/#{@mongoTypes.URL}.js", @utf8
		cconfig = utils.fs.readFileSync utils.config('/databases/connections.js'), @utf8
		cconfig = cconfig.replace /\$MONGO\.CONNECTION/, uconfig
		cconfig = cconfig.replace /\$MONGO\.URL/gi, uri
		@setupDBWithConfig 'Remote MongoDB', cconfig


	setupDBWithConfig: (db, cconfig) ->
		mdest = @app.file '/config/models.js'
		mconfig = utils.fs.readFileSync mdest, @utf8
		mconfig = mconfig.replace(/'alter'/gi, "'safe'").replace(/\/\/ /gi,'').replace(/connection/gi, '// connection')
		utils.fs.writeFileSync mdest, mconfig
		if not not cconfig
			cdest = @app.file '/config/connections.js'
			utils.fs.writeFileSync cdest, cconfig
			ddest = @app.file '/config/env/development.js'
			dconfig = utils.fs.readFileSync ddest, @utf8
			dconfig = dconfig.replace(/\/\/ /gi,'').replace(/someMongodbServer/gi, @mongoType)
			utils.fs.writeFileSync ddest, dconfig
		ui.ok "#{db} database configuration done."
		@configureAPIs()


	configureAPIs: ->
		ui.warn 'Configure APIs.'
		utils.prompt.start()
		input = ' APIs'
		ui.line()
		utils.prompt.get [input], (err, result) =>
			ui.line()
			res = if result[input].length > 0 then result[input] else null
			if not not res
				apis = res.split ','
				utils.installApis apis
				ui.ok "APIs configuration done."
				@save()
			else
				@save()


	throwError: (error) ->
		if @app.path
			@root = utils.path.dirname @app.path
			process.chdir @root
			utils.fs.removeSync @app.path
		utils.throwError error


	save: ->
		@endTime = new Date 
		@app.add (err, app) =>
			if err then @throwError err
			else
				ui.ok "#{app.name} was successfully added."

		total = (@endTime - @app.created) / 1000
		if total < 60 
			@initTime = "#{Math.round(total)} seconds" 
		else
			@initTime = "#{Math.round(total / 60)} minutes #{Math.round(total % 60)} seconds"
		ui.notice "Path: #{@app.path}"
		ui.notice "Creation Time: #{@initTime}"


# export marie module
module.exports = new Marie 