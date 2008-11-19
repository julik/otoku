function attachLinkCallbacks() {
  $$("b.disc").each(function(disclosureButn) {
    var link = disclosureButn.parentNode;
    
    disclosureButn.onclick = function(e) {
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
      Event.stop(e);
    }
    
    link.onclick = function(evt) {
      window.ObjectSelections.handleNode(link, evt.shiftKey);
      Event.stop(evt);
    }
    
    $$("li.clip").each(function(clipNode) {
      clipNode.onclick = function(evt) {
        if (evt.shiftKey) {
         alert("shifet"); 
        }
        window.ObjectSelections.handleNode(link, evt.shiftKey);
        Event.stop(evt);
      }
    });
  });
}
window.onload = function() {
  attachLinkCallbacks();
}

SelectedObject = new Object({type: "None", id: "None", uri: "None"});

ObjectSelections = new Object();
ObjectSelections.selected = {};
ObjectSelections.handleNode = function(node, inclusive) {
  var cont = new Object();
  // Make an object that contains the selection
  cont.id = node.id
  cont.uri = node.uri
  cont.type = node.className;
  
  // If shift is pressed AND this object already was selected - remove
  // elsif shift pressed AND this object was NOT selected - select it TOO
  // else select this object ONLY
  
  if (inclusive) {
    // if already selected - deselect
    if (this.selected[cont.id]) {
      this.selected[cont.id] = null;
      this.unmarkSelected(node);
    } else {
      this.selected[this.selected.id] = cont;
      this.markSelected(node);
    }
  } else {
    // if already selected - deselect
    if (this.selected[cont.id]) {
      this.selected = {}
      this.unmarkSelected(node);
    } else {
      this.selected = {}
      this.selected[this.selected.id] = cont;
      this.markSelected(node);
    }
  }
  alert(Object.keys(this.selected));
}

ObjectSelections.markSelected = function(node) {
  $(node).addClassName("sel");
}

ObjectSelections.unmarkSelected = function(node) {
  $(node).removeClassName("sel");
}