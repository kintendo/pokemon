fs = require 'fs'
Pokemon = require './pokemon.coffee'

class Player
	constructor: (@name) ->
		@deck = []
		@hand = []
		@discard = []
		@bench = []
		@active = ""
		@last_attack = ""
		@prizes = []
		@status = ""

	# loads a player's deck
	load_deck: (filename) ->
		try
			json = fs.readFileSync "#{__dirname}/#{filename}.json"
			if json? then @deck = JSON.parse json 
		catch error
			console.log error

	# shuffle a player's deck
	shuffle: ->
		deck = @deck.concat @hand
		top = deck.length
		while --top
			rand = Math.floor Math.random()*(top+1)
			tmp = deck[rand]
			deck[rand] = deck[top]
			deck[top] = tmp
		@deck = deck

	# draws card from player deck to hand
	draw_card: ->
		@hand.push @deck.shift()

	# draws 7 cards
	draw_hand: ->
		@hand = []
		for num in [7..1]
			@draw_card()

	# draws 6 prizes
	draw_prizes: ->
		for num in [6..1]
			@prizes.push @deck.shift()

	# creates new active pokemon from hand
	set_active_pokemon: (card) ->
		@active = new Pokemon(card)
		@hand.splice @hand.indexOf(card), 1

	# creates new bench pokemon from hand
	set_bench_pokemon: (card) ->
		pokemon = new Pokemon(card)
		@bench.push pokemon 
		@hand.splice @hand.indexOf(card), 1

	attach_energy: (index, card) ->
		@hand.splice @hand.indexOf(card), 1
		if index is "0"
			@active.attached.push card	
		else
			@bench[index].attached.push card

	retreat: (index) ->
		[@active, @bench[index]] = [@bench[index], @active]
		@bench[index].status = ""
		
module.exports = Player