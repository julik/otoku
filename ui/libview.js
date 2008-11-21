// List manager - just a function store
ListM = {
  handleClick : function(evt) {
    var link = Event.element(evt);
    
    // Treat shift+click as Focus
    if(evt.shiftKey) {
      return true;
    } else if(evt.altKey) {
      ListM.removeAllChildrenOf(link);
      if (ListM.isExpanded(link)) {
        ListM.collapse(link)
      } else {
        ListM.loadContentOf(link, {inc : 1});
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
    Event.stop(evt);
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
    	Element.remove(sibling);
    });
  },
  
  isExpanded : function(link) {
    return ($(link).classNames() == 'hd open');
  },
  
  collapse : function(link) {
    $(link).removeClassName("open");
    Element.hide($(link.parentNode.getElementsByTagName("ul")[0]));
    new Ajax.Request('/close/' + link.id, { method:'post'});
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
        });
        ListM.expand(link);
      }
    });
  },
  
  expand : function(link) {
    $(link).addClassName("open");
    new Ajax.Request('/open/' + link.id, { method:'post'});
    
    try {
      Element.show($(link).parentNode.getElementsByTagName("ul")[0]);
    } catch(e) {}
  }  	
};

window.onload = function() {
  ListM.attachEvents();
}