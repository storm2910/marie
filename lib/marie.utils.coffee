###
@namespace marie
@author Teddy Moussignac (teddy.moussignac@gmail.com)
@version 0.0.3
@copyright: March 2016
@note Marie utility class
###

class Utils
	sails: 'sails@0.12.1'
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
	processors: [
		'less', 
		'scss', 
		'stylus'
	]
	templates: [
		'ejs'
		'jade'
		'handlebars'
	]
	tasks: [
		'/tasks/register/compileAssets'
		'/tasks/register/syncAssets'
		'/tasks/config/sync'
		'/tasks/config/copy'
	]
	storageType:
		DISK: 'localDiskDb'
		LOCAL: 'localMongodbServer'
		REMOTE: 'remoteMongodbServer'
		URL: 'remoteMongodbServerWithURL'

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

	now: ->
		return Date.now() / 100 | 0

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
	installApi: (api, cb) ->
		api = @trim api.toLowerCase()
		@exe 'sails', ['generate', 'api', api, '--coffee'], cb

	###
	Uninstall api method definition
	@param [String] api api to install
	@param [App] app app to remove api from
	@param [Function] cb callback function
	###
	uninstallApi: (api, app, cb) ->
		api = api.toLowerCase().replace /^[.\s]+|[.\s]+$/g, ''
		@fs.unlink app.file("/api/controllers/#{api}controller.coffee"), (err) =>
			@fs.unlink app.file("/api/models/#{api}.coffee"), (err) ->
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
			@fs.copySync @config('/tasks/compileAssets'), app.file('/tasks/register/compileAssets.js'), { clobber: true }
			@fs.copySync @config('/tasks/syncAssets'), app.file('/tasks/register/syncAssets.js'), { clobber: true }
			@fs.copySync @config('/tasks/includes'), app.file('/tasks/config/includes.js'), { clobber: true }
			@fs.copySync @config('/tasks/.bowerrc'), app.file('/.bowerrc'), { clobber: true }
			@fs.mkdirSync app.file('/assets/modules')
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
			@fs.writeFileSync app.file('/assets/js/app.coffee'), ''
			cb null, app

	###
	Remove package to app
	@param [App] app
	@param [Function] cb callback function
	###
	configureJadeFor: (app, cb) ->
		@install 'jade@1.11.0', '--save-dev', (error, stdout, stderr) =>
			viewSrc = app.file '/config/views.js'
			stream = @fs.readFileSync viewSrc, @encoding.UTF8
			stream = stream.replace(/ejs/gi, 'jade').replace(/'layout'/gi, false)
			@fs.writeFileSync viewSrc, stream
			dirs = ['/views/modules', '/views/partials', '/views/layouts']
			for dir in dirs then @fs.mkdirSync app.file dir
			files = ['views/403', 'views/404', 'views/500', 'views/layout', 'views/homepage']
			@fs.unlinkSync app.file "/#{file}.ejs" for file in files
			files.splice files.indexOf('views/layout'), 1
			partial = 'views/partial'
			files.push partial 
			for file in files
				sfile = @config "/templates/#{file}.jade"
				dfile = app.file(if file == partial then '/views/partials/partial.jade' else "/#{file}.jade")
				@fs.copySync sfile, dfile
			masterPath = @config '/templates/views/master.jade'
			masterData = @fs.readFileSync masterPath, @encoding.UTF8
			masterData = masterData.replace /\$APP_NAME/gi, app.name
			@fs.writeFileSync app.file('/views/layouts/master.jade'), masterData
			cb null, app

	###
	Reset cssProcessor
	@param [App] app
	@param [Function] cb callback function
	###
	resetCssProcessor: (app, cb) ->
		for task in @tasks
			stream = @fs.readFileSync app.file("#{task}.js"), @encoding.UTF8
			for processor in @processors
				if task.match /register/
					regex = new RegExp "#{processor}:dev", 'gi'
				else
					regex = new RegExp "#{processor}", 'gi'
				stream = stream.replace regex, ''
				@fs.writeFileSync app.file("#{task}.js"), stream
		cb()

	###
	Remove package to app
	@param [App] app
	@param [Function] cb callback function
	###
	configureLessFor: (cb) ->
		configs = [
			'/tasks/register/compileAssets'
			'/tasks/register/syncAssets'
			'/tasks/config/sync'
			'/tasks/config/copy'
		]

		for config in configs
			stream = @fs.readFileSync app.file("#{config}.js"), @encoding.UTF8
			if config.match /register/
				stream = stream.replace(/less:dev/gi, 'stylus:dev')
			else
				stream = stream.replace(/less/gi, 'stylus')
			@fs.writeFileSync app.file("#{config}.js"), stream
		cb null, app

	###
	Remove package to app
	@param [App] app
	@param [Function] cb callback function
	###
	configureScssFor: (app, cb) ->

	###
	Remove package to app
	@param [App] app
	@param [Function] cb callback function
	###
	configureStylusFor: (app, cb) ->
		@resetCssProcessor app, =>
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
		ext = '.styl'
		try
			@fs.removeSync app.file('/assets/styles/importer.less')
			@fs.removeSync app.file('/assets/styles/bundles')
		catch e
			# ...
		@fs.mkdirSync app.file('/assets/styles/bundles')
		@fs.writeFileSync app.file("/assets/styles/bundles/default#{ext}"), "/** default styles **/"
		@fs.writeFileSync app.file("/assets/styles/bundles/admin#{ext}"), "/** admin styles **/"
		cb null, app

	###
	Local mongodb database configuration
	@param [App] app
	@param [Function] cb callback function
	###
	configureLocalMongoDBFor: (app, cb) ->
		app.storage = @storageType.LOCAL
		lconfig = @fs.readFileSync @config "/databases/#{@storageType.LOCAL}.js", @encoding.UTF8
		cconfig = @fs.readFileSync @config('/databases/connections.js'), @encoding.UTF8
		cconfig = cconfig.replace /\$MONGO\.CONNECTION/, lconfig
		@install 'sails-mongo@0.12.0', '--save', (error, stdout, stderr) =>
			@setupDBWithConfigFor app, cconfig, cb

	###
	Configure remote mongodb with user, password, host, port and database credentials
	@param [App] app
	@param [Object] config
	@param [Function] cb callback function
	###
	configureRemoteMongoDBWithConfigFor: (app, config, cb) ->
		app.storage = @storageType.REMOTE
		sconfig = @fs.readFileSync @config "/databases/#{@storageType.REMOTE}.js", @encoding.UTF8
		cconfig = @fs.readFileSync @config('/databases/connections.js'), @encoding.UTF8
		cconfig = cconfig.replace /\$MONGO\.CONNECTION/, sconfig
		cconfig = cconfig.replace /\$MONGO\.HOST/gi, @trim config.host
		cconfig = cconfig.replace /\$MONGO\.PORT/gi, Number config.port
		cconfig = cconfig.replace /\$MONGO\.USER/gi, @trim config.user
		cconfig = cconfig.replace /\$MONGO\.PASSWORD/gi, @trim config.password
		cconfig = cconfig.replace /\$MONGO\.DATABASE/gi, @trim config.database
		@install 'sails-mongo@0.12.0', '--save', (error, stdout, stderr) =>
			@setupDBWithConfigFor app, cconfig, cb

	###
	Configure mongodb with URI
	@param [App] app
	@param [String] uri databse url 
	@param [Function] cb callback function
	###
	configureRemoteMongoDBWithURIFor: (app, uri, cb) ->
		app.storage = @storageType.URL
		uconfig = @fs.readFileSync @config "/databases/#{@storageType.URL}.js", @encoding.UTF8
		cconfig = @fs.readFileSync @config('/databases/connections.js'), @encoding.UTF8
		cconfig = cconfig.replace /\$MONGO\.CONNECTION/, uconfig
		cconfig = cconfig.replace /\$MONGO\.URL/gi, uri
		@install 'sails-mongo@0.12.0', '--save', (error, stdout, stderr) =>
			@setupDBWithConfigFor app, cconfig, cb

	###
	Default databse connection configuration
	@param [String] db databse label
	@param [String] config databse connection config data 
	###
	setupDBWithConfigFor: (app, cconfig, cb) ->
		mdest = app.file '/config/models.js'
		mconfig = @fs.readFileSync mdest, @encoding.UTF8
		mconfig = mconfig.replace(/'alter'/gi, "'safe'").replace(/\/\/ /gi,'').replace(/connection/gi, '// connection')
		@fs.writeFileSync mdest, mconfig
		if not not cconfig
			cdest = app.file '/config/connections.js'
			@fs.writeFileSync cdest, cconfig
		ddest = app.file '/config/env/development.js'
		pdest = app.file '/config/env/production.js'
		dconfig = @fs.readFileSync ddest, @encoding.UTF8
		dconfig = dconfig.replace(/\/\/ /gi,'').replace(/someMongodbServer|localDiskDb|localMongodbServer|remoteMongodbServerWithURL|remoteMongodbServer/g, app.storage)
		@fs.writeFileSync ddest, dconfig
		@fs.writeFileSync pdest, dconfig
		cb null, app

# export utils module
module.exports = new Utils 