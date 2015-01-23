function validateTaskOutputOptions (error_msg_mailto_email_required, error_msg_mailto_bad_email_address)
{
  var mailto = document.forms[0].txtMailTo.value.toLowerCase();

  if ( document.forms[0].taskOptions[1].checked ) {
    if ( mailto == '' ) {
      alert(error_msg_mailto_email_required);
      return false;
    }
    if ( /@/.test(mailto) ) {
      if (validate_email_addr(mailto)) {
        alert(error_msg_mailto_bad_email_address);
        return false;
      }
    }
    else {
    }
  }

  return true;
}

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

 
