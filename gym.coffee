class Gym
	constructor: (@name) ->
		@status = "waiting"		#current gym status "waiting"|"full"
		@trainers = []			#obj holding two players
		@turn = "none"			#name of current trainer's turn
		@retreat = false		#if retreat used this turn
		@energy = false			#if energy add used this turn
		@cache = []				#collection of cards during gameplay
		@debt = 0				#keeps track of retreat costs
		@pending = ""			#keeps track of index of chosen bench pokemon

	end_turn: () ->
		@turn = if @turn is @trainers[0].name then @trainers[1].name else @trainers[0].name
		@retreat = false
		@energy = false
		@cache = []
		@debt = 0
		@pending = ""

#retreat & energy once/turn
module.exports = Gym