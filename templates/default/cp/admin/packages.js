function confirmAction(confirmString, redirectURL)
{
 if (confirm(confirmString)) {
    window.location=redirectURL; 
    /// return false here to prevent href from being followed (BUG08180)
    return false;
  }
  else {
    return false;
  }
}  

 
