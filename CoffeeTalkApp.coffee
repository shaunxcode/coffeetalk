class _Class extends Backbone.Model
	nodeType: "Class"

	initialize: ->
		@_slots = new Slots 
		@_slots.add @get "slots"

	getInstanceSlots: ->
		@_slots.where type: "Instance"
		
	getClassSlots: ->
		@_slots.where type: "Class"

class _Classes extends Backbone.Collection
	model: _Class 

	getByPackage: (pkg) ->
		_class for _class in @models when _class.get("package") is pkg

class Slot extends Backbone.Model
	nodeType: "Slot"

class Slots extends Backbone.Collection
	model: Slot

class BrowserSettings extends Backbone.Model
	defaults:
		activePackage: false
		activeClass: false
		activeSlot: false
		groupClassesByParent: true
		showTestClasses: false
		groupSlotsByProtocol: true
		showInheritedSlots: false
		collapsedOutput: false
		
	initialize: ->
		@bind "change:activePackage", => @set activeClass: false
		@bind "change:activeClass", => @set activeSlot: false
		
	toggle: (field) ->
		@set field, not @get field
		@get field
		
class _PackageList extends Backbone.View
	className: "packageList"

	initialize: ->
		@collection.bind "reset", => @renderPackages()
		@collection.bind "add", => @renderPackages()
		@collection.bind "change", => @renderPackages()
		
	render: ->
		@$el.append $("<h2 />").text("Packages")
		@ul = $("<ul />").appendTo @$el
		
		this
		
	renderPackages: ->
		@ul.html ""
		for _package, classes of (@collection.groupBy (c) -> c.get "package")
			do (_package) =>
				@ul.append li = $("<li />").text(if _package is "" then "(no package)" else _package).click =>
					$("li", @ul).removeClass "active"
					li.addClass "active"
					@openPackage _package

	openPackage: (_package) ->
		@model.set "activePackage", _package
		
