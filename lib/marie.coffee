fs = require 'fs'
fs = require 'fs-extra'
path = require 'path'
prompt = require 'prompt'
exe = require('child_process').execFile
ui = require './marie.ui'
App = require './marie.app'

class Marie
	@args
	@app
	@dir
	@root
	@commands
	@startTime
	@endTime
	@initTime
	@cssProcessor
	@frontEndFramework
	@templateEnegine
	@mongoType

	UTF8: 'utf8'
	templates:
		JADE: 'jade'
		EJS: 'ejs'
		HANDLEBARS: 'handlebars'
	processors:
		STYLUS: 'stylus'
		SCSS: 'scss'
		LESS: 'less'
	frameworks:
		BOOTSTRAP: 'bootstrap'
		FOUNDATION: 'foundation'
	mongoTypes:
		LOCAL: 'localMongodbServer'
		REMOTE: 'someMongodbServer'
		URL: 'someMongodbServerWithURL'
	

	constructor: ->
		@startTime = new Date 
		@root = process.cwd()
		prompt.message = null
		@configureCommands()
		@configureArgs()


	configureCommands: ->
		@commands =
			'new': @add
			'update': @update
			'list': @list
			'remove': @remove
			'start': @start
			'stop': @start


	configureArgs: ->
		@args = process.argv
		len = @args.length
		if len >= 3
			cmd = @args[2]
			if @commands[cmd]? then @commands[cmd](@args[3]) else @add cmd
		else
			@add null


	add: (app) =>
		if not not app
			@app = app
			ui.header 'Creating', @app
			@dir = @rootPath "/#{@app}"
			fs.stat @dir, (err, stats) =>
				if err then @configureSails() else ui.warn 'App already exists.'
		else
			ui.warn 'Enter app name.'
			prompt.start()
			ui.line()
			prompt.get ['name'], (error, result) =>
				if error 
					ui.error 'An error occured.'
				else
					@add result.name


	update: (app) =>
		ui.warn 'update command'


	list: (app) =>
		App.find @args[3], (err, row) =>
			if err then @throwError err
			if row then console.log row


	remove: (app) =>
		ui.warn 'remove command'


	start: (app) =>
		ui.warn 'start command'


	stop: (app) =>
		ui.warn 'stop command'


	configureSails: ->
		ui.write 'Configuring Sails...'
		exe 'sails', ['generate', 'new', @app], (error, stdout, stderr) =>
			if error
				exe 'npm', ['install', 'sails', '-g'], (error, stdout, stderr) =>
					if error 
						ui.error 'An error occured.'
						ui.notice "Run `sudo npm install sails -g` then try again."
					else
						@configureSails()
			else
				ui.ok 'Sails configuration done.'
				process.chdir @dir
				@configureTasManager()


	configureTasManager: ->
		ui.write 'Configuring Grunt...'
		@install 'grunt-includes', '--save-dev', =>
			fs.copySync @configPath('/tasks/compileAssets.js'), @appPath('/tasks/register/compileAssets.js'), { clobber: true }
			fs.copySync @configPath('/tasks/syncAssets.js'), @appPath('/tasks/register/syncAssets.js'), { clobber: true }
			fs.copySync @configPath('/tasks/includes.js'), @appPath('/tasks/config/includes.js'), { clobber: true }
			ui.ok 'Grunt configuration done.'
			@configureCoffeeScript()


	configureCoffeeScript: ->
		ui.write 'Configuring CoffeeScript...'
		@install 'coffee-script', '--save-dev', =>
			pkgs = ['sails-generate-controller-coffee', 'sails-generate-model-coffee']
			@installPackages pkgs
			fs.copySync @configPath('/tasks/coffee.js'), @appPath('/tasks/config/coffee.js'), { clobber: true }
			fs.writeFileSync @appPath('/assets/js/app.coffee'), ''
			ui.ok 'CoffeeScript configuration done.'
			@configureJade()


	configureJade: ->
		ui.write 'Configuring Jade...'
		@install 'jade', '--save-dev', =>
			@templateEnegine = @templates.JADE
			viewSrc = @appPath '/config/views.js'
			stream = fs.readFileSync viewSrc, @UTF8
			stream = stream.replace(/ejs/gi, 'jade').replace(/'layout'/gi, false)
			fs.writeFileSync viewSrc, stream
			
			dirs = ['/views/modules', '/views/partials', '/views/layouts']
			for dir in dirs then fs.mkdirSync @appPath dir
			
			files = ['views/403', 'views/404', 'views/500', 'views/layout', 'views/homepage']
			fs.unlinkSync @appPath "/#{file}.ejs" for file in files
			files.splice files.indexOf('views/layout'), 1
			partial = 'views/partial'
			files.push partial 
			for file in files
				sfile = @configPath "/templates/#{file}.jade"
				dfile = @appPath(if file == partial then '/views/partials/partial.jade' else "/#{file}.jade")
				fs.copySync sfile, dfile

			masterPath = @configPath '/templates/views/master.jade'
			masterData = fs.readFileSync masterPath, @UTF8
			masterData = masterData.replace /\$APP_NAME/gi, @app
			fs.writeFileSync @appPath('/views/layouts/master.jade'), masterData
			ui.ok 'Jade configuration done.'
			@configureStylus()


	configureStylus: ->
		ui.write 'Configuring Stylus...'
		@install 'stylus', '--save-dev', =>
			@cssProcessor = @processors.STYLUS
			pkgs = ['grunt-contrib-stylus']
			@installPackages pkgs
			stream = fs.readFileSync @appPath('/tasks/config/less.js'), @UTF8
			stream = stream.replace(/less/gi, 'stylus').replace(/importer.stylus/gi,'bundles\/*')
			fs.writeFileSync @appPath('/tasks/config/stylus.js'), stream
			configs = [
				'/tasks/register/compileAssets'
				'/tasks/register/syncAssets'
				'/tasks/config/sync'
				'/tasks/config/copy'
			]
			for config in configs
				stream = fs.readFileSync @appPath("#{config}.js"), @UTF8
				if config.match /register/
					stream = stream.replace(/less:dev/gi, 'stylus:dev')
				else
					stream = stream.replace(/less/gi, 'stylus')
				fs.writeFileSync @appPath("#{config}.js"), stream
			ui.ok 'Stylus configuration done.'
			@configureStyleFramework()


	configureStyleFramework: ->
		ui.warn 'Choose your style framework.'
		prompt.start()
		ui.line()
		input = ' Foundation/Bootstrap/None'
		prompt.get [input], (err, result) =>
			ui.line()
			if result[input].match(/^f/i)
				@configureFrontend @frameworks.FOUNDATION
			else if result[input].match(/^b/i)
				@configureFrontend @frameworks.BOOTSTRAP
			else
				@configureBundles()
			

	configureFrontend: (framework) ->
		@frontEndFramework = framework
		cpath = "#{@frontEndFramework}-#{@cssProcessor}"
		jpath = "#{@frontEndFramework}-js"
		fs.copySync @configPath("/#{cpath}"), @appPath("/assets/styles/#{@frontEndFramework}"), { clobber: true }
		fs.copySync @configPath("/#{jpath}"), @appPath("/assets/js/dependencies/#{@frontEndFramework}"), { clobber: true }
		@configureBundles()


	configureBundles: ->
		ext = if @cssProcessor == @processors.STYLUS then '.styl' else @cssProcessor
		styles = if not not @frontEndFramework then "@import '../#{@frontEndFramework}'" else ''
		fs.mkdirSync @appPath('/assets/styles/bundles')
		fs.removeSync @appPath('/assets/styles/importer.less')
		fs.writeFileSync @appPath("/assets/styles/bundles/default#{ext}"), styles
		fs.writeFileSync @appPath("/assets/styles/bundles/admin#{ext}"), styles
		ui.ok 'Frontend configuration done.'
		@configureDB()


	configureDB: ->
		ui.warn 'Choose your database.'
		prompt.start()
		input = ' Mongo/Disk'
		ui.line()
		prompt.get [input], (err, result) =>
			ui.line()
			if result[input].match(/^m/i) then @configureMongoDB() else @configureNativeDB()


	configureNativeDB: ->
		@mongoType = 'localDisk'
		@setupDBWithConfig 'The local disk'


	configureMongoDB: ->
		ui.warn 'Configure MongoDB database.'
		input = [' local/remote']
		ui.line()
		prompt.get input, (err, result) =>
			ui.line()
			ui.write "Configuring MongoDB..."
			@install 'sails-mongo', '--save', (error, stdout, stderr) =>
				ui.clear()
				if result[input].match(/^r/i) then @configureRemoteMongoDB() else @configureLocalMongoDB()


	configureLocalMongoDB: ->
		@mongoType = @mongoTypes.LOCAL
		lconfig = fs.readFileSync @configPath "/databases/#{@mongoTypes.LOCAL}.js", @UTF8
		cconfig = fs.readFileSync @configPath('/databases/connections.js'), @UTF8
		cconfig = cconfig.replace /\$MONGO\.CONNECTION/, lconfig
		@setupDBWithConfig 'Local MongoDB', cconfig


	configureRemoteMongoDB: ->
		input = [' mongodb uri']
		prompt.get input, (err, result) =>
			ui.line()
			if result[input].length > 0 
				@configureRemoteMongoDBWithURI result[input]
			else
				@configureRemoteMongoDBWithConfig() 


	configureRemoteMongoDBWithConfig: ->
		@mongoType = @mongoTypes.REMOTE
		inputs = [' host', ' port', ' user', ' password', ' database']
		prompt.get inputs, (err, result) =>
			ui.line()
			sconfig = fs.readFileSync @configPath "/databases/#{@mongoTypes.REMOTE}.js", @UTF8
			cconfig = fs.readFileSync @configPath('/databases/connections.js'), @UTF8
			cconfig = cconfig.replace /\$MONGO\.CONNECTION/, sconfig
			cconfig = cconfig.replace /\$MONGO\.HOST/gi, result[' host'] if result[' host']? 
			cconfig = cconfig.replace /\$MONGO\.PORT/gi, result[' port'] if result[' port']? 
			cconfig = cconfig.replace /\$MONGO\.USER/gi, result[' user'] if result[' user']? 
			cconfig = cconfig.replace /\$MONGO\.PASSWORD/gi, result[' password'] if result[' password']? 
			cconfig = cconfig.replace /\$MONGO\.DATABASE/gi, result[' database'] if result[' database']? 
			@setupDBWithConfig 'Remote MongoDB', cconfig


	configureRemoteMongoDBWithURI: (uri) ->
		@mongoType = @mongoTypes.URL
		uconfig = fs.readFileSync @configPath "/databases/#{@mongoTypes.URL}.js", @UTF8
		cconfig = fs.readFileSync @configPath('/databases/connections.js'), @UTF8
		cconfig = cconfig.replace /\$MONGO\.CONNECTION/, uconfig
		cconfig = cconfig.replace /\$MONGO\.URL/gi, uri
		@setupDBWithConfig 'Remote MongoDB', cconfig


	setupDBWithConfig: (db, cconfig) ->
		mdest = @appPath '/config/models.js'
		mconfig = fs.readFileSync mdest, @UTF8
		mconfig = mconfig.replace(/'alter'/gi, "'safe'").replace(/\/\/ /gi,'').replace(/connection/gi, '// connection')
		fs.writeFileSync mdest, mconfig
		if not not cconfig
			cdest = @appPath '/config/connections.js'
			fs.writeFileSync cdest, cconfig
			ddest = @appPath '/config/env/development.js'
			dconfig = fs.readFileSync ddest, @UTF8
			dconfig = dconfig.replace(/\/\/ /gi,'').replace(/someMongodbServer/gi, @mongoType)
			fs.writeFileSync ddest, dconfig
		ui.ok "#{db} database configuration done."
		@configureAPIs()


	configureAPIs: ->
		ui.warn 'Configure APIs.'
		prompt.start()
		input = ' APIs'
		ui.line()
		prompt.get [input], (err, result) =>
			ui.line()
			res = if result[input].length > 0 then result[input] else null
			if not not res
				apis = res.split ','
				@installApis apis
				ui.ok "APIs configuration done."
				@save()
			else
				@save()


	throwError: (error) ->
		if @dir
			@root = path.dirname @dir
			process.chdir @root
			fs.removeSync @dir
		if error then ui.error error else 'An error occured.'


	appPath: (loc) ->
		return path.join @dir, loc


	rootPath: (loc) ->
		return path.join @root, loc


	configPath: (loc) ->
		return path.join __dirname.replace('/marie/lib', '/marie/config'), loc


	install: (pkg, opt, cb) ->
		exe 'npm', ['install', pkg, opt], cb


	uninstall: (pkg, cb) ->
		exe 'npm', ['uninstall', pkg], cb


	installPackages: (pkgs) ->
		for pkg in pkgs then @install pkg, '--save-dev', @stdoutCallBack


	uninstallPackages: (pkgs) ->
		for pkg in pkgs then @uninstall pkg, @stdoutCallBack


	installApi: (api) ->
		api = api.toLowerCase().replace /\s/, ''
		exe 'sails', ['generate', 'api', api, '--coffee'], @stdoutCallBack


	installApis: (apis)->
		for api in apis then @installApi api


	stdoutCallBack: (error, stdout, stderr) =>
		if error then @throwError()


	save: ->
		@endTime = new Date 
		app = new App {
			name: @app
			path: @dir
			created: @endTime.getTime()
			live: 0
			templateEnegine: @templateEnegine
			cssProcessor: @cssProcessor
			frontEndFramework: @frontEndFramework
			storage: @mongoType
		}
		total = (@endTime - @startTime) / 1000
		if total < 60 
			@initTime = "#{Math.round(total)} seconds" 
		else
			@initTime = "#{Math.round(total / 60)} minutes #{Math.round(total % 60)} seconds"
		ui.notice "Path: #{@dir}"
		ui.notice "Creation Time: #{@initTime}"


# export class
module.exports = new Marie 