###
@namespace marie
@author Teddy Moussignac (teddy.moussignac@gmail.com)
@version 0.0.3
@copyright: March 2016
@note Marie App query utility class
###

class Query
	INIT: 'CREATE TABLE IF NOT EXISTS app(id TEXT primary key not null, name TEXT, path TEXT, cssProcessor TEXT, frontendFramework TEXT, storage TEXT, templateEngine TEXT, live NUMERIC, created NUMERIC, lastActive NUMERIC, pid NUMERIC)'
	ADD: 'INSERT INTO app (id, name, path, cssProcessor, frontendFramework, storage, templateEngine, live, created, lastActive, pid) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)' 
	SAVE: 'UPDATE app  SET path = ?, cssProcessor = ?, frontendFramework = ?, storage = ?, templateEngine = ?, live = ?, created = ?, lastActive = ?, pid = ? WHERE id = ?' 
	REMOVE: 'DELETE FROM app WHERE id = ?'
	FIND_ONE: 'SELECT * FROM app WHERE id = ? LIMIT 1'
	FIND: 'SELECT * FROM app'
	LIVE: 'SELECT * FROM app WHERE live = 1'

# export query module
module.exports = new Query 