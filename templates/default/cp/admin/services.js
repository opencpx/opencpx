// javascript functions specific to service (and application) management

function confirmAction(confirmString, redirectURL)
{
  if (confirm(confirmString)) {
    window.location = redirectURL;
  }
  else {
    return false;
  }
}  

