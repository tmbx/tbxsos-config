var formHelpLastIdent = "";

function formHelpFindPos(obj)
{
  var curleft = curtop = 0;
  if (obj.offsetParent) {
    curleft = obj.offsetLeft
    curtop = obj.offsetTop
    while (obj = obj.offsetParent) {
      curleft += obj.offsetLeft
      curtop += obj.offsetTop
    }
  }
  return [curleft,curtop];
}
function formHelpGetElementById(objectId)
{
    // cross-browser function to get an object's style object given its id
    if(document.getElementById && document.getElementById(objectId)) {
        // W3C DOM
        return document.getElementById(objectId);
    } else if (document.all && document.all(objectId)) {
        // MSIE 4 DOM
        return document.all(objectId);
    } else if (document.layers && document.layers[objectId]) {
        // NN 4 DOM.. note: this won't find nested layers
        return document.layers[objectId];
    } else {
        return false;
    }
}
function formHelpPopHelp(linkobj,helpident)
{
  // find the help window
  var helpbox = formHelpGetElementById("helpbox");

  if (helpbox.style.visibility == "visible" && formHelpLastIdent == helpident)
  {
    helpbox.style.visibility = "hidden";
    return
  }

  formHelpLastIdent = helpident;

  // hide the help window in case it's open
  helpbox.style.visibility = "hidden";

  // transfer message in the help _window_
  formHelpGetElementById("helpbox_message").innerHTML = formHelpGetElementById(helpident).innerHTML;

  // position help _window_
  helpbox = formHelpGetElementById("helpbox");
  var tmpxy, x, y; // tmpxy was used after having problems with explorer
  tmpxy = formHelpFindPos(linkobj);
  x = tmpxy[0];
  y = tmpxy[1];
  x = x - helpbox.offsetWidth;
  x = x - 15;
  y = y + 30;
  helpbox.style.left = x+"px";
  helpbox.style.top = y+"px";

  // display help _window_
  helpbox.style.visibility = "visible";
}
function formHelpHideHelp()
{
  // hide help _window_
  var helpbox = formHelpGetElementById("helpbox");
  helpbox.style.visibility = "hidden";
}


