class CoffeeTalkClass
	constructor: (props) ->
		@name = props.name
		@extends = props.extends
		@package = props.package
		@namespace = props.namespace
		@description = props.description
		@slots = []
		@id = "#{@package}.#{@namespace}.#{@name}"

	toClassString: ->
		classString = "class #{if @namespace then "#{namespace}." else ""}#{@name}#{if @extends then " extends #{@extends}" else ""}\n"

		for slot in @slots
			classString += "\t#{if slot.type is "class" then "@" else ""}#{slot.name}: "

			for line in slot.body.split("\n")
				classString += "\t\t#{line}\n\n"

		classString
			
	toJSON: ->
		{
			id: @id
			name: @name
			extends: @extends
			package: @package
			namespace: @namespace
			description: @description
			slots: @slots
		}
		
class CoffeeTalkSlot
	constructor: (props) ->
		@name = props.name
		@type = props.type
		@version = props.version
		@protocol = props.protocol
		@body = props.body
		@description = props.description
		@id = "#{props.classId}.#{@name}"

	toJSON: ->
		{
			id: @id
			name: @name
			type: @type
			version: @version
			protocol: @protocol
			body: @body
			description: @description
		}

class CoffeeTalkPersistance
	getClassList: -> "child responsibility"
	saveClass: -> "child responsibility"
	saveSlot: -> "child responsibility"

class CoffeeTalkFile

	constructor: (name) ->
		@name = name
		@parts = name.replace(/\//g, '.').split('.')
		@fs = require "fs"
		@wrench = require "wrench"
				
	isClass: ->
 		@parts[@parts.length - 2] is "class" and @isJsonExt()
	
	isJsonExt: ->
		@parts[@parts.length - 1] is "json"

	readAsJson: ->
		try 
			return JSON.parse @fs.readFileSync @name, "UTF8"
		catch e
			return false
			
	asSlot: (slotDir, nameArray) ->
		props = @readAsJson()
		if not props then return false

		props.body = @fs.readFileSync "#{@parts[0..-2].join "/"}.coffee", "UTF8"

		new CoffeeTalkSlot props
		
	asClass: ->
			classDef = @readAsJson()
			if not classDef then return false

			coffeeTalkClass = new CoffeeTalkClass classDef

			slotDir = "#{@parts[0..-3].join "/"}/slots"

			for slotFileName in @wrench.readdirSyncRecursive(slotDir)
				slotFile = new CoffeeTalkFile "#{slotDir}/#{slotFileName}"
				
				if slotFile.isJsonExt()
					newSlot = slotFile.asSlot()
					if newSlot then coffeeTalkClass.slots.push newSlot

			coffeeTalkClass
			
class CoffeeTalkPersistanceFlatFile extends CoffeeTalkPersistance
	constructor: (props) ->
		@wrench = require "wrench"
		@fs = require "fs"
		@classDir = props.classDir
		
	getClassList: ->
		classes = []
			
		for fileName in @wrench.readdirSyncRecursive(@classDir)
			file = new CoffeeTalkFile "#{@classDir}/#{fileName}"
			if file.isClass()
				newClass = file.asClass()
				if newClass then classes.push newClass
					
		classes

	_getClassDir: (_class) ->
		"#{@classDir}/#{if _class.namespace then "#{_class.namespace}/" else ""}#{_class.name}/"

	saveClass: (_class) ->
		baseClassDir = @_getClassDir _class
		@wrench.mkdirSyncRecursive "#{baseClassDir}slots"
		classDef = _class.toJSON()
		delete classDef.slots
		@fs.writeFileSync "#{baseClassDir}class.json", JSON.stringify classDef
		(new CoffeeTalkFile "#{baseClassDir}class.json").asClass()
		
	saveSlot: (_class, slot) ->
		baseClassDir = @_getClassDir _class 
		baseSlotDir = baseClassDir + "/slots/"
		@fs.writeFileSync "#{baseSlotDir}#{slot.name}.coffee", slot.body
		delete slot.body
		@fs.writeFileSync "#{baseSlotDir}#{slot.name}.json", JSON.stringify slot.toJSON()
		(new CoffeeTalkFile "#{baseClassDir}class.json").asClass()
		
class CoffeeTalkServer
	constructor: ->
		@express = require "express"
		@socketio = require "socket.io"
		args = require("optimist")
			.usage("Pass port as -p (to use port 80 you need to sudo)")
			.default("p", "6655")
			.alias("c", "classDir")
			.default("c", "Class")
			.alias("d", "debug")
			.alias("p", "port")
			.argv

		@ctpFlatFile = new CoffeeTalkPersistanceFlatFile classDir: args.c

		@debug = args.d
		@port = args.p
		
	start: ->
		app = @express.createServer()
		io = @socketio.listen(app)
		#io.set "log level", 1
		app.listen @port

		app.configure =>
			app.use @express.static(__dirname + '/public')

		io.sockets.on 'connection', (socket) => 
			socket.emit "classList", classes: @ctpFlatFile.getClassList()

			socket.on 'saveClass', (data) =>
				newClass = @ctpFlatFile.saveClass(new CoffeeTalkClass(data.class))
				socket.emit "updateClass", newClass

			socket.on 'saveSlot', (data) =>
				updatedClass = @ctpFlatFile.saveSlot(new CoffeeTalkClass(data.class), new CoffeeTalkSlot(data.slot))
				socket.emit "updateClass", updatedClass

		console.log "go to http://localhost:#{@port}/"
		
exports.CoffeeTalkClass = CoffeeTalkClass
exports.CoffeeTalkSlot = CoffeeTalkSlot
exports.CoffeeTalkPersistanceFlatFile = CoffeeTalkPersistanceFlatFile
exports.CoffeeTalkServer = CoffeeTalkServer