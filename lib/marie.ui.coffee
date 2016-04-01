###
@namespace marie
@author Teddy Moussignac (teddy.moussignac@gmail.com)
@version 0.0.3
@copyright: March 2016
@note Marie ui class
###

utils = require './marie.utils'

class UI
	XPIXELS: 104
	DASH: '\u0335'
	CARET: '\u2192 '
	CHECK: '\u221A '
	BULLET: '\u262F '

	styles:
		WARN: utils.clc.yellowBright
		INFO: utils.clc.white
		OK: utils.clc.greenBright
		ERROR: utils.clc.redBright

	###
	Construct app
	###
	constructor: ->

	###
	Configure message output syle method
	@param [String] msg string message to output
	@maram [String] theme style to apply to string
	###
	msg: (msg, theme) ->
		console.log utils.clc.white "#{@CARET}" + clc[theme] msg

	###
	Configure write to console without new line method
	@param [String] msg string message to output
	###
	write: (msg) ->
		@clear()
		process.stdout.write utils.clc.blackBright "#{@BULLET}" + utils.clc.blackBright msg

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
	log: (msg, symbol) ->
		@clear()
		console.log utils.clc.white  (symbol or @CARET) + msg

	###
	Configure warning message output method
	@param [String] msg string message to output
	###
	warn: (msg) ->
		@log @styles.WARN msg

	###
	Configure notice message output method
	@param [String] msg string message to output
	###
	notice: (msg) ->
		@log @styles.INFO msg

	###
	Configure okay message output method
	@param [String] msg string message to output
	###
	ok: (msg) ->
		@log @styles.OK(msg), @CHECK

	###
	Configure error message output method
	@param [String] msg string message to output
	###
	error: (msg) ->
		@log @styles.INFO msg

	###
	Configure write line to output method
	###
	line: ->
		stdout = ''
		for i in [0..@XPIXELS] then stdout = stdout + @DASH
		console.log utils.clc.blackBright stdout

	###
	Configure console header style method
	###
	header: (a,b) ->
		@line()
		console.log utils.clc.yellowBright "#{a}" + utils.clc.whiteBright " #{b}"
		@line()


# export ui module
module.exports = new UI 