###
@namespace marie
@author Teddy Moussignac (teddy.moussignac@gmail.com)
@version 0.0.3
@copyright March 2016
@note Marie controller class. Maps routes and commands to app methods.
###

Marie = require './marie'

class MarieCLI

	###
	Construct Marie
	###
	constructor: ->
		new Marie process.argv, process.cwd()

# export controller module
module.exports = new MarieCLI