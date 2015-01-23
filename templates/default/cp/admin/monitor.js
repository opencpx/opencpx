// javascript functions specific to the monitor system

function monitorNotifyValue()
{
  for (i=0; i<document.forms[0].notify_events.length; i++) {
    if (document.forms[0].notify_events[i].checked == true) {
      return document.forms[0].notify_events[i].value;
    }
  }
}

function monitorIntervalValue()
{
  for (i=0; i<document.forms[0].monitor_interval.length; i++) {
    if (document.forms[0].monitor_interval[i].checked == true) {
      return document.forms[0].monitor_interval[i].value;
    }
  }
}

function monitorFormVisibility()
{
  var dovecot_installed = document.forms[0].dovecot_installed.value;
  var mailman_installed = document.forms[0].mailman_installed.value;
  var mysql_installed = document.forms[0].mysql_installed.value;
  var postfix_installed = document.forms[0].postfix_installed.value;
  var postgresql_installed = document.forms[0].postgresql_installed.value;
  var sendmail_installed = document.forms[0].sendmail_installed.value;
  var shell_enabled = document.forms[0].shell_enabled.value;

  var monitor_interval = monitorIntervalValue();
  if (monitor_interval == '0') {
    document.forms[0].autorestart_service_ftp.disabled = true;
    document.forms[0].autorestart_service_httpd.disabled = true;
    if (shell_enabled == '1') {
      document.forms[0].autorestart_service_ssh.disabled = true;
    }
    document.forms[0].autorestart_service_vsapd.disabled = true;
    if (dovecot_installed == '1') {
      document.forms[0].autorestart_service_dovecot.disabled = true;
      document.forms[0].notify_service_dovecot.disabled = true;
    }
    else {
      document.forms[0].autorestart_service_imap.disabled = true;
      document.forms[0].autorestart_service_imaps.disabled = true;
      document.forms[0].autorestart_service_pop3.disabled = true;
      document.forms[0].autorestart_service_pop3s.disabled = true;
      document.forms[0].notify_service_imap.disabled = true;
      document.forms[0].notify_service_imaps.disabled = true;
      document.forms[0].notify_service_pop3.disabled = true;
      document.forms[0].notify_service_pop3s.disabled = true;
    }
    if (mysql_installed == '1') {
      document.forms[0].autorestart_service_mysqld.disabled = true;
      document.forms[0].notify_service_mysqld.disabled = true;
    }
    if (postgresql_installed == '1') {
      document.forms[0].autorestart_service_postgresql.disabled = true;
      document.forms[0].notify_service_postgresql.disabled = true;
    }
    if (sendmail_installed == '1') {
      document.forms[0].autorestart_service_sendmail.disabled = true;
      document.forms[0].notify_service_sendmail.disabled = true;
    }
    if (mailman_installed == '1') {
      document.forms[0].autorestart_service_mailman.disabled = true;
      document.forms[0].notify_service_mailman.disabled = true;
    }
    if (postfix_installed == '1') {
      document.forms[0].autorestart_service_postfix.disabled = true;
      document.forms[0].notify_service_postfix.disabled = true;
    }
    for (i=0; i<document.forms[0].notify_events.length; i++) {
      document.forms[0].notify_events[i].disabled = true;
    }
    document.forms[0].notify_events_max.disabled = true;
    document.forms[0].notify_service_ftp.disabled = true;
    document.forms[0].notify_service_httpd.disabled = true;
    if (shell_enabled == '1') {
      document.forms[0].notify_service_ssh.disabled = true;
    }
    document.forms[0].notify_service_vsapd.disabled = true;
    document.forms[0].notify_server_reboot.disabled = true;
    document.forms[0].notify_email_address.disabled = true;
    document.forms[0].notify_email_server.disabled = true;
    document.forms[0].notify_smtp_auth_username.disabled = true;
    document.forms[0].notify_smtp_auth_password.disabled = true;
  }
  else {
    document.forms[0].autorestart_service_ftp.disabled = false;
    document.forms[0].autorestart_service_httpd.disabled = false;
    if (shell_enabled == '1') {
      document.forms[0].autorestart_service_ssh.disabled = false;
    }
    document.forms[0].autorestart_service_vsapd.disabled = false;
    if (dovecot_installed == '1') {
      document.forms[0].autorestart_service_dovecot.disabled = false;
    }
    else {
      document.forms[0].autorestart_service_imap.disabled = false;
      document.forms[0].autorestart_service_imaps.disabled = false;
      document.forms[0].autorestart_service_pop3.disabled = false;
      document.forms[0].autorestart_service_pop3s.disabled = false;
    }
    if (mysql_installed == '1') {
      document.forms[0].autorestart_service_mysqld.disabled = false;
    }
    if (postgresql_installed == '1') {
      document.forms[0].autorestart_service_postgresql.disabled = false;
    }
    if (sendmail_installed == '1') {
      document.forms[0].autorestart_service_sendmail.disabled = false;
    }
    if (mailman_installed == '1') {
      document.forms[0].autorestart_service_mailman.disabled = false;
    }
    if (postfix_installed == '1') {
      document.forms[0].autorestart_service_postfix.disabled = false;
    }
    for (i=0; i<document.forms[0].notify_events.length; i++) {
      document.forms[0].notify_events[i].disabled = false;
    }
    document.forms[0].notify_events_max.disabled = false;
    var notify_events = monitorNotifyValue();
    if (notify_events == 0) {
      document.forms[0].notify_service_ftp.disabled = true;
      document.forms[0].notify_service_httpd.disabled = true;
      if (shell_enabled == '1') {
        document.forms[0].notify_service_ssh.disabled = true;
      }
      document.forms[0].notify_service_vsapd.disabled = true;
      if (dovecot_installed == '1') {
        document.forms[0].notify_service_dovecot.disabled = true;
      }
      else {
        document.forms[0].notify_service_imap.disabled = true;
        document.forms[0].notify_service_imaps.disabled = true;
        document.forms[0].notify_service_pop3.disabled = true;
        document.forms[0].notify_service_pop3s.disabled = true;
      }
      if (mysql_installed == '1') {
        document.forms[0].notify_service_mysqld.disabled = true;
      }
      if (postgresql_installed == '1') {
        document.forms[0].notify_service_postgresql.disabled = true;
      }
      if (sendmail_installed == '1') {
        document.forms[0].notify_service_sendmail.disabled = true;
      }
      if (mailman_installed == '1') {
        document.forms[0].notify_service_mailman.disabled = true;
      }
      if (postfix_installed == '1') {
        document.forms[0].notify_service_postfix.disabled = true;
      }
      document.forms[0].notify_server_reboot.disabled = true;
      document.forms[0].notify_email_address.disabled = true;
      document.forms[0].notify_email_server.disabled = true;
      document.forms[0].notify_smtp_auth_username.disabled = true;
      document.forms[0].notify_smtp_auth_password.disabled = true;
    }
    else {
      document.forms[0].notify_service_ftp.disabled = false;
      document.forms[0].notify_service_httpd.disabled = false;
      if (shell_enabled == '1') {
        document.forms[0].notify_service_ssh.disabled = false;
      }
      document.forms[0].notify_service_vsapd.disabled = false;
      if (dovecot_installed == '1') {
        document.forms[0].notify_service_dovecot.disabled = false;
      }
      else {
        document.forms[0].notify_service_imap.disabled = false;
        document.forms[0].notify_service_imaps.disabled = false;
        document.forms[0].notify_service_pop3.disabled = false;
        document.forms[0].notify_service_pop3s.disabled = false;
      }
      if (mysql_installed == '1') {
        document.forms[0].notify_service_mysqld.disabled = false;
      }
      if (postgresql_installed == '1') {
        document.forms[0].notify_service_postgresql.disabled = false;
      }
      if (sendmail_installed == '1') {
        document.forms[0].notify_service_sendmail.disabled = false;
      }
      if (mailman_installed == '1') {
        document.forms[0].notify_service_mailman.disabled = false;
      }
      if (postfix_installed == '1') {
        document.forms[0].notify_service_postfix.disabled = false;
      }
      document.forms[0].notify_server_reboot.disabled = false;
      document.forms[0].notify_email_address.disabled = false;
      document.forms[0].notify_email_server.disabled = false;
      document.forms[0].notify_smtp_auth_username.disabled = false;
      document.forms[0].notify_smtp_auth_password.disabled = false;
    }
  }
}

function validateMonitorForm(monitor_err_nothing_to_monitor, monitor_err_no_notify_service_selected, monitor_err_max_notify_blank, monitor_err_max_notify_invalid, monitor_err_email_address_blank, monitor_err_email_address_invalid, monitor_err_mail_server_invalid, monitor_err_auth_username_blank, monitor_err_auth_password_blank)
{
  var monitor_interval = monitorIntervalValue();
  if (monitor_interval == '0') {
    // monitoring off
  }
  else {
    var notify_events = monitorNotifyValue();
    var dovecot_installed = document.forms[0].dovecot_installed.value;
    var mailman_installed = document.forms[0].mysql_installed.value;
    var mysql_installed = document.forms[0].mysql_installed.value;
    var postfix_installed = document.forms[0].postfix_installed.value;
    var postgresql_installed = document.forms[0].postgresql_installed.value;
    var sendmail_installed = document.forms[0].sendmail_installed.value;
    var shell_enabled = document.forms[0].shell_enabled.value;
    if (((dovecot_installed == '0') ||
         ((dovecot_installed == '1') && (document.forms[0].autorestart_service_dovecot.checked == false))) &&
        (document.forms[0].autorestart_service_ftp.checked == false) &&
        (document.forms[0].autorestart_service_httpd.checked == false) &&
        ((sendmail_installed == '0') ||
         ((sendmail_installed == '1') && (document.forms[0].autorestart_service_sendmail.checked == false))) &&
        ((mailman_installed == '0') ||
         ((mailman_installed == '1') && (document.forms[0].autorestart_service_mailman.checked == false))) &&
        ((postfix_installed == '0') ||
         ((postfix_installed == '1') && (document.forms[0].autorestart_service_postfix.checked == false))) &&
        ((mysql_installed == '0') ||
         ((mysql_installed == '1') && (document.forms[0].autorestart_service_mysqld.checked == false))) &&
        ((postgresql_installed == '0') ||
         ((postgresql_installed == '1') && (document.forms[0].autorestart_service_postgresql.checked == false))) &&
        ((dovecot_installed == '1') ||
         ((dovecot_installed == '0') && (document.forms[0].autorestart_service_imap.checked == false))) &&
        ((dovecot_installed == '1') ||
         ((dovecot_installed == '0') && (document.forms[0].autorestart_service_imaps.checked == false))) &&
        ((dovecot_installed == '1') ||
         ((dovecot_installed == '0') && (document.forms[0].autorestart_service_pop3.checked == false))) &&
        ((dovecot_installed == '1') ||
         ((dovecot_installed == '0') && (document.forms[0].autorestart_service_pop3s.checked == false))) &&
        ((shell_enabled == '0') ||
         ((shell_enabled == '1') && (document.forms[0].autorestart_service_ssh.checked == false))) &&
        (document.forms[0].autorestart_service_vsapd.checked == false) &&
        (notify_events == '0')) {
      // monitoring turned on, but nothing to monitor!
      alert(monitor_err_nothing_to_monitor);
      return false;
    }
    if (notify_events == '0') {
      // notifications off
    }
    else {
      if (((dovecot_installed == '0') ||
           ((dovecot_installed == '1') && (document.forms[0].notify_service_dovecot.checked == false))) &&
          (document.forms[0].notify_service_ftp.checked == false) &&
          (document.forms[0].notify_service_httpd.checked == false) &&
          ((sendmail_installed == '0') ||
           ((sendmail_installed == '1') && (document.forms[0].notify_service_sendmail.checked == false))) &&
          ((mailman_installed == '0') ||
           ((mailman_installed == '1') && (document.forms[0].notify_service_mailman.checked == false))) &&
          ((postfix_installed == '0') ||
           ((postfix_installed == '1') && (document.forms[0].notify_service_postfix.checked == false))) &&
          ((mysql_installed == '0') ||
           ((mysql_installed == '1') && (document.forms[0].notify_service_mysqld.checked == false))) &&
          ((postgresql_installed == '0') ||
           ((postgresql_installed == '1') && (document.forms[0].notify_service_postgresql.checked == false))) &&
          ((dovecot_installed == '1') ||
           ((dovecot_installed == '0') && (document.forms[0].notify_service_imap.checked == false))) &&
          ((dovecot_installed == '1') ||
           ((dovecot_installed == '0') && (document.forms[0].notify_service_imaps.checked == false))) &&
          ((dovecot_installed == '1') ||
           ((dovecot_installed == '0') && (document.forms[0].notify_service_pop3.checked == false))) &&
          ((dovecot_installed == '1') ||
           ((dovecot_installed == '0') && (document.forms[0].notify_service_pop3s.checked == false))) &&
          ((shell_enabled == '0') ||
           ((shell_enabled == '1') && (document.forms[0].notify_service_ssh.checked == false))) &&
          (document.forms[0].notify_service_vsapd.checked == false) &&
          (document.forms[0].notify_server_reboot.checked == false)) {
        // notifications turned on, but nothing to monitor!
        alert(monitor_err_no_notify_service_selected);
        return false;
      }
      if (notify_events == 'N') {
        var notify_events_max = document.forms[0].notify_events_max.value;
        if (notify_events_max == '') {
          alert(monitor_err_max_notify_blank);
          return false;
        }
        if (notify_events_max.match(/\D/)) {
          alert(monitor_err_max_notify_invalid);
          return false;
        }
      }
      if (document.forms[0].notify_email_address.value == '') {
        alert(monitor_err_email_address_blank);
        return false;
      }
      if (validate_email_addr(document.forms[0].notify_email_address.value)) {
        alert(monitor_err_email_address_invalid);
        return false;
      }
      if ((document.forms[0].notify_email_server.value != '') &&
          (document.forms[0].notify_email_server.value != 'localhost')) {
        if (validate_domain(document.forms[0].notify_email_server.value)) {
          alert(monitor_err_mail_server_invalid);
          return false;
        }
      }
      if ((document.forms[0].notify_smtp_auth_username.value == '') &&
          (document.forms[0].notify_smtp_auth_password.value != '')) {
        alert(monitor_err_auth_username_blank);
        return false;
      }
      if ((document.forms[0].notify_smtp_auth_username.value != '') &&
          (document.forms[0].notify_smtp_auth_password.value == '') &&
          (document.forms[0].password_on_file.value == '0')) {
        alert(monitor_err_auth_password_blank);
        return false;
      }
    }
  }
  return true;
}

