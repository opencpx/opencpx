/* ALL FUNCTIONS!!  This will contain all javascript functions used by the Control Panel */

//
//  global used to track which message to display for help
//
var help_state = false;
//
//  help_info
//
//     JavaScript function to toggle whether to show message requesting more help
//     or the contents of the help message.
//     The function also changes the 'arrow' image next to the message.
//
//   Input:
//    help_img_short   The collapsed help image.
//    help_img_long    The expanded help image (displayed when the user requests more help)
//
//    The help_img_short should be shown by default when the page is initially loaded.
//
function help_info(help_img_long,help_img_short) {
  var help_text_node = document.getElementById("addl_help_text");
  var image_node = document.getElementById("addl_help_image");

  var help_short_node = document.getElementById("help_short");
  var help_long_node = document.getElementById("help_long");

  if (help_state) {
    help_text_node.innerHTML = help_short_node.innerHTML;
    image_node.src = help_img_short;
    help_state = false;
  }
  else {
    help_text_node.innerHTML = help_long_node.innerHTML;
    image_node.src = help_img_long;
    help_state = true;
  }
}

//
// submitCheck
//
//   Function for form validation/submition. Checks to make sure a given form
//   value is not blank, or a checkbox list has at least one box selected.
//
//   Input:
//     alertString      Message for alert box if formItemToCheck is blank
//     formItemToCheck  Form item (or checkbox group) to check
//     targetItem       Item to set to targetValue if formItemToCheck is not blank
//     targetValue      Value to set targetItem to
//     confirmString    (optional) If givin, this string will pop up before the form is
//                        submited ("Are you sure you want to delete...")
//
function submitCheck(alertString, formItemToCheck, targetItem, targetValue, confirmString) {
  if (document.forms[0].elements[formItemToCheck].length == 0) {
    return false;
  }
  else if (countChecks(formItemToCheck) == 0) {
    alert(alertString);
  }
  else {
    if (confirmString) {
      if(confirm(confirmString)) {
        document.forms[0].elements[targetItem].value = targetValue;
      }
      else {
        return false;
      }
    }
    document.forms[0].elements[targetItem].value = targetValue;
    document.forms[0].submit();
  }
}

//
// countChekcs
//
//   Helper function for submitCheck. Makes sure formItemToCheck is not blank.
//
function countChecks(formItemToCheck) {
  var checks = 0;
  var itemToCheck = document.forms[0].elements[formItemToCheck];
  if (itemToCheck) {
    if (itemToCheck.length) {
      for (i = 0; i < itemToCheck.length; i++) {
        if (itemToCheck[i].checked) {
          checks++;
        }
      }
    }
    else {
      if (itemToCheck.checked) {
        checks++;
      }
    }
  }
  return checks;
}

// for checking & unchecking flags of a particular field (helpful in the mail, file, and user sections)
var checkflag = 'false';
function check(field) {
  if (field) {
    if (checkflag == 'false') {
      field.checked=true;
      for(i = 0; i < field.length; i++) {
        field[i].checked = true;
      }
      checkflag='true';
    }
    else {
      field.checked=false;
      for(i = 0; i < field.length; i++) {
        field[i].checked = false;
      }
      checkflag='false';
    }
  }
}

function restartApache(message, url) {
  if (document.all) {
     var xMax = screen.width, yMax = screen.height;
  }
  else {
     if (document.layers) {
       var xMax = window.outerWidth, yMax = window.outerHeight;
     }
     else {
       var xMax = 640, yMax=480;
     }
  }
  var xOffset = (xMax + 100), yOffset = (yMax + 100);
  var myRestartWindow = window.open(url, 'restart',
        "width=1,height=1,screenX="+xOffset+",screenY="+yOffset+",top="+xOffset+",left="+yOffset+"");
  window.alert(message);
  myRestartWindow.close();
}

function submitButton(type, field, confirmstring, alertstring, numChecks) {
  var showAlert = 0;

  if (numChecks > 1) {
    for (i = 0; i < numChecks; i++) {
      if (document.forms[0].cbUserID[i].checked == false) {
        showAlert++;
      }
    }
  }
  else if (numChecks == 1) {
    if (document.forms[0].cbUserID.checked == false) {
      showAlert++;
    }
  }

  if (showAlert == numChecks) {
    alert(alertstring);
  }
  else {
    if (confirm(confirmstring)) {
      document.forms[0].confirmdelete.value = "yes";
      document.forms[0].submit();
    }
  }
}

