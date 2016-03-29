utils = require './marie.utils'
sqlite3 = require('sqlite3').verbose()
db_path = utils.path.join __dirname.replace('/marie/lib', '/marie/config'), '/.db'
db = new sqlite3.Database db_path

class App
	@name
	@path
	@cssProcessor
	@frontEndFramework 
	@storage
	@templateEngine
	@live
	@created
	@lastActive
	@pid

	query: require './marie.query'


	constructor: ({@name, @path, @cssProcessor, @frontEndFramework, @storage, @templateEngine, @live, @created, @lastActive, @pid}) ->


	add: (cb) ->
		return @store 'add', cb


	save: (cb) ->
		return @store 'save', cb


	store: (cmd, cb) ->
		db.serialize =>
			db.run App::query.INIT
			if cmd.match /save/
				stmt = db.prepare App::query.SAVE
				stmt.run @path, @cssProcessor, @frontEndFramework, @storage, @templateEngine, @live, @created, @lastActive, @pid, @name 
			else
				stmt = db.prepare App::query.ADD
				stmt.run @name, @path, @cssProcessor, @frontEndFramework, @storage, @templateEngine, @live, @created, @lastActive, @pid
			stmt.finalize()
			if cb then cb null, @


	file: (path) ->
		return utils.path.join @path, path


	stop: ->
		@live = false
		@lastActive = new Date().getTime()
		@pid = 0


	start: (pid) ->
		@live = true
		@lastActive = new Date().getTime()
		@pid = pid


	@live: (cb) ->
		db.serialize =>
			db.all App::query.LIVE, (err, rows) ->
				if cb and rows
					apps = []
					apps.push new App row for row in rows
					cb err, apps
				else if cb and not rows
					cb err, null


	@find: (name, cb) ->
		db.serialize =>
			db.run App::query.INIT
			if not not name
				db.each App::query.FIND_ONE, name, (err, row) ->
					if cb then cb err, new App row
			else
				db.all App::query.FIND, (err, rows) ->
					if cb and rows
						apps = []
						apps.push new App row for row in rows
						cb err, apps
					else if cb and not rows
						cb err, null



	@remove:(name, cb) ->
		@find name, (err, row) =>
			if err then cb err, row
			if row
				path = row['path']
				db.run App::query.REMOVE, name, (err, success) ->
					if not err
						utils.fs.removeSync path
						if cb then cb null, "#{name} was successfully removed."
					else
						if cb then cb "#{name} was not removed.", null


	@start: (app, cb) ->
		file = app.file '/app.js'
		log = "#{utils.root}/config/.log"
		out = utils.fs.openSync log, 'a'
		err = utils.fs.openSync log, 'a'
		start = utils.spawn 'node', [file], {
			detached: true
			stdio: ['ignore', out, err]
		}
		app.start start.pid 
		app.save (err, app) =>
			if cb then cb err, app


	@stop: (app, cb) ->
		if app.live
			utils.spawnSync 'kill', ['-SIGTERM', app.pid]
			app.stop()
			app.save (err, app) =>
				if cb then cb err, app
		else return true


	@addApi: (name, api, cb) ->
		@find name, (err, row) =>
			if err then cb err, row
			if row
				app = new App row
				process.chdir app.path
				utils.installApi api, (error, stdout, stderr) ->
					cb error, app


	@removeApi: (name, api, cb) ->
		@find name, (err, row) =>
			if err then cb err, row
			if row
				app = new App row
				utils.fs.unlink app.file("/api/controllers/#{api}controller.coffee"), (err) ->
				utils.fs.unlink app.file("/api/models/#{api}.coffee"), (err) ->
				cb err, app


	@addModule: (name, pkg, cb) ->
		@find name, (err, row) =>
			if err then cb err, row
			if row
				app = new App row
				process.chdir app.path
				utils.install [pkg], '--save', (error, stdout, stderr) ->
					cb error, app


	@removeModule: (name, pkg, cb) ->
		@find name, (err, row) =>
			if err then cb err, row
			if row
				app = new App row
				process.chdir app.path
				utils.uninstall [pkg], (error, stdout, stderr) ->
					cb error, app



# export app module
module.exports = App