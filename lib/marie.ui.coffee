###
@namespace marie
@author Teddy Moussignac (teddy.moussignac@gmail.com)
@version 0.0.3
@copyright: March 2016
@note Marie ui class
###

class UI
	@styles
	clc: require 'cli-color'
	BULLET: '\u262F '
	DASH: '\u0335'
	CARET: '\u2192 '
	CHECK: '\u221A '
	XPIXELS: 104
	
	###
	Construct app
	###
	constructor: ->
		@styles = 
			WARN: @clc.yellowBright
			INFO: @clc.white
			OK: @clc.greenBright
			ERROR: @clc.redBright

	###
	Configure message output syle method
	@param [String] msg string message to output
	@maram [String] theme style to apply to string
	###
	msg: (msg, theme) ->
		console.log @clc.white "#{@CARET}" + clc[theme] msg

	###
	Configure write to console without new line method
	@param [String] msg string message to output
	###
	write: (msg) ->
		@clear()
		process.stdout.write @clc.blackBright "#{@BULLET}" + @clc.blackBright msg

	###
	Configure clear console method
	###
	clear: ->
		process.stdout.clearLine()
		process.stdout.cursorTo 0

	###
	Configure message output method
	@param [String] msg string message to output
	@maram [String] symbol symbol to preprend to message
	###
	# log: (msg, symbol) ->
	# 	@clear()
	# 	console.log msg
		# console.log @clc.white  (symbol or @CARET) + msg

	###
	Configure warning message output method
	@param [String] msg string message to output
	###
	warn: (msg) ->
		# @log @styles.WARN msg
		console.log msg

	###
	Configure notice message output method
	@param [String] msg string message to output
	###
	notice: (msg) ->
		# @log @styles.INFO msg
		console.log msg

	###
	Configure okay message output method
	@param [String] msg string message to output
	###
	ok: (msg) ->
		# @log @styles.OK(msg), @CHECK
		console.log msg

	###
	Configure error message output method
	@param [String] msg string message to output
	###
	error: (msg) ->
		# @log @styles.INFO msg
		console.log msg

	###
	Configure write line to output method
	###
	line: ->
		stdout = ''
		for i in [0..@XPIXELS] then stdout = stdout + @DASH
		console.log @clc.blackBright stdout

	###
	Configure console header style method
	@param [String] a
	@param [String] a
	@example ui.header 'a', 'b'
	###
	header: (a,b) ->
		@line()
		console.log @clc.yellowBright "#{a}" + @clc.whiteBright " #{b}"
		@line()

# export ui module
module.exports = new UI 