var windowname = "maincp";
function showAddress() {
    filename = "wm_select-addressee.xsl";
    filetitle = "SelectRecipient";
    window.name = windowname;

    if (document.all)
     var xMax = screen.width, yMax = screen.height;
    else
     if (document.layers)
       var xMax = window.outerWidth, yMax = window.outerHeight;
     else
       var xMax = 640, yMax=480;

    var xOffset = (xMax - 380)/2, yOffset = (yMax - 300)/2;

    var myConfirmWindow = window.open(filename, filetitle,
        "scrollbars=yes,resizable=yes,width=530,height=400,screenX="+xOffset+",screenY="+yOffset+",top="+xOffset+",left="+yOffset+"");

    if (myConfirmWindow.opener == null)
      myConfirmWindow.opener = self;
    return false;
}

function closeAddress() {
  // fill in the selected addresses in the to, cc, and bcc fields in the parent window.
  var i = 0;
  var tos = 0;
  var tostring = "";
  var ccs = 0;
  var ccstring = "";
  var bccs = 0;
  var bccstring = "";

  if (document.forms[0].to != null) {
    if (document.forms[0].to.length == null) {
      if ((document.forms[0].to) && (document.forms[0].to.checked)){
        tostring += document.forms[0].to.value;
        tos = 1;
      }
      if ((document.forms[0].cc) && (document.forms[0].cc.checked)) {
        ccstring += document.forms[0].cc.value;
        ccs = 1;
      }
      if ((document.forms[0].bcc) && (document.forms[0].bcc.checked)) {
        bccstring += document.forms[0].bcc.value;
        bccs = 1;
      }
    }

    for (i = 0; i <= document.forms[0].to.length; i++) {
      if ((document.forms[0].to[i]) && (document.forms[0].to[i].checked)) {
        // add a comma if you're at the second or more 'to' address or if there's already text in the "to" text field
        if (tos >= 1) {
          tostring += ", " + document.forms[0].to[i].value;
        }
        else {
          tostring += document.forms[0].to[i].value;
        }
        tos++;
      }

      if ((document.forms[0].cc[i]) && (document.forms[0].cc[i].checked)) {
        // add a comma if you're at the second or more 'cc' address or if there's already text in the "cc" text field
        if (ccs >= 1) {
          ccstring += ", " + document.forms[0].cc[i].value;
        }
        else {
          ccstring += document.forms[0].cc[i].value;
        }
        ccs++;
      }

      if ((document.forms[0].bcc[i]) && (document.forms[0].bcc[i].checked)) {
        // add a comma if you're at the second or more 'bcc' address or if there's already text in the "bcc" text field
        if (bccs >= 1) {
          bccstring += ", " + document.forms[0].bcc[i].value;
        }
        else {
          bccstring += document.forms[0].bcc[i].value;
        }
        bccs++;
      }
    }

    var epat = /^\s*$/;

    if (tostring != "") {
      var text = window.opener.document.forms[0].txtToName.value;
      if (text.match(epat)) {
        window.opener.document.forms[0].txtToName.value += tostring;
      }
      else {
        window.opener.document.forms[0].txtToName.value += ", " + tostring;
      }
    }

    if (ccstring != "") {
      var text = window.opener.document.forms[0].txtCcName.value;
      if (text.match(epat)) {
        window.opener.document.forms[0].txtCcName.value += ccstring;
      }
      else {
        window.opener.document.forms[0].txtCcName.value += ", " + ccstring;
      }
    }

    if (bccstring != "") {
      var text = window.opener.document.forms[0].txtBccName.value;
      if (text.match(epat)) {
        window.opener.document.forms[0].txtBccName.value += bccstring;
      }
      else {
        window.opener.document.forms[0].txtBccName.value += ", " + bccstring;
      }
    }
  }
  window.close();
}

function help_window(type) {
    if (document.all)
     var xMax = screen.width, yMax = screen.height;
    else
     if (document.layers)
       var xMax = window.outerWidth, yMax = window.outerHeight;
     else
       var xMax = 640, yMax=480;
    var xOffset = (xMax - 380)/2, yOffset = (yMax - 300)/2;
    var helpWindow = window.open("/ControlPanel/cp/help/index.xsl?lang=" + type,
      "helpwin",
      "scrollbars=yes,resizable=yes,width=530,height=400,screenX="+xOffset+",screenY="+yOffset+",top="+xOffset+",left="+yOffset);
}

