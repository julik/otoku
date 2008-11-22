// List manager - just a function store
ListM = Class.create({
  initialize : function(linkSelector) {
    this.linkSelector = linkSelector;
    this.attachEvents();
  },
  
  handleClick : function(evt) {
    Event.stop(evt);
    // go up the event chain until we find the link
    var elem = Event.element(evt);
    var link = (elem.nodeName == 'A' ? elem : elem.parentNode);

    this.handleExpandCollapse(link, evt);
    this.handlePostClick(link, evt);
    return false;
  },
  
  handlePostClick : function(link) {
    
  },
  
  handleDoubleClick : function(evt) {
    Event.stop(evt);
    var link = Event.element(evt);
    this.handleExpandCollapse(link, evt);
    return false;
  },
  
  handleExpandCollapse : function (link, evt) {
    // Treat shift+click as Focus
    if(evt.shiftKey) {
      return true;
    } else if(evt.altKey) {
      if (this.isExpanded(link)) {
        this.collapse(link, true);
      } else {
        if(this.isPreloadedCompletely(link)) {
          this.expand(link, true)
        } else {
          this.removeAllChildrenOf(link);
          this.loadContentOf(link, true);
        }
      }
    } else {
      if (this.isExpanded(link)) {
        this.collapse(link);
      } else {
        if (this.linkPreloaded(link)) {
          this.expand(link);	 
        } else {
          this.loadContentOf(link);
        }
      }
    }
  },
  
  linkPreloaded : function(link) {
    return (this.isPreloadedCompletely(link) || link.parentNode.getElementsByTagName("ul").length > 0);
  },
  
  isPreloadedCompletely : function(link) {
    return $(link).classNames().include("all");
  },

  attachEventsTo : function(link) {
    var clk = this.handleClick;
    var dbl = this.handleDoubleClick;
    
    // Observe single click on the expansion triangle only
    // The second one should come last because of the way IE bubbles
    Event.observe(link.getElementsByTagName("b")[0], 'click', clk.bindAsEventListener(this));
    Event.observe(link, 'click', function(e){ Event.stop(e); });
    
    // Observe touch and double clock on the whole link
    Event.observe(link, 'dblclick', dbl.bindAsEventListener(this));
  },
    
  attachEvents : function() {
    $$(this.linkSelector).each(this.attachEventsTo, this);
  },
  
  removeAllChildrenOf : function(link) {
    $A(link.parentNode.getElementsByTagName('ul')).each(Element.remove);
  },
  
  isExpanded : function(link) {
    return $(link).classNames().include('open');
  },
  
  isPreloaded : function(link) {
    return $(link).classNames().include("all");
  },
  
  collapse : function(link, withChildren) {
    $(link).removeClassName("open");
    if (withChildren) {
      var extras = { inc : this.getNestedIdentifiers(link)};
      $A(link.parentNode.getElementsByTagName("ul")).map(Element.hide);
      $A(link.parentNode.getElementsByTagName("a")).map(function(e) {
        $(e).removeClassName('open');
      });
      
      new Ajax.Request('/close/' + link.id, { method:'post', parameters : extras});
    } else {
      Element.hide($(link.parentNode.getElementsByTagName("ul")[0]));
      new Ajax.Request('/close/' + link.id, { method:'post'});
    }
  },
  
  loadContentOf : function(link, inclusive) {
    var params = {bare : 1}
    if (inclusive) params.inc = 1;
    
    var me = this;
    // Remove all other content
    new Ajax.Request(link.href, { method:'get', parameters: params,
      onSuccess: function(transport){
        var li = link.parentNode;
        var list = document.createElement('ul');
        li.appendChild(list);
        Element.hide(list);
        
        list.innerHTML = transport.responseText;
        $A(list.getElementsByTagName("a")).each(function(sub) {
          this.attachEventsTo(sub);
          if(inclusive)  $(sub).addClassName("all");
        }, me);
        
        me.expand(link, inclusive);
      }
    });
  },
  
  getNestedIdentifiers : function(link) {
    return $A(link.parentNode.getElementsByTagName("a")).map(function(child) {
      return child.id;
    });
  },
  
  expand : function(link, withChildren) {
    if (withChildren) {
      $(link).addClassName("all");
      var childIds = this.getNestedIdentifiers(link);
      var extra = {inc : childIds };
      new Ajax.Request('/open/' + link.id, { method:'post', parameters : extra});
    } else {
      new Ajax.Request('/open/' + link.id, { method:'post'});
    }
    
    try {
      if(withChildren) {
        $A(link.parentNode.getElementsByTagName("ul")).each(Element.show);
        $A(link.parentNode.getElementsByTagName("a")).each(function(e) {
          if (!$(e).classNames().include("open") ) $(e).addClassName("open");
        });
      } else {
        $(link).addClassName("open");
        Element.show($(link).parentNode.getElementsByTagName("ul")[0]);
      }
    } catch(e) {
      // TODO
    }
  }  	
});

window.onload = function() {
  var listManager = new ListM("a.hd");
}