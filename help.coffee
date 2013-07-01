
# helper helps implements game rules
fs = require 'fs'
pokedex = JSON.parse fs.readFileSync "#{__dirname}/cards.json"

# checks to see if deck is valid
exports.is_deck_valid = (deck) ->
	if deck.length isnt 60
		return false
	deck.sort()
	for card in deck
		if (deck.lastIndexOf card)-(deck.indexOf card)+1 > 4
			if not card.match /energy$/
				return false
	return true

# checks to see if card is a basic pokemon
exports.is_basic_pokemon = (card) ->
	console.log card
	pokedex[card].evolves is "none"

# check to see if hand has card that is basic pokemon
exports.has_basic_pokemon = (hand) ->
	if hand?
		for card in hand
			if @is_basic_pokemon card
				return true
	return false

# check to see if card is in hand
exports.is_in_hand = (hand, card) ->
	return hand.indexOf card isnt -1

# flips a coin
exports.flip_coin = () ->
	return Math.floor Math.random()*2

#check to see if card is an energy card
exports.is_energy = (card)->
	return pokedex[card].type is "energy"
	
#checks to see if pokemon has enough energy
exports.is_enough_energy = (card, attached) ->
	cost = pokedex[card].retreat
	count = 0
	for card in attached
		if pokedex[card].type is "energy"
			if pokedex[card].element is "colorless"
				count+=2
			else count+=1
	return count >= cost

#returns a card's retreat cost
exports.get_retreat_cost = (card) ->
	return pokedex[card].retreat

#checks if card is a double colorless energy
exports.is_colorless_energy = (card) ->
	console.log "inside help: #{card}"
	return pokedex[card].element is "colorless"
###


function claim_prize(game_index, player_index){
	var random_prize_index = Math.floor(Math.random()*games[game_index].players[player_index].prizes.length);
	var random_prize = games[game_index].players[player_index].prizes[random_prize_index];
	games[game_index].players[player_index].prizes.splice(random_prize_index,1);
	games[game_index].players[player_index].hand.push(random_prize);
}

function is_asleep(game_index, player_index){
	return games[game_index].players[player_index].active.status == "asleep";
}
function is_confused(game_index, player_index){
	return games[game_index].players[player_index].active.status == "confused";
}
function is_paralyzed(game_index, player_index){
	return games[game_index].players[player_index].active.status == "paralyzed";
}


###
