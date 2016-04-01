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


# export utils module
module.exports = new Utils 
