// javascript functions specific to the config file utilities

function confirmAction(confirmString, redirectURL)
{
    if (confirm(confirmString)) {
        window.location = redirectURL;
    }
    else {
        return false;
    }
}

function discardConfigConfirm(discardString)
{
    if (document.forms[0].contents.value == document.forms[0].original.value) {
        // no changes
        return true;
    }
    else {
        if (confirm(discardString)) {
            // discard changes
            return true;
        }
        else {
            // cancel
            return false;
        }
    }
}

function validateConfigSettings(error_password_fmt,error_password_no_match,no_changes_alert,save_backup_alert) {

    var password = document.forms[0].new_password.value;

    if (password != '') {
        if (password.length < 8) {
            alert(error_password_fmt);
            return false;
        }
        if (password.search(/([^A-Za-z])+/) < 0) {
            alert(error_password_fmt);
            return false;
        }
        if (password.search(/([^0-9])+/) < 0) {
            alert(error_password_fmt);
            return false;
        }
    }

    if (document.forms[0].new_password.value !=  document.forms[0].new_password2.value) {
        alert(error_password_no_match);
        return false;
    }

    if ( document.forms[0].contents.value == document.forms[0].original.value ) {
        if ( password == '' ) {
            window.alert(no_changes_alert);
            return false;
        }
        else {
            document.forms[0].save.value='';
            document.forms[0].submit();
        }
    }
    else {
        window.alert(save_backup_alert);
        document.forms[0].save.value='yes';
        document.forms[0].cancel.value='';
        document.forms[0].recover.value='';
        document.forms[0].original.value='';
        document.forms[0].submit();
    }

    return true;
}

function showEditConfigAlert(no_changes_alert, save_backup_alert)
{
    if (document.forms[0].contents.value == document.forms[0].original.value) {
        window.alert(no_changes_alert);
        return false;
    }
    else {
        window.alert(save_backup_alert);
        document.forms[0].save.value='yes';
        document.forms[0].cancel.value='';
        document.forms[0].recover.value='';
        document.forms[0].original.value='';
        document.forms[0].submit();
    }
    return true;
}