function new_help_window(category, topic) {
    if (document.all)
     var xMax = screen.width, yMax = screen.height;
    else
     if (document.layers)
       var xMax = window.outerWidth, yMax = window.outerHeight;
     else
       var xMax = 640, yMax=480;

    var xOffset = (xMax - 380)/2, yOffset = (yMax - 300)/2;

    var windowprops = "scrollbars=yes,resizable=yes,width=1024,height=500,screenX="+xOffset+",screenY="+yOffset+",top="+xOffset+",left="+yOffset;

    var help_window = window.open( "/ControlPanel/help/index.xsl?category="+category+"&topic="+topic, "helpwin", windowprops );

    help_window.focus();
}

function showDirectoryDialog() {
    var filename = "/ControlPanel/cp/files/dirdialog.xsl?path=";
    filename += window.document.forms[0].target.value;
    if ((window.document.forms[0].target_user) && (window.document.forms[0].target_user.value)) {
      filename += "&target_user=";
      filename += window.document.forms[0].target_user.value;
    }
    var filetitle = "SelectDirectory";
    window.name = windowname;

    var myConfirmWindow = window.open(filename, filetitle,"scrollbars=yes,resizable=yes,width=240,height=440,screenX=30,screenY=30,top=30,left=30");

    if (myConfirmWindow.opener == null)
      myConfirmWindow.opener = self;
    return false;
}

function closeDirectoryDialog() {

  window.opener.document.forms[0].target.value = window.document.forms[0].selectedPath.value;
  if (window.opener.document.forms[0].target_user)
    window.opener.document.forms[0].target_user.value = window.document.forms[0].target_user.value;
  window.close();

}

function setTextAreaCursor(textAreaElement)
{
    if (textAreaElement.setSelectionRange) {
        textAreaElement.focus();
        textAreaElement.setSelectionRange(0, 0);
    }
    else if (textAreaElement.createTextRange) {
        var range = textAreaElement.createTextRange();
        range.moveStart('character', 0);
        range.select();
    }
}

function setTextAreaWrap(SelectControl, TextAreaControl)
{
    TextAreaControl.wrap = SelectControl.options(SelectControl.selectedIndex).value;
}

// used by file manager edit contents
function setTemplate(SelectControl, TextAreaControl, messageString, confirmString)
{
  if (SelectControl.value == '') {
    if (confirm(confirmString))
      TextAreaControl.value = '';
  }
  else {
    if (TextAreaControl.value == '')
      TextAreaControl.value = SelectControl.options[SelectControl.selectedIndex].value;
    else
      alert(messageString);
  }
}

// used by file manager upload file
function removeSingleFileUpload(url)
{
  if (document.getElementById('overwrite').checked)
    url += '&overwrite=true';
  window.location.href = url;
}

function validateField(messageString, field)
{
 if(field.value != '')
  return true;

  alert(messageString);
  return false;
}

function validateRenameNewNameField(messageString, field)
{
  if (field.value.indexOf('/') == -1)
    return true;

  alert(messageString);
  return false;
}

function changeUser()
{
  document.forms[0].action.value="changeUser";
  document.forms[0].submit();
}

// for checking & unchecking flags of a particular field (helpful in the mail, file, and user sections)
var checkflag = 'false';
function check2(field, checked) {
  if (field) {
    field.checked = checked;
    for(i = 0; i < field.length; i++) {
        field[i].checked = checked;
    }
  }
}

/*
Start Menu Collapse
*/

