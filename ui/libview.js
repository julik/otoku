function attachLinkCallbacks() {
  $$("a.hd").each(function(link) {
    link.onclick = function(e) {
      // If the list is already loaded
      if (link.parentNode.getElementsByTagName("ul").length > 0) {
        if ($(link).classNames() == 'hd open') {
          $(link).removeClassName("open");
          Element.hide($(link.parentNode.getElementsByTagName("ul")[0]));
          if(e.altKey) {
            // collect all child nodes
            var closes = $A(link.parentNode.getElementsByTagName("a")).map(function(sibAndChild) {
              $(sibAndChild).removeClassName("open");
              Element.hide(sibAndChild.parentNode.getElementsByTagName("ul")[0]);
              return sibAndChild.id;
            });
            new Ajax.Request('/close/' + link.id, { method:'post', parameters : {inclusive : closes}});
          } else {
            new Ajax.Request('/close/' + link.id, { method:'post'});
          }
        } else {
          $(link).addClassName("open");
          Element.show($(link.parentNode.getElementsByTagName("ul")[0]));
          new Ajax.Request('/open/' + link.id, { method:'post'});
        }
      } else {
        var params = { bare : 1}
        if (e.altKey) {
          params.inc = 1;
        }
        
        new Ajax.Request(link.href, { method:'get', parameters: params,
          onSuccess: function(transport){
            var li = link.parentNode;
            var list = document.createElement('ul');
            li.appendChild(list);
            list.innerHTML = transport.responseText;
            $(link).addClassName("open");
            attachLinkCallbacks();
          }
        });
      }
      Event.stop(e);
    }
    
    
//  link.ondblclick = link.onclick;
    
  $$("li.Clip").each(function(clipNode) {
      clipNode.onclick = function(evt) {
//        window.ObjectSelections.handleNode(clipNode, evt.shiftKey);
        Event.stop(evt);
      }
    });
  });
}
window.onload = function() {
  attachLinkCallbacks();
}