class _ClassList extends Backbone.View
	className: "classList"
	
	@SettingsForm = false
	initialize: ->
		@model.bind "change:activePackage", => @renderItems()
		@model.bind "change:groupClassesByParent", => @renderItems()
		@model.bind "change:showTestClasses", => @renderItems()
		@collection.bind "reset", => @renderItems()
		@collection.bind "add", => @renderItems()
			
		if not @SettingsForm
			@SettingsForm = $("#classListSettings").remove()
			@groupByParentCheckBox = $(".groupByParent", @SettingsForm)
			@showTestClassesCheckBox = $(".showTestClasses", @SettingsForm)
					
			$('body').on 'change', '.popover .groupByParent', (e) =>
				e.stopPropagation()
				@model.set "groupClassesByParent", @groupByParentCheckBox.is(":checked")

			$('body').on 'change', '.popover .showTestClasses', (e) =>
				@model.set "showTestClasses", @showTestClassesCheckBox.is(":checked")

		@newClassModal = $("#newClassModal").modal show: false, keyboard: false
		@newPackage = $("input[name=package]", @newClassModal)
		@newNamespace = $("input[name=namespace]", @newClassModal)
		@newName = $("input[name=name]", @newClassModal)
		@newExtends = $("input[name=extends]", @newClassModal)
		@newDescription = $("textarea", @newClassModal)
		@newMode = $(".mode", @newClassModal)
		
		@newClassModal.on "shown", =>
			if @editing
				@newMode.text "Edit"
				@newPackage.val @model.get("activeClass").get "package"
				@newNamespace.val @model.get("activeClass").get "namespace"
				@newName.val @model.get("activeClass").get "name"
				@newExtends.val @model.get("activeClass").get "extends"
				@newDescription.val @model.get("activeClass").get "description"
				@mainButton.text "Save"
			else
				@newMode.text "New"
				$("input, textarea", @newClassModal).val("")
				@newPackage.val @model.get("activePackage")
				@mainButton.text "Create"
				
			@newName.focus()
	
		@mainButton = $(".btn-primary", @newClassModal).click =>
			if @newName.val().trim().length is 0 
				alert "Name is required"
				return

			@model.set "activePackage", @newPackage.val()

			newClass = @collection.create
				package: @newPackage.val()
				namespace: @newNamespace.val()
				name: @newName.val()
				extends: @newExtends.val()
				description: @newDescription.val()
			
			@newClassModal.modal "hide"

	render: ->
		buttons = $("<div />").appendTo(@$el).addClass("buttons")
		
		@editButton = $("<span />")
			.text("Edit")
			.addClass("btn btn-primary disabled")
			.appendTo(buttons)
			.click =>
				@editing = true
				@newClassModal.modal "show"
				

		@newClassButton = $("<span />")
			.text("New")
			.addClass("btn btn-primary")
			.appendTo(buttons)
			.click =>
				@editing = false
				@newClassModal.modal "show"
				
		@optionsButton = $("<span />")
			.addClass("btn btn-primary")
			.html($("<i />").addClass("icon-cog icon-white"))
			.appendTo(buttons)
			.popover(
				title: false
				trigger: "manual"
				placement: "bottom"
				live: true
				content: => 
					if @model.get("groupClassesByParent")
						@groupByParentCheckBox.attr "checked", true
					
					if @model.get("showTestClasses")
						@showTestClassesCheckBox.attr "checked", true
						
					$('.popover').remove()
					@SettingsForm)
			.click (e) =>
				e.stopPropagation() 
				@optionsButton.popover "show"


		@ul = $("<ul />").appendTo @$el
		
		this
	
	addItem: (_class) ->
		if _class.get("package") isnt @model.get("activePackage") then return
		
		@ul.append li = $("<li />").text(_class.get "name").click => 
			$("li", @ul).removeClass "active"
			li.addClass "active"
			@openClass _class
			
	renderItems: ->
		if not @model.get("activePackage") then return
		
		@ul.html ""
		classList = @collection.filter (c) => c.get("package") is @model.get("activePackage")
		if @model.get("groupClassesByParent")
			for parent, classes of (_(classList).groupBy (c) -> c.get "extends")
				@ul.append $("<li />").text(if parent is "" then "α" else parent).addClass("parentGrouping")
				for _class in classes 
					@addItem _class
		else
			for _class in classList
				@addItem _class
				
		this
		
	openClass: (_class) ->
		@model.set "activeClass", _class
		@editButton.removeClass "disabled"

