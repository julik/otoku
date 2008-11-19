function attachLinkCallbacks() {
  $$("a.hd").each(function(link) {
    link.onclick = function() {
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
      return false;
    }
  });
}
window.onload = function() {
  attachLinkCallbacks();
}