class CoffeeTalkClass
	constructor: (props) ->
		@name = props.name
		@extends = props.extends
		@package = props.package
		@namespace = if props.namespace? and props.namespace.length then props.namespace else "GLOBAL"
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
		@classId = props.classId
		@id = "#{@classId}.#{@name}"

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
	@getClassById: (id) ->
		[pkg, nameSpace, className] = id.split '.'
		name = [className]
		if nameSpace isnt "GLOBAL" then name.unshift nameSpace
		(new CoffeeTalkFile name.join('/') + "/class.json").asClass()

	@getSlotById: (id) ->
		[pkg, nameSpace, className, slotName] = id.split '.'
		name = [className, "slots"]
		if nameSpace isnt "GLOBAL" then name.unshift nameSpace
		(new CoffeeTalkFile name.join('/') + "/#{slotName}.json").asSlot([pkg, nameSpace, className].join '.')

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
			return JSON.parse @fs.readFileSync "#{CoffeeTalkFile.classDir}/#{@name}", "UTF8"
		catch e
			console.log e
			return false
			
	asSlot: (classId) ->
		props = @readAsJson()
		if not props then return false

		props.body = @fs.readFileSync "#{CoffeeTalkFile.classDir}/#{@parts[0..-2].join "/"}.coffee", "UTF8"
		props.classId = classId

		new CoffeeTalkSlot props
		
	asClass: ->
			classDef = @readAsJson()
			if not classDef then return false

			coffeeTalkClass = new CoffeeTalkClass classDef

			slotDir = "#{@parts[0..-3].join "/"}/slots"

			for slotFileName in @wrench.readdirSyncRecursive("#{CoffeeTalkFile.classDir}/#{slotDir}")
				slotFile = new CoffeeTalkFile "#{slotDir}/#{slotFileName}"
				
				if slotFile.isJsonExt()
					newSlot = slotFile.asSlot(coffeeTalkClass.id)
					if newSlot then coffeeTalkClass.slots.push newSlot

			coffeeTalkClass
			
class CoffeeTalkPersistanceFlatFile extends CoffeeTalkPersistance
	constructor: (props) ->
		@wrench = require "wrench"
		@fs = require "fs"
		@classDir = props.classDir
		CoffeeTalkFile.classDir = @classDir

	getClassList: ->
		classes = []
			
		for fileName in @wrench.readdirSyncRecursive(@classDir)
			file = new CoffeeTalkFile fileName
			if file.isClass()
				newClass = file.asClass()
				if newClass then classes.push newClass
					
		classes

	_getClassDir: (_class) ->
		"#{@classDir}/#{if _class.namespace isnt "GLOBAL" then "#{_class.namespace}/" else ""}#{_class.name}/"

	saveClass: (data) ->
		if not data.namespace? or data.namespace.trim().length is 0 
			data.namespace = "GLOBAL"

		newClass = new CoffeeTalkClass data
		newClassDir = @_getClassDir newClass

		if data.id?
			oldClass = CoffeeTalkFile.getClassById data.id
			oldClassDir = @_getClassDir oldClass
			if oldClassDir isnt newClassDir
				wrench.rmdirSyncRecursive oldClassDir, true
		else
			@wrench.mkdirSyncRecursive "#{newClassDir}slots"

		classDef = newClass.toJSON()
		delete classDef.slots
		@fs.writeFileSync "#{newClassDir}class.json", JSON.stringify classDef
		(new CoffeeTalkFile "#{newClassDir}class.json").asClass()

	deleteClass: (data) ->
		oldClass = CoffeeTalkFile.getClassById data.id
		baseClassDir = @_getClassDir oldClass
		@wrench.rmdirSyncRecursive baseClassDir, true
		true

	saveSlot: (data) ->
		#first get old by id
		if not data.id?
			newSlot = new CoffeeTalkSlot data
		else
			oldSlot = CoffeeTalkFile.getSlotById data.id
			data.classId = oldSlot.classId
			newSlot = new CoffeeTalkSlot data

		#build base dirs
		baseClassDir = @_getClassDir CoffeeTalkFile.getClassById data.classId
		baseSlotDir = baseClassDir + "/slots/"

		#if id is different than delete old first
		if oldSlot? and oldSlot.id isnt newSlot.id
			@fs.unlinkSync "#{baseSlotDir}#{oldSlot.name}.coffee"
			@fs.unlinkSync "#{baseSlotDir}#{oldSlot.name}.json"

		@fs.writeFileSync "#{baseSlotDir}#{newSlot.name}.coffee", newSlot.body
		slotDef = newSlot.toJSON()
		delete slotDef.body
		@fs.writeFileSync "#{baseSlotDir}#{newSlot.name}.json", JSON.stringify slotDef
		
		newSlot

	deleteSlot: (data) ->
		oldSlot = CoffeeTalkFile.getSlotById data.id
		
		#build base dirs
		baseClassDir = @_getClassDir CoffeeTalkFile.getClassById oldSlot.classId
		baseSlotDir = baseClassDir + "/slots/"

		@fs.unlinkSync "#{baseSlotDir}#{oldSlot.name}.coffee"
		@fs.unlinkSync "#{baseSlotDir}#{oldSlot.name}.json"
		true

		
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
		io.set "log level", 1
		app.listen @port

		app.configure =>
			app.use @express.static(__dirname + '/public')

		io.sockets.on 'connection', (socket) => 
			socket.emit "classList", classes: @ctpFlatFile.getClassList()

			socket.on 'saveNode', (req) =>
				method = if req.method in ["create", "update"] then "save" else req.method
				responseData = @ctpFlatFile[method + req.type](req.data)
				socket.emit "updateNode", 
					method: req.method
					type: req.type
					data: responseData
					reqID: req.reqID

		console.log "go to http://localhost:#{@port}/"

exports.CoffeeTalkServer = CoffeeTalkServer