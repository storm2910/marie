###
@namespace marie
@author Teddy Moussignac (teddy.moussignac@gmail.com)
@version 0.0.3
@copyright: March 2016
@note Marie utility class
###

class Utils
	sailsVersion: '0.12.1'
	bower: require 'bower'
	encoding:
		UTF8: 'utf8'
	exe: require('child_process').execFile
	fs: require 'fs'
	path: require 'path'
	prompt: require 'prompt'
	root: __dirname.replace '/marie/lib', '/marie'
	spawn: require('child_process').spawn
	spawnSync: require('child_process').spawnSync
	sqlite: require 'sqlite3'
	tasks: [
		'/tasks/register/compileAssets'
		'/tasks/register/syncAssets'
		'/tasks/config/sync'
		'/tasks/config/copy'
	]
	compilers:
		COFFEE:
			id: '--coffee'
			name: 'CoffeeScript'
			extension: '.coffee'
		NATIVE:
			id: '--native'
			name: 'native'
			extension: '.js'
	processors:
		LESS:
			id: 'less'
			extension: '.less'
		SCSS:
			id: 'scss'
			extension: '.scss'
		STYLUS:
			id: 'stylus'
			extension: '.styl'
	engines:
		EJS:
			id: 'ejs'
			extension: '.ejs'
		JADE:
			id: 'jade'
			extension: '.jade'
		HANDLEBARS:
			id: 'handlebars'
			extension: '.handlebars'
	storage:
		DISK: 
			name: 'disk'
			id: 'localDiskDb'
			adapter: 'sails-disk'
			version: 'latest'
		MONGODB: 
			name: 'mongodb'
			id: 'someMongodbServer'
			adapter: 'sails-mongo'
			version: '0.12.0'
		MYSQL: 
			name: 'mysql'
			id: 'someMysqlServer'
			adapter: 'sails-mysql'
			version: 'latest'
		POSTGRESQL: 
			name: 'postgresql'
			id: 'somePostgresqlServer'
			adapter: 'sails-postgresql'
			version: 'latest'
		REDIS: 
			name: 'redis'
			id: 'someRedisServer'
			adapter: 'sails-redis'
			version: 'latest'
	views:
		DIRS: [
			'/views/modules' 
			'/views/partials'
			'/views/layouts'
		]
		FILES: [
			'/views/homepage'
			'/views/403'
			'/views/404'
			'/views/500'
			'/views/partials/partial'
			'/views/layouts/master'
		]

	###
	Construct app
	###
	constructor: ->
		@configureProcess()
		@configurePrompt()
		@configureFs()

	configureProcess: ->
		process.on 'uncaughtException', (err) ->
			console.log err.stack

	###
	Configure config file path
	@param [String] path path to config file
	###
	config: (path) ->
		if not path.match /\./g then path = path + '.js'
		return @path.join @root, "/config/#{path}"

	###
	Extend the fs module with fs-extra
	###
	configureFs: ->
		@fs = require 'fs-extra'

	###
	Configure the prompt module
	###
	configurePrompt: ->
		@prompt.message = null

	###
	Configure system default error handler
	@param [String, Object] error 
	###
	throwError: (error) ->
		if error then console.log error else console.log 'an error occured.'
		setTimeout ->
			process.exit(1)
		, 300

	###
	Configure string trim method
	@param [String] string to trim 
	###
	trim: (s) ->
		s = s.replace /^[.\s]+|[.\s]+$/g, ''
		return s

	###
	Get unix timestamp
	###
	now: ->
		return Date.now() / 100 | 0

	###
	Get compiler object
	###
	getCompiler: (name) ->
		for k, v of @compilers
			if name == v.id or name == v.name then return v
		return false

	###
	Get compiler list
	###
	compilerList: ->
		compilers = []
		for k, v of @compilers
			compilers.push v.id
		return compilers

	###
	Get processor object
	###
	getProcessor: (id) ->
		for k, v of @processors
			if id == v.id then return v
		return false

	###
	Get processor list
	###
	processorList: ->
		processors = []
		for k, v of @processors
			processors.push v.id
		return processors

	###
	Get view Engine object
	###
	getEngine: (id) ->
		for k, v of @engines
			if id == v.id then return v
		return false

	###
	Get engine list
	###
	engineList: ->
		engines = []
		for k, v of @engines
			engines.push v.id
		return engines

	###
	Detect if app is coffee
	@param [App] app app to install apis for
	###
	isCoffee: (app) ->
		return  app.jsCompiler == @compilers.COFFEE.name

	###
	configure id
	###
	configureId: (name) ->
		id = @trim name
		id = id.toLowerCase()
		id = id.replace /\s/g, '-'
		return id

	###
	Install package method definition
	@param [String] pkg package to install
	@param [String] opt option --save-dev
	@param [Function] cb callback function
	###
	install: (pkg, opt, cb) ->
		if opt.match /\-front/
			@bower.commands.install(pkg, {save:true, directory: 'assets/modules'}).on 'end', (installed) ->
				cb null, installed, null
		else
			@exe 'npm', ['install', pkg, opt], cb

	###
	Uninstall package method definition
	@param [String] pkg package to uninstall
	@param [String] opt option
	@param [Function] cb callback function
	###
	uninstall: (pkg, opt, cb) ->
		if opt.match /\-front/
			@bower.commands.uninstall(pkg, {save:true, directory: 'assets/modules'}).on 'end', (installed) ->
				cb null, installed, null
		else
			@exe 'npm', ['uninstall', pkg, opt], cb

	###
	Install packages method definition
	@param [Array<String>] pkgs packages to install
	###
	installPackages: (pkgs) ->
		for pkg in pkgs then @install pkg, '--save-dev', @stdoutCallBack

	###
	Uninstall packages method definition
	@param [Array<String>] pkgs packages to install
	###
	uninstallPackages: (pkgs) ->
		for pkg in pkgs then @uninstall pkg, @stdoutCallBack

	###
	Install api method definition
	@param [String] api api to install
	@param [Function] cb callback function
	###
	installApi: (api, app, cb) ->
		api = @trim api.toLowerCase()
		if @isCoffee(app)
			@exe 'sails', ['generate', 'api', api, @compilers.COFFEE.id], cb
		else
			@exe 'sails', ['generate', 'api', api], cb

	###
	Uninstall api method definition
	@param [String] api api to install
	@param [App] app app to remove api from
	@param [Function] cb callback function
	###
	uninstallApi: (api, app, cb) ->
		api = api.toLowerCase().replace /^[.\s]+|[.\s]+$/g, ''
		ext = if @isCoffee(app) then '.coffee' else '.js'
		@fs.unlink app.file("/api/controllers/#{api}controller#{ext}"), (err) =>
			@fs.unlink app.file("/api/models/#{api}#{ext}"), (err) ->
				if cb then cb err, app

	###
	Uninstall api method definition
	@param [Array<String>] api api to install
	@param [App] app app to install apis for
	###
	installApis: (apis) ->
		for api in apis then @installApi api

	###
	Uninstall api method definition
	@param [Array<String>] api api to install
	@param [App] app app to remove apis from
	###
	uninstallApis: (apis, app) ->
		for api in apis then @uninstallApi api, app

	###
	Uninstall api method definition
	@param [Object] err
	@param [Object] stdout
	@param [Object] stderr
	###
	stdoutCallBack: (error, stdout, stderr) =>
		if error then @throwError()

	###
	configure sqlite3 as default storage
	@returns sqlite verbose
	###
	configureStorage: ->
		return @sqlite.verbose()

	###
	Remove package to app
	@param [App] app
	@param [Function] cb callback function
	###
	configureTasManagerFor: (app, cb) ->
		@install 'grunt-includes@0.5.4', '--save-dev', (error, stdout, stderr) =>
			includeConfig = if @isCoffee(app) then '/tasks/includes-coffee' else '/tasks/includes'
			@fs.copySync @config('/tasks/pipeline'), app.file('/tasks/pipeline.js'), { clobber: true }
			@fs.copySync @config('/tasks/compileAssets'), app.file('/tasks/register/compileAssets.js'), { clobber: true }
			@fs.copySync @config('/tasks/syncAssets'), app.file('/tasks/register/syncAssets.js'), { clobber: true }
			@fs.copySync @config(includeConfig), app.file('/tasks/config/includes.js'), { clobber: true }
			@fs.copySync @config('/tasks/.bowerrc'), app.file('/.bowerrc'), { clobber: true }
			@fs.mkdirsSync app.file('/assets/modules')
			cb null, app

	###
	Remove package to app
	@param [App] app
	@param [Function] cb callback function
	###
	configureCoffeeScriptFor: (app, cb) ->
		@install 'coffee-script@1.10.0', '--save-dev', (error, stdout, stderr) =>
			pkgs = ['sails-generate-controller-coffee@0.0.0', 'sails-generate-model-coffee@0.10.9']
			@installPackages pkgs
			@fs.copySync @config('/tasks/coffee'), app.file('/tasks/config/coffee.js'), { clobber: true }
			cb null, app

	###
	Reset resetViewEngine
	@param [App] app
	@param [Function] cb callback function
	###
	resetViewEngine: (engine, layout, app, cb) ->
		config = app.file '/config/views.js'
		dir = app.file '/views'
		@fs.removeSync dir
		stream = @fs.readFileSync config, @encoding.UTF8
		for k, eng of @engines
			regex = new RegExp "#{eng.id}", 'gi'
			stream = stream.replace regex, "#{engine.id}"
			stream = stream.replace /'layout'/gi, layout
			@fs.writeFileSync config, stream
		@fs.mkdirsSync app.file dir
		for vdir in @views.DIRS then @fs.mkdirsSync app.file vdir
		cb()

	###
	Configure viewEngine
	@param [App] app
	@param [Function] cb callback function
	###
	generateViews: (engine, app, cb) ->
		for view in @views.FILES
			sfile = @config "/templates/#{engine.id}#{view}#{engine.extension}"
			dfile = app.file "#{view}#{engine.extension}"
			@fs.copySync sfile, dfile
		master = app.file "/views/layouts/master#{engine.extension}"
		data = @fs.readFileSync master, @encoding.UTF8
		data = data.replace /\$APP_NAME/gi, app.name
		@fs.writeFileSync master, data
		home = app.file "/views/homepage#{engine.extension}"
		data = @fs.readFileSync home, @encoding.UTF8
		data = data.replace /\$APP_NAME/gi, app.name
		@fs.writeFileSync home, data
		cb()

	###
	Remove package to app
	@param [App] app
	@param [Function] cb callback function
	###
	configureJadeFor: (app, cb) ->
		engine = @engines.JADE
		@resetViewEngine engine, false, app, =>
			@install "#{engine.id}@1.11.0", '--save-dev', (error, stdout, stderr) =>
				@generateViews engine, app, =>
					cb null, app

	###
	Remove package to app
	@param [App] app
	@param [Function] cb callback function
	###
	configureEJSFor: (app, cb) ->
		engine = @engines.EJS
		@resetViewEngine engine, "'layouts/master'", app, =>
			@generateViews engine, app, =>
				cb null, app

	###
	Remove package to app
	@param [App] app
	@param [Function] cb callback function
	###
	configureHandlebarsFor: (app, cb) ->
		engine = @engines.HANDLEBARS
		@install "#{engine.id}@4.0.5", '--save', (error, stdout, stderr) =>
			@fs.copySync @config("/templates/#{engine.id}/views.js"), app.file('/config/views.js'), { clobber: true }
			@fs.copySync @config("/templates/#{engine.id}/helpers.js"), app.file('/config/helpers.js'), { clobber: true }
			@generateViews engine, app, =>
				cb null, app

	###
	Reset cssPreProcessor
	@param [App] app
	@param [Function] cb callback function
	###
	resetCssPreProcessor: (app, cb) ->
		for task in @tasks
			stream = @fs.readFileSync app.file("#{task}.js"), @encoding.UTF8
			for k, processor of @processors
				if task.match /register/
					regex = new RegExp "#{processor.id}:dev", 'gi'
				else
					regex = new RegExp "#{processor.id}", 'gi'
				stream = stream.replace regex, ''
				@fs.writeFileSync app.file("#{task}.js"), stream
		cb()

	###
	Remove package to app
	@param [App] app
	@param [Function] cb callback function
	###
	configureLessFor: (app, cb) ->
		@resetCssPreProcessor app, =>
			stream = @fs.readFileSync app.file('/tasks/config/less.js'), @encoding.UTF8
			stream = stream.replace(/importer.less/gi,'bundles\/*')
			@fs.writeFileSync app.file('/tasks/config/less.js'), stream
			for task in @tasks
				stream = @fs.readFileSync app.file("#{task}.js"), @encoding.UTF8
				if task.match /register/
					stream = stream.replace("'',", "'less:dev',")
				else
					stream = stream.replace("coffee|", "coffee|less")
				@fs.writeFileSync app.file("#{task}.js"), stream
			cb null, app

	###
	Remove package to app
	@param [App] app
	@param [Function] cb callback function
	###
	configureScssFor: (app, cb) ->
		@resetCssPreProcessor app, =>
			@install 'sass@0.5.0', '--save-dev', =>
				pkgs = ['grunt-contrib-sass@1.0.0']
				@installPackages pkgs
				stream = @fs.readFileSync app.file('/tasks/config/less.js'), @encoding.UTF8
				stream = stream.replace(/less/gi, 'sass').replace(/importer.sass/gi,'bundles\/*')
				@fs.writeFileSync app.file('/tasks/config/sass.js'), stream
				for task in @tasks
					stream = @fs.readFileSync app.file("#{task}.js"), @encoding.UTF8
					if task.match /register/
						stream = stream.replace("'',", "'sass:dev',")
					else
						stream = stream.replace("coffee|", "coffee|scss")
					@fs.writeFileSync app.file("#{task}.js"), stream
				cb null, app

	###
	Remove package to app
	@param [App] app
	@param [Function] cb callback function
	###
	configureStylusFor: (app, cb) ->
		@resetCssPreProcessor app, =>
			@install 'stylus@0.54.3', '--save-dev', =>
				pkgs = ['grunt-contrib-stylus@1.2.0']
				@installPackages pkgs
				stream = @fs.readFileSync app.file('/tasks/config/less.js'), @encoding.UTF8
				stream = stream.replace(/less/gi, 'stylus').replace(/importer.stylus/gi,'bundles\/*')
				@fs.writeFileSync app.file('/tasks/config/stylus.js'), stream
				for task in @tasks
					stream = @fs.readFileSync app.file("#{task}.js"), @encoding.UTF8
					if task.match /register/
						stream = stream.replace("'',", "'stylus:dev',")
					else
						stream = stream.replace("coffee|", "coffee|stylus")
					@fs.writeFileSync app.file("#{task}.js"), stream
				cb null, app

	###
	Remove package to app
	@param [App] app
	@param [Function] cb callback function
	###
	configureBundlesFor: (app, cb) ->
		processor = @getProcessor app.cssPreProcessor
		try
			@fs.removeSync app.file('/assets/styles/importer.less')
			@fs.removeSync app.file('/assets/styles/bundles')
		catch e
			# ...
		@fs.mkdirSync app.file('/assets/styles/bundles')
		@fs.writeFileSync app.file("/assets/styles/bundles/default#{processor.extension}"), "/** default styles **/"
		compiler = @getCompiler(app.jsCompiler) or @compilers.NATIVE
		@fs.copySync @config("/templates/#{compiler.id}/app#{compiler.extension}"), app.file("/assets/js/app#{compiler.extension}"), { clobber: true }
		@fs.copySync @config("/templates/#{compiler.id}/Page#{compiler.extension}"), app.file("/assets/js/Page#{compiler.extension}"), { clobber: true }
		cb null, app

	###
	Configure storage with URI
	@param [App] app
	@param [String] uri databse url 
	@param [Function] cb callback function
	###
	configureStorageFor: (app, url, cb) ->
		key = app.storage.toUpperCase()
		storage = @storage[key]
		@install "#{storage.adapter}@#{storage.version}", '--save', (error, stdout, stderr) =>
			@fs.copySync @config("/storage/#{key}/connections"), app.file("/config/connections.js"), { clobber: true }
			if not not url 
				conn = app.file "/config/connections.js"
				data = @fs.readFileSync conn, @encoding.UTF8
				data = data.replace /\$URL/gi, url
				@fs.writeFileSync conn, data
			@setupDBWithConfigFor app, cb

	###
	Default databse connection configuration
	@param [String] db databse label
	@param [String] config databse connection config data 
	###
	setupDBWithConfigFor: (app, cb) ->
		key = app.storage.toUpperCase()
		storage = @storage[key]
		mdest = app.file '/config/models.js'
		mconfig = @fs.readFileSync mdest, @encoding.UTF8
		mconfig = mconfig.replace(/'alter'/gi, "'safe'").replace(/\/\/ /gi,'').replace(/connection/gi, '// connection')
		@fs.writeFileSync mdest, mconfig
		ddest = app.file '/config/env/development.js'
		pdest = app.file '/config/env/production.js'
		dconfig = @fs.readFileSync ddest, @encoding.UTF8
		dconfig = dconfig.replace(/\/\/ /gi,'').replace(/localDiskDb|someMongodbServer|someMysqlServer|somePostgresqlServer|someRedisServer/g, storage.id)
		@fs.writeFileSync ddest, dconfig
		@fs.writeFileSync pdest, dconfig
		cb null, app

# export utils module
module.exports = new Utils 