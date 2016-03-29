utils = require './marie.utils'
ui = require './marie.ui'
App = require './marie.app'

class Marie
	@app

	utf8: 'utf8'
	framework:
		BOOTSTRAP: 'bootstrap'
		FOUNDATION: 'foundation'
	storageType:
		LOCAL: 'localMongodbServer'
		REMOTE: 'remoteMongodbServer'
		URL: 'remoteMongodbServerWithURL'


	configureSails: ->
		ui.write 'Configuring Sails...'
		utils.exe 'sails', ['generate', 'new', @app.name], (error, stdout, stderr) =>
			if error
				utils.exe 'npm', ['install', 'sails', '-g'], (error, stdout, stderr) =>
					if error 
						ui.error 'An error occured.'
						ui.notice "Run `sudo npm install sails -g` then try again."
					else
						@configureSails()
			else
				ui.ok 'Sails configuration done.'
				process.chdir @app.path
				@configureTasManager()


	configureTasManager: ->
		ui.write 'Configuring Grunt...'
		utils.install 'grunt-includes', '--save-dev', =>
			utils.fs.copySync utils.config('/tasks/compileAssets'), @app.file('/tasks/register/compileAssets.js'), { clobber: true }
			utils.fs.copySync utils.config('/tasks/syncAssets'), @app.file('/tasks/register/syncAssets.js'), { clobber: true }
			utils.fs.copySync utils.config('/tasks/includes'), @app.file('/tasks/config/includes.js'), { clobber: true }
			ui.ok 'Grunt configuration done.'
			@configureCoffeeScript()


	configureCoffeeScript: ->
		ui.write 'Configuring CoffeeScript...'
		utils.install 'coffee-script', '--save-dev', =>
			pkgs = ['sails-generate-controller-coffee', 'sails-generate-model-coffee']
			utils.installPackages pkgs
			utils.fs.copySync utils.config('/tasks/coffee'), @app.file('/tasks/config/coffee.js'), { clobber: true }
			utils.fs.writeFileSync @app.file('/assets/js/app.coffee'), ''
			ui.ok 'CoffeeScript configuration done.'
			@configureJade()


	configureJade: ->
		ui.write 'Configuring Jade...'
		utils.install 'jade', '--save-dev', =>
			viewSrc = @app.file '/config/views.js'
			stream = utils.fs.readFileSync viewSrc, @utf8
			stream = stream.replace(/ejs/gi, 'jade').replace(/'layout'/gi, false)
			utils.fs.writeFileSync viewSrc, stream
			
			dirs = ['/views/modules', '/views/partials', '/views/layouts']
			for dir in dirs then utils.fs.mkdirSync @app.file dir
			
			files = ['views/403', 'views/404', 'views/500', 'views/layout', 'views/homepage']
			utils.fs.unlinkSync @app.file "/#{file}.ejs" for file in files
			files.splice files.indexOf('views/layout'), 1
			partial = 'views/partial'
			files.push partial 
			for file in files
				sfile = utils.config "/templates/#{file}.jade"
				dfile = @app.file(if file == partial then '/views/partials/partial.jade' else "/#{file}.jade")
				utils.fs.copySync sfile, dfile

			masterPath = utils.config '/templates/views/master.jade'
			masterData = utils.fs.readFileSync masterPath, @utf8
			masterData = masterData.replace /\$APP_NAME/gi, @app.name
			utils.fs.writeFileSync @app.file('/views/layouts/master.jade'), masterData
			ui.ok 'Jade configuration done.'
			@configureStylus()


	configureStylus: ->
		ui.write 'Configuring Stylus...'
		utils.install 'stylus', '--save-dev', =>
			pkgs = ['grunt-contrib-stylus']
			utils.installPackages pkgs
			stream = utils.fs.readFileSync @app.file('/tasks/config/less.js'), @utf8
			stream = stream.replace(/less/gi, 'stylus').replace(/importer.stylus/gi,'bundles\/*')
			utils.fs.writeFileSync @app.file('/tasks/config/stylus.js'), stream
			configs = [
				'/tasks/register/compileAssets'
				'/tasks/register/syncAssets'
				'/tasks/config/sync'
				'/tasks/config/copy'
			]
			for config in configs
				stream = utils.fs.readFileSync @app.file("#{config}.js"), @utf8
				if config.match /register/
					stream = stream.replace(/less:dev/gi, 'stylus:dev')
				else
					stream = stream.replace(/less/gi, 'stylus')
				utils.fs.writeFileSync @app.file("#{config}.js"), stream
			ui.ok 'Stylus configuration done.'
			@configureStyleFramework()


	configureStyleFramework: ->
		ui.warn 'Choose your style framework.'
		utils.prompt.start()
		ui.line()
		input = ' Foundation/Bootstrap/None'
		utils.prompt.get [input], (err, result) =>
			ui.line()
			if result[input].match(/^f/i)
				@configureFrontend @framework.FOUNDATION
			else if result[input].match(/^b/i)
				@configureFrontend @framework.BOOTSTRAP
			else
				@configureBundles()
			

	configureFrontend: (framework) ->
		@app.frontEndFramework = framework
		cpath = "#{utils.root}/config/#{@app.frontEndFramework}-#{@app.cssProcessor}"
		jpath = "#{utils.root}/config/#{@app.frontEndFramework}-js"
		utils.fs.copySync cpath, @app.file("/assets/styles/#{@app.frontEndFramework}"), { clobber: true }
		utils.fs.copySync jpath, @app.file("/assets/js/dependencies/#{@app.frontEndFramework}"), { clobber: true }
		@configureBundles()


	configureBundles: ->
		ext = '.styl'
		styles = if not not @app.frontEndFramework then "@import '../#{@app.frontEndFramework}'" else ''
		utils.fs.mkdirSync @app.file('/assets/styles/bundles')
		utils.fs.removeSync @app.file('/assets/styles/importer.less')
		utils.fs.writeFileSync @app.file("/assets/styles/bundles/default#{ext}"), styles
		utils.fs.writeFileSync @app.file("/assets/styles/bundles/admin#{ext}"), styles
		ui.ok 'Frontend configuration done.'
		@configureDB()


	configureDB: ->
		ui.warn 'Choose your database.'
		utils.prompt.start()
		input = ' Mongo/Disk'
		ui.line()
		utils.prompt.get [input], (err, result) =>
			ui.line()
			if result[input].match(/^m/i) then @configureMongoDB() else @configureNativeDB()


	configureNativeDB: ->
		@app.storage = 'localDisk'
		@setupDBWithConfig 'The local disk'


	configureMongoDB: ->
		ui.warn 'Configure MongoDB database.'
		input = [' local/remote']
		ui.line()
		utils.prompt.get input, (err, result) =>
			ui.line()
			ui.write "Configuring MongoDB..."
			utils.install 'sails-mongo', '--save', (error, stdout, stderr) =>
				ui.clear()
				if result[input].match(/^r/i) then @configureRemoteMongoDB() else @configureLocalMongoDB()


	configureLocalMongoDB: ->
		@app.storage = @storageType.LOCAL
		lconfig = utils.fs.readFileSync utils.config "/databases/#{@storageType.LOCAL}.js", @utf8
		cconfig = utils.fs.readFileSync utils.config('/databases/connections.js'), @utf8
		cconfig = cconfig.replace /\$MONGO\.CONNECTION/, lconfig
		@setupDBWithConfig 'Local MongoDB', cconfig


	configureRemoteMongoDB: ->
		input = [' mongodb uri']
		utils.prompt.get input, (err, result) =>
			ui.line()
			if result[input].length > 0 
				@configureRemoteMongoDBWithURI result[input]
			else
				@configureRemoteMongoDBWithConfig() 


	configureRemoteMongoDBWithConfig: ->
		@app.storage = @storageType.REMOTE
		inputs = [' host', ' port', ' user', ' password', ' database']
		utils.prompt.get inputs, (err, result) =>
			ui.line()
			sconfig = utils.fs.readFileSync utils.config "/databases/#{@storageType.REMOTE}.js", @utf8
			cconfig = utils.fs.readFileSync utils.config('/databases/connections.js'), @utf8
			cconfig = cconfig.replace /\$MONGO\.CONNECTION/, sconfig
			cconfig = cconfig.replace /\$MONGO\.HOST/gi, result[' host'] if result[' host']? 
			cconfig = cconfig.replace /\$MONGO\.PORT/gi, result[' port'] if result[' port']? 
			cconfig = cconfig.replace /\$MONGO\.USER/gi, result[' user'] if result[' user']? 
			cconfig = cconfig.replace /\$MONGO\.PASSWORD/gi, result[' password'] if result[' password']? 
			cconfig = cconfig.replace /\$MONGO\.DATABASE/gi, result[' database'] if result[' database']? 
			@setupDBWithConfig 'Remote MongoDB', cconfig


	configureRemoteMongoDBWithURI: (uri) ->
		@app.storage = @storageType.URL
		uconfig = utils.fs.readFileSync utils.config "/databases/#{@storageType.URL}.js", @utf8
		cconfig = utils.fs.readFileSync utils.config('/databases/connections.js'), @utf8
		cconfig = cconfig.replace /\$MONGO\.CONNECTION/, uconfig
		cconfig = cconfig.replace /\$MONGO\.URL/gi, uri
		@setupDBWithConfig 'Remote MongoDB', cconfig


	setupDBWithConfig: (db, cconfig) ->
		mdest = @app.file '/config/models.js'
		mconfig = utils.fs.readFileSync mdest, @utf8
		mconfig = mconfig.replace(/'alter'/gi, "'safe'").replace(/\/\/ /gi,'').replace(/connection/gi, '// connection')
		utils.fs.writeFileSync mdest, mconfig
		if not not cconfig
			cdest = @app.file '/config/connections.js'
			utils.fs.writeFileSync cdest, cconfig
			ddest = @app.file '/config/env/development.js'
			dconfig = utils.fs.readFileSync ddest, @utf8
			dconfig = dconfig.replace(/\/\/ /gi,'').replace(/someMongodbServer/gi, @app.storage)
			utils.fs.writeFileSync ddest, dconfig
		ui.ok "#{db} database configuration done."
		@configureAPIs()


	configureAPIs: ->
		ui.warn 'Configure APIs.'
		utils.prompt.start()
		input = ' APIs'
		ui.line()
		utils.prompt.get [input], (err, result) =>
			ui.line()
			res = if result[input].length > 0 then result[input] else null
			if not not res
				apis = res.split ','
				utils.installApis apis
				ui.ok "APIs configuration done."
				@save()
			else
				@save()


	throwFatalError: (error) ->
		utils.fs.stat @app.path, (err, stats) =>
			if not err
				utils.fs.removeSync @app.path
				App.remove @app.name
				utils.throwError error
			else
				utils.throwError error


	save: ->
		@endTime = new Date 
		@app.add (err, app) =>
			if err then @throwFatalError err
			else
				ui.ok "#{app.name} was successfully added."
		total = (@endTime - @app.created) / 1000
		if total < 60 
			@initTime = "#{Math.round(total)} seconds" 
		else
			@initTime = "#{Math.round(total / 60)} minutes #{Math.round(total % 60)} seconds"
		ui.notice "Path: #{@app.path}"
		ui.notice "Creation Time: #{@initTime}"
		@onSave()


	onSave: ->
		ui.warn 'Start app?'
		utils.prompt.start()
		input = ' yes/no'
		ui.line()
		utils.prompt.get [input], (err, result) =>
			ui.line()
			if result[input].match(/^y/i)
				App.live (err, apps) =>
					if apps
						@stop()
						@_start @app
					else
						return @_start @app


# export marie module
module.exports = Marie