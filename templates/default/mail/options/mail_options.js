// javascript specific to the mail options sections

function getRadioSelection(group)
{
    for (var i=0; i<group.length; i++) {
        if (group[i].checked) {
            return(group[i].value);
        }
    }
    return('');
}

function validate_autoreply(alertMsg)
{
    var text = document.forms[0].textareaName.value;
    var group = document.forms[0].groupAutoreply;

    if (getRadioSelection(group) == "on" && text == "") {
        // Make sure a message has been specified
        alert (alertMsg);
        return false;
    }
    else {
        document.forms[0].save_autoreply.value = 'yes';
        document.forms[0].submit();
    }
    return true;
}
 
function validate_forward(alertMsg)
{
    var text = document.forms[0].textareaName.value;
    var group = document.forms[0].groupForward;

    text = text.replace(/^\s+|\s+$/, '');

    if (getRadioSelection(group) == "on" && text == "") {
        // Make sure a forwarding address has been specified
        alert (alertMsg);
        return false;
    }
    else {
        document.forms[0].save_forward.value = 'yes';
        document.forms[0].submit();
    }
    return true;
}

function visibility_autoreply()
{
    var group = document.forms[0].groupAutoreply;
    var igroup = document.forms[0].interval;

    // update cached copy of form values
    document.forms[0].autoreply_message.value = document.forms[0].textareaName.value;
    document.forms[0].autoreply_replyto.value = document.forms[0].replyto.value;
    document.forms[0].autoreply_subject.value = document.forms[0].subject.value;
    document.forms[0].autoreply_encoding.value = document.forms[0].encoding.value;
    document.forms[0].autoreply_interval.value = getRadioSelection(igroup);

    // disable or enable form widgets
    if (getRadioSelection(group) == "on") {
        document.forms[0].textareaName.disabled = false;
        document.forms[0].replyto.disabled = false;
        document.forms[0].subject.disabled = false;
        document.forms[0].encoding.disabled = false;
        for (i=0; i<document.forms[0].interval.length; i++) {
          document.forms[0].interval[i].disabled = false;
        }
    }
    else {
        document.forms[0].textareaName.disabled = true;
        document.forms[0].replyto.disabled = true;
        document.forms[0].subject.disabled = true;
        document.forms[0].encoding.disabled = true;
        for (i=0; i<document.forms[0].interval.length; i++) {
          document.forms[0].interval[i].disabled = true;
        }
    }
}

function visibility_forward()
{
    var group = document.forms[0].groupForward;

    // update cached copy of form values
    document.forms[0].forward_address.value = document.forms[0].textareaName.value;
    if (document.forms[0].save_copy.checked) {
        document.forms[0].forward_save_copy.value = "on";
    }
    else {
        document.forms[0].forward_save_copy.value = "off";
    }

    // disable or enable form widgets
    if (getRadioSelection(group) == "on") {
        document.forms[0].textareaName.disabled = false;
        document.forms[0].save_copy.disabled = false;
    }
    else {
        document.forms[0].textareaName.disabled = true;
        document.forms[0].save_copy.disabled = true;
        document.forms[0].save_copy.checked = false;
        document.forms[0].forward_save_copy.value = "off";
    }
}

