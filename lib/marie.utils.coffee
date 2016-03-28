fs = require 'fs'
fs = require 'fs-extra'

class Utils
	fs: fs
	path: require 'path'
	prompt: require 'prompt'
	exe: require('child_process').execFile
	spawn: require('child_process').spawn
	spawnSync: require('child_process').spawnSync


	configPath: (path) ->
		return @path.join __dirname.replace('/marie/lib', '/marie/config'), path


module.exports = new Utils 
