clc = require 'cli-color'

class UI
	XPIXELS: 104
	CARET: '\u2192 '
	CHECK: '\u221A '
	BULLET: '\u262F '
	DASH: '\u0335'

	constructor: ->


	warn: (msg) ->
		@log 'warn', msg


	notice: (msg) ->
		@log 'notice', msg


	ok: (msg) ->
		@log 'ok', msg, @CHECK


	error: (msg) ->
		@log 'error', msg


	msg: (msg, theme) ->
		console.log clc.white "#{@CARET}" + clc[theme] msg


	write: (msg) ->
		@clear()
		process.stdout.write clc.blackBright "#{@BULLET}" + clc.blackBright msg


	clear: ->
		process.stdout.clearLine()
		process.stdout.cursorTo 0


	log: (key, msg, symbol) ->
		_clc =
			warn: clc.yellowBright
			notice: clc.white
			ok: clc.greenBright
			error: clc.redBright
		@clear()
		console.log clc.white "#{symbol or @CARET}" + _clc[key] msg


	line: ->
		stdout = ''
		for i in [0..@XPIXELS] then stdout = stdout + @DASH
		console.log clc.blackBright stdout


	header: (a,b) ->
		@line()
		console.log clc.yellowBright "#{a}" + clc.whiteBright " #{b}"
		@line()


# export ui module
module.exports = new UI 