// javascript functions specific to the webdav config 

function toggleEditUserFormVisibility() {

    var userList = document.forms[0].user_list;

    var selectedUser = '';
    var selectedCount = 0;
    for (var i = 0; i < userList.options.length; i++) {
        if (userList.options[i].selected) {
            selectedCount++;
            selectedUser = userList.options[i].value;
        }
    }

    if (selectedUser == '__EMPTY') {
        document.getElementById("webdavEditForm").style.display = 'none';
        document.forms[0].edit_user.value = '';
        return false;
    }

    if (selectedCount == '1') {
        document.getElementById("webdavEditForm").style.display = '';
        document.forms[0].edit_user.value = selectedUser;
    }
    else {
        document.getElementById("webdavEditForm").style.display = 'none';
        document.forms[0].edit_user.value = '';
    }
}



function validateWebDavUser( error_login_req, error_login_fmt_chars, error_login_fmt_start, error_password_req, error_password_fmt, error_password_no_match, is_edit ) {
  var login;
  var password;
  var confirm_password;
  
  if( is_edit ) {
    login = $('input[name=edit_user]').val();
    password = $('input[name=edit_password]').val();
    confirm_password = $('input[name=edit_confirm_password]').val();
  }
  else {
    login = $('input[name=add_user]').val();
    password = $('input[name=add_password]').val();
    confirm_password = $('input[name=add_confirm_password]').val();
    
    if ( login == '' ) {
      alert( error_login_req );
      return false;
    }
    
    if( login.match( /[^a-z0-9_\.\-]/ ) ) {
      alert( error_login_fmt_chars );
      return false;
    }
      
      if( login.match( /^[^a-z0-9_]/ ) ) {
        alert( error_login_fmt_start );
        return false;
      }
  }
  
  if( password == '' ) {
    alert( error_password_req );
    return false;
  }
  
  if( password.length < 8 ) {
    alert( error_password_fmt );
    return false;
  }
  
  if( password.search( /([^A-Za-z])+/) < 0 ) {
    alert( error_password_fmt );
    return false;
  }
  
  if( password.search( /([^0-9])+/ ) < 0 ) {
    alert( error_password_fmt );
    return false;
  }
  
  if( password == login ) {
    alert( error_password_fmt );
    return false;
  }

  if( password != confirm_password ) {
    alert( error_password_no_match );
    return false;
  }
    
  if( is_edit ) {
    $('input[name=editUser]').val('yes');
    $('input[name=addUser]').val('');
    $('input[name=removeUser]').val('');
  }
  else {
    $('input[name=editUser]').val('');
    $('input[name=addUser]').val('yes');
    $('input[name=removeUser]').val('');
  }

  document.forms[0].submit();
  
  return true;
}




