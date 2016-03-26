clc = require 'cli-color'

class UI
	@xpixels
	caret: '\u02c3 '
	dash: '\u0335'


	constructor: ->
		@xpixels = 8 * 12


	warn: (msg) ->
		@log 'warn', msg


	notice: (msg) ->
		@log 'notice', msg


	ok: (msg) ->
		@log 'ok', msg


	error: (msg) ->
		@log 'error', msg


	msg: (msg, theme) ->
		console.log clc.white "#{@caret}" + clc[theme] msg


	log: (key, msg) ->
		_clc =
			warn: clc.yellowBright
			notice: clc.white
			ok: clc.greenBright
			error: clc.redBright
		console.log clc.white "#{@caret}" + _clc[key] msg


	line: ->
		stdout = ''
		for i in [0..@xpixels] then stdout = stdout + @dash
		console.log clc.blackBright stdout


	header: (a,b) ->
		@line()
		console.log clc.yellowBright "#{a}" + clc.whiteBright " #{b}"
		@line()


# export class
module.exports = new UI 