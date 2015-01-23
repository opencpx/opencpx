// File with functions specific to the mail section.

//
// submitMoveMail
//
//   Function for move message action on wm_messages.xsl. Checks to make sure 
//   a dest folder has been chosen and that at least one message is selected.
//
//   Input:
//     no_msg_msg     Alert message to show if no messages have been selected
//     no_folder_msg  Alert message to show if no folder has been selected
//
function submitMoveMail(no_msg_msg, no_folder_msg) {
  if (document.forms[0].dest_folder[0].value == "") {
    // Make sure a folder to move the messages to has been selected
    alert (no_folder_msg);
    return false;
  }

  if (no_msg_msg == 0) {
    // Skip checkbox checking if we are on the view page
    document.forms[0].elements["move"].value = "yes";
    document.forms[0].submit();
  } else {
    submitCheck(no_msg_msg, "uid", "move", "yes");
  }  
}

// for keeping the two select boxes at the top & bottom of the screen in the webmail box contents view synchronized.
var orig_select = 0;
function syncselects() {
  var sync_select0 = document.forms[0].dest_folder[0];
  var sync_select1 = document.forms[0].dest_folder[1];
  var index;

  if (orig_select == sync_select0.selectedIndex) {
    index = sync_select1.selectedIndex;
    orig_select = index;
    sync_select0.selectedIndex = index;
  } else {
    index = sync_select0.selectedIndex;
    orig_select = index;
    sync_select1.selectedIndex = index;
  }
}

function verifyAddFolder(type,alertMsg,alertBadFolderName) {
  if(document.forms[0].newfolder.value == '') {
	alert(alertMsg);
	return false;
  }
  
  var folder = document.forms[0].newfolder.value;

  if(!validateFolder(folder)) {
	alert(alertBadFolderName);
	return false;
  }

  if(type == 'save') {
	document.forms[0].save_folder.value = 'yes';
  }
  if(type == 'another') {
	document.forms[0].save_another.value = 'yes';
  }
  document.forms[0].submit();
  return true;
}

function verifySubscribeFolder(type,alertMsg,alertBadFolderName) {
  if(document.forms[0].newfolder.value == '') {
	alert(alertMsg);
	return false;
  }
  
  var folder = document.forms[0].newfolder.value;

  if(!validateFolder(folder)) {
	alert(alertBadFolderName);
	return false;
  }

  if(type == 'subscribe') {
	document.forms[0].subscribe_folder.value = 'yes';
  }
  if(type == 'another') {
	document.forms[0].subscribe_another.value = 'yes';
  }
  document.forms[0].submit();
  return true;
}

function encodeRE(regex) { 
}

