NetflixRoulette = require 'netflix-roulette'
http = require 'http'
jade = require 'jade'
omdb = require 'omdb'
fs = require 'fs'
port = 9090

moviesCached = []
cacheLifetime = 1000*60*60*24
lastUpdated = 0

getRandom = (min, max) ->
	min ?= 0
	max ?= moviesCached.length
	return Math.floor(Math.random() * (max - min)) + min

render = (options) ->
	options ?= {}
	options.pretty = true
	options.compileDebug = true
	return jade.renderFile('./index.jade', options)


getCageMovies = (cb) ->
	if lastUpdated+cacheLifetime < new Date().getTime()
		NetflixRoulette.actor 'Nicolas Cage', (error, movies) ->
			waitingFor = 0
			getOMDB = (movie, cb) ->
				omdb.get { title: movie.show_title, year: movie.release_year }, true, (err, omdbmovie) ->
					waitingFor--
					movie.ratings = 
						imdb: omdbmovie.imdb.rating
						metacritic: omdbmovie.metacritic
					movie.awards = omdbmovie.awards.text
					cb movie

			for movie in movies
				waitingFor++

				getOMDB movie, (movie) ->
					waitingFor--
					moviesCached = movies

					if waitingFor is 0
						cb()
			lastUpdated = new Date().getTime()
	else
		cb()

# Setup Node server instance and socket.io connection handler
setupServer = ->
	app = http.createServer (req, res) ->

		if req.url.indexOf('.jpg') isnt -1
			res.writeHead 200
			fs.readFile 'index.jpg', (err, data)->
				res.write data
				res.end()
		else getCageMovies () ->
			console.log 'RES'
			res.writeHead 200
			console.log moviesCached
			console.log getRandom()

			# console.log moviesCached[getRandom()]
			res.write render moviesCached[getRandom()]
			# res.write JSON.stringify moviesCached[getRandom()]
			res.end()

	app.listen port

setupServer()