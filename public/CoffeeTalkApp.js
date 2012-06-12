(function() {
  var Browser, BrowserSettings, IDE, REPL, Todo, _Class, _ClassList, _Classes, _PackageList, _SlotEditor, _SlotList,
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  _Class = (function(_super) {

    __extends(_Class, _super);

    function _Class() {
      _Class.__super__.constructor.apply(this, arguments);
    }

    _Class.prototype.getSlotsByType = function(type) {
      var slot, _i, _len, _ref, _results;
      _ref = this.get("slots");
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        slot = _ref[_i];
        if (slot.type === type) _results.push(slot);
      }
      return _results;
    };

    _Class.prototype.getInstanceSlots = function() {
      return this.getSlotsByType("Instance");
    };

    _Class.prototype.getClassSlots = function() {
      return this.getSlotsByType("Class");
    };

    return _Class;

  })(Backbone.Model);

  _Classes = (function(_super) {

    __extends(_Classes, _super);

    function _Classes() {
      _Classes.__super__.constructor.apply(this, arguments);
    }

    _Classes.prototype.model = _Class;

    _Classes.prototype.getByPackage = function(pkg) {
      var _class, _i, _len, _ref, _results;
      _ref = this.models;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        _class = _ref[_i];
        if (_class.get("package") === pkg) _results.push(_class);
      }
      return _results;
    };

    return _Classes;

  })(Backbone.Collection);

  BrowserSettings = (function(_super) {

    __extends(BrowserSettings, _super);

    function BrowserSettings() {
      BrowserSettings.__super__.constructor.apply(this, arguments);
    }

    BrowserSettings.prototype.defaults = {
      activePackage: false,
      activeClass: false,
      activeSlot: false,
      groupClassesByParent: true,
      showTestClasses: false,
      groupSlotsByProtocol: true,
      showInheritedSlots: false,
      collapsedOutput: false
    };

    BrowserSettings.prototype.initialize = function() {
      var _this = this;
      this.bind("change:activePackage", function() {
        return _this.set({
          activeClass: false
        });
      });
      return this.bind("change:activeClass", function() {
        return _this.set({
          activeSlot: false
        });
      });
    };

    BrowserSettings.prototype.toggle = function(field) {
      this.set(field, !this.get(field));
      return this.get(field);
    };

    return BrowserSettings;

  })(Backbone.Model);

  _PackageList = (function(_super) {

    __extends(_PackageList, _super);

    function _PackageList() {
      _PackageList.__super__.constructor.apply(this, arguments);
    }

    _PackageList.prototype.className = "packageList";

    _PackageList.prototype.initialize = function() {
      var _this = this;
      this.collection.bind("reset", function() {
        return _this.renderPackages();
      });
      this.collection.bind("add", function() {
        return _this.renderPackages();
      });
      return this.collection.bind("change", function() {
        return _this.renderPackages();
      });
    };

    _PackageList.prototype.render = function() {
      this.$el.append($("<h2 />").text("Packages"));
      this.ul = $("<ul />").appendTo(this.$el);
      return this;
    };

    _PackageList.prototype.renderPackages = function() {
      var classes, _package, _ref, _results,
        _this = this;
      this.ul.html("");
      _ref = this.collection.groupBy(function(c) {
        return c.get("package");
      });
      _results = [];
      for (_package in _ref) {
        classes = _ref[_package];
        _results.push((function(_package) {
          var li;
          return _this.ul.append(li = $("<li />").text(_package === "" ? "(no package)" : _package).click(function() {
            $("li", _this.ul).removeClass("active");
            li.addClass("active");
            return _this.openPackage(_package);
          }));
        })(_package));
      }
      return _results;
    };

    _PackageList.prototype.openPackage = function(_package) {
      return this.model.set("activePackage", _package);
    };

    return _PackageList;

  })(Backbone.View);

  _ClassList = (function(_super) {

    __extends(_ClassList, _super);

    function _ClassList() {
      _ClassList.__super__.constructor.apply(this, arguments);
    }

    _ClassList.prototype.className = "classList";

    _ClassList.SettingsForm = false;

    _ClassList.prototype.initialize = function() {
      var _this = this;
      this.model.bind("change:activePackage", function() {
        return _this.renderItems();
      });
      this.model.bind("change:groupClassesByParent", function() {
        return _this.renderItems();
      });
      this.model.bind("change:showTestClasses", function() {
        return _this.renderItems();
      });
      this.collection.bind("reset", function() {
        return _this.renderItems();
      });
      this.collection.bind("add", function() {
        return _this.renderItems();
      });
      if (!this.SettingsForm) {
        this.SettingsForm = $("#classListSettings").remove();
        this.groupByParentCheckBox = $(".groupByParent", this.SettingsForm);
        this.showTestClassesCheckBox = $(".showTestClasses", this.SettingsForm);
        $('body').on('change', '.popover .groupByParent', function(e) {
          e.stopPropagation();
          return _this.model.set("groupClassesByParent", _this.groupByParentCheckBox.is(":checked"));
        });
        $('body').on('change', '.popover .showTestClasses', function(e) {
          return _this.model.set("showTestClasses", _this.showTestClassesCheckBox.is(":checked"));
        });
      }
      this.newClassModal = $("#newClassModal").modal({
        show: false,
        keyboard: false
      });
      this.newPackage = $("input[name=package]", this.newClassModal);
      this.newNamespace = $("input[name=namespace]", this.newClassModal);
      this.newName = $("input[name=name]", this.newClassModal);
      this.newExtends = $("input[name=extends]", this.newClassModal);
      this.newDescription = $("textarea", this.newClassModal);
      this.newMode = $(".mode", this.newClassModal);
      this.newClassModal.on("shown", function() {
        if (_this.editing) {
          _this.newMode.text("Edit");
          _this.newPackage.val(_this.model.get("activeClass").get("package"));
          _this.newNamespace.val(_this.model.get("activeClass").get("namespace"));
          _this.newName.val(_this.model.get("activeClass").get("name"));
          _this.newExtends.val(_this.model.get("activeClass").get("extends"));
          _this.newDescription.val(_this.model.get("activeClass").get("description"));
          _this.mainButton.text("Save");
        } else {
          _this.newMode.text("New");
          $("input, textarea", _this.newClassModal).val("");
          _this.newPackage.val(_this.model.get("activePackage"));
          _this.mainButton.text("Create");
        }
        return _this.newName.focus();
      });
      return this.mainButton = $(".btn-primary", this.newClassModal).click(function() {
        var newClass;
        if (_this.newName.val().trim().length === 0) {
          alert("Name is required");
          return;
        }
        newClass = {
          package: _this.newPackage.val(),
          namespace: _this.newNamespace.val(),
          name: _this.newName.val(),
          "extends": _this.newExtends.val(),
          description: _this.newDescription.val()
        };
        window.socket.emit("saveClass", {
          "class": newClass
        });
        _this.model.set("activePackage", _this.newPackage.val());
        return _this.newClassModal.modal("hide");
      });
    };

    _ClassList.prototype.render = function() {
      var buttons,
        _this = this;
      buttons = $("<div />").appendTo(this.$el).addClass("buttons");
      this.editButton = $("<span />").text("Edit").addClass("btn btn-primary disabled").appendTo(buttons).click(function() {
        _this.editing = true;
        return _this.newClassModal.modal("show");
      });
      this.newClassButton = $("<span />").text("New").addClass("btn btn-primary").appendTo(buttons).click(function() {
        _this.editing = false;
        return _this.newClassModal.modal("show");
      });
      this.optionsButton = $("<span />").addClass("btn btn-primary").html($("<i />").addClass("icon-cog icon-white")).appendTo(buttons).popover({
        title: false,
        trigger: "manual",
        placement: "bottom",
        live: true,
        content: function() {
          if (_this.model.get("groupClassesByParent")) {
            _this.groupByParentCheckBox.attr("checked", true);
          }
          if (_this.model.get("showTestClasses")) {
            _this.showTestClassesCheckBox.attr("checked", true);
          }
          $('.popover').remove();
          return _this.SettingsForm;
        }
      }).click(function(e) {
        e.stopPropagation();
        return _this.optionsButton.popover("show");
      });
      this.ul = $("<ul />").appendTo(this.$el);
      return this;
    };

    _ClassList.prototype.addItem = function(_class) {
      var li,
        _this = this;
      if (_class.get("package") !== this.model.get("activePackage")) return;
      return this.ul.append(li = $("<li />").text(_class.get("name")).click(function() {
        $("li", _this.ul).removeClass("active");
        li.addClass("active");
        return _this.openClass(_class);
      }));
    };

    _ClassList.prototype.renderItems = function() {
      var classList, classes, parent, _class, _i, _j, _len, _len2, _ref,
        _this = this;
      if (!this.model.get("activePackage")) return;
      this.ul.html("");
      classList = this.collection.filter(function(c) {
        return c.get("package") === _this.model.get("activePackage");
      });
      if (this.model.get("groupClassesByParent")) {
        _ref = _(classList).groupBy(function(c) {
          return c.get("extends");
        });
        for (parent in _ref) {
          classes = _ref[parent];
          this.ul.append($("<li />").text(parent === "" ? "α" : parent).addClass("parentGrouping"));
          for (_i = 0, _len = classes.length; _i < _len; _i++) {
            _class = classes[_i];
            this.addItem(_class);
          }
        }
      } else {
        for (_j = 0, _len2 = classList.length; _j < _len2; _j++) {
          _class = classList[_j];
          this.addItem(_class);
        }
      }
      return this;
    };

    _ClassList.prototype.openClass = function(_class) {
      this.model.set("activeClass", _class);
      return this.editButton.removeClass("disabled");
    };

    return _ClassList;

  })(Backbone.View);

  _SlotList = (function(_super) {

    __extends(_SlotList, _super);

    function _SlotList() {
      _SlotList.__super__.constructor.apply(this, arguments);
    }

    _SlotList.prototype.className = "slotList";

    _SlotList.prototype.activeSlot = false;

    _SlotList.prototype._class = false;

    _SlotList.SettingsForm = false;

    _SlotList.prototype.initialize = function() {
      var _this = this;
      this.model.bind("change:activePackage", function() {
        return _this.clear();
      });
      this.model.bind("change:activeClass", function() {
        return _this.setActiveClass(_this.model.get("activeClass"));
      });
      if (!this.SettingsForm) {
        this.SettingsForm = $("#slotListSettings").remove().html();
      }
      this.newSlotModal = $("#newSlotModal").modal({
        show: false,
        keyboard: false
      });
      this.newSlotInstanceOrClass = $("h3 .instanceOrClass", this.newSlotModal);
      this.newSlotClassName = $("h3 .className", this.newSlotModal);
      this.newName = $("input[name=name]", this.newSlotModal);
      this.newDescription = $("textarea", this.newSlotModal);
      this.newProtocol = $("input[name=protocol]", this.newSlotModal);
      this.newSlotModal.on("shown", function() {
        $("input, textarea", _this.newClassModal).val("");
        return _this.newName.focus();
      });
      return $(".btn-primary", this.newSlotModal).click(function() {
        var newSlot;
        if (_this.newName.val().trim().lengths === 0) {
          alert("Name is required");
          return;
        }
        newSlot = {
          name: _this.newName.val(),
          protocol: _this.newProtocol.val(),
          description: _this.newDescription.val(),
          body: '',
          type: _this.currentType()
        };
        window.socket.emit("saveSlot", {
          "class": _this._class.toJSON(),
          slot: newSlot
        });
        _this.newSlotModal.modal("hide");
        return _this.openSlot(newSlot);
      });
    };

    _SlotList.prototype.currentType = function() {
      if (this.instanceTab.hasClass("active")) {
        return "Instance";
      } else {
        return "Class";
      }
    };

    _SlotList.prototype.render = function() {
      var buttons,
        _this = this;
      buttons = $("<div />").appendTo(this.$el).addClass("buttons");
      this.newSlotButton = $("<span />").text("New").addClass("btn btn-primary disabled").appendTo(buttons).click(function() {
        if (_this.newSlotButton.hasClass("disabled")) return;
        _this.newSlotInstanceOrClass.text(_this.currentType());
        _this.newSlotClassName.text(_this._class.get("name"));
        return _this.newSlotModal.modal("show");
      });
      this.optionsButton = $("<span />").addClass("btn btn-primary").html($("<i />").addClass("icon-cog icon-white")).appendTo(buttons).popover({
        title: false,
        trigger: "manual",
        placement: "bottom",
        content: function() {
          $('.popover').remove();
          return _this.SettingsForm;
        }
      }).click(function(e) {
        e.stopPropagation();
        return _this.optionsButton.popover("show");
      });
      this.tabs = $("<div />").addClass("tabbable tabs-below").appendTo(this.$el).append(this.tabContent = $("<div />").addClass("tab-content")).append($("<ul />").addClass("nav nav-tabs").append(this.instanceTab = $("<li />").addClass("active").append($("<a />").attr({
        "data-toggle": "tab",
        href: "#instanceTab"
      }).text("instance").append(this.instanceTabCount = $("<span />"))), this.classTab = $("<li />").append($("<a />").attr({
        "data-toggle": "tab",
        href: "#classTab"
      }).text("class").append(this.classTabCount = $("<span />")))));
      this.instanceSlotsUL = $("<ul />").addClass("active").attr("id", "instanceTab").addClass("tab-pane").appendTo(this.tabContent);
      this.classSlotsUL = $("<ul />").attr("id", "classTab").addClass("tab-pane").appendTo(this.tabContent);
      return this;
    };

    _SlotList.prototype.clear = function() {
      this.instanceSlotsUL.html("");
      return this.classSlotsUL.html("");
    };

    _SlotList.prototype.drawSlots = function(ul, slots) {
      var protocol, slot, slotList, _ref, _results;
      ul.html("");
      _ref = _(slots).groupBy(function(c) {
        return c.protocol;
      });
      _results = [];
      for (protocol in _ref) {
        slotList = _ref[protocol];
        $("<li />").text(protocol === "" ? "Unclassified" : protocol).addClass("protocol").appendTo(ul);
        _results.push((function() {
          var _i, _len, _results2,
            _this = this;
          _results2 = [];
          for (_i = 0, _len = slotList.length; _i < _len; _i++) {
            slot = slotList[_i];
            _results2.push((function(slot) {
              var li;
              ul.append(li = $("<li />").text(slot.name).click(function() {
                console.log("CLICKED", slot);
                $("li", _this.tabContent).removeClass("active");
                li.addClass("active");
                return _this.openSlot(slot);
              }));
              if (slot.name === _this.model.get("activeSlot").name) {
                return li.click();
              }
            })(slot));
          }
          return _results2;
        }).call(this));
      }
      return _results;
    };

    _SlotList.prototype.drawSlotLists = function() {
      var classSlots, instanceSlots;
      instanceSlots = this._class.getInstanceSlots();
      this.drawSlots(this.instanceSlotsUL, instanceSlots);
      this.instanceTabCount.text(" " + instanceSlots.length);
      classSlots = this._class.getClassSlots();
      this.drawSlots(this.classSlotsUL, classSlots);
      return this.classTabCount.text(" " + classSlots.length);
    };

    _SlotList.prototype.setActiveClass = function(_class) {
      if (this._class) this._class.off("change", this.drawSlotLists, this);
      this._class = _class;
      if (!this._class) return;
      this._class.on("change", this.drawSlotLists, this);
      this.newSlotButton.removeClass("disabled");
      return this.drawSlotLists();
    };

    _SlotList.prototype.openSlot = function(slot) {
      return this.model.set("activeSlot", slot);
    };

    return _SlotList;

  })(Backbone.View);

  _SlotEditor = (function(_super) {

    __extends(_SlotEditor, _super);

    function _SlotEditor() {
      _SlotEditor.__super__.constructor.apply(this, arguments);
    }

    _SlotEditor.prototype.className = "slotEditor";

    _SlotEditor.prototype.initialize = function() {
      var _this = this;
      this.model.bind("change:activePackage", function() {
        return _this.clear();
      });
      this.model.bind("change:activeClass", function() {
        return _this.clear();
      });
      return this.model.bind("change:activeSlot", function() {
        if (_this.model.get("activeSlot")) {
          return _this.edit(_this.model.get("activeSlot"));
        } else {
          return _this.clear();
        }
      });
    };

    _SlotEditor.prototype.render = function() {
      var buttons,
        _this = this;
      buttons = $("<div />").appendTo(this.$el).addClass("buttons");
      this.nameInput = $("<input />").addClass("slotName").appendTo(buttons).keydown(function() {
        if (_this.model.get("activeSlot").name !== _this.nameInput.val()) {
          return _this.saveSlot();
        }
      });
      this.typeButton = $("<span />").text("Slot Type").addClass("btn btn-primary disabled").appendTo(buttons).click(function() {
        if (_this.typeButton.hasClass("disabled")) {}
      });
      this.protocolButton = $("<span />").text("Protocol").addClass("btn btn-primary disabled").appendTo(buttons).click(function() {
        if (_this.typeButton.hasClass("disabled")) {}
      });
      this.optionsButton = $("<span />").addClass("btn btn-primary").html($("<i />").addClass("icon-cog icon-white")).appendTo(buttons).popover({
        title: false,
        trigger: "manual",
        placement: "bottom",
        content: function() {
          $('.popover').remove();
          return _this.SettingsForm;
        }
      }).click(function(e) {
        e.stopPropagation();
        return _this.optionsButton.popover("show");
      });
      this.output = $("<pre />").addClass("output").appendTo(this.$el);
      this.output.on("dblclick", function() {
        if (_this.model.toggle("collapsedOutput")) {
          return _this.output.addClass("collapsed");
        } else {
          return _this.output.removeClass("collapsed");
        }
      });
      this.textarea = $("<textarea />").appendTo(this.$el);
      this.editor = CodeMirror.fromTextArea(this.textarea[0], {
        mode: "coffeescript",
        theme: "cobalt",
        gutter: true,
        lineNumbers: true,
        indentWithTabs: false,
        onChange: function() {
          var compiled, slotSig;
          if (_this.editor.getValue().trim().length === 0) return;
          try {
            slotSig = 'slot = ';
            compiled = CoffeeScript.compile(slotSig + _this.editor.getValue(), {
              bare: true
            });
            _this.output.text(compiled.split("\n").slice(1).join("\n").replace(slotSig, '').trim());
            _this.output.removeClass("error");
            if (_this.model.get("activeSlot").body !== _this.editor.getValue()) {
              return _this.saveSlot();
            }
          } catch (e) {
            compiled = false;
            _this.output.text(e.message.trim());
            return _this.output.addClass("error");
          }
        }
      });
      return this;
    };

    _SlotEditor.prototype.saveSlot = function() {
      var activeSlot;
      activeSlot = this.model.get("activeSlot");
      activeSlot.body = this.editor.getValue();
      activeSlot.name = this.nameInput.val();
      return socket.emit('saveSlot', {
        "class": this.model.get("activeClass"),
        slot: activeSlot
      });
    };

    _SlotEditor.prototype.edit = function(slot) {
      this.output.text("");
      this.editor.setOption("readOnly", false);
      this.editor.setValue(slot.body);
      return this.nameInput.val(slot.name);
    };

    _SlotEditor.prototype.clear = function() {
      this.output.text("");
      this.editor.setValue("");
      this.editor.setOption("readOnly", true);
      return this.nameInput.val("");
    };

    return _SlotEditor;

  })(Backbone.View);

  Browser = (function(_super) {

    __extends(Browser, _super);

    function Browser() {
      Browser.__super__.constructor.apply(this, arguments);
    }

    Browser.prototype.className = "browser";

    Browser.prototype.initialize = function(options) {
      var _this = this;
      this.settings = options.settings;
      this.options.parent.on("resize", function(newSize) {
        return _this.setHeights(newSize);
      });
      window.settings = this.settings;
      this.packageListView = new _PackageList({
        collection: this.collection,
        browser: this,
        model: this.settings
      });
      this.packageListView.render().$el.appendTo(this.$el);
      this.classListView = new _ClassList({
        collection: this.collection,
        browser: this,
        model: this.settings
      });
      this.classListView.render().$el.appendTo(this.$el);
      this.slotListView = new _SlotList({
        browser: this,
        model: this.settings
      });
      this.slotListView.render().$el.appendTo(this.$el);
      this.slotEditor = new _SlotEditor({
        model: this.settings
      });
      this.slotEditor.$el.appendTo(this.$el);
      return this.slotEditor.render();
    };

    Browser.prototype.setHeights = function(newSize) {
      var newHeight;
      this.$el.css('height', newSize);
      newHeight = newSize - 35;
      this.packageListView.$el.css("height", newHeight);
      this.classListView.$el.css("height", newHeight);
      this.slotListView.$el.css("height", newHeight);
      $(this.slotEditor.editor.getScrollerElement()).css("height", newHeight);
      return this.slotEditor.editor.refresh();
    };

    return Browser;

  })(Backbone.View);

  REPL = (function(_super) {

    __extends(REPL, _super);

    function REPL() {
      REPL.__super__.constructor.apply(this, arguments);
    }

    REPL.prototype.className = "REPL";

    REPL.prototype.render = function() {
      this.$el.text("this is going to be a repl");
      return this;
    };

    return REPL;

  })(Backbone.View);

  IDE = (function(_super) {

    __extends(IDE, _super);

    function IDE() {
      IDE.__super__.constructor.apply(this, arguments);
    }

    IDE.prototype.className = "IDE tabbable";

    IDE.prototype.tabIndex = 0;

    IDE.prototype.addTab = function(name, view) {
      var tabId;
      tabId = this.tabIndex++;
      this.navTabs.append($("<li />").append($("<a />").attr({
        href: "#tab" + tabId,
        "data-toggle": "tab"
      }).text(name)));
      this.tabContent.append($("<div />").addClass("tab-pane").attr("id", "tab" + tabId).html(view.render().$el));
      return this;
    };

    IDE.prototype.initialize = function() {
      var _this = this;
      this.$el.append(this.navTabs = $("<ul />").addClass("nav nav-tabs"));
      this.$el.append(this.tabContent = $("<div />").addClass("tab-content"));
      this.$el.append(this.dragHandle = $("<div />").addClass("drag-handle"));
      return this.$el.draggable({
        handle: ".drag-handle",
        axis: "y",
        start: function() {
          return _this.startHeight = _this.tabContent.height();
        },
        drag: function(evt, ui) {
          _this.trigger("resize", _this.startHeight + ui.position.top);
          return ui.position.top = 0;
        }
      });
    };

    return IDE;

  })(Backbone.View);

  Todo = (function(_super) {

    __extends(Todo, _super);

    function Todo() {
      Todo.__super__.constructor.apply(this, arguments);
    }

    Todo.prototype.render = function() {
      this.$el.html($("pre.TODO").remove());
      return this;
    };

    return Todo;

  })(Backbone.View);

  window.CoffeeTalkApp = (function() {

    function CoffeeTalkApp() {}

    CoffeeTalkApp.prototype.init = function() {
      var classesCollection, ide,
        _this = this;
      window.socket = io.connect('http://localhost');
      $('body').on('click', '.popover', function(e) {
        return e.stopPropagation();
      });
      $('body').click(function() {
        return $('.popover').remove();
      });
      classesCollection = new _Classes;
      window.classes = classesCollection;
      ide = new IDE;
      ide.$el.appendTo('body');
      ide.addTab("REPL", new REPL({
        collection: classesCollection
      }));
      ide.addTab("Browser", new Browser({
        collection: classesCollection,
        settings: new BrowserSettings,
        parent: ide
      }));
      ide.addTab("Todo", new Todo);
      window.socket.on('classList', function(data) {
        return classesCollection.reset(data.classes);
      });
      return window.socket.on('updateClass', function(data) {
        var existing;
        existing = classesCollection.find(function(c) {
          return c.get("name") === data.name;
        });
        if (existing) {
          return existing.set(data);
        } else {
          return classesCollection.add(data);
        }
      });
    };

    return CoffeeTalkApp;

  })();

}).call(this);
