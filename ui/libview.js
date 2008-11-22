// List manager - just a function store
ListM = {
  handleClick : function(evt) {
    Event.stop(evt);
    // go up the event chain until we find the link
    var elem = Event.element(evt);
    var link = (elem.nodeName == 'A' ? elem : elem.parentNode);

    ListM.handleExpandCollapse(link, evt);
    ListM.handlePostClick(link, evt);
    return false;
  },
  
  handlePostClick : function(link) {
    
  },
  
  handleDoubleClick : function(evt) {
    Event.stop(evt);
    var link = Event.element(evt);
    ListM.handleExpandCollapse(link, evt);
    return false;
  },
  
  handleExpandCollapse : function (link, evt) {
    // Treat shift+click as Focus
    if(evt.shiftKey) {
      return true;
    } else if(evt.altKey) {
      if (ListM.isExpanded(link)) {
        ListM.collapse(link, true);
      } else {
        ListM.isPreloadedCompletely(link) ? ListM.expand(link, true) : ListM.loadContentOf(link, true);
      }
    } else {
      if (ListM.isExpanded(link)) {
        ListM.collapse(link);
      } else {
        if (ListM.linkPreloaded(link)) {
          ListM.expand(link);	 
        } else {
          ListM.loadContentOf(link);
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
    // Observe single click on the expansion triangle only
    // The second one should come last because of the way IE bubbles
    Event.observe(link.getElementsByTagName("b")[0], 'click', this.handleClick.bindAsEventListener(this));
    Event.observe(link, 'click', function(e){ Event.stop(e); });
    
    // Observe touch and double clock on the whole link
    Event.observe(link, 'touchend', this.handleClick.bindAsEventListener(this));
    Event.observe(link, 'dblclick', this.handleDoubleClick.bindAsEventListener(this));
  },
    
  attachEvents : function() {
    $$("a.hd").each(function(link) {
      ListM.attachEventsTo(link);
    });
  },
  
  removeAllChildrenOf : function(link) {
    var subIds = $A(link.parentNode.getElementsByTagName('a')).map( function(el) { 
      return el.id; 
    });
    
    new Ajax.Request('/close/' + link.id, { method:'post', parameters : {inc : subIds}});
    
    $A(link.parentNode.getElementsByTagName('ul')).each( function(sibling) {
    	Element.hide(sibling);
    });
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
      var extras = { inc : ListM.getNestedIdentifiers(link)};
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
    
    new Ajax.Request(link.href, { method:'get', parameters: params,
      onSuccess: function(transport){
        var li = link.parentNode;
        var list = document.createElement('ul');
        li.appendChild(list);
        Element.hide(list);
        
        list.innerHTML = transport.responseText;
        $A(list.getElementsByTagName("a")).each(function(sub) {
          ListM.attachEventsTo(sub);
          if(inclusive)  $(sub).addClassName("all");
        });
        ListM.expand(link, inclusive);
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
      var childIds = ListM.getNestedIdentifiers(link);
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
    } catch(e) {}
  }  	
};

window.onload = function() {
  ListM.attachEvents();
}