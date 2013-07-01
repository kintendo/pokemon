# sends index.html to each connection
# ==============================================================================
http = require 'http'
fs = require 'fs'

app = http.createServer (req,res)->
	fs.readFile "#{__dirname}/index.html", (err, data) ->
		if err
			res.writeHead(500)
			res.end('Error loading index.html')
		else
			res.writeHead(200)
			res.end(data)

io = require('socket.io').listen app
app.listen process.env.PORT

# logic accessible by all sockets
# ==============================================================================

# every server holds pokedex data and helper functions
help = require './help.coffee'
Player = require './player.coffee'
Pokemon = require './pokemon.coffee'
Gym = require './gym.coffee'

# every server holds all game data
gyms = new Object 
gyms['lobby'] = new Gym('lobby')

# logic unique to each socket
# ==============================================================================

io.sockets.on 'connection', (socket) ->
	trainer = rival = []
	trainer.name = 'Guest'
	gym = gyms['lobby']
	socket.join 'lobby'

	send_game_state = () ->
		socket.emit 'game_state', {
			i_turn: if gym.turn is trainer.name then "true" else "false",
			i_hand: JSON.stringify(trainer.hand),
			i_name: trainer.name,
			i_prizes: trainer.prizes.length,
			i_active: JSON.stringify(trainer.active),
			i_bench: JSON.stringify(trainer.bench),
			u_hand: rival.hand.length,
			u_name: rival.name,
			u_prizes: rival.prizes.length,
			u_active: JSON.stringify(rival.active),
			u_bench: JSON.stringify(rival.bench)
		}
		socket.broadcast.to(gym.name).emit 'game_state', {
			i_turn: if gym.turn is rival.name then "true" else "false",
			i_hand: JSON.stringify(rival.hand),
			i_name: rival.name,
			i_prizes: rival.prizes.length,
			i_active: JSON.stringify(rival.active),
			i_bench: JSON.stringify(rival.bench),
			u_hand: trainer.hand.length,
			u_name: trainer.name,
			u_prizes: trainer.prizes.length,
			u_active: JSON.stringify(trainer.active),
			u_bench: JSON.stringify(trainer.bench)
		}


	#on send chat
	socket.on 'send_chat', (data) ->
		console.log "#{trainer.name} says '#{data.message}' in #{gym.name}"
		socket.broadcast.to(gym.name).emit 'send_chat', {message: data.message, name: trainer.name}

	#on set trainer name (will always be in lobby)
	socket.on 'set_name', (data) ->
		console.log "trying to set name as #{data.name}"
		if gym.trainers[data.name]?
			socket.emit 'error', {message: 'Name already exists.'}
		else if trainer.name is not 'Guest'
			gym.trainers[trainer.name] = null
			gym.trainers[data.name] = trainer
			trainer.name = data.name
		else
			console.log "name set as #{data.name}"
			trainer = gym.trainers[data.name] = new Player(data.name)
			socket.broadcast.to(gym.name).emit 'send_chat', { message: 'Trainer '+trainer.name+' has entered the battlefield!', name: 'Bot'}
			gym_list = []
			for key in gyms
				gym_list.push key
			socket.emit 'gym_list', { list: JSON.stringify gym_list}

	#on join gym
	socket.on 'join_game', (data) ->
		if not gyms[data.name]?
			gym.trainers[trainer.name] = null
			socket.leave 'lobby'
			gym = gyms[data.name] = new Gym(data.name)
			gym.trainers[trainer.name] = trainer
			socket.join data.name
		else if gym.status is 'full'
			socket.emit 'full_game', {message: 'The gym is currently full. Observe?'}
		else
			gym.trainers[trainer.name] = null
			socket.leave 'lobby'
			gym = gyms[data.name]
			gym.trainers[trainer.name] = trainer
			socket.join data.name
			gym.status = 'full'
			console.log gym

	#on disconnect
	socket.on 'disconnect', () ->
		socket.broadcast.to(gym.name).emit 'send_chat', { message: 'Trainer  #{data.name} has left the battlefield!'}
		gyms[gym.name].trainers[trainer.name] = null
		socket.leave gym.name
		trainer = rival = gym = null

	#on set deck name
	socket.on 'set_deck', (data) ->
		trainer.load_deck data.deck
		if not help.is_deck_valid trainer.deck
			socket.emit 'error', { message: "Your deck was invalid! Please enter a valid deck name."}

	#on start game (shuffle & draw)
	socket.on 'start_game', (data) ->
		if trainer.name is 'Guest'
			socket.emit 'error', {message: "Need to name yourself first."}
		else
			if not help.is_deck_valid trainer.deck
				socket.emit 'error', {message: "Need to load a valid deck first."}
			else
				while not help.has_basic_pokemon trainer.hand
					trainer.shuffle()
					trainer.draw_hand()
				trainer.draw_prizes
				socket.emit 'get_active', { message: "Choose a basic Pokemon as your active Pokemon!", hand: JSON.stringify trainer.hand }

	#on set active pokemon (beginning of game)
	socket.on 'set_active', (data) ->
		if help.is_basic_pokemon data.card
			console.log "setting active pkmn: #{data.card}"
			trainer.set_active_pokemon data.card
			socket.emit 'get_bench',{ message: "Now choose your benched Pokemon!", hand: JSON.stringify trainer.hand }
		else
			socket.emit 'get_active',{ message: "Please choose a BASIC Pokemon!", hand: JSON.stringify trainer.hand }

	#on set bench pokemon (beginning of game) TODO: check full bench
	socket.on 'set_bench', (data) ->
		if help.is_basic_pokemon data.card
			if trainer.bench.length < 5
				trainer.set_bench_pokemon data.card
			else
				socket.emit 'error',{message: "Bench full!"}
		socket.emit 'get_bench', {hand: JSON.stringify trainer.hand }

	#on end choosing pokemon (beginning of game)
	socket.on 'set_end', (data) ->
		if gym.status is "battle"
			socket.broadcast.to(gym.name).emit 'set_rival', {name: trainer.name}
		else
			gym.status = "battle"
			socket.emit 'send_chat', { message: 'Waiting for your rival to prepare for battle...', name: 'Bot'}

	#sets rival
	socket.on 'set_rival', (data) ->
		rival = gym.trainers[data.name]
		socket.broadcast.to(gym.name).emit 'ack_rival', {name: trainer.name}

	#acknlowdging the opponent so they know who you are, battle begin
	socket.on 'ack_rival', (data) ->
		rival = gym.trainers[data.name]
		gym.turn = if help.flip_coin() then trainer.name else rival.name #both players set: pick first turn
		send_game_state()

	#on show attached cards
	socket.on 'show_attached', (data) ->
		cards = []
		switch data.context
			when "i_bench" then cards = trainer.bench[data.index].attached
			when "i_active" then cards = trainer.active.attached
			when "u_bench" then cards = rival.bench[data.index].attached
			when "u_active" then cards = rival.active.attached
		socket.emit 'show_attached', { cards: JSON.stringify cards }

	#on attach energy
	socket.on 'attach_energy', (data) ->
		if help.is_in_hand trainer.hand, data.card
			if help.is_energy data.card
				trainer.attach_energy data.index, data.card
				gym.energy = true
				send_game_state()

	#on make active pokemon
	socket.on 'make_active', (data) ->
		if gym.turn is trainer.name
			if not gym.retreat
				if help.is_enough_energy trainer.active.name, trainer.active.attached
					gym.pending = data.index
					pay_retreat_cost trainer.active.name
				else
					socket.emit 'error', {message: "not enough energy to retreat"}
			else 
				socket.emit 'error', {message: "can only retreat once a turn"}
		else
			socket.emit 'error', {message: "not your turn"}
	
	pay_retreat_cost = (card) ->
		gym.debt = help.get_retreat_cost card
		if gym.debt <= 0
			trainer.retreat(gym.pending)
			gym.pending = ""
			gym.retreat = true
			send_game_state()
		else
			socket.emit 'select_energy', {cards: JSON.stringify trainer.active.attached}

	#on choose energy
	socket.on 'select_energy', (data) ->
		trainer.active.discard(data.card)
		if help.is_colorless_energy(data.card) then gym.debt-=2 else gym.debt-=1
		if gym.debt <= 0
			trainer.retreat(gym.pending)
			gym.retreat = true
			send_game_state()
		else
			socket.emit 'select_energy', {cards: JSON.stringify trainer.active.attached}

	#on play card
	socket.on 'play_card', (data) ->
		if gym.turn is trainer.name
			if help.is_in_hand trainer.hand, data.card
				if help.is_energy data.card
					if not gym.energy
						socket.emit 'choose_energy_target', { energy: data.card, active: JSON.stringify(trainer.active), bench: JSON.stringify(trainer.bench) }
					else
						socket.emit 'error', {message: "You can only attach 1 energy a turn!"}
		else
			socket.emit 'error', {message: "It's not your turn!"}

	#on end turn
	socket.on 'end_turn', () ->
		gym.end_turn()
		#deal with dots
		send_game_state()
#trainer card?
#pokemon card?

