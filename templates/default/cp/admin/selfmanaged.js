// javascript functions specific to the switch to self managed utility

function validateSwitchToSelfManaged(error_password_blank,error_password_req,error_password_fmt,error_password_no_match,confirm_message) {

    var old_password = document.forms[0].old_password.value;
    var new_password = document.forms[0].new_password.value;

    if (old_password == '') {
        alert(error_password_blank);
        return false;
    }

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

    if (window.confirm(confirm_message)) {
        document.forms[0].switch.value='yes';
        document.forms[0].submit();
    }
    else {
        return false;
    }

    return true;
}

