#coffeetalk
Coffeetalk is a smalltalk browser/ide for coffeescript. It has long been my opinion that the greatest strength of smalltalk is not the syntax but rather the development environment. Coffeescript has gone a long way towards exposing the power of javascripts object model but I still find myself with an itch for a more robust way to browse,  create and search through my code base. Coffeetalk is my answer. Whilst I love smalltalk I find it difficult to convince other developers to make the jump, I am hoping this can be a gateway or at the least a stopgap. The only crucial missing functionality (well beyond keyword messages, blocks etc.) is "doesNotUnderstand". However it would be possible to implement via a forked version of coffeescript which passes all method calls through a MOPApply dispatcher (this could also facilitate TCO, but I digress). My gut feeling though is that there are Other Ways of accomplishing what doesNotUnderstand would be used for w/o incurring the runtime penalty. 

##what is it?
initially the standard 3 panel browser (package, class, slot) with an editor based (initially) upon code mirror. 

##terminology
###package: 
This is an arbitrary grouping of classes. Most likely this means your application or library. 
###namespace:
Not required unless you need things like Backbone.View or MyApp.Views.SomeView, which you probably do. 
###class:
Group of slots which can extend a parent class to inherit said parents slots.
###protocol:
A grouping of slots within a class, nice for organizing your classes in a manner beyond 
###slot:
A slot can either be a method or a variable. There are both instance and class slots. 

##how?
Storing classes as json files which have a directory of slots (defined by a json description and coffee file per slot). The advantages to this beyond facilitating coffeetalk browser are that you get per-slot revision history out of the box regardless of SCM as well as flat files editable by what ever editor so you are not locked into the coffeetalk interface (e.g. you can use vim to edit a slot, upon save the server will update any listening clients via socket.io). Currently the persistence layer is utilizing socket.io and flat files but it is architected in such a way that storage in other manners is viable (maybe in a database? couchdb?). 

##whats done (will be done at 0.1)?
###REPL
define and manage instances of objects, nice for rapid development/experimentation.  
###browser
navigating through packages, classes and slots is fully functional as is creation of new classes and slots. You can group classes by parent, slots by protocol, and show inherited slots.
###slot editor
compiles the slot on keystroke so you can immediately see the output - basically a nice way of verifying that your coffee is doing what you expect immediately. Any time it successfully compiles it persists the slot so you never lose your work. 
###deploy
compiles down to single file containing class definitions. Can either be coffee or the compiled/uglified source. You can export either a single slot, class, package (including any parent classes regardless of package) or entire system. 
###live edit
edit the codebase of the running app in the browser (or in another browser). 

##what else is coming?
###drag and drop workspace 
w/ mini map and saved workspaces (drag out the slots you want to work on, give the workspace a label, slap some notes on it etc. so next time you have a task to deal with just load the workspace. 
###custom slot editor
define "type" of slot and get a custom editor e.g. json editor, string (essentially wraps content in a heredoc, nice for defining templates)
###integrated testing
test classes created as classes/slots are defined - test runner which works in conjunction w/ slot editor so the tests are being run on loop as you edit your slot. Once all green, persists slot.
###import class file
import coffee script class files (not sure how to handle this other than only allowing import of class files which contain only the class definition?)
###port of backbone, bootstrap, underscore, zepto
For the sake of fun it would be nice to port some of the most commonly used libs to coffeetalk - this should actually be relatively trivial - but totally un-necessary as there is no need for a lib to be defined in coffeetalk for it to be leveraged e.g. the browser itself is defined in terms of coffeetalk but extending/utilizing backbone, jquery, socket.io etc.
###more reflection
things like auto completing package/class names when defining/editing a package/class. 
###editing goodness
autocomplete, clickable text nodes for looking up class definition etc.
###versioning integration
hooks to allow for branching/versioning with click of button - nice for experimenting and then being able to easily jump back to a different version of a package/class/slot. This would be the yang to the yin of the autosave agenda.
###brett victor style tangible testing
set inputs, see line by line what the outcome of conditionals are, what state of variables are etc.
