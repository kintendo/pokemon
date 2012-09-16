http = require 'http'
app = http.createServer (req,res)->
  fs.readFile(__dirname + '/index.html',
  (err, data) ->
    if err
      res.writeHead(500)
      res.end('Error loading index.html')
    res.writeHead(200)
    res.end(data)
  )

fs = require 'fs'
io = require('socket.io').listen app

app.listen process.env.PORT

io.sockets.on 'connection', (socket) ->
    socket.emit 'new_trainer', {message: 'it works!'}
