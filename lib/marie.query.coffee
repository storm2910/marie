class Query
	INIT: 'CREATE TABLE IF NOT EXISTS app(name TEXT primary key not null, path TEXT, cssProcessor TEXT, frontEndFramework TEXT, storage TEXT, templateEnegine TEXT, live NUMERIC, created TEXT, lastActive TEXT, pid INTEGER)'
	SAVE: 'INSERT INTO app (name, path, cssProcessor, frontEndFramework, storage, templateEnegine, live, created, lastActive, pid) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)' 
	UPDATE: 'UPDATE app  SET path = ?, cssProcessor = ?, frontEndFramework = ?, storage = ?, templateEnegine = ?, live = ?, created = ?, lastActive = ?, pid = ? WHERE name = ?' 
	REMOVE: 'DELETE FROM app WHERE name = ?'
	FIND_ONE: 'SELECT * FROM app WHERE name = ?'
	FIND: 'SELECT * FROM app'

# export app module
module.exports = new Query 