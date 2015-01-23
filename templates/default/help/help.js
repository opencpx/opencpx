// File with functions specific to the help section.

/*
    validateSearch

    Used to check the search query string.
*/
function validateSearch ( t, help_search_query_required, help_search_query_too_short, help_search_query_invalid )
{
    if ( ! t.value.length )
    {
        alert( help_search_query_required );
        return false;
    }
    else if ( t.value.length < 3 )
    {
        alert( help_search_query_too_short );
        return false;
    }  

    return true;
}

var windowprops = "width=800,height=500,location=no,toolbar=no,menubar=yes,scrollbars=yes,resizable=yes";
      
function helpWindow (link)  
{     
    var help_window = window.open( link, "Help", windowprops );
    help_window.focus(); 
}     


