// If the custom navigation frame is loaded, it uses the query string to get
// a label to look up a URL value from an array that is build into the custom_frame.xsl
// page.
function loadCustomFrame() {
  var dls = document.location.search;

  if ( dls ) {

    // Should be a label to look up. Only grabbing first key=val.
    var qString = {};
    
    dls.replace(
      new RegExp("([^?=&]+)(=([^&]*))?", "g"),
      function($0, $1, $2, $3) { qString[$1] = $3; }
    );
    
    var label = qString['label'];
    if ( customFrameLabels[ label ] ) {
      document.getElementById('custom_content_frame').src = customFrameLabels[ label ];
    }
    else {
      var dLoc = document.location;
      document.getElementById('custom_content_frame').src = dLoc.host + '/ControlPanel' + '/error/404.xsl';
    }

    makeActive(label);
  }
}



// If the custom navigation/iframe is present, just load the passed url (and query),
// otherwise call the custom_frame.xsl along with the label in order to look up the URL.
function customNav( baseUrl, label, location, query ) {
  if ( document.getElementById('custom_content_frame') ) {
    document.getElementById('custom_content_frame').src = location + "/" + query;
  }
  else {
    document.location = baseUrl + '/cp/custom_frame.xsl?label=' + label;
  }

  makeActive(label);
}



function makeActive( label ) {
  var menuItem = 'custNav_' + label;

  $('[id^=custNav_]').removeClass( 'custSideNavLabelOn' );
  $('[id^=custNav_]').addClass( 'custSideNavLabelOff' );
  $('#' + menuItem).removeClass( 'custSideNavLabelOff' );
  $('#' + menuItem).addClass( 'custSideNavLabelOn' );
}