function validateFolder (folder) {

  // minimum illegal charset per IMAP RFC: '\(){%*]"' and CTRL
  // expanded illegal charset per DRD: '\(){}%*[]"?$#&|'
  //
  // note: CTRL chars are checked for in VSAP modules

  if (folder.match(/[\\(){}%*[\]"?$#&|]/)) {
     return false;
  }
  return true;
}

function verifyRenameFolder(alertMsg,alertBadFolderName) {
  if(document.forms[0].newfolder.value == '') {
	alert(alertMsg);
	return false;
  }

  var folder = document.forms[0].newfolder.value;

  if(!validateFolder(folder)) {
        alert(alertBadFolderName);
        return false;
  }

  document.forms[0].save_rename.value = 'yes';
  document.forms[0].submit();
  return true;
}

var remote=null;
function newWindow(n,u,w,h,x) {
//  args="width="+w+",height="+h+",resizable=yes,scrollbars=auto,status=1";
  args="width="+w+",height="+h+",resizable=yes,scrollbars=yes,status=1,location=1";
  remote=window.open(u,n,args);
  if (remote!= null) {
    if (remote.opener == null)
      remote.opener = self;
 } 
  remote.moveTo(400,10);
  if (x == 1) { return remote; }    
  
}

var attachWindow=null;

function ScriptAttach() {
  window_path = '/ControlPanel/mail/wm_add-edit-attachment.xsl?nothing=true';

  document.forms[0].noconfirm.value="yes";
  window_path += '&messageid=' + document.forms[0].messageid.value
  
  attachWindow=newWindow('attachments',window_path,550,500,1);
  attachWindow.focus();
  document.forms[0].noconfirm.value="";
}   

function verifyCompose(alertText) {	
	if(document.forms[0].txtToName.value.length==0) {
		alert(alertText);
		document.forms[0].txtToName.focus();
		return false;
	} else {
		document.forms[0].noconfirm.value='yes';
		document.forms[0].save_send.value='yes';
		document.forms[0].submit();
	}
}

function composeCheck(showDiag) {
        if((document.forms[0].noconfirm.value=='no') &&
	  ((document.forms[0].txtToName.value.length!=0) || 
	   (document.forms[0].subject.value.length!=0) || 
	   (document.forms[0].body.value.length!=0))) {
		event.returnValue = showDiag;
	} else {
		document.forms[0].submit();
	} 
}

function addRemoveSig(alertText) {
  var form = document.forms[0];
  var signature = form.signature.value;
  var message = form.body;
  var reWhitespace = /^\s+$/;
  var ie = (navigator.appVersion.indexOf('MSIE') != -1);

  if (form.checkboxSig.checked) {
    // Adding signature
    // check that a signature exists
    if (reWhitespace.test(signature)) {
      alert(alertText);
      form.checkboxSig.checked = false;
    } else {
      // make sure there are at least two newlines at the end of the message
      if(ie == false) {
		if (message.value.charAt(message.value.length - 1) != "\n") {
			message.value = message.value + "\n";
		}
		if (message.value.charAt(message.value.length - 2) != "\n") {
			message.value = message.value + "\n";
		}
      } else {
		if (message.value.substr(message.value.length - 2,2) != "\r\n") {
			message.value = message.value + "\r\n";
		}
		if (message.value.substr(message.value.length - 4,2) != "\r\n") {
			message.value = message.value + "\r\n";
		}
      }
      message.value = message.value + signature;
      message.focus();
    }
  } else {
    // Removing signature
    var new_message = message.value;
    var chk_sig = signature;
    if(ie == false) {
	chk_sig = chk_sig.replace(/\r\n/g,"\n");
    }
    chk_match = new_message.lastIndexOf(chk_sig);
    if(chk_match != -1) {
	new_message = new_message.substring(0,chk_match);
    }
    message.value = new_message;
    message.focus();
  }

  return true;
}  

function RecordAttachments(noAttachments) {


  var attachString = "";

    if(document.specialwindow.filename) {
     if(document.specialwindow.filename.type == 'hidden') {
         attachString = document.specialwindow.filename.value;
     } 
     if(document.specialwindow.filename.type != 'hidden') {
      for (i = 0; i < 5; i++) {
        if (document.specialwindow.filename[i]) {
	  if(attachString != '') {
		attachString += "; ";
	  }
          attachString += document.specialwindow.filename[i].value;
        }
       }
     }
    }

  if(attachString == '') {
    attachString = noAttachments;
  }

  if (document.specialwindow.messageid) {
    if (document.specialwindow.messageid.value) {
      window.opener.document.forms[0].attachments_display.value = attachString;
    }
  }
}

function unsubscribeButton(type, field, confirmstring, alertstring, numChecks) {
  var showAlert = 0;
    
  if (numChecks > 1) {
    for (i = 0; i < numChecks; i++) {
      if (document.forms[0].cbUserID[i].checked == false) {
        showAlert++;
      }
    }
  } else if (numChecks == 1) {
    if (document.forms[0].cbUserID.checked == false) {
      showAlert++;
    }
  }

  if (showAlert == numChecks) {
    alert(alertstring);
  } else {
    if (confirm(confirmstring)) {
      document.forms[0].confirmunsubscribe.value = "yes";
      document.forms[0].submit();
    }
  }
}

