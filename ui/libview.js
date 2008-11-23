/* List manager for a simple tree view. Here is how to organize the elements for it to work

  <ul>
    <li><a href="url-to-load-list-content">Click me</a></li>
    <li><a href="url-to-load-second-list-content">Click me too </a></li>
  </ul>

When the first link is clicked, the following will happen:
1) The browser will go to the URL in the href of this first link and load the content of the 
   list below (only LI elements without the wrapper)
2) An empty UL element will be created under the first LI element (next to the first link)
   and the fetched elements will be put into that UL element
3) The UL element will be inserted after the link, and the link class will change to "open"
4) After the sublist is preloaded, it will no longer touch the server

*/
ListM = Class.create({
  initialize : function(linkSelector) {
    this.linkSelector = linkSelector;
    this.attachEvents();
  },
  
  // Handle expand/collapse event
  handleClick : function(evt) {
    Event.stop(evt);
    // go up the event chain until we find the link
    var elem = Event.element(evt);
    var link = (elem.nodeName == 'A' ? elem : elem.parentNode);

    this.handleExpandCollapse(link, evt);
    this.handlePostClick(link, evt);
    return false;
  },
  
  // What should happen after click
  handlePostClick : function(link, evt) {
    
  },
  
  // Handle expand-collapse after the element has been determined.
  // Shift+click will be treated as "go to this link directly"
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
    var dbl = this.handleClick;
    
    // Observe single click on the expansion triangle only
    // The second one should come last because of the way IE bubbles
    Event.observe(link.getElementsByTagName("b")[0], 'click', clk.bindAsEventListener(this));
    Event.observe(link, 'click', function(e){ Event.stop(e); });
    
    // Observe touch and double clock on the whole link
    Event.observe(link, 'dblclick', dbl.bindAsEventListener(this));
  },

  // Attach events to the elements selected by the constructor selector
  // TODO - scan the doc starting from the root node
  attachEvents : function() {
    $$(this.linkSelector).each(this.attachEventsTo, this);
  },
  
  // Remove all child lists of this link
  removeAllChildrenOf : function(link) {
    $A(link.parentNode.getElementsByTagName('ul')).each(Element.remove);
  },
  
  // Is the link in the expanded state?
  isExpanded : function(link) {
    return $(link).classNames().include('open');
  },

  // Is the child content of the link preloaded?
  isPreloaded : function(link) {
    return $(link).classNames().include("all");
  },

  // Collapse the element but do not remove the nodes.
  // If the second passed argument is true, also collapse everything underneath
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

  // Load the content bound to this link. With second argument set to true
  // will also load and expand all of the child nodes
  loadContentOf : function(link, inclusive) {
    var params = {bare : 1}
    if (inclusive) params.inc = 1;
    var me = this;
    
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
  
  // Get the IDs of all the child links of this one, so that a list of
  // elements that are open/closed can be sent to the server
  getNestedIdentifiers : function(link) {
    return $A(link.parentNode.getElementsByTagName("a")).map(function(child) {
      return child.id;
    });
  },
  
  // Expand the link. Will add the class "open" to the class list of the link itself
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