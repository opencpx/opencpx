function confirmAction(confirmString, redirectURL)
{
 if(confirm(confirmString))
  {window.location=redirectURL}
 else
  {return false;}
}  


function submitItems(alertString, formItemToCheck, confirmString, actionType)
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

function doSubmit(actionType)
{
 document.forms[0].action.value = actionType;
 document.forms[0].submit();
 return false; 
}

 
