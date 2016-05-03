### A Modern Nodejs Application Management and Blueprint Tool

#### Install Marie
Stable release

```bash
$ npm install marie -g
```

*npm is a built in CLI when you install Node.js - 

[Install Node.js](https://nodejs.org)

[Install Node.js with NVM](https://keymetrics.io/2015/02/03/installing-node-js-and-io-js-with-nvm/)


#### Create new App

```bash
$ marie add app-id
$ marie add "App name"
$ marie add "App name" scss jade
$ marie add "App name" less handlebars --coffee
```

Creates a custom [Sails](http://sailsjs.org) application with [Socket.io](http://socket.io), a powerful File Include system for easy bundle, and [Bower](http://bower.io) for managing your frontend modules. Marie takes care of the implemention and configuration of it all, so you can focus on what's really important to you--- building your cool app.
An app can be created with any combination of any of these css pre-processors, view template engines, javascript compilers and databases:
Supported css pre-processors: [LESS](http://stylus-lang.com), [SCSS](http://sass-lang.com/documentation/file.SCSS_FOR_SASS_USERS.html), and [Stylus](http://stylus-lang.com)
Suported view engines: [Jade](http://jade-lang.com), [EJS](http://www.embeddedjs.com), and [Handlebars](http://handlebarsjs.com)
Supported JS compilers: [CoffeeScript](http://coffeescript.org) and native Javascript
Supported Databases: [MongoDb](https://www.mongodb.org), [MySql](https://www.mysql.com), [PostgreSql](http://www.postgresql.org) and [Redis](http://redis.io)
Default configuration: less, jade, nativeJs and disk for local storage
## Application Management

#### Start an app

```bash
$ marie start app-id
```


#### Delete an app

```bash
$ marie remove app-id
```


#### Show app attributes

```bash
$ marie app-id list
```

#### Show app attribute value

```bash
$ marie app-id list path
```

### Show app config
```bash
$ marie app-id list config
$ marie app-id list config name
```

#### Show app modules

```bash
$ marie app-id list module
```


#### Show 'save' app modules

```bash
$ marie app-id list module --save
```


#### Show 'dev' app modules

```bash
$ marie app-id list module --dev
```


#### Show 'frontend' app modules

```bash
$ marie app-id list module --frontend
```


#### Add a module to an app

```bash
$ marie app-id add module bower --save
```

```bash
$ marie app-id add module gulp --dev
```

```bash
$ marie app-id add module backbone --frontend
```


#### Remove a module from an app

```bash
$ marie app-id remove module bower --save
```

```bash
$ marie app-id remove module gulp --dev
```

```bash
$ marie app-id remove module backbone --frontend
```


#### Add an Api to an app

```bash
$ marie app-id add api post
```


#### Remove an Api from an app

```bash
$ marie app-id remove api post
```


#### Configure database storage
Supported Databases: [MongoDb](https://www.mongodb.org), [MySql](https://www.mysql.com), [PostgreSql](http://www.postgresql.org) and [Redis](http://redis.io)
Sails/Waterline Adapters: [MongoDb](https://github.com/balderdashy/sails-mongo), [MySql](https://github.com/balderdashy/sails-mysql), [PostgreSql](https://github.com/balderdashy/sails-postgresql) and [Redis](https://github.com/balderdashy/sails-redis)

```bash
$ marie app-id set db disk
$ marie app-id set db mongodb some.mongodb.db.url
$ marie app-id set db mysql some.mysql.db.url
$ marie app-id set db postgresql some.postgresql.db.url
$ marie app-id set db redis some.redis.db.url
```
Then add apis that correspond to your database collecions or tables. For example, to view data from the 'post' collection or table of that database:

```bash
$ marie app-id add api post
```
Then in your browser, navigate to http://your-localhost-or-host-url/post


## Utility Commands

#### Show all apps

```bash
$ marie list
```


#### Show live app

```bash
$ marie live
```


#### Stop live app

```bash
$ marie stop
```


#### Restart live app

```bash
$ marie restart
```


#### Show version

```bash
$ marie version
```


#### Display log

```bash
$ marie log
```


#### Clear log

```bash
$ marie log clear
```


#### Display help

```bash
$ marie help
```


## GUI Clients
Mac OSX desktop app coming soon.


