// File with functions specific to the file manager section.

function doSubmit(actionType, currentDir, currentUser, currentItem, refPage, sortBy, sortType, showHidden, senderData)
{
 document.forms[0].actionType.value = actionType;
 if (currentDir) document.forms[0].currentDir.value = unescape(currentDir);
 if (currentUser) document.forms[0].currentUser.value = currentUser;
 if (currentItem) document.forms[0].currentItem.value = unescape(currentItem);
 if (refPage) document.forms[0].refPage.value = refPage;
 if (sortBy) document.forms[0].sortBy.value = sortBy;
 if (sortType) document.forms[0].sortType.value = sortType;
 if (showHidden) document.forms[0].showHidden.value = showHidden;
 if (senderData) document.forms[0].senderData.value = unescape(senderData);
 document.forms[0].submit();
 return false; 
}

function submitFiles(alertString, formItemToCheck, confirmString, actionType)
{
 if(document.forms[0].elements[formItemToCheck].length == 0)
  {return false;}
 else 
  if (countChecks(formItemToCheck) == 0)
   {alert(alertString);}
  else 
  {
   if (confirmString)
   {
    if(confirm(confirmString))
     {doSubmit(actionType);}
    else
     {return false;}
   }  
   doSubmit(actionType);
  }
}
 
function uncheckFiles(field) {
  if (field) {
    field.checked=false;
    for(i = 0; i < field.length; i++) {
      field[i].checked = false;
    }
  }
}

