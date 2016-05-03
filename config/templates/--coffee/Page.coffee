class Page
	@title

	constructor: (@title) ->

	greet: ->
		console.log "This is your #{@title}."