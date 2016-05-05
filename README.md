### A Modern Nodejs Application Management and Blueprint Tool

#### Install Marie
Stable release

```bash
$ npm install marie -g
```

*npm is a built in CLI when you install Node.js - 

[Install Node.js](https://nodejs.org)


#### Create new App

```bash
$ marie add app-id
$ marie add "App name"
$ marie add "App name" scss jade
$ marie add "App name" less handlebars --coffee
```

Creates a custom [Sails](http://sailsjs.org) application with [Socket.io](http://socket.io), a built-in file include system for easy bundle, and [Bower](http://bower.io) for managing your frontend modules. Marie takes care of the implemention and configuration of it all, so you can focus on what's really important to you--- building your app that's going to change the world!  
An app can be created with any combination of any of these css pre-processors, view template engines, javascript compilers and databases. 

* Supported css pre-processors: [LESS](http://lesscss.org), [SCSS](http://sass-lang.com/documentation/file.SCSS_FOR_SASS_USERS.html), and [Stylus](http://stylus-lang.com). 
* Suported view engines: [Jade](http://jade-lang.com), [EJS](http://www.embeddedjs.com), and [Handlebars](http://handlebarsjs.com). 
* Supported JS compilers: [CoffeeScript](http://coffeescript.org) and native Javascript. 
* Supported Databases: [MongoDb](https://www.mongodb.org), [MySql](https://www.mysql.com), [PostgreSql](http://www.postgresql.org) and [Redis](http://redis.io). 
* Default configuration: less, jade, nativeJs and disk for local storage.

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
$ marie app-id add module gulp --save
```

```bash
$ marie app-id add module gulp --dev
```

```bash
$ marie app-id add module backbone --frontend
```


#### Remove a module from an app

```bash
$ marie app-id remove module gulp --save
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

* Supported Databases: [MongoDb](https://www.mongodb.org), [MySql](https://www.mysql.com), [PostgreSql](http://www.postgresql.org) and [Redis](http://redis.io)
* Sails/Waterline Adapters: [sails-mongo](https://github.com/balderdashy/sails-mongo), [sails-mySql](https://github.com/balderdashy/sails-mysql), [sails-postgreSql](https://github.com/balderdashy/sails-postgresql) and [sails-redis](https://github.com/balderdashy/sails-redis)

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


## Other Docs & Examples 

* [Sails docs](http://sailsjs.org/documentation/concepts/)
* [Waterline docs](https://github.com/balderdashy/waterline-docs)
* [socket.io docs](http://socket.io/docs/)
* [Grunt plugins](http://gruntjs.com/plugins/contrib)
* [Bower packages](http://bower.io/search/)
* [Less examples](http://lesscss.org/features/)
* [SCSS examples](http://sass-lang.com/documentation/file.SCSS_FOR_SASS_USERS.html)
* [Stylus examples](http://stylus-lang.com)
* [Jade examples](http://jade-lang.com/reference/attributes/)
* [EJS examples](http://www.embeddedjs.com)
* [Handlebars examples](http://handlebarsjs.com)
* [CoffeeScript examples](http://coffeescript.org)


## GUI Clients
Mac OSX desktop app coming soon.


## License
Marie is released under the [MIT License](http://www.opensource.org/licenses/MIT)


## Donate
Found Marie useful? Support.

[![PayPal][buttonImage]][buttonLink]

[buttonLink]: https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=HSQK7KQP2CQGU&lc=US&item_name=Marie%20Application%20Management%20and%20Blueprint%20Tool&item_number=marie%2dcli&currency_code=USD&bn=PP%2dDonationsBF%3abtn_donate_LG%2egif%3aNonHosted
[buttonImage]: https://www.paypalobjects.com/en_US/i/btn/btn_donate_LG.gif

