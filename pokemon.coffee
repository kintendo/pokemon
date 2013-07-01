class Pokemon
	constructor: (@name) ->
		@status = ""
		@damage = 0
		@poisoned = false
		@burned = false
		@attached = []
		@cooldown = true

	discard: (card) ->
		@attached.splice @attached.indexOf(card), 1

#bench pokemon have no status

module.exports = Pokemon