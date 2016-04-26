### A Modern Nodejs Application Management Tool

#### Install Marie

```bash
$ npm install marie -g
```

*npm is a builtin CLI when you install Node.js - 

[Install Node.js](https://nodejs.org)

[Install Node.js with NVM](https://keymetrics.io/2015/02/03/installing-node-js-and-io-js-with-nvm/)


#### Create new App

```bash
$ marie add app-name
```

Creates a custom [Sails](http://sailsjs.org) application with [Socket.io](http://socket.io), [CoffeeScript](http://coffeescript.org), [Stylus](http://stylus-lang.com), [Jade](http://jade-lang.com), a powerful File Include system for easy bundle, and [Bower](http://bower.io) for managing your frontend modules. Marie takes care of the implemention and configuration of it all, so you can focus on what's really important to you--- building your cool app.

######  Frontend CoffeeScript file include example

User.coffee
```coffeescript
class User
	@name
	constructor: (@name) ->

	greet: ->
		console.log "Hello, #{@name}"
```

page.coffee
```coffeescript
#import User

user = new User 'Steeve Jobs'
user.greet() # -> Hello, Steeve Jobs
```

######  Frontend Stylus file include example
user.styl
```scss
.user-name
  font: 12px Helvetica, Arial, sans-serif

a.button
  border-radius: 5px

```

page.styl
```scss
@import '../bootstrap'
@import 'user'
```


## Application Management

#### Start an app

```bash
$ marie start app-name
```


#### Stop an app

```bash
$ marie stop app-name
```


#### Delete an app

```bash
$ marie remove app-name
```


#### Show app attributes

```bash
$ marie app-name list
```

#### Show app attribute value

```bash
$ marie app-name list path
```

### Show app config
```bash
$ marie app-name list config
$ marie app-name list config name
```

#### Show app modules

```bash
$ marie app-name list module
```


#### Show 'save' app modules

```bash
$ marie app-name list module --save
```


#### Show 'dev' app modules

```bash
$ marie app-name list module --dev
```


#### Show 'frontend' app modules

```bash
$ marie app-name list module --frontend
```


#### Add a module to an app

```bash
$ marie app-name add module bower --save
```

```bash
$ marie app-name add module gulp --dev
```

```bash
$ marie app-name add module backbone --frontend
```


#### Remove a module from an app

```bash
$ marie app-name remove module bower --save
```

```bash
$ marie app-name remove module gulp --dev
```

```bash
$ marie app-name remove module backbone --frontend
```


#### Add an Api to an app

```bash
$ marie app-name add api post
```


#### Remove an Api from an app

```bash
$ marie app-name remove api post
```


#### Configure Frontend Framework

```bash
$ marie app-name set frontendFramework
```


#### Configure database storage

```bash
$ marie app-name set storage
```


## Utility Commands

#### Show all apps

```bash
$ marie list
```


#### Show live app

```bash
$ marie live
```


#### Restart live app

```bash
$ marie restart
```


#### Show version

```bash
$ marie version
```


#### Display help

```bash
$ marie help
```



