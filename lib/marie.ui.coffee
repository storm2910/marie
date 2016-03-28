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

	constructor: ->


	msg: (msg, theme) ->
		console.log utils.clc.white "#{@CARET}" + clc[theme] msg


	write: (msg) ->
		@clear()
		process.stdout.write utils.clc.blackBright "#{@BULLET}" + utils.clc.blackBright msg


	clear: ->
		process.stdout.clearLine()
		process.stdout.cursorTo 0


	log: (msg, symbol) ->
		@clear()
		console.log utils.clc.white  (symbol or @CARET) + msg


	warn: (msg) ->
		@log @styles.WARN msg


	notice: (msg) ->
		@log @styles.INFO msg


	ok: (msg) ->
		@log @styles.OK(msg), @CHECK


	error: (msg) ->
		@log @styles.INFO msg


	line: ->
		stdout = ''
		for i in [0..@XPIXELS] then stdout = stdout + @DASH
		console.log utils.clc.blackBright stdout


	header: (a,b) ->
		@line()
		console.log utils.clc.yellowBright "#{a}" + utils.clc.whiteBright " #{b}"
		@line()


# export ui module
module.exports = new UI 