class _SlotList extends Backbone.View
	className: "slotList"
	activeSlot: false
	_class: false
	
	@SettingsForm = false
	initialize: ->
		@model.bind "change:activePackage", => @clear()
		@model.bind "change:activeClass", => @setActiveClass @model.get "activeClass"

		if not @SettingsForm
			@SettingsForm = $("#slotListSettings").remove().html()

		@newSlotModal = $("#newSlotModal").modal show: false, keyboard: false
		@newSlotInstanceOrClass = $("h3 .instanceOrClass", @newSlotModal)
		@newSlotClassName = $("h3 .className", @newSlotModal)
		@newName = $("input[name=name]", @newSlotModal)
		@newDescription = $("textarea", @newSlotModal)
		@newProtocol = $("input[name=protocol]", @newSlotModal)
		@newSlotModal.on "shown", =>
			$("input, textarea", @newClassModal).val("")
			@newName.focus()
		
		$(".btn-primary", @newSlotModal).click =>
			if @newName.val().trim().lengths is 0 
				alert "Name is required"
				return
				
			newSlot = @_class._slots.create
				classId: @_class.get "id"
				name: @newName.val()
				protocol: @newProtocol.val()
				description: @newDescription.val()
				body: ''
				type: @currentType()

			@newSlotModal.modal "hide"
			@openSlot newSlot
			@drawSlotLists()

	currentType: ->
		return if @instanceTab.hasClass("active") then "Instance" else "Class"
		
	render: ->
		buttons = $("<div />").appendTo(@$el).addClass("buttons")

		@newSlotButton = $("<span />")
			.text("New")
			.addClass("btn btn-primary disabled")
			.appendTo(buttons).click =>
				if @newSlotButton.hasClass("disabled") then return
				@newSlotInstanceOrClass.text @currentType()
				@newSlotClassName.text @_class.get "name"
				@newSlotModal.modal "show"

		@optionsButton = $("<span />")
			.addClass("btn btn-primary")
			.html($("<i />").addClass("icon-cog icon-white"))
			.appendTo(buttons)
			.popover(
				title: false
				trigger: "manual"
				placement: "bottom"
				content: =>
					$('.popover').remove()
					@SettingsForm)
			.click (e) =>
				e.stopPropagation()
				@optionsButton.popover "show"

		@tabs = $("<div />")
			.addClass("tabbable tabs-below")
			.appendTo(@$el)
			.append(@tabContent = $("<div />").addClass("tab-content"))
			.append($("<ul />").addClass("nav nav-tabs").append(
				@instanceTab = $("<li />")
					.addClass("active")
					.append($("<a />")
						.attr("data-toggle": "tab", href: "#instanceTab")
						.text("instance")
						.append(@instanceTabCount = $("<span />")))
				@classTab = $("<li />")
					.append($("<a />")
						.attr("data-toggle": "tab", href: "#classTab")
						.text("class")
						.append(@classTabCount = $("<span />")))))
			
		@instanceSlotsUL = $("<ul />")
			.addClass("active")
			.attr("id", "instanceTab")
			.addClass("tab-pane")
			.appendTo @tabContent
			
		@classSlotsUL = $("<ul />")
			.attr("id", "classTab")
			.addClass("tab-pane")
			.appendTo @tabContent
			
		this

	clear: ->
		@instanceSlotsUL.html ""
		@classSlotsUL.html ""
			
	drawSlots: (ul, slots) ->
		ul.html ""
		
		sortedSlots = []
		for protocol, slotList of (_(slots).groupBy (c) -> c.get("protocol"))
			sortedSlots.push {protocol: protocol, slots: (_(slotList).sortBy (s) -> s.get "name")}

		for grouping in _(sortedSlots).sortBy("protocol")
			protocol = grouping.protocol
			slotList = grouping.slots

			$("<li />").text(if protocol is "" then "Unclassified" else protocol).addClass("protocol").appendTo(ul)
			for slot in slotList
				do (slot) =>
					slot.on "change", => li.text slot.get "name"
					slot.on "destroy", => li.remove()

					ul.append li = $("<li />").text(slot.get "name").click => 
						$("li", @tabContent).removeClass("active")
						li.addClass "active"
						@openSlot slot
					
					if slot.get("name") is @model.get("activeSlot").get?("name")
						li.click()
					
	drawSlotLists: ->
		instanceSlots = @_class.getInstanceSlots()
		@drawSlots @instanceSlotsUL, instanceSlots
		@instanceTabCount.text " #{instanceSlots.length}"
		
		classSlots =  @_class.getClassSlots()
		@drawSlots @classSlotsUL, classSlots
		@classTabCount.text " #{classSlots.length}"
					
	setActiveClass: (_class) ->
		#move this into model 
		if @_class
			@_class.off "change", @drawSlotLists, @
			@_class._slots.off "change", @drawSlotsList, @

		@_class = _class
		
		if not @_class then return
			
		@_class.on "change", @drawSlotLists, @
		@_class._slots.on "add", @drawSlotLists, @

		@newSlotButton.removeClass("disabled")
		@drawSlotLists()
	
	openSlot: (slot) ->
		@model.set "activeSlot", slot

