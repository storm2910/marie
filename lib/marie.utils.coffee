###
@namespace marie
@author Teddy Moussignac (teddy.moussignac@gmail.com)
@version 0.0.3
@copyright: March 2016
@note Marie utility class
###

class Utils
	fs: require 'fs'
	path: require 'path'
	prompt: require 'prompt'
	exe: require('child_process').execFile
	spawn: require('child_process').spawn
	spawnSync: require('child_process').spawnSync
	clc: require 'cli-color'
	root: __dirname.replace '/marie/lib', '/marie'
	encoding:
		UTF8: 'utf8'
	framework:
		BOOTSTRAP: 'bootstrap'
		FOUNDATION: 'foundation'
	storageType:
		LOCAL: 'localMongodbServer'
		REMOTE: 'remoteMongodbServer'
		URL: 'remoteMongodbServerWithURL'

	###
	Construct app
	###
	constructor: ->
		@configurePrompt()
		@configureFs()

	###
	Configure config file path
	@param [String] path path to config file
	###
	config: (path) ->
		if not @path.extname path  then path = path + '.js'
		return @path.join @root, "/config/#{ path }"

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
		if error then console.log error else 'An error occured.'
		setTimeout ->
			process.exit()
		, 300

	###
	Install package method definition
	@param [String] pkg package to install
	@param [String] opt option --save-dev
	@param [Function] cb callback function
	###
	install: (pkg, opt, cb) ->
		@exe 'npm', ['install', pkg, opt], cb

	###
	Uninstall package method definition
	@param [String] pkg package to uninstall
	@param [Function] cb callback function
	###
	uninstall: (pkg, opt, cb) ->
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
	@param [App] app app to install api for
	###
	installApi: (api, app, cb) ->
		process.chdir app.path
		api = api.toLowerCase().replace /^[.\s]+|[.\s]+$/g, ''
		@exe 'sails', ['generate', 'api', api, '--coffee'], cb

	###
	Uninstall api method definition
	@param [String] api api to install
	@param [App] app app to remove api from
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
	installApis: (apis, app)->
		for api in apis then @installApi api, app

	###
	Uninstall api method definition
	@param [Array<String>] api api to install
	@param [App] app app to remove apis from
	###
	uninstallApis: (apis, app)->
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
		return require('sqlite3').verbose()

	###
	Remove package to app
	@param [String] name app id name
	@param [Function] cb callback function
	###
	configureTasManagerFor: (app, cb) ->
		@install 'grunt-includes', '--save-dev', (error, stdout, stderr) =>
			@fs.copySync @config('/tasks/compileAssets'), app.file('/tasks/register/compileAssets.js'), { clobber: true }
			@fs.copySync @config('/tasks/syncAssets'), app.file('/tasks/register/syncAssets.js'), { clobber: true }
			@fs.copySync @config('/tasks/includes'), app.file('/tasks/config/includes.js'), { clobber: true }
			cb null, app

	###
	Remove package to app
	@param [String] name app id name
	@param [Function] cb callback function
	###
	configureCoffeeScriptFor: (app, cb) ->
		@install 'coffee-script', '--save-dev', (error, stdout, stderr) =>
			pkgs = ['sails-generate-controller-coffee', 'sails-generate-model-coffee']
			@installPackages pkgs
			@fs.copySync @config('/tasks/coffee'), app.file('/tasks/config/coffee.js'), { clobber: true }
			@fs.writeFileSync app.file('/assets/js/app.coffee'), ''
			cb null, app

	###
	Remove package to app
	@param [String] name app id name
	@param [Function] cb callback function
	###
	configureJadeFor: (app, cb) ->
		@install 'jade', '--save-dev', (error, stdout, stderr) =>
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
	Remove package to app
	@param [String] name app id name
	@param [Function] cb callback function
	###
	configureStylusFor: (app, cb) ->
		@install 'stylus', '--save-dev', =>
			pkgs = ['grunt-contrib-stylus']
			@installPackages pkgs
			stream = @fs.readFileSync app.file('/tasks/config/less.js'), @encoding.UTF8
			stream = stream.replace(/less/gi, 'stylus').replace(/importer.stylus/gi,'bundles\/*')
			@fs.writeFileSync app.file('/tasks/config/stylus.js'), stream
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
	@param [String] name app id name
	@param [Function] cb callback function
	###
	configureFrontEndFrameworkFor: (app, cb) ->
		ccpath = "#{@root}/config/#{app.frontEndFramework}-#{app.cssProcessor}"
		cjpath = "#{@root}/config/#{app.frontEndFramework}-js"
		dcpath = app.file "/assets/styles/#{app.frontEndFramework}"
		djpath = app.file "/assets/js/dependencies/#{app.frontEndFramework}"
		@fs.copySync ccpath, dcpath, { clobber: true }
		@fs.copySync cjpath, djpath, { clobber: true }
		cb null, app

	###
	Remove package to app
	@param [String] name app id name
	@param [Function] cb callback function
	###
	configureBundlesFor: (app, cb) ->
		ext = '.styl'
		styles = if not not app.frontEndFramework then "@import '../#{app.frontEndFramework}'" else ''
		@fs.mkdirSync app.file('/assets/styles/bundles')
		@fs.removeSync app.file('/assets/styles/importer.less')
		@fs.writeFileSync app.file("/assets/styles/bundles/default#{ext}"), styles
		@fs.writeFileSync app.file("/assets/styles/bundles/admin#{ext}"), styles
		cb null, app


# export utils module
module.exports = new Utils 
