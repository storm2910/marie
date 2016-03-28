# importer + utility class

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


module.exports = new Utils 
