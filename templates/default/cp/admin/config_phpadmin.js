// javascript functions specific to the php admin utilities (phpmyadmin, phppgadmin)

function validateSQLPassword(error_password_req,error_password_fmt,error_password_no_match) {

    var new_password = document.forms[0].new_password.value;

    if (new_password == '') {
        alert(error_password_req);
        return false;
    }

    if (new_password.length < 8) {
        alert(error_password_fmt);
        return false;
    }
    if (new_password.search(/([^A-Za-z])+/) < 0) {
        alert(error_password_fmt);
        return false;
    }
    if (new_password.search(/([^0-9])+/) < 0) {
        alert(error_password_fmt);
        return false;
    }

    if (document.forms[0].new_password.value !=  document.forms[0].new_password2.value) {
        alert(error_password_no_match);
        return false;
    }

    document.forms[0].save.value='yes';
    document.forms[0].cancel.value='';
    document.forms[0].submit();

    return true;
}

