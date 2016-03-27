clc = require 'cli-color'

class UI
	@xpixels
	caret: '\u2192 '
	check: '\u221A '
	bullet: '\u262F '
	dash: '\u0335'


	constructor: ->
		@xpixels = Math.round Math.pow 8, 2.333


	warn: (msg) ->
		@log 'warn', msg


	notice: (msg) ->
		@log 'notice', msg


	ok: (msg) ->
		@log 'ok', msg, @check


	error: (msg) ->
		@log 'error', msg


	msg: (msg, theme) ->
		console.log clc.white "#{@caret}" + clc[theme] msg

	write: (msg) ->
		@clear()
		process.stdout.write clc.blackBright "#{@bullet}" + clc.blackBright msg


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
		console.log clc.white "#{symbol or @caret}" + _clc[key] msg


	line: ->
		stdout = ''
		for i in [0..@xpixels] then stdout = stdout + @dash
		console.log clc.blackBright stdout


	header: (a,b) ->
		@line()
		console.log clc.yellowBright "#{a}" + clc.whiteBright " #{b}"
		@line()


# export ui module
module.exports = new UI 