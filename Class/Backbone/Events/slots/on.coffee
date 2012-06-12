(events, callback, context) ->
  return if not callback
  events = events.split Events.eventSplitter
  calls = @_callbacks or= {}
  
  while event = events.shift()
    list = calls[event]
    node = if list then list.tail else {}
    node.next = tail = {}
    node.context = context
    node.callback = callback
    calls[event] = 
    	tail: tail
      	next: if list? then list.next else node
      
  this