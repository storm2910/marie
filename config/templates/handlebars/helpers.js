
var Handlebars = require('handlebars');

module.exports = {

	script: function(data, options){
		var output = '';
		var scripts = data.split(',');
		scripts.forEach(function(script){
			output += '<script type="text/javascript" src="'+ script.replace(/^[.\s]+|[.\s]+$/g, '') +'"></script>';
		});
		return new Handlebars.SafeString(output);
	},

	stylesheet: function(data, options){
		var output = '';
		var styles = data.split(',');
		styles.forEach(function(style){
			output += '<link rel="stylesheet" type="text/css" href="'+ style.replace(/^[.\s]+|[.\s]+$/g, '') +'"/>';
		});
		return new Handlebars.SafeString(output);
	}
}