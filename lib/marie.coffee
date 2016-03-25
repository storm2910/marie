fs = require 'fs'
fs = require 'fs-extra'
path = require 'path'
prompt = require 'prompt'
exe = require('child_process').execFile
ui = require './ui'

class Marie
	@app
	@dir
	@root
	@startTime
	@endTime
	@initTime
	@cssProcessor
	@frontEndFramework
	@templateEnegine
	@mongoType

	UTF8: 'utf8'
	templates:
		JADE: 'jade'
		EJS: 'ejs'
		HANDLEBARS: 'handlebars'
	processors:
		STYLUS: 'stylus'
		SCSS: 'scss'
		LESS: 'less'
	frameworks:
		BOOTSTRAP: 'bootstrap'
		FOUNDATION: 'foundation'
	mongoTypes:
		LOCAL: 'localMongodbServer'
		REMOTE: 'someMongodbServer'
		URL: 'someMongodbServerWithURL'


	constructor: ->
		@startTime = new Date 
		@root = process.cwd()
		prompt.message = null
		@parseArgs()


	parseArgs: ->
		args = process.argv
		len = args.length
		if len >= 3
			@app = args[args.length-1]
			@configure()
		else
			console.log ''
			ui.warn 'Enter app name.'
			prompt.start()
			ui.line()
			prompt.get ['name'], (error, result) =>
				if error 
					ui.error 'An error occured.'
				else
					@app = result.name
					@configure()


	configure: ->
		ui.header 'Generating', @app
		@dir = @rootPath "/#{@app}"
		fs.stat @dir, (err, stats) =>
			if err then @configureSails() else ui.warn 'App already exists.'


	configureSails: ->
		exe 'sails', ['generate', 'new', @app], (error, stdout, stderr) =>
			if error
				ui.warn 'Configuring Sails...'
				exe 'npm', ['install', 'sails', '-g'], (error, stdout, stderr) =>
					if error 
						ui.error 'An error occured.'
						ui.notice "Run `sudo npm install sails -g` then try again."
					else
						@configureSails()
			else
				process.chdir @dir
				exe 'sails', ['generate', 'api', 'admin', '--coffee'], (error, stdout, stderr) =>
					if error then @throwError()
					ui.ok 'Sails configuration done.'
					@configureTasManager()


	configureTasManager: ->
		@installPackages ['grunt-includes']
		fs.copySync @configPath('/tasks/compileAssets.js'), @appPath('/tasks/register/compileAssets.js'), { clobber: true }
		fs.copySync @configPath('/tasks/syncAssets.js'), @appPath('/tasks/register/syncAssets.js'), { clobber: true }
		fs.copySync @configPath('/tasks/includes.js'), @appPath('/tasks/config/includes.js'), { clobber: true }
		@configureCoffeeScript()


	configureCoffeeScript: ->
		pkgs = ['coffee-script', 'sails-generate-controller-coffee', 'sails-generate-model-coffee']
		@installPackages pkgs
		fs.copySync @configPath('/tasks/coffee.js'), @appPath('/tasks/config/coffee.js'), { clobber: true }
		fs.writeFileSync @appPath('/assets/js/app.coffee'), ''
		ui.ok 'CoffeeScript configuration done.'
		@configureJade()


	configureJade: ->
		@templateEnegine = @templates.JADE
		pkgs = ['jade']
		@installPackages pkgs
		viewSrc = @appPath '/config/views.js'
		stream = fs.readFileSync viewSrc, @UTF8
		stream = stream.replace(/ejs/gi, 'jade').replace(/'layout'/gi, false)
		fs.writeFileSync viewSrc, stream
		
		dirs = ['/views/modules', '/views/partials', '/views/layouts']
		for dir in dirs then fs.mkdirSync @appPath dir
		
		files = ['views/403', 'views/404', 'views/500', 'views/layout', 'views/homepage']
		fs.unlinkSync @appPath "/#{file}.ejs" for file in files
		files.splice files.indexOf('views/layout'), 1
		partial = 'views/partial'
		files.push partial 
		for file in files
			sfile = @configPath "/templates/#{file}.jade"
			dfile = @appPath(if file == partial then '/views/partials/partial.jade' else "/#{file}.jade")
			fs.copySync sfile, dfile

		masterPath = @configPath '/templates/views/master.jade'
		masterData = fs.readFileSync masterPath, @UTF8
		masterData = masterData.replace /\$APP_NAME/gi, @app
		fs.writeFileSync @appPath('/views/layouts/master.jade'), masterData
		ui.ok 'Jade configuration done.'
		@configureStylus()


	configureStylus: ->
		@cssProcessor = @processors.STYLUS
		pkgs = ['stylus', 'grunt-contrib-stylus']
		@installPackages pkgs
		stream = fs.readFileSync @appPath('/tasks/config/less.js'), @UTF8
		stream = stream.replace(/less/gi, 'stylus').replace(/importer.stylus/gi,'bundles\/*')
		fs.writeFileSync @appPath('/tasks/config/stylus.js'), stream
		configs = [
			'/tasks/register/compileAssets'
			'/tasks/register/syncAssets'
			'/tasks/config/sync'
			'/tasks/config/copy'
		]
		for config in configs
			stream = fs.readFileSync @appPath("#{config}.js"), @UTF8
			if config.match /register/
				stream = stream.replace(/less:dev/gi, 'stylus:dev')
			else
				stream = stream.replace(/less/gi, 'stylus')
			fs.writeFileSync @appPath("#{config}.js"), stream
		ui.ok 'Stylus configuration done.'
		@configureStyleFramework()


	configureStyleFramework: ->
		ui.warn 'Choose your style framework.'
		prompt.start()
		ui.line()
		input = ' Foundation/Bootstrap/None'
		prompt.get [input], (err, result) =>
			ui.line()
			if result[input].match(/^f/i)
				@configureFrontend @frameworks.FOUNDATION
			else if result[input].match(/^b/i)
				@configureFrontend @frameworks.BOOTSTRAP
			else
				@configureBundles()
			

	configureFrontend: (framework) ->
		@frontEndFramework = framework
		cpath = "#{@frontEndFramework}-#{@cssProcessor}"
		jpath = "#{@frontEndFramework}-js"
		fs.copySync @configPath("/#{cpath}"), @appPath("/assets/styles/#{@frontEndFramework}"), { clobber: true }
		fs.copySync @configPath("/#{jpath}"), @appPath("/assets/js/dependencies/#{@frontEndFramework}"), { clobber: true }
		@configureBundles()


	configureBundles: ->
		ext = if @cssProcessor == @processors.STYLUS then '.styl' else @cssProcessor
		styles = if not not @frontEndFramework then "@import '../#{@frontEndFramework}'" else ''
		fs.mkdirSync @appPath('/assets/styles/bundles')
		fs.removeSync @appPath('/assets/styles/importer.less')
		fs.writeFileSync @appPath("/assets/styles/bundles/default#{ext}"), styles
		fs.writeFileSync @appPath("/assets/styles/bundles/admin#{ext}"), styles
		ui.ok 'Frontend configuration done.'
		@configureDB()


	configureDB: ->
		ui.warn 'Choose your Database.'
		prompt.start()
		input = ' Mongo/Disk'
		ui.line()
		prompt.get [input], (err, result) =>
			ui.line()
			if result[input].match(/^m/i) then @configureMongoDB() else @configureNativeDB()


	configureNativeDB: ->
		@setupDBWithConfig 'The local disk'


	configureMongoDB: ->
		ui.warn 'Setup MongoDB connection.'
		ui.msg 'Leave all blank to use local mongodb. If any.', 'blackBright'
		ui.line()
		inputs = [' host', ' port', ' user', ' password', ' database', ' url']
		prompt.get inputs, (err, result) =>
			ui.line()
			ui.warn 'Configuring database...'
			@install 'sails-mongo', '--save', (error, stdout, stderr) =>
				cconfig = fs.readFileSync @configPath('/connections/connections.js'), @UTF8
				if result[' url'].length > 3
					@mongoType = @mongoTypes.URL
					uconfig = fs.readFileSync @configPath "/connections/#{@mongoTypes.URL}.js", @UTF8
					cconfig = cconfig.replace /\$MONGO\.CONNECTION/, uconfig
					cconfig = cconfig.replace /\$MONGO\.URL/gi, result[' url']
				else
					list = inputs.slice 0, inputs.length-1
					remote = true
					for input in list
						remote = false if result[input].length <= 2
					if not not remote 
						@mongoType = @mongoTypes.REMOTE
						sconfig = fs.readFileSync @configPath "/connections/#{@mongoTypes.REMOTE}.js", @UTF8
						cconfig = cconfig.replace /\$MONGO\.CONNECTION/, sconfig
						cconfig = cconfig.replace /\$MONGO\.HOST/gi, result[' host'] if result[' host']? 
						cconfig = cconfig.replace /\$MONGO\.PORT/gi, result[' port'] if result[' port']? 
						cconfig = cconfig.replace /\$MONGO\.USER/gi, result[' user'] if result[' user']? 
						cconfig = cconfig.replace /\$MONGO\.PASSWORD/gi, result[' password'] if result[' password']? 
						cconfig = cconfig.replace /\$MONGO\.DATABASE/gi, result[' database'] if result[' database']? 
					else
						@mongoType = @mongoTypes.LOCAL
						lconfig = fs.readFileSync @configPath "/connections/#{@mongoTypes.LOCAL}.js", @UTF8
						cconfig = cconfig.replace /\$MONGO\.CONNECTION/, lconfig
				@setupDBWithConfig 'MongoDB', cconfig


	setupDBWithConfig: (db, cconfig) ->
		mdest = @appPath '/config/models.js'
		mconfig = fs.readFileSync mdest, @UTF8
		mconfig = mconfig.replace(/'alter'/gi, "'safe'").replace(/\/\/ /gi,'').replace(/connection/gi, '// connection')
		fs.writeFileSync mdest, mconfig
		if not not cconfig
			cdest = @appPath '/config/connections.js'
			fs.writeFileSync cdest, cconfig
			ddest = @appPath '/config/env/development.js'
			dconfig = fs.readFileSync ddest, @UTF8
			dconfig = dconfig.replace(/\/\/ /gi,'').replace(/someMongodbServer/gi, @mongoType)
			fs.writeFileSync ddest, dconfig
		ui.ok "Done. #{db} will be used for data storage."
		@exit()


	throwError: (error) ->
		ui.error 'An error occured.'
		ui.warn 'Exit.'
		@root = path.dirname @dir
		process.chdir @root
		fs.removeSync @dir
		throw error


	appPath: (loc) ->
		return path.join @dir, loc


	rootPath: (loc) ->
		return path.join @root, loc


	configPath: (loc) ->
		return path.join __dirname.replace('/marie/lib', '/marie/config'), loc


	install: (pkg, opt, cb) ->
		exe 'npm', ['install', pkg, opt], cb


	uninstall: (pkg, cb) ->
		exe 'npm', ['uninstall', pkg], cb


	installPackages: (pkgs) ->
		for pkg in pkgs then @install pkg, '--save-dev', @stdoutCallBack


	uninstallPackages: (pkgs) ->
		for pkg in pkgs then @uninstall pkg, @stdoutCallBack


	stdoutCallBack: (error, stdout, stderr) =>
		if error then @throwError()


	exit: ->
		@endTime = new Date 
		total = (@endTime - @startTime) / 1000
		if total < 60 
			@initTime = "#{Math.round(total)} seconds" 
		else
			@initTime = "#{Math.round(total / 60)} minutes #{Math.round(total % 60)} seconds"
		ui.ok "#{@app} is ready"
		ui.notice "Path: #{@dir}"
		ui.notice "Started: #{@startTime}"
		ui.notice "Ended: #{@endTime}"
		ui.notice "Total Time: #{@initTime}"


# export class
module.exports = new Marie 