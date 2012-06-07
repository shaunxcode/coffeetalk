class CoffeeTalkClass
	constructor: (props) ->
		@name = props.name
		@extends = props.extends
		@package = props.package
		@namespace = props.namespace
		@description = props.description
		@slots = []
		
	toClassString: ->
		classString = "class #{if @namespace then "#{namespace}." else ""}#{@name}#{if @extends then " extends #{@extends}" else ""}\n"

		for slot in @slots
			classString += "\t#{if slot.type is "class" then "@" else ""}#{slot.name}: "

			for line in slot.body.split("\n")
				classString += "\t\t#{line}\n\n"

		classString
			
	toJSON: ->
		{
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
		
	toJSON: ->
		{
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

class CoffeeTalkPersistanceFlatFile extends CoffeeTalkPersistance
	constructor: (props) ->
		@wrench = require "wrench"
		@fs = require "fs"
		@classDir = props.classDir

	getClassList: ->
		classes = []
			
		for file in @wrench.readdirSyncRecursive(@classDir)
			parts = file.replace(/\//g, '.').split(".")
			if parts[parts.length - 1] is "json" and parts[parts.length - 2] is "class"
				coffeeTalkClass = new CoffeeTalkClass JSON.parse(@fs.readFileSync(@classDir + "/" + file, "UTF8"))
				slotDir = @classDir + "/" + parts[0..-3].join("/") + "/slots"
				for slotFile in @wrench.readdirSyncRecursive(slotDir)
					slotParts = slotFile.replace(/\//g, '.').split('.')
					if slotParts[slotParts.length - 1] is "json"
						props = JSON.parse(@fs.readFileSync(slotDir + "/" + slotFile, "UTF8"))
						props.body = @fs.readFileSync slotDir + "/" + slotParts[0..-2].join("/") + ".coffee", "UTF8"
						coffeeTalkSlot = new CoffeeTalkSlot props
						coffeeTalkClass.slots.push coffeeTalkSlot
				classes.push coffeeTalkClass

		classes

	_getClassDir: (_class) ->
		"#{@classDir}/#{if _class.namespace then "#{_class.namespace}/" else ""}#{_class.name}/"

	saveClass: (_class) ->
		baseClassDir = @_getClassDir _class
		@wrench.mkdirSyncRecursive "#{baseClassDir}slots"
		@fs.writeFileSync "#{baseClassDir}class.json", JSON.stringify _class.toJSON 
		
	saveSlot: (_class, slot) ->
		baseClassDir = @_getClassDir(_class) + "/slots/"
		@fs.writeFileSync "#{baseClassDir}#{slot.name}.json", JSON.stringify _class.toJSON
		@fs.writeFileSync "#{baseClassDir}#{slot.name}.coffee", slot.body

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