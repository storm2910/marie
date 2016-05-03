###
@namespace marie
@author Teddy Moussignac (teddy.moussignac@gmail.com)
@version 0.0.3
@copyright: March 2016
@note Marie ui class
###

class UI

	###
	Configure write to console without new line method
	@param [String] msg string message to output
	###
	write: (msg) ->
		console.log msg

	###
	Configure clear console method
	###
	clear: ->
		process.stdout.clearLine()
		process.stdout.cursorTo 0

	###
	Configure warning message output method
	@param [String] msg string message to output
	###
	warn: (msg) ->
		console.log msg

	###
	Configure notice message output method
	@param [String] msg string message to output
	###
	notice: (msg) ->
		console.log msg

	###
	Configure okay message output method
	@param [String] msg string message to output
	###
	ok: (msg) ->
		console.log msg

	###
	Configure error message output method
	@param [String] msg string message to output
	###
	error: (msg) ->
		console.log msg

	###
	Configure write line to output method
	###
	line: ->
		@clear()

	###
	Configure console header style method
	@param [String] a
	@param [String] a
	@example ui.header 'a', 'b'
	###
	header: (a,b) ->
		console.log "#{a} #{b}"

# export ui module
module.exports = new UI 