if (window.jQuery)
{
  window.Menu = function ()
  {
    var thisMenu = this;
    thisMenu.containerId = '';
    thisMenu.saveKey = '';
    thisMenu.saveArray = [];
    
    var del = '|';
    var showStr = 's';
    var hideStr = 'h';
    var container = null;
    var headerRows = null;
    var arrowDownClass = 'arrowDown';
    var arrowSideClass = 'arrowSide';
    
    thisMenu.showSideClass = function (obj)
  	{
      $('img', obj).attr('src', '/cpimages/arrowSide.gif');
    };
    
    thisMenu.showDownClass = function (obj)
    {
		  $('img', obj).attr('src', '/cpimages/arrowDown.gif');
    };
    
    thisMenu.toggle = function ()
    {
      var jThis = $(this);
      var obj = $('~ tr', this);
      var isVisible = obj.is(':visible');
      if (isVisible)
      {
        obj.hide();
        thisMenu.showSideClass(jThis);
      }
      else
      {
        obj.show();
        thisMenu.showDownClass(jThis);
      }
      thisMenu.saveState();
    };
    
    thisMenu.populateSaveElement = function (index)
    {
      var obj = $('~ tr', this);
      var isVisible = obj.is(':visible');
      var state = hideStr ;
      if (isVisible)
      {
        state = showStr;
      }
      thisMenu.saveArray[index] = state;
    };
    
    thisMenu.saveState = function ()
    {
      headerRows.each(thisMenu.populateSaveElement);
      var value = thisMenu.saveArray.join(del);
      value = encodeURI(value);
      var days = 7;
      var date = new Date();
      date.setTime(date.getTime() + (days * 24 * 60 * 60 * 1000));
      var expires = "; expires = " + date.toGMTString();
      document.cookie = thisMenu.saveKey + "=" + value + expires + "; path=/";
    };
    
    thisMenu.loadState = function ()
    {
      var i = 0;
      var cookieNameArray = [];
      var cookieName = '';
      var cookieValue = '';
      if (document.cookie)
      {
        cookieNameArray = document.cookie.split('; ');
        for (i = 0; i < cookieNameArray.length; i += 1)
        {
          cookieName = cookieNameArray[i];
          if (cookieName.indexOf(thisMenu.saveKey) === 0)
          {
            cookieValue = cookieName.substring(thisMenu.saveKey.length + 1);
            cookieValue = decodeURI(cookieValue);
            thisMenu.saveArray = cookieValue.split(del);
          }
        }
      }
    };
    
    thisMenu.hideAll = function ()
    {
      $('~ tr', headerRows).hide();
      thisMenu.showSideClass(headerRows);
    };
    
    thisMenu.showState = function (index)
    {
      var saveArray = thisMenu.saveArray;
      var jThis = $(this);
      if (saveArray.length > index)
      {
        if (saveArray[index] === showStr)
        {
          $('~ tr', this).show();
          thisMenu.showDownClass(jThis);
        }
      }
    };
    
    thisMenu.showActive = function ()
    {
      var activeRow = $('tr.active', container);
      $('~ tr', activeRow).show();
      thisMenu.showDownClass(activeRow);
    };
    
    thisMenu.init = function (paramObject)
    {
      thisMenu.containerId = paramObject.containerId;
      thisMenu.saveKey = paramObject.saveKey;
      
      container = $('#' + thisMenu.containerId);
      headerRows = $('tr.title', container);
      //
      // $('td', headerRows).append('<img src="/cpimages/arrowSide.gif" class="menuArrowImage"  >');
      //
      // In order to make the customer navigation menu function properly, needed to  
      // leave out the custom navigation header row (tr) from the selection when
      // adding the arrow graphic, and set the custom 'headerRow' on its own.
      var notCustomHeaderRows = headerRows.not("#titleCustomSideNavTR");
      $('td', notCustomHeaderRows).append('<img src="/cpimages/arrowSide.gif" class="menuArrowImage"  >');
      $('#titleCustomSideNav', container).append('<img src="/cpimages/arrowSide.gif" class="menuArrowImage"  >');
    
      thisMenu.hideAll();
      thisMenu.showActive();
      thisMenu.loadState();
      headerRows.each(thisMenu.showState);
      headerRows.click(thisMenu.toggle);
    };
  };
  
  window.Menu.initMenu = function ()
  {
    var paramObject = {
      'containerId': 'navbgcontrolpanel',
      'saveKey': 'menuState'
    };
    
    var menu = new window.Menu();
    menu.init(paramObject);
    
    paramObject = {
      'containerId': 'navbgmail',
      'saveKey': 'emailMenuState'
    };
    
    var emailMenu = new window.Menu();
    emailMenu.init(paramObject);
  };
  
  $(document).ready(window.Menu.initMenu);
}

/*
End Menu Collapse
*/

