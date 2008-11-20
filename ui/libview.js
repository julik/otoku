function attachLinkCallbacks() {
  $$("a.hd").each(function(link) {
    link.onclick = function(e) {
      // If the list is already loaded
      if (link.parentNode.getElementsByTagName("ul").length > 0) {
        if ($(link).classNames() == 'hd open') {
          $(link).removeClassName("open");
          Element.hide($(link.parentNode.getElementsByTagName("ul")[0]));
        } else {
          $(link).addClassName("open");
          Element.show($(link.parentNode.getElementsByTagName("ul")[0]));
        }
      } else {
        new Ajax.Request(link.href, { method:'get', parameters: {"bare":"1"},
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
      link.focus();
      Event.stop(e);
    }
    
    
  link.ondblclick = link.onclick;
    
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