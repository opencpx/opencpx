// File with functions specific to the cp section.

// ///////////////////////////////////////////////////////////////////////////
//
// validate_domain
//
//  Function to check a domain name string for syntax validity
//
//  Args:
//  domain      Domain name string to check
//
function validate_domain(domain)
{
    if ( ( /^[a-zA-Z0-9]+[a-zA-Z0-9\-\.]+\.[a-zA-Z0-9]+$/.test(domain) ) ||
         ( /\.\./.test(domain) ) ||
         ( /\.-/.test(domain) ) ||
         ( /-\./.test(domain) ) ) {
        return false;
    }

    return true;
}

// ///////////////////////////////////////////////////////////////////////////
//
// validate_email_addr
//
//  Function to check an email address  string for syntax validity
//  (must be fqdn to pass)
//
//  Args:
//  email       Email address string to check
//
function validate_email_addr (email)
{
    //
    // HIC-607 requires that hyphen not be the first character due to issues with
    // Postfix. Removed hyphen as a valid first character.
    //
    // HIC-879 OCN wants hyphen back. (Postfix has a config setting to allow.)
    //
    // HIC-917 It was decided to once again remove the leading hyphen, and to never,
    //         ever, ever, ever, ever, ever, never, ever, never, allow it back.
    //

    if ( /^[\w!$%&'*+/=?^_`{|}~](\.|[\w!$%&'*+/=?^_`{|}~-])+(\.[\w!#$%&'*+/=?^_`{|}~-]+)*@\w+((\.|-+)?\w)*\.\w+$/.test(email) ) {
        return false;
    }

    return true;
}

// ///////////////////////////////////////////////////////////////////////////
//
// validate_flexible_email_addr
//
//  Function to check an email address  string for syntax validity
//  (not required to be fqdn to pass)
//
//  Input:
//  email       Email address string to check
//
function validate_flexible_email_addr (email)
{
    if ( ( /^[\w%]+([\.-]?\w)*@\w+([\.-]?\w)*\.\w+$/.test(email) ) ||
         ( /^[\w%]+([\.-]?\w)*$/.test(email) ) ) {
        return false;
    }

    return true;
}

// ///////////////////////////////////////////////////////////////////////////
//
// disenable
//
//  Function to toggle the "disabled" attribute of a form element using a checkbox
//
//  Input:
//  chkBox          Checkbox that controls the disabled attribute of "elementName"
//  elementName     Name of form element to be enabled or disabled
//
function disenable(chkBox, elementName)
{
    if (chkBox.checked) {
        document.forms[0].elements[elementName].disabled = false;
    }
    else {
        document.forms[0].elements[elementName].disabled = true;
    }
}

// ///////////////////////////////////////////////////////////////////////////
//
// switchRotationSwitches
//
//  Function to toggle the log rotation options in domain_add/edit and user_add_domain
//
//  Input:
//  chkSwitch   Either 'yes' (enable radio) or 'no' (disable radio)
//
function switchRotationSwitches(chkSwitch)
{
    if (chkSwitch.value == 'no') {
        document.forms[0].log_rotate_select[0].disabled = 'disabled';
        document.forms[0].log_rotate_select[1].disabled = 'disabled';
        document.forms[0].log_rotate.disabled = 'disabled';
        document.forms[0].log_save.disabled = 'disabled';
    }
    else {
        document.forms[0].log_rotate_select[0].disabled = '';
        document.forms[0].log_rotate_select[1].disabled = '';
        document.forms[0].log_rotate.disabled = '';
        document.forms[0].log_save.disabled = '';
    }
    return false;
}

// ///////////////////////////////////////////////////////////////////////////
//
// populateDomainContact
//
//  Function to populate the domain contact name in the domain_add_setup app
//
//  Input:
//  domain      The name of the domain entered
//
function populateDomainContact(domain)
{
    var domain_contact = "";
    var strDomain = document.forms[0].domain.value.toLowerCase();

    strDomain = (strDomain.replace(/^\W+/,'')).replace(/\W+$/,'');
    // HIC-635 - allow www.some.dom
    //strDomain = strDomain.replace(/^www\./,'');
    domain = strDomain;

    if (domain) {
      domain_contact = "root@" + domain;
    }
    else {
      domain_contact = "root@ (prepopulates domain once added)";
    }
    document.forms[0].domain_contact.value = domain_contact;
}