class _SlotEditor extends Backbone.View
	className: "slotEditor"
	
	initialize: ->
		@model.bind "change:activePackage", => @clear()
		@model.bind "change:activeClass", => @clear()
		@model.bind "change:activeSlot", => 
			if @model.get "activeSlot"
				@edit @model.get "activeSlot"
			else
				@clear()
					
	render: ->
		buttons = $("<div />").appendTo(@$el).addClass("buttons")

		@nameInput = $("<input />")
			.addClass("slotName")
			.appendTo(buttons)
			.keyup =>
				if @slot.get("name") isnt @nameInput.val()
					@saveSlot()
				
		@typeButton = $("<span />")
			.text("Slot Type")
			.addClass("btn btn-primary disabled")
			.appendTo(buttons).click =>
				if @typeButton.hasClass("disabled") then return

		@protocolButton = $("<span />")
			.text("Protocol")
			.addClass("btn btn-primary disabled")
			.appendTo(buttons).click =>
				if @typeButton.hasClass("disabled") then return
				
		@optionsButton = $("<span />")
			.addClass("btn btn-primary")
			.html($("<i />").addClass("icon-cog icon-white"))
			.appendTo(buttons)
			.popover(
				title: false
				trigger: "manual"
				placement: "bottom"
				content: =>
					$('.popover').remove()
					@SettingsForm)
			.click (e) =>
				e.stopPropagation()
				@optionsButton.popover "show"
				
		@deleteButton = $("<span />")
			.addClass("btn btn-danger disabled")
			.html($("<i />").addClass("icon-remove icon-white"))
			.appendTo(buttons)
			.click =>
				return if @deleteButton.hasClass "disabled"

				if confirm "Are you sure you want to delete #{@slot.get "name"}"
					@slot.destroy()
					@clear()

		@output = $("<pre />").addClass("output").appendTo @$el
		@output.on "dblclick", => 
			
			if @model.toggle "collapsedOutput"
				@output.addClass "collapsed"
			else
			 	@output.removeClass "collapsed"
		
		@textarea = $("<textarea />").appendTo @$el
		@editor = CodeMirror.fromTextArea @textarea[0], 
			mode: "coffeescript"
			theme: "cobalt"
			gutter: true
			lineNumbers: true
			indentWithTabs: false
			onChange: =>
				if @editor.getValue().trim().length is 0 then return
				
				try
					slotSig =  'slot = '
					compiled = CoffeeScript.compile slotSig + @editor.getValue(), bare: true
					#we want to ignore the first var declaration as it is hack to allow super compilation to not assplode
					@output.text compiled.split("\n")[1..-1].join("\n").replace(slotSig, '').trim()
					@output.removeClass "error"
					
					#commit to server
					if @slot.get("body") isnt @editor.getValue()
						@saveSlot()
				catch e
					compiled = false
					@output.text e.message.trim()
					@output.addClass "error"

		this

	saveSlot: ->
		@slot.set "body", @editor.getValue()
		@slot.set "name", @nameInput.val()
		@slot.save()
			
	edit: (slot) ->
		@slot = slot
		@output.text ""
		@editor.setOption "readOnly", false
		@editor.setValue @slot.get "body"
		@deleteButton.removeClass "disabled"
		@nameInput.val @slot.get "name"
		@nameInput.removeAttr "disabled"

	clear: ->
		@output.text ""
		@editor.setValue ""
		@editor.setOption "readOnly", true
		@deleteButton.addClass "disabled"
		@nameInput.val ""
		@nameInput.attr "disabled", true
		
class Browser extends Backbone.View
	className: "browser"
	initialize: (options) ->
		@settings = options.settings
		
		@options.parent.on "resize", (newSize) => @setHeights newSize
			
		window.settings = @settings
		
		@packageListView = new _PackageList collection: @collection, browser: this, model: @settings
		@packageListView.render().$el.appendTo @$el
		
		@classListView = new _ClassList collection: @collection, browser: this, model: @settings
		@classListView.render().$el.appendTo @$el

		@slotListView = new _SlotList browser: this, model: @settings
		@slotListView.render().$el.appendTo @$el
	
		@slotEditor = new _SlotEditor model: @settings
		@slotEditor.$el.appendTo(@$el)
		@slotEditor.render()

	setHeights: (newSize) ->
		@$el.css 'height', newSize
		newHeight = newSize - 35
		@packageListView.$el.css "height", newHeight
		@classListView.$el.css "height", newHeight
		@slotListView.$el.css "height", newHeight
		$(@slotEditor.editor.getScrollerElement()).css "height", newHeight
		@slotEditor.editor.refresh()
		
