// Setup event handlers for password fields.
function formSubmitPasswordHandlers( error_password_req, error_password_fmt, error_password_no_match ) {

  // "new_password" text field keydown handler.
  $('input[name=new_password],input[name=new_password2]').keydown( function(e) {
  
    var k = e.keyCode || e.which;
  
    if ( k == 13 ) {
      if ( validateSQLPassword( error_password_req, error_password_fmt, error_password_no_match ) ) {
        $("input[name=btn_save]").click();
      }
      else {
        e.preventDefault();
      }
    }
  
  });

}


  
function formSubmitAccessListHandlers( allowFromEmpty, allowFromInvalid ) {

  // 'allow_from' text field keydown handler.
  $('input[name=allow_from]').keydown( function(e) {
  
    var k = e.keyCode || e.which;
  
    if ( k == 13 ) {
      if ( checkAllowFrom( allowFromEmpty, allowFromInvalid ) ) {
        $('input[name=add]').click();
      }
      else {
        e.preventDefault();
      }
    }
  });

}



// Check for valid values in the 'allow_from' text field.
function checkAllowFrom( allowFromEmpty, allowFromInvalid ) {
  var fqdn = /(?=^.{1,254}$)(^(?:(?!\d+\.)[a-zA-Z0-9\-]{1,63}\.)+(?:[a-zA-Z]{2,})$)/;
  var ip = /^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/;
  
  if ( ! $('input[name=allow_from]').val() ) {
    alert( allowFromEmpty );
    return false;
  }
  else if ( fqdn.test( $('input[name=allow_from]').val() ) || ip.test( $('input[name=allow_from]').val() ) ) {
    return true;
  }
  else {
    alert( allowFromInvalid );
    return false;
  }
}



// Setup WebDAV event handlers.
function submitWebDavUser( error_login_req, error_login_fmt_chars, error_login_fmt_start, error_password_req, error_password_fmt, error_password_no_match ) {

  $('input[name=add_user],input[name=add_password],input[name=add_confirm_password]').keydown( function(e) {
  
    var k = e.keyCode || e.which;
  
    if ( k == 13 ) {
      validateWebDavUser( error_login_req, error_login_fmt_chars, error_login_fmt_start, error_password_req, error_password_fmt, error_password_no_match, 0 );
    }
  
  });


  $('input[name=edit_password],input[name=edit_confirm_password]').keydown( function(e) {

    var k = e.keyCode || e.which;
  
    if ( k == 13 ) {
      validateWebDavUser( error_login_req, error_login_fmt_chars, error_login_fmt_start, error_password_req, error_password_fmt, error_password_no_match, 1 );
    }
  
  });

}




