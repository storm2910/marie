class Utils
	fs: require 'fs'
	path: require 'path'
	prompt: require 'prompt'
	exe: require('child_process').execFile
	spawn: require('child_process').spawn
	spawnSync: require('child_process').spawnSync
	clc: require 'cli-color'
	root: __dirname.replace '/marie/lib', '/marie'


	constructor: ->
		@configurePrompt()
		@configureFs()


	config: (path) ->
		if not @path.extname path  then path = path + '.js'
		return @path.join @root, "/config/#{ path }"


	configureFs: ->
		@fs = require 'fs-extra'


	configurePrompt: ->
		@prompt.message = null


	throwError: (error) ->
		if error then ui.error error else 'An error occured.'
		setTimeout ->
			process.exit()
		, 300


	install: (pkg, opt, cb) ->
		@exe 'npm', ['install', pkg, opt], cb


	uninstall: (pkg, cb) ->
		@exe 'npm', ['uninstall', pkg], cb


	installPackages: (pkgs) ->
		for pkg in pkgs then @install pkg, '--save-dev', @stdoutCallBack


	uninstallPackages: (pkgs) ->
		for pkg in pkgs then @uninstall pkg, @stdoutCallBack


	installApi: (api) ->
		api = api.toLowerCase().replace /\s/, ''
		@exe 'sails', ['generate', 'api', api, '--coffee'], @stdoutCallBack

	installApis: (apis)->
		for api in apis then @installApi api


	stdoutCallBack: (error, stdout, stderr) =>
		if error then @throwError()


module.exports = new Utils 
