#!/usr/bin/env node

require('coffee-script')
require('coffee-script/register')

var path = require('path');
var fs   = require('fs');
var lib  = path.join(path.dirname(fs.realpathSync(__filename)), '/lib');

module.exports = require(lib + '/marie.controller')