// ///////////////////////////////////////////////////////////////////////////
//
// validateDomain
//
//  Function to validate add_domain_setup and edit_domain field input
//
//  Input:
//  error_null_domain             Error message to display if field is null
//  error_invalid_domain          Error message to display if domain format invalid
//  error_null_eus                Error message to display if null for end users selected
//  error_fmt_eus                 Error message to display if max end-users < 0
//  error_null_ems                Error message to display if null for email addrs selected
//  error_fmt_ems                 Error message to display if max email addrs < 0
//  error_null_contact            Error message to display if field is null
//  error_invalid_contact         Error message to display if email address format invalid
//  error_null_catchall           Error message to display if 'Deliver mail to' is null
//  error_invalid_catchall        Error message to display if mail catchall email address format invalid
//  error_invalid_domain_alias    Error message to display if domain "other aliases" invalid
//
function validateDomain(error_null_domain,error_invalid_domain,error_null_eus,error_fmt_eus,error_null_ems,error_fmt_ems,error_null_contact,error_invalid_contact,error_null_catchall,error_invalid_catchall,error_invalid_domain_alias)
{
    var strDomain = document.forms[0].domain.value.toLowerCase();
    var aliasCb = document.getElementById('www_alias');

    // HIC-635 - allow www.some.dom, so only strip www if alias checkbox was checked.
    if ( aliasCb.checked == true ) {
        strDomain = (strDomain.replace(/^\W+/,'')).replace(/\W+$/,'');
        strDomain = strDomain.replace(/^www\./,'');
        document.forms[0].domain.value = strDomain;
    }

    if ( document.forms[0].domain.value == '' ) {
        alert(error_null_domain);
        return false;
    }
    if ( validate_domain(document.forms[0].domain.value) ) {
        alert(error_invalid_domain);
        return false;

    }
    if ( document.forms[0].other_aliases.value != '' ) {
        var otherAliases = document.forms[0].other_aliases.value.toLowerCase();
        otherAliases = (otherAliases.replace(/^\W+/,'')).replace(/\W+$/,'');
        document.forms[0].other_aliases.value = otherAliases;
        var domainAliasList = otherAliases.split(",");
        for ( index=0; index < domainAliasList.length; index++ ) {
            domainAlias = domainAliasList[index];
            domainAlias = (domainAlias.replace(/^\W+/,'')).replace(/\W+$/,'');
            if ( validate_domain(domainAlias) ) {
                alert(error_invalid_domain_alias);
                return false;
            }
        }
    }

    if ( document.forms[0].end_users[0].checked ) {
        if ( document.forms[0].end_users_limit.value == '' ) {
                alert(error_null_eus);
                return false;
        }
        var validate_number = document.forms[0].end_users_limit.value;
        if ( validate_number.match(/\D/) ) {
            alert(error_fmt_eus);
            return false;
        }
    }

    if ( document.forms[0].email_addr[0].checked ) {
        if ( document.forms[0].email_addr_limit.value == '' ) {
            alert(error_null_ems);
            return false;
        }
        var validate_number = document.forms[0].email_addr_limit.value;
        if ( validate_number.match(/\D/) ) {
            alert(error_fmt_ems);
            return false;
        }
    }

    if ( document.forms[0].domain_contact.value == '') {
        alert(error_null_contact);
        return false;
    }
    if ( validate_email_addr(document.forms[0].domain_contact.value) ) {
        alert(error_invalid_contact);
        return false;
    }

    if ( document.forms[0].mail_catchall[3].checked ) {
        if ( document.forms[0].mail_catchall_custom.value == '' ) {
            alert(error_null_catchall);
            return false;
        }
        var emailAddresses = document.forms[0].mail_catchall_custom.value.toLowerCase();
        emailAddresses = (emailAddresses.replace(/^\s+/,'')).replace(/\s+$/,'');
        document.forms[0].mail_catchall_custom.value = emailAddresses;
        var emailAddressList = emailAddresses.split(",");
        for ( index=0; index < emailAddressList.length; index++ ) {
            emailAddress = emailAddressList[index];
            emailAddress = (emailAddress.replace(/^\s+/,'')).replace(/\s+$/,'');
            if ( validate_flexible_email_addr(emailAddress) ) {
                alert(error_invalid_catchall);
                return false;
            }
        }
    }
    document.forms[0].next.value = 1;
    document.forms[0].submit();
    return false;
}

// ///////////////////////////////////////////////////////////////////////////
//
// validateDomainEdit
//
//   Function to validate add_domain_setup and edit_domain field input
//
//   Input:
//     error_null_eus                        Error message to display if null for end users selected
//     error_fmt_eus                        Error message to display if max end users < 0
//     error_null_ems                        Error message to display if null for email addrs selected
//     error_fmt_ems                        Error message to display if max email addrs < 0
//     error_null_contact                Error message to display if field is null
//     error_invalid_contact                Error message to display if email address format invalid
//     error_invalid_domain        Error message to display if domain invalid
//     error_null_catchall                Error message to display if 'Deliver mail to' is null
//     error_invalid_catchall                Error message to display if mail catchall email address format invalid
//     error_invalid_domain_alias        Error message to display if domain "other aliases" invalid
//
function validateDomainEdit(src,error_null_eus,error_fmt_eus,error_null_ems,error_fmt_ems,error_null_contact,error_invalid_contact,error_invalid_domain,error_null_catchall,error_invalid_catchall,error_invalid_domain_alias) {

        if(src == 'useradd' || src == 'domaineditsa') {
                if(document.forms[0].end_users[0].checked) {
                        if(document.forms[0].end_users_limit.value == '') {
                                alert(error_null_eus);
                                return false;
                        }
                        var validate_number = document.forms[0].end_users_limit.value;
                        if(validate_number.match(/\D/)) {
                                alert(error_fmt_eus);
                                return false;
                        }
                }

                if(document.forms[0].email_addr[0].checked) {
                        if(document.forms[0].email_addr_limit.value == '') {
                                alert(error_null_ems);
                                return false;
                        }
                        var validate_number = document.forms[0].email_addr_limit.value;
                        if(validate_number.match(/\D/)) {
                                alert(error_fmt_ems);
                                return false;
                        }
                }
        }

        if(document.forms[0].other_aliases.value != '') {
                var otherAliases = document.forms[0].other_aliases.value.toLowerCase();
                otherAliases = (otherAliases.replace(/^\W+/,'')).replace(/\W+$/,'');
                document.forms[0].other_aliases.value = otherAliases;
                var domainAliasList = otherAliases.split(",");
                for(index=0; index < domainAliasList.length; index++) {
                        domainAlias = domainAliasList[index];
                        domainAlias = (domainAlias.replace(/^\W+/,'')).replace(/\W+$/,'');
                        if(validate_domain(domainAlias)) {
                                alert(error_invalid_domain_alias);
                                return false;
                        }
                }
        }
        if(document.forms[0].domain_contact.value == '') {
                alert(error_null_contact);
                return false;
        }

        if(validate_email_addr(document.forms[0].domain_contact.value)) {
                alert(error_invalid_contact);
                return false;
        }

        if(document.forms[0].mail_catchall[3].checked) {
                if(document.forms[0].mail_catchall_custom.value == '') {
                        alert(error_null_catchall);
                        return false;
                }
                var emailAddresses = $( "[name=mail_catchall_custom]" ).val();
                emailAddresses = (emailAddresses.replace(/^\s+/,'')).replace(/\s+$/,'');
                $( "[name=mail_catchall_custom]" ).val( emailAddresses );
                var emailAddressList = emailAddresses.split(",");
                for(index=0; index < emailAddressList.length; index++) {
                        emailAddress = emailAddressList[index];
                        emailAddress = (emailAddress.replace(/^\s+/,'')).replace(/\s+$/,'');
                        if(validate_flexible_email_addr(emailAddress)) {
                                alert(error_invalid_catchall);
                                return false;
                        }
                }
        }
        document.forms[0].save.value = 1;
        document.forms[0].submit();
        return false;
}

// ///////////////////////////////////////////////////////////////////////////
//
// validate_profile
//
//   Function to validate user_add_eu_profile and user_edit_eu_profile field input
//
//   Input:
//     error_fullname_req                Error message to display if null fullname
//     error_fullname_fmt_chars                Error message to display if fullname contains an invalid character
//     error_loginid_req                Error message to display if null login id
//     error_loginid_fmt_chars                Error message to display if login id contains an invalid character
//     error_loginid_fmt_start                Error message to display if login id does not start with valid character
//     error_password_req                Error message to display if null password
//     error_password_fmt                Error message to display if password not 8 characters with non-alpha character
//     error_password_login_match        Error message to display if password and login match
//     error_password_no_match                Error message to display if password not equal to confirm password
//     error_quota_req                        Error message to display if null quota
//     error_quota_fmt                        Error message to display if quota not integer >= 0
//     warning_quota_zero                Warning message to display if quota == 0
//     error_quota_exceeded                Error message to display if quota > admin quota
//     error_missing_dap                 Error message to display if no da privileges
//     error_missing_eup                 Error message to display if no eu privileges
//     error_domain_req                        Error message to display if null domain
//     error_domain_fmt                        Error message to display if domain in bad format
//     error_euprefix_fmt_chars                Error message to display if eu prefix contains an invalid character
//     error_euprefix_fmt_start                Error message to display if eu prefix does not start with valid character
//     err_email_bad_prefix       Error message to display if invalid email prefix
//     err_user_max               Error message to display if max users has been reached
//     err_user_email_max         Error message to display if max email has been reached
//
function validate_profile(error_fullname_req,error_fullname_fmt_chars,error_loginid_req,error_loginid_fmt_chars,error_loginid_fmt_start,error_password_req,error_password_fmt,error_password_login_match,error_password_no_match,error_quota_req,error_quota_fmt,warning_quota_zero,error_quota_exceeded,error_missing_dap,error_missing_eup,error_domain_req,error_domain_fmt,error_euprefix_fmt_chars,error_euprefix_fmt_start,err_email_bad_prefix,err_user_max,err_user_email_max) {

  var source = document.forms[0].source.value;
  var type = document.forms[0].type.value;

  if(document.forms[0].txtFullName.value == '') {
    alert(error_fullname_req);
    return false;
  }
  var fullname = document.forms[0].txtFullName.value;
  if(fullname.match(/[\:\,\=\"]/)) {
    alert(error_fullname_fmt_chars);
    return false;
  }
  var password = document.forms[0].txtPassword.value;
  if(source == 'add') {
    var strLoginID = document.forms[0].txtLoginID.value;
    strLoginID = (strLoginID.replace(/^\s+/,'')).replace(/\s+$/,'');
    document.forms[0].txtLoginID.value = strLoginID;
    if(document.forms[0].txtLoginID.value == '') {
      alert(error_loginid_req);
      return false;
    }
    var loginid = document.forms[0].txtLoginID.value;
    if(loginid.match(/[^a-z0-9_\.\-]/)) {
      alert(error_loginid_fmt_chars);
      return false;
    }
    if(loginid.match(/^[^a-z0-9_]/)) {
      alert(error_loginid_fmt_start);
      return false;
    }
    if(type != 'eu' && type != 'ma') {
      var strEUP = document.forms[0].eu_prefix.value;
      if(strEUP != '') {
        strEUP = (strEUP.replace(/^\s+/,'')).replace(/\s+$/,'');
        document.forms[0].eu_prefix.value = strEUP;
        var euprefix = document.forms[0].eu_prefix.value;
        if(euprefix.match(/[^a-z0-9_\.\-]/)) {
          alert(error_euprefix_fmt_chars);
          return false;
        }
        if(euprefix.match(/^[^a-z0-9_]/)) {
          alert(error_euprefix_fmt_start);
          return false;
        }
      }
    }
    if(document.forms[0].txtPassword.value == '') {
      alert(error_password_req);
      return false;
    }
    if(password.length < 8) {
      alert(error_password_fmt);
      return false;
    }
    if(password.search(/([^A-Za-z])+/) < 0) {
      alert(error_password_fmt);
      return false;
    }
    if(password.search(/([^0-9])+/) < 0) {
      alert(error_password_fmt);
      return false;
    }
    if(password.search(/([^\x00-\x80])+/) >= 0) {
      alert(error_password_fmt);
      return false;
    }
    if(document.forms[0].txtPassword.value == document.forms[0].txtLoginID.value) {
      alert(error_password_login_match);
      return false;
    }
    if(document.forms[0].txtPassword.value != document.forms[0].txtConfirmPassword.value) {
      alert(error_password_no_match);
      return false;
    }
  }
  if(source == 'edit') {
    if(type != 'eu' && type != 'ma') {
      var strEUP = document.forms[0].eu_prefix.value;
      if(strEUP != '') {
        strEUP = (strEUP.replace(/^\s+/,'')).replace(/\s+$/,'');
        document.forms[0].eu_prefix.value = strEUP;
        var euprefix = document.forms[0].eu_prefix.value;
        if(euprefix.match(/[^a-z0-9_\.\-]/)) {
          alert(error_euprefix_fmt_chars);
          return false;
        }
        if(euprefix.match(/^[^a-z0-9_]/)) {
          alert(error_euprefix_fmt_start);
          return false;
        }
      }
    }
    if ( password == '' && $('input[name="txtConfirmPassword"]').val() != '' ) {
      alert( error_password_no_match );
      return false;
    }
    if ( password != '' ) {
      if ( password.length < 8 ) {
        alert( error_password_fmt );
        return false;
      }
      if ( password.search(/([^A-Za-z])+/) < 0 ) {
        alert( error_password_fmt );
        return false;
      }
      if ( password.search(/([^0-9])+/) < 0 ) {
        alert( error_password_fmt );
        return false;
      }
      if ( password.search(/([^\x00-\x80])+/) >= 0 ) {
        alert( error_password_fmt );
        return false;
      }
      if ( document.forms[0].txtPassword.value ==  document.forms[0].login_id.value ) {
        alert( error_password_login_match );
        return false;
      }
      if ( document.forms[0].txtPassword.value !=  document.forms[0].txtConfirmPassword.value ) {
        alert( error_password_no_match );
        return false;
      }
    }
  }
  if(document.forms[0].txtQuota.value == '') {
    alert(error_quota_req);
    return false;
  }
  var quota = document.forms[0].txtQuota.value;
  if(!quota.match(/^(0|[1-9]+[0-9]*)$/)) {
    alert(error_quota_fmt);
    return false;
  }
  if(quota == '0') {
    if ( type == 'da') {
      alert(error_quota_req);
      return false;
    }
    if( type == 'eu' || type == 'ma') {
      if(!confirm(warning_quota_zero)) {
        return false;
      }
    }
  }
  if(source != 'edit') {
    var max_space = Math.round(document.forms[0].max_space.value);
    if(quota > max_space) {
      alert(error_quota_exceeded);
      return false;
    }
  }

  if(type == 'da') {
    if((!document.forms[0].checkboxUserMail.checked) &&
      (!document.forms[0].checkboxUserFtp.checked) &&
      (!document.forms[0].checkboxUserFM.checked) &&
      (!document.forms[0].checkboxUserPC.checked) &&
      (!document.forms[0].checkboxUserShell.checked)) {
        alert(error_missing_dap);
        return false;
    }
  }
  if(type == 'eu' || type == 'ma') {
    var mail_ok = document.forms[0].eu_capa_mail.value;
    var ftp_ok = document.forms[0].eu_capa_ftp.value;
    var fm_ok = document.forms[0].eu_capa_fm.value;
    var shell_ok = document.forms[0].eu_capa_shell.value;

    var valid_eup = 0;

    // HIC-815 - Need to check for a valid email if the mail privelege has been checked.
    if ( source == 'edit' ) {
      var eAddr = $("input[name='login_id']").val() + '@' + $("select[name='domain']").val();

      //
      // HIC-917 It was decided to once again remove the leading hyphen, and to never,
      //         ever, ever, ever, ever, ever, never, ever, never, allow it back.
      //
      var emailRegex = /^[\w!$%&'*+/=?^_`{|}~]\.?[\w!$%&'*+/=?^_`{|}~-]+(\.[\w!#$%&'*+/=?^_`{|}~-]+)*@\w+((\.|-+)?\w)*\.\w+$/;

      if ( $("input[name='mail_service_exists']").val() == 0 && mail_ok && $("#usermail").is(':checked') ) {
        if ( ! emailRegex.test( eAddr ) ) {
          $("#usermail").removeAttr("checked");
          alert( err_email_bad_prefix + ' (' + $("input[name='login_id']").val() + ')');
          return false;
        }
      }
    }
    // End HIC-815 check.

    if(mail_ok == 1 && document.forms[0].checkboxUserMail.checked) {
      valid_eup = 1;
    }
    else if(type == 'ma' && mail_ok == 1 && document.forms[0].checkboxUserMail.value=='true') {
      valid_eup = 1;
    }
    else if(mail_ok != 1 && typeof document.forms[0].checkboxUserMail!='undefined') {
      if(document.forms[0].checkboxUserMail.checked) {
        valid_eup = 1;
      }
      else if (document.forms[0].checkboxUserMail.value=='true') {
        valid_eup = 1;
      }
    }
                if(ftp_ok == 1 && document.forms[0].checkboxUserFtp.checked) {
                        valid_eup = 1;
                }
    else if(ftp_ok != 1 && typeof document.forms[0].checkboxUserFtp!='undefined') {
      if(document.forms[0].checkboxUserFtp.checked) {
        valid_eup = 1;
      }
      else if (document.forms[0].checkboxUserFtp.value='true') {
        valid_eup = 1;
      }
    }
    if(fm_ok == 1 && document.forms[0].checkboxUserFM.checked) {
      valid_eup = 1;
    }
    else if(fm_ok != 1 && typeof document.forms[0].checkboxUserFM!='undefined') {
      if(document.forms[0].checkboxUserFM.checked) {
        valid_eup = 1;
      }
      else if (document.forms[0].checkboxUserFM.value='true') {
        valid_eup = 1;
      }
    }
                if(shell_ok == 1 && document.forms[0].checkboxUserShell.checked) {
                        valid_eup = 1;
                }
    else if(shell_ok != 1 && typeof document.forms[0].checkboxUserShell!='undefined') {
      if(document.forms[0].checkboxUserShell.checked) {
        valid_eup = 1;
      }
      else if (document.forms[0].checkboxUserShell.value='true') {
        valid_eup = 1;
      }
    }
    if(!valid_eup) {
      alert(error_missing_eup);
      return false;
    }
  }

  if ( type == 'da' ) {
    var noChecked = true;

    if ( ( document.forms[0].checkboxEndUserMail.checked ) ||
         ( document.forms[0].checkboxEndUserFtp.checked  ) ||
         ( document.forms[0].checkboxEndUserFM.checked   ) )
    {
        noChecked = false;
    }

    if ( noChecked && document.forms[0].checkboxEndUserShell && document.forms[0].checkboxEndUserShell.checked ) {
        noChecked = false;
    }

    if ( noChecked ) {
      alert(error_missing_eup);
      return false;
    }

  }

  if(type == 'da' && source == 'add') {
    if(document.forms[0].txtDomain.value == '') {
                        alert(error_domain_req);
                        return false;
                }
                var strDomain = document.forms[0].txtDomain.value.toLowerCase();

                strDomain = (strDomain.replace(/^\W+/,'')).replace(/\W+$/,'');
          // HIC-635 - allow www.some.dom
                //strDomain = strDomain.replace(/^www\./,'');
                document.forms[0].txtDomain.value = strDomain;
                if(validate_domain(document.forms[0].txtDomain.value)) {
                        alert(error_domain_fmt);
                        return false;
                }
        }
  if((type == 'eu' || type == 'ma') && source == 'add') {
                if(document.forms[0].selectName.value == '') {
                        alert(error_domain_req);
                        return false;
                }
        }

        if(source == 'add') {
                document.forms[0].mail_next.value = 1;
        }
  else {
                document.forms[0].save.value = 1;
        }

  if ( source == 'add' && document.forms[0].selectName ) {
    var idx = document.forms[0].selectName.selectedIndex;
    var user_add_ok = window.user_add_ok_array[idx];
    var email_add_ok = window.email_add_ok_array[idx];

    if ( user_add_ok <= 0 ) {
      alert( err_user_max );
      return false;
    }
    else {
      if ( email_add_ok <= 0 ) {
        alert( err_user_email_max );
        return false;
      }
    }
  }

        document.forms[0].submit();
        return false;
}

// ///////////////////////////////////////////////////////////////////////////
//
// validate_mail
//
//   Function to validate user_add_eu_mail and user_edit_eu_mail field input
//
//   Input:
//     error_email_fmt                Error message to display invalid email addr format
//
function validate_mail(error_email_fmt) {
        var source = document.forms[0].source.value;
        var type = document.forms[0].type.value;

        var email_addr = '';
        if(source == 'add') {
                email_addr = document.forms[0].txtAlias.value + '@';
                if(type == 'da') {
                        email_addr = email_addr + document.forms[0].txtDomain.value.toLowerCase();
                }
                else {
                        email_addr = email_addr + document.forms[0].selectName.value;
                }
        }
        else {
                email_addr = document.forms[0].login_id.value + '@' + document.forms[0].domain.value;
        }
        if(validate_email_addr(email_addr)) {
                 alert(error_email_fmt);
                return false;
        }

        if(source == 'add') {
                document.forms[0].preview_next.value = 1;
        }
        else {
                document.forms[0].save.value = 1;
        }
        document.forms[0].submit();
        return false;
}

// ///////////////////////////////////////////////////////////////////////////
//
// setEUCheckbox
//
//   Function to turn on/off checkboxes in the add_user/edit_user apps
//
//   Input:
//     chkbox        The clicked checkbox
//
function setEUCheckbox(chkbox) {

        var admin_type = document.forms[0].type.value;

        if(admin_type != 'sa' && chkbox.name != 'checkboxUserShell') {
                if(chkbox.name == 'checkboxUserMail' && !chkbox.checked) {
                        document.forms[0].checkboxEndUserMail.checked = '';
                        document.forms[0].checkboxEndUserMail.disabled = 'disabled';
                }
                else if(chkbox.name == 'checkboxUserMail' && chkbox.checked) {
                        document.forms[0].checkboxEndUserMail.disabled = '';
                }

                else if(chkbox.name == 'checkboxUserFtp' && !chkbox.checked) {
                        document.forms[0].checkboxEndUserFtp.checked = '';
                        document.forms[0].checkboxEndUserFtp.disabled = 'disabled';
                }
                else if(chkbox.name == 'checkboxUserFtp' && chkbox.checked) {
                        document.forms[0].checkboxEndUserFtp.disabled = '';
                }

                else if(chkbox.name == 'checkboxUserFM' && !chkbox.checked) {
                        document.forms[0].checkboxEndUserFM.checked = '';
                        document.forms[0].checkboxEndUserFM.disabled = 'disabled';
                }
                else if(chkbox.name == 'checkboxUserFM' && chkbox.checked) {
                        document.forms[0].checkboxEndUserFM.disabled = '';
                }

        }

               if(chkbox.name == 'checkboxUserShell' && !chkbox.checked) {
                document.forms[0].selectShell.disabled = 'disabled';
                if(admin_type != 'sa') {
                        document.forms[0].checkboxEndUserShell.checked = '';
                        document.forms[0].checkboxEndUserShell.disabled = 'disabled';
                }
        }
        else if(chkbox.name == 'checkboxUserShell' && chkbox.checked) {
                document.forms[0].selectShell.disabled = '';
                if(admin_type != 'sa') {
                        document.forms[0].checkboxEndUserShell.disabled = '';
                }
        }
}

// ///////////////////////////////////////////////////////////////////////////
//
// setShellCheckbox
//
//   Function to turn on/off the shell privilege/shell name in add_user/edit_user apps (only when adding an end user)
//
//   Input:
//     chkbox        The clicked checkbox
//
function setShellCheckbox(chkbox) {
        if(chkbox.checked) {
                document.forms[0].selectShell.disabled = '';
        }
        else {
                document.forms[0].selectShell.disabled = 'disabled';
        }
}

// ///////////////////////////////////////////////////////////////////////////
//
// validateEmail
//
//   Function to validate added/edited email address
//
//   Input:
//     error_null_email                Error message to display if email address is null
//     error_invalid_email        Error message to display if email address format invalid
//     error_null_email_dlv        Error message to display if delivery email address is null
//     error_invalid_email_dlv        Error message to display if delivery email address format invalid
//     error_add_max_emails     Error message to display if max email has been reached
//
function validateEmail(error_null_email,error_invalid_email,error_null_email_dlv,error_invalid_email_dlv,error_add_max_emails) {

        var action = document.forms[0].action.value;

        if(action != 'edit') {
                var strAddress = document.forms[0].lhs.value;

                // The following replacement is causing "inappropriate characters" from the beginning
                // or end of a proposed username to be ignored.  Since I can't figure out why this is
                // a good idea, I'm commenting it out.  -michael

                //strAddress = (strAddress.replace(/^\W+/,'')).replace(/\W+$/,'');

                if(strAddress == '') {
                              alert(error_null_email);
                        return false;
                }
                document.forms[0].lhs.value = strAddress;
                strEmail = strAddress + '@' + document.forms[0].domain.value;

                if(validate_email_addr(strEmail)) {
                        alert(error_invalid_email);
                        return false;
                }
                var idx = document.forms[0].domain.selectedIndex;
                var email_add_ok = window.email_add_ok_array[idx];
                if(email_add_ok <= 0) {
                        alert(error_add_max_emails);
                        return false;
                }
        }

        if(document.forms[0].delivery[2].checked) {
                if(document.forms[0].local_mailbox.value == '') {
                        alert(error_null_email_dlv);
                        return false;
                }
        }

        if(document.forms[0].delivery[3].checked) {
                if(document.forms[0].address_list.value == '') {
                        alert(error_null_email_dlv);
                        return false;
                }
        }

        document.forms[0].Save.value = 1;
        document.forms[0].submit();
        return false;
}

// ///////////////////////////////////////////////////////////////////////////
//
// switchSystemDisplay
//
//   Function to toggle display of system email addrs in email addresses list
//
//   Input:
//
function switchSystemDisplay() {

        if(document.forms[0].show_system.value == '0') {
                document.forms[0].show_system.value = 'on';
        }
        else {
                document.forms[0].show_system.value = '0';
        }
        document.forms[0].submit();
}

// ///////////////////////////////////////////////////////////////////////////
//
// validatePassword
//
//   Function to validate added/edited password
//
//   Input:
//     error_password_req        Error message to display if password null
//     error_password_fmt        Error message to display if password in bad format
//     error_password_no_match        Error message to display if password != confirm password
//     error_old_password_req        Error message to display if old  password null
//
function validatePassword(error_password_req,error_password_fmt,error_password_no_match,error_old_password_req,error_password_login_match,user_name) {

        var password = document.forms[0].new_password.value;


        if(error_old_password_req) {
                if(document.forms[0].old_password.value == '') {
                        alert(error_old_password_req);
                        return false;
                }
        }
        if(error_password_req) {
                if(password == '') {
                        alert(error_password_req);
                        return false;
                }
                if(password.length < 8) {
                        alert(error_password_fmt);
                        return false;
                }
                if(password.search(/([^A-Za-z])+/) < 0) {
                        alert(error_password_fmt);
                        return false;
                }
                if(password.search(/([^0-9])+/) < 0) {
                        alert(error_password_fmt);
                        return false;
                }
    if(password.search(/([^\x00-\x80])+/) >= 0) {
      alert(error_password_fmt);
      return false;
    }
    if(password == user_name) {
      alert(error_password_login_match);
      return false;
    }

        }
        if(document.forms[0].new_password.value !=  document.forms[0].new_password2.value) {
                alert(error_password_no_match);
                return false;
        }
        document.forms[0].save.value = 'save';
        document.forms[0].submit();
        return false;
}

// ///////////////////////////////////////////////////////////////////////////
//
// switchUsageDisplay
//
//   Function to toggle display of disk usage in domains list
//
//   Input:
//
function switchUsageDisplay() {

        if(document.forms[0].show_usage.value == '1') {
                document.forms[0].show_usage.value = '0';
        }
        else {
                document.forms[0].show_usage.value = '1';
        }
        document.forms[0].submit();
}

// used by file manager change perms
function disenableRecurseX(chkbox) {
  if (chkbox.checked) {
          document.forms[0].recurse_X[0].disabled = false;
          document.forms[0].recurse_X[1].disabled = false;
  }
  else {
          document.forms[0].recurse_X[0].disabled = true;
          document.forms[0].recurse_X[1].disabled = true;
  }
}

// ///////////////////////////////////////////////////////////////////////////
// used by file manager upload progress window
function initProgressRefreshTimeout()
{
    // the timeout value should be the same as in the "refresh" meta-tag
    setTimeout( "refreshProgress()", 2*1000 );
}
function refreshProgress()
{
    window.location.reload(true);
}

// ///////////////////////////////////////////////////////////////////////////
//
// setFirewallSwitches
//
//   Function to turn on/off radio buttons in the firewall app
//
//   Input:
//     chk_switch       The clicked switch
//
function setFirewallSwitches(chk_switch) {

  if (chk_switch.value == '0') {
    document.forms[0].firewall_type[0].disabled = 'disabled';
    document.forms[0].firewall_type[1].disabled = 'disabled';
    document.forms[0].firewall_type[0].checked = 'checked';
  }

  if (chk_switch.value == '1') {
    document.forms[0].firewall_type[0].disabled = 'disabled';
    document.forms[0].firewall_type[1].disabled = 'disabled';
    document.forms[0].firewall_type[0].checked = 'checked';
  }

  if (chk_switch.value == '2') {
    document.forms[0].firewall_type[0].disabled = '';
    document.forms[0].firewall_type[1].disabled = '';
  }

  if (chk_switch.value == '3') {
    document.forms[0].firewall_type[0].disabled = '';
    document.forms[0].firewall_type[1].disabled = '';
  }

}

// ///////////////////////////////////////////////////////////////////////////
//
// checkUserRemoveThreshold
//
function checkUserRemoveThreshold(alertString, formItemToCheck) {
  if (countChecks(formItemToCheck) > 50) {
    alert(alertString);
    return false;
  }
  return true;
}


//
// validateAddCSR
//
// Function to validate the "Add CSR" fields
//   domain - valid domain name
//   country - A-Za-z only, two-letter code
//   state - A-Za-z only
//   city - A-Za-z only, spelled out, not abbreviations (i.e. St. Louis = Saint Louis)
//   company - A-Za-z only, no special characters (e.g. @, &, .)
//   company division (organizational unit) - optional
//   email - valid email address
//
// Expects:
//   error_invalid_domain
//   error_invalid_country
//   error_invalid_state
//   error_invalid_city
//   error_invalid_company
//   error_invalid_company_division
//   error_invalid_email
//
function validateAddCSR( error_invalid_domain, error_invalid_country, error_invalid_state, error_invalid_city, error_invalid_company, error_invalid_company_division, error_invalid_email ) {

  // Make refs easy
  var frm = document.forms[0];
  //var domain = frm.domain.value;
  var select = frm.domain;
  var domain = select.options[select.selectedIndex].value;
  var domainAlias = frm.domainAliases.options[frm.domainAliases.selectedIndex].value;
  var country = frm.country.value;
  var state = frm.state.value;
  var city = frm.city.value;
  var company = frm.company.value;
  var company_division = frm.company_division.value;
  var email = frm.email.value;

  // Define regex's
  var alphaExp = /^[a-zA-Z]+$/;
  var validChars = /^[a-zA-Z0-9\s-\.\,\+\/\(\)_]+$/;
  var domainExp = /^[a-zA-Z0-9]+[a-zA-Z0-9\-\.]+\.[a-zA-Z0-9]+$/;
  var emailExp = /^[\w!$%&'*+/=?^_`{|}~-]+(\.[\w!#$%&'*+/=?^_`{|}~-]+)*@\w+((\.|-+)?\w)*\.\w+$/;


  // Validate domain name
  // Currently, this is coming from a select element...just make sure it's not empty.
  // This may change in the near future.
  // Define regex's
  // var domainExp = /^[a-zA-Z0-9]+[a-zA-Z0-9\-\.]+\.[a-zA-Z0-9]+$/;
  // Uncomment above line if switching to something other than drop-down selection.

  //if ( domain == "" || ! domainExp.test( domain ) ) {
  if ( domain == "" || domain.length > 64 ) {
    alert( error_invalid_domain );
    return false;
  }

  // Currently domain alias is also coming from a select element...just make sure
  // if it's empty, domain is not.
  if ( ( domainAlias == "" && domain == "" ) || domainAlias.length > 64 ) {
    alert( error_invalid_domain );
    return false;
  }

  // Validate country
  frm.country.value = country.toUpperCase();
  if ( country.length != 2 || ! alphaExp.test( country ) ) {
    alert( error_invalid_country );
    return false;
  }

  // Validate state
  if ( state == "" || state.length > 64 || ! validChars.test( state ) ) {
    alert( error_invalid_state );
    return false;
  }

  // Validate city
  if ( city == "" || city.length > 64 || ! validChars.test( city ) ) {
    alert( error_invalid_city );
    return false;
  }

  // Validate company
  if ( company == "" || company.length > 64 || ! validChars.test( company ) ) {
    alert( error_invalid_company );
    return false;
  }

  // Validate company division
  if ( company_division != "" || company_division.length > 64 ) {
    if ( ! validChars.test( company_division ) ) {
      alert( error_invalid_company_division );
      return false;
    }
  }

  // Validate email
  if ( ( email && ! emailExp.test( email ) ) || email.length > 64 ) {
    alert( error_invalid_email );
    return false;
  }

  // All good
        document.forms[0].save.value = 1;
        document.forms[0].submit();
        return false;
}

// ///////////////////////////////////////////////////////////////////////////
//
// validateCertForm
//
// Function to validate the self signed certificate, and install
// certificate/intermediate certificate forms:
//
// For both forms:
//   domain - valid domain name
//   understand - A checkbox that must be checked in order to proceed with function.
//   applyto_apache - checkbox indicating if cert should be applied to application
//   applyto_dovecot -   "
//   applyto_postfix -   "
//   applyto_vsftpd -    "
//
// Additionally, an "are you sure" alert is displayed for additional confirmation.
// This alert uses the text_confirmation passed in to the function.
//
// SSC Expects:
//   error_domain
//   error_applied
//   error_understand
//   text_confirmation
//
// Certificate/Intermediate Certificate Expects:
//   error_domain
//   error_applied
//   error_understand
//   text_confirmation
//   error_required
//
function validateCertForm( error_domain, error_applied, error_understand, text_confirmation, error_required ) {

  // Make refs easy
  var frm = document.forms[0];
  var select = frm.domain;
  var domain = select.options[select.selectedIndex].value;
  var understand = frm.understand.checked;
  var ssc = ( frm.self == undefined || frm.self.value != 1 ) ? false : true;
  var cert = ( ssc ) ? '' : frm.cert.value;
  var cacert = ( ssc ) ? '' : frm.cacert.value;
  var key = ( ssc ) ? '' : frm.key.value;
  var apache = frm.applyto_apache.value;
  var dovecot = frm.applyto_dovecot.value;
  // Postfix currently has an issue applying a cert, comment out for now.
  //var postfix = frm.applyto_postfix.value;
  var vsftpd = frm.applyto_vsftpd.value;

  // Validate domain name
  // Currently, this is coming from a select element...just make sure it's not empty.
  // This may change in the near future.
  // Define regex's
  // var domainExp = /^[a-zA-Z0-9]+[a-zA-Z0-9\-\.]+\.[a-zA-Z0-9]+$/;
  // Uncomment above line if switching to something other than drop-down selection.

  //if ( domain == "" || ! domainExp.test( domain ) ) {
  if ( domain == "" ) {
    alert( error_domain );
    return false;
  }

  // If cert/intermediate cert:
  // Make sure at least one of cert or cacert is supplied.
  if ( ! ssc ) {
    if ( cert == '' && cacert == '' ) {
      alert( error_required );
      return false;
    }
  }

  // Make sure at least one "apply to" checkbox is checked.
  var numChecked = $("input[type=checkbox][id^=applyto]:checked").length;
  if ( numChecked == 0 ) {
    alert( error_applied );
    return false;
  }


  // Make sure the "understand" checkbox is checked
  if ( ! understand ) {
    alert( error_understand );
    return false;
  }

  // Popup dialog to get extra confirmation
  if ( ! confirm( text_confirmation ) ) {
    frm.cancel.value = 'yes';
    frm.submit();
    return false;
  }

  frm.save.value = 1;
  frm.submit();
  return false;
}

// ///////////////////////////////////////////////////////////////////////////
//
// checkValidCert
//
// Make sure a supplied cert, cacert, or key all at least have the '-----BEGIN'
// and '-----END' tags, along with a few other attributes. Text can vary, but all
// should at least have those.
// This is just a very cursory check before submitting to VSAP, which runs an
// openssl modulus operation for validation.
//
// Expects:
//    Textarea field, error message to populate the alert
//
function checkValidCert( ta, errMsg ) {
  var ssc = ( document.forms[0].self == undefined || document.forms[0].self.value != 1 ) ? false : true;
  var matchTag = /^-----BEGIN(\s\w+)+-----(\r\n|\n){1}([a-zA-Z0-9]|\+|\/|\r\n|\n)+\={0,2}(\r\n|\n){1}-----END(\s\w+)+-----(\r\n|\n)?$/;

  if ( ! ssc ) {

    if ( ta.value != '' && ! matchTag.test( ta.value ) ) {
      alert( errMsg );

      // Re-focus on the textarea field. Force it!
      ta.focus();
      setTimeout( function() {
        ta.focus();
      }, 0);
    }
  }
}


// ///////////////////////////////////////////////////////////////////////////
//
// checkWWWDomainAlias
//
// Function to check for a 'www.' in the domain field while adding a domain, which
// will indicate that the user, in fact, wants a virtual host created as 'www.somedom.com'.
//
// A pop-up will confirm that this is wanted as the field focus is lost.
//
// Upon confirmation, the 'Enable www domain alias...' checkbox will be unchecked and
// disabled.
//
// Expects:
//    warning - warning string to populate the confirmation popup
//
function checkWwwDomainAlias(warning) {
  var www = /^www\./i;
  var tf = document.getElementById('domain');
  var cb = document.getElementById('www_alias');
  var cbState = cb.checked;
  var txt = document.getElementById('enableWwwDomAlias');

  if( www.test( tf.value ) ) {

    var choose = confirm( warning );

    if ( choose ) {

      cb.checked = false;
      cb.disabled = true;
      txt.className = 'textElementDisabled';

      // Make sure to populate the domain contact.
      populateDomainContact(tf.value, 'root@');

    }
    else {

      // Re-focus on the domain text field. Force it!
      tf.focus();
      setTimeout( function() {
        tf.focus();
      }, 0);
    }
  }
  else {

    // Make sure the 'www' alias checkbox is as it was when the textbox was entered.
    cb.disabled = false;
    cb.checked = cbState;

    txt.className = 'textElementEnabled';

    // Make sure to populate the domain contact.
    populateDomainContact(tf.value, 'root@');

  }
}

// ///////////////////////////////////////////////////////////////////////////

// end