class REPL extends Backbone.View
	className: "REPL"
		
	render: ->
		@replCol = $("<div />")
			.addClass("replCol")
			.appendTo(@$el)

		@output = $("<pre />")
			.addClass("output")
			.appendTo(@replCol)

		@input = $("<textarea />")
			.addClass("input")
			.appendTo(@replCol)

		@sendButton = $("<span />")
			.text("Send")
			.addClass("btn btn-primary")
			.appendTo(@replCol)
			
		@state = $("<textarea />")
			.addClass("state pull-right")
			.appendTo(@$el)

		@env = $("<ul />")
			.addClass("env pull-right")
			.appendTo(@$el)


		this

class IDE extends Backbone.View
	className: "IDE tabbable"
	
	tabIndex: 0
	
	addTab: (name, view) ->
		tabId = @tabIndex++
		@navTabs.append $("<li />").append($("<a />").attr(href: "#tab#{tabId}", "data-toggle": "tab").text(name))
		@tabContent.append $("<div />").addClass("tab-pane").attr("id", "tab#{tabId}").html(view.render().$el)
		this
		
	initialize: ->
		@$el.append @navTabs = $("<ul />").addClass("nav nav-tabs")
		@$el.append @tabContent = $("<div />").addClass("tab-content")
		@$el.append @dragHandle = $("<div />").addClass("drag-handle")
		
		@$el.draggable
			handle: ".drag-handle"
			axis: "y"
			start: =>
				@startHeight = @tabContent.height()
			,
			drag: (evt, ui) =>
				@trigger "resize", @startHeight + ui.position.top
				ui.position.top = 0

class Todo extends Backbone.View 
	render: ->
		@$el.html $("pre.TODO").remove() 
		this

class window.CoffeeTalkApp
	init: ->
		window.socket = socket = io.connect 'http://localhost'
		cbQueueID = 0
		cbQueue = {}

		Backbone.sync = (method, model, options) ->
			switch method
				when "create", "update", "delete"
					reqID = ++cbQueueID

					socket.emit "saveNode", 
						method: method
						type: model.nodeType
						data: model.toJSON()
						reqID: reqID

					cbQueue[reqID] = options.success
					#register timeout for failure??

		socket.on "updateNode", (response) ->
			if response.reqID? and cbQueue[response.reqID]
				cbQueue[response.reqID](if response.method is "delete" then true else response.data)
				delete cbQueue[response.reqID]
			else
				switch response.type 
					when "Class"
						existing = classesCollection.where id: response.data.classId
						if existing
							existing[0].set response.data
						else
							classesCollection.add response.data
					when "Slot"
						slotClass = classesCollection.where id: response.data.classId
						if slotClass
							slot = slotClass[0]._slots.where id: response.data.id
							if slot
								slot[0].set response.data
							else
								slotClass[0]._slots.create response.data

		#yuck and the yuck faces
		$('body').on 'click', '.popover', (e) =>
			e.stopPropagation()
			
		#hack for popover 
		$('body').click -> $('.popover').remove()
		
		classesCollection = new _Classes
		window.classes = classesCollection

		ide = new IDE
		ide.$el.appendTo 'body'
		ide.addTab "REPL", new REPL collection: classesCollection
		ide.addTab "Browser", new Browser collection: classesCollection, settings: new BrowserSettings, parent: ide
		ide.addTab "Todo", new Todo
	
		socket.on 'classList', (data) => classesCollection.reset data.classes