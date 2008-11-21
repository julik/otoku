// List manager - just a function store
ListM = {
  handleClick : function(evt) {
    var link = Event.element(evt);
    Event.stop(evt);
    
    // Treat shift+click as Focus
    if(evt.shiftKey) {
      return true;
    } else if(evt.altKey) {
      if (ListM.isExpanded(link)) {
        ListM.collapse(link, true);
      } else {
        ListM.isPreloaded(link) ? ListM.expand(link, true) : ListM.loadContentOf(link, true);
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
    return false;
  },
  
  linkPreloaded : function(link) {
    return (link.parentNode.getElementsByTagName("ul").length > 0);
  },

  attachEventTo : function(link) {
    Event.observe(link, 'click', ListM.handleClick.bindAsEventListener(this));
  },
    
  attachEvents : function() {
    $$("a.hd").each(function(link) {
      ListM.attachEventTo(link);
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
          ListM.attachEventTo(sub);
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
    $(link).addClassName("open");
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
        Element.show($(link).parentNode.getElementsByTagName("ul")[0]);
      }
    } catch(e) {}
  }  	
};

window.onload = function() {
  ListM.attachEvents();
}