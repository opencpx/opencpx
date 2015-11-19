<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../cp_global.xsl" />

<xsl:variable name="message">
  <xsl:if test="string(/cp/msgs/msg)">
    <xsl:copy-of select="/cp/strings/*[local-name()=/cp/msgs/msg/@name]" />
  </xsl:if>
</xsl:variable>

<xsl:variable name="feedback">
  <xsl:if test="$message != ''">
    <xsl:call-template name="feedback_table">
      <xsl:with-param name="image">
        <xsl:choose>
          <xsl:when test="/cp/vsap/vsap[@type='error'] or /cp/msgs/msg='error'">error</xsl:when>
          <xsl:otherwise>success</xsl:otherwise>
        </xsl:choose>
      </xsl:with-param>
      <xsl:with-param name="message">
        <xsl:copy-of select="$message" />
      </xsl:with-param>
    </xsl:call-template>
  </xsl:if>
</xsl:variable>

<xsl:variable name="dovecot_installed">
  <xsl:choose>
    <xsl:when test="string(/cp/form/dovecot_installed)">
      <xsl:value-of select="/cp/form/dovecot_installed"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="/cp/vsap/vsap[@type='sys:monitor:get']/dovecot_installed"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="mailman_installed">
  <xsl:choose>
    <xsl:when test="string(/cp/form/mailman_installed)">
      <xsl:value-of select="/cp/form/mailman_installed"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="/cp/vsap/vsap[@type='sys:monitor:get']/mailman_installed"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="mysql_installed">
  <xsl:choose>
    <xsl:when test="string(/cp/form/mysql_installed)">
      <xsl:value-of select="/cp/form/mysql_installed"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="/cp/vsap/vsap[@type='sys:monitor:get']/mysql_installed"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="postfix_installed">
  <xsl:choose>
    <xsl:when test="string(/cp/form/postfix_installed)">
      <xsl:value-of select="/cp/form/postfix_installed"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="/cp/vsap/vsap[@type='sys:monitor:get']/postfix_installed"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="postgresql_installed">
  <xsl:choose>
    <xsl:when test="string(/cp/form/postgresql_installed)">
      <xsl:value-of select="/cp/form/postgresql_installed"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="/cp/vsap/vsap[@type='sys:monitor:get']/postgresql_installed"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="sendmail_installed">
  <xsl:choose>
    <xsl:when test="string(/cp/form/sendmail_installed)">
      <xsl:value-of select="/cp/form/sendmail_installed"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="/cp/vsap/vsap[@type='sys:monitor:get']/sendmail_installed"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="password_on_file">
  <xsl:choose>
    <xsl:when test="string(/cp/form/password_on_file)">
      <xsl:value-of select="/cp/form/password_on_file"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="/cp/vsap/vsap[@type='sys:monitor:get']/password_on_file"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="monitor_interval">
  <xsl:choose>
    <xsl:when test="string(/cp/form/monitor_interval)">
      <xsl:value-of select="/cp/form/monitor_interval"/>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='sys:monitor:get']/monitor_interval">
      <xsl:value-of select="/cp/vsap/vsap[@type='sys:monitor:get']/monitor_interval"/>
    </xsl:when>
    <xsl:otherwise>0</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="autorestart_service_dovecot">
  <xsl:choose>
    <xsl:when test="string(/cp/form/btnSave)">
      <xsl:choose>
        <xsl:when test="string(/cp/form/autorestart_service_dovecot)">
          <xsl:value-of select="/cp/form/autorestart_service_dovecot"/>
        </xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='sys:monitor:get']/autorestart_service_dovecot">
      <xsl:value-of select="/cp/vsap/vsap[@type='sys:monitor:get']/autorestart_service_dovecot"/>
    </xsl:when>
    <xsl:otherwise>1</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="autorestart_service_ftp">
  <xsl:choose>
    <xsl:when test="string(/cp/form/btnSave)">
      <xsl:choose>
        <xsl:when test="string(/cp/form/autorestart_service_ftp)">
          <xsl:value-of select="/cp/form/autorestart_service_ftp"/>
        </xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='sys:monitor:get']/autorestart_service_ftp">
      <xsl:value-of select="/cp/vsap/vsap[@type='sys:monitor:get']/autorestart_service_ftp"/>
    </xsl:when>
    <xsl:otherwise>1</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="autorestart_service_httpd">
  <xsl:choose>
    <xsl:when test="string(/cp/form/btnSave)">
      <xsl:choose>
        <xsl:when test="string(/cp/form/autorestart_service_httpd)">
          <xsl:value-of select="/cp/form/autorestart_service_httpd"/>
        </xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='sys:monitor:get']/autorestart_service_httpd">
      <xsl:value-of select="/cp/vsap/vsap[@type='sys:monitor:get']/autorestart_service_httpd"/>
    </xsl:when>
    <xsl:otherwise>1</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="autorestart_service_imap">
  <xsl:choose>
    <xsl:when test="string(/cp/form/btnSave)">
      <xsl:choose>
        <xsl:when test="string(/cp/form/autorestart_service_imap)">
          <xsl:value-of select="/cp/form/autorestart_service_imap"/>
        </xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='sys:monitor:get']/autorestart_service_imap">
      <xsl:value-of select="/cp/vsap/vsap[@type='sys:monitor:get']/autorestart_service_imap"/>
    </xsl:when>
    <xsl:otherwise>1</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="autorestart_service_imaps">
  <xsl:choose>
    <xsl:when test="string(/cp/form/btnSave)">
      <xsl:choose>
        <xsl:when test="string(/cp/form/autorestart_service_imaps)">
          <xsl:value-of select="/cp/form/autorestart_service_imaps"/>
        </xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='sys:monitor:get']/autorestart_service_imaps">
      <xsl:value-of select="/cp/vsap/vsap[@type='sys:monitor:get']/autorestart_service_imaps"/>
    </xsl:when>
    <xsl:otherwise>1</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="autorestart_service_inetd">
  <xsl:choose>
    <xsl:when test="string(/cp/form/btnSave)">
      <xsl:choose>
        <xsl:when test="string(/cp/form/autorestart_service_inetd)">
          <xsl:value-of select="/cp/form/autorestart_service_inetd"/>
        </xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='sys:monitor:get']/autorestart_service_inetd">
      <xsl:value-of select="/cp/vsap/vsap[@type='sys:monitor:get']/autorestart_service_inetd"/>
    </xsl:when>
    <xsl:otherwise>1</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="autorestart_service_mailman">
  <xsl:choose>
    <xsl:when test="string(/cp/form/btnSave)">
      <xsl:choose>
        <xsl:when test="string(/cp/form/autorestart_service_mailman)">
          <xsl:value-of select="/cp/form/autorestart_service_mailman"/>
        </xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='sys:monitor:get']/autorestart_service_mailman">
      <xsl:value-of select="/cp/vsap/vsap[@type='sys:monitor:get']/autorestart_service_mailman"/>
    </xsl:when>
    <xsl:otherwise>0</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="autorestart_service_mysqld">
  <xsl:choose>
    <xsl:when test="string(/cp/form/btnSave)">
      <xsl:choose>
        <xsl:when test="string(/cp/form/autorestart_service_mysqld)">
          <xsl:value-of select="/cp/form/autorestart_service_mysqld"/>
        </xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='sys:monitor:get']/autorestart_service_mysqld">
      <xsl:value-of select="/cp/vsap/vsap[@type='sys:monitor:get']/autorestart_service_mysqld"/>
    </xsl:when>
    <xsl:otherwise>0</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="autorestart_service_pop3">
  <xsl:choose>
    <xsl:when test="string(/cp/form/btnSave)">
      <xsl:choose>
        <xsl:when test="string(/cp/form/autorestart_service_pop3)">
          <xsl:value-of select="/cp/form/autorestart_service_pop3"/>
        </xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='sys:monitor:get']/autorestart_service_pop3">
      <xsl:value-of select="/cp/vsap/vsap[@type='sys:monitor:get']/autorestart_service_pop3"/>
    </xsl:when>
    <xsl:otherwise>1</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="autorestart_service_pop3s">
  <xsl:choose>
    <xsl:when test="string(/cp/form/btnSave)">
      <xsl:choose>
        <xsl:when test="string(/cp/form/autorestart_service_pop3s)">
          <xsl:value-of select="/cp/form/autorestart_service_pop3s"/>
        </xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='sys:monitor:get']/autorestart_service_pop3s">
      <xsl:value-of select="/cp/vsap/vsap[@type='sys:monitor:get']/autorestart_service_pop3s"/>
    </xsl:when>
    <xsl:otherwise>1</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="autorestart_service_postfix">
  <xsl:choose>
    <xsl:when test="string(/cp/form/btnSave)">
      <xsl:choose>
        <xsl:when test="string(/cp/form/autorestart_service_postfix)">
          <xsl:value-of select="/cp/form/autorestart_service_postfix"/>
        </xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='sys:monitor:get']/autorestart_service_postfix">
      <xsl:value-of select="/cp/vsap/vsap[@type='sys:monitor:get']/autorestart_service_postfix"/>
    </xsl:when>
    <xsl:otherwise>1</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="autorestart_service_postgresql">
  <xsl:choose>
    <xsl:when test="string(/cp/form/btnSave)">
      <xsl:choose>
        <xsl:when test="string(/cp/form/autorestart_service_postgresql)">
          <xsl:value-of select="/cp/form/autorestart_service_postgresql"/>
        </xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='sys:monitor:get']/autorestart_service_postgresql">
      <xsl:value-of select="/cp/vsap/vsap[@type='sys:monitor:get']/autorestart_service_postgresql"/>
    </xsl:when>
    <xsl:otherwise>1</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="autorestart_service_sendmail">
  <xsl:choose>
    <xsl:when test="string(/cp/form/btnSave)">
      <xsl:choose>
        <xsl:when test="string(/cp/form/autorestart_service_sendmail)">
          <xsl:value-of select="/cp/form/autorestart_service_sendmail"/>
        </xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='sys:monitor:get']/autorestart_service_sendmail">
      <xsl:value-of select="/cp/vsap/vsap[@type='sys:monitor:get']/autorestart_service_sendmail"/>
    </xsl:when>
    <xsl:otherwise>1</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="autorestart_service_ssh">
  <xsl:choose>
    <xsl:when test="string(/cp/form/btnSave)">
      <xsl:choose>
        <xsl:when test="string(/cp/form/autorestart_service_ssh)">
          <xsl:value-of select="/cp/form/autorestart_service_ssh"/>
        </xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='sys:monitor:get']/autorestart_service_ssh">
      <xsl:value-of select="/cp/vsap/vsap[@type='sys:monitor:get']/autorestart_service_ssh"/>
    </xsl:when>
    <xsl:otherwise>1</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="autorestart_service_vsapd">
  <xsl:choose>
    <xsl:when test="string(/cp/form/btnSave)">
      <xsl:choose>
        <xsl:when test="string(/cp/form/autorestart_service_vsapd)">
          <xsl:value-of select="/cp/form/autorestart_service_vsapd"/>
        </xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='sys:monitor:get']/autorestart_service_vsapd">
      <xsl:value-of select="/cp/vsap/vsap[@type='sys:monitor:get']/autorestart_service_vsapd"/>
    </xsl:when>
    <xsl:otherwise>1</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="notify_events">
  <xsl:choose>
    <xsl:when test="string(/cp/form/notify_events)">
      <xsl:value-of select="/cp/form/notify_events"/>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='sys:monitor:get']/notify_events">
      <xsl:value-of select="/cp/vsap/vsap[@type='sys:monitor:get']/notify_events"/>
    </xsl:when>
    <xsl:otherwise>0</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="notify_events_max">
  <xsl:choose>
    <xsl:when test="string(/cp/form/notify_events_max)">
      <xsl:value-of select="/cp/form/notify_events_max"/>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='sys:monitor:get']/notify_events">
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='sys:monitor:get']/notify_events = '0'">10</xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='sys:monitor:get']/notify_events = '-1'">10</xsl:when>
        <xsl:otherwise><xsl:value-of select="/cp/vsap/vsap[@type='sys:monitor:get']/notify_events"/></xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:otherwise>10</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="notify_email_address">
  <xsl:choose>
    <xsl:when test="string(/cp/form/notify_email_address)">
      <xsl:value-of select="/cp/form/notify_email_address"/>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='sys:monitor:get']/notify_email_address">
      <xsl:value-of select="/cp/vsap/vsap[@type='sys:monitor:get']/notify_email_address"/>
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="notify_email_server">
  <xsl:choose>
    <xsl:when test="string(/cp/form/notify_email_server)">
      <xsl:value-of select="/cp/form/notify_email_server"/>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='sys:monitor:get']/notify_email_server">
      <xsl:value-of select="/cp/vsap/vsap[@type='sys:monitor:get']/notify_email_server"/>
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="notify_smtp_auth_username">
  <xsl:choose>
    <xsl:when test="string(/cp/form/notify_smtp_auth_username)">
      <xsl:value-of select="/cp/form/notify_smtp_auth_username"/>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='sys:monitor:get']/notify_smtp_auth_username">
      <xsl:value-of select="/cp/vsap/vsap[@type='sys:monitor:get']/notify_smtp_auth_username"/>
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="notify_service_dovecot">
  <xsl:choose>
    <xsl:when test="string(/cp/form/btnSave)">
      <xsl:choose>
        <xsl:when test="string(/cp/form/notify_service_dovecot)">
          <xsl:value-of select="/cp/form/notify_service_dovecot"/>
        </xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='sys:monitor:get']/notify_service_dovecot">
      <xsl:value-of select="/cp/vsap/vsap[@type='sys:monitor:get']/notify_service_dovecot"/>
    </xsl:when>
    <xsl:otherwise>1</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="notify_service_ftp">
  <xsl:choose>
    <xsl:when test="string(/cp/form/btnSave)">
      <xsl:choose>
        <xsl:when test="string(/cp/form/notify_service_ftp)">
          <xsl:value-of select="/cp/form/notify_service_ftp"/>
        </xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='sys:monitor:get']/notify_service_ftp">
      <xsl:value-of select="/cp/vsap/vsap[@type='sys:monitor:get']/notify_service_ftp"/>
    </xsl:when>
    <xsl:otherwise>1</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="notify_service_httpd">
  <xsl:choose>
    <xsl:when test="string(/cp/form/btnSave)">
      <xsl:choose>
        <xsl:when test="string(/cp/form/notify_service_httpd)">
          <xsl:value-of select="/cp/form/notify_service_httpd"/>
        </xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='sys:monitor:get']/notify_service_httpd">
      <xsl:value-of select="/cp/vsap/vsap[@type='sys:monitor:get']/notify_service_httpd"/>
    </xsl:when>
    <xsl:otherwise>1</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="notify_service_imap">
  <xsl:choose>
    <xsl:when test="string(/cp/form/btnSave)">
      <xsl:choose>
        <xsl:when test="string(/cp/form/notify_service_imap)">
          <xsl:value-of select="/cp/form/notify_service_imap"/>
        </xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='sys:monitor:get']/notify_service_imap">
      <xsl:value-of select="/cp/vsap/vsap[@type='sys:monitor:get']/notify_service_imap"/>
    </xsl:when>
    <xsl:otherwise>1</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="notify_service_imaps">
  <xsl:choose>
    <xsl:when test="string(/cp/form/btnSave)">
      <xsl:choose>
        <xsl:when test="string(/cp/form/notify_service_imaps)">
          <xsl:value-of select="/cp/form/notify_service_imaps"/>
        </xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='sys:monitor:get']/notify_service_imaps">
      <xsl:value-of select="/cp/vsap/vsap[@type='sys:monitor:get']/notify_service_imaps"/>
    </xsl:when>
    <xsl:otherwise>1</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="notify_service_inetd">
  <xsl:choose>
    <xsl:when test="string(/cp/form/btnSave)">
      <xsl:choose>
        <xsl:when test="string(/cp/form/notify_service_inetd)">
          <xsl:value-of select="/cp/form/notify_service_inetd"/>
        </xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='sys:monitor:get']/notify_service_inetd">
      <xsl:value-of select="/cp/vsap/vsap[@type='sys:monitor:get']/notify_service_inetd"/>
    </xsl:when>
    <xsl:otherwise>1</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="notify_service_mailman">
  <xsl:choose>
    <xsl:when test="string(/cp/form/btnSave)">
      <xsl:choose>
        <xsl:when test="string(/cp/form/notify_service_mailman)">
          <xsl:value-of select="/cp/form/notify_service_mailman"/>
        </xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='sys:monitor:get']/notify_service_mailman">
      <xsl:value-of select="/cp/vsap/vsap[@type='sys:monitor:get']/notify_service_mailman"/>
    </xsl:when>
    <xsl:otherwise>1</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="notify_service_mysqld">
  <xsl:choose>
    <xsl:when test="string(/cp/form/btnSave)">
      <xsl:choose>
        <xsl:when test="string(/cp/form/notify_service_mysqld)">
          <xsl:value-of select="/cp/form/notify_service_mysqld"/>
        </xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='sys:monitor:get']/notify_service_mysqld">
      <xsl:value-of select="/cp/vsap/vsap[@type='sys:monitor:get']/notify_service_mysqld"/>
    </xsl:when>
    <xsl:otherwise>1</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="notify_service_pop3">
  <xsl:choose>
    <xsl:when test="string(/cp/form/btnSave)">
      <xsl:choose>
        <xsl:when test="string(/cp/form/notify_service_pop3)">
          <xsl:value-of select="/cp/form/notify_service_pop3"/>
        </xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='sys:monitor:get']/notify_service_pop3">
      <xsl:value-of select="/cp/vsap/vsap[@type='sys:monitor:get']/notify_service_pop3"/>
    </xsl:when>
    <xsl:otherwise>1</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="notify_service_pop3s">
  <xsl:choose>
    <xsl:when test="string(/cp/form/btnSave)">
      <xsl:choose>
        <xsl:when test="string(/cp/form/notify_service_pop3s)">
          <xsl:value-of select="/cp/form/notify_service_pop3s"/>
        </xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='sys:monitor:get']/notify_service_pop3s">
      <xsl:value-of select="/cp/vsap/vsap[@type='sys:monitor:get']/notify_service_pop3s"/>
    </xsl:when>
    <xsl:otherwise>1</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="notify_service_postfix">
  <xsl:choose>
    <xsl:when test="string(/cp/form/btnSave)">
      <xsl:choose>
        <xsl:when test="string(/cp/form/notify_service_postfix)">
          <xsl:value-of select="/cp/form/notify_service_postfix"/>
        </xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='sys:monitor:get']/notify_service_postfix">
      <xsl:value-of select="/cp/vsap/vsap[@type='sys:monitor:get']/notify_service_postfix"/>
    </xsl:when>
    <xsl:otherwise>1</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="notify_service_postgresql">
  <xsl:choose>
    <xsl:when test="string(/cp/form/btnSave)">
      <xsl:choose>
        <xsl:when test="string(/cp/form/notify_service_postgresql)">
          <xsl:value-of select="/cp/form/notify_service_postgresql"/>
        </xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='sys:monitor:get']/notify_service_postgresql">
      <xsl:value-of select="/cp/vsap/vsap[@type='sys:monitor:get']/notify_service_postgresql"/>
    </xsl:when>
    <xsl:otherwise>1</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="notify_service_sendmail">
  <xsl:choose>
    <xsl:when test="string(/cp/form/btnSave)">
      <xsl:choose>
        <xsl:when test="string(/cp/form/notify_service_sendmail)">
          <xsl:value-of select="/cp/form/notify_service_sendmail"/>
        </xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='sys:monitor:get']/notify_service_sendmail">
      <xsl:value-of select="/cp/vsap/vsap[@type='sys:monitor:get']/notify_service_sendmail"/>
    </xsl:when>
    <xsl:otherwise>1</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="notify_service_ssh">
  <xsl:choose>
    <xsl:when test="string(/cp/form/btnSave)">
      <xsl:choose>
        <xsl:when test="string(/cp/form/notify_service_ssh)">
          <xsl:value-of select="/cp/form/notify_service_ssh"/>
        </xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='sys:monitor:get']/notify_service_ssh">
      <xsl:value-of select="/cp/vsap/vsap[@type='sys:monitor:get']/notify_service_ssh"/>
    </xsl:when>
    <xsl:otherwise>1</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="notify_service_vsapd">
  <xsl:choose>
    <xsl:when test="string(/cp/form/btnSave)">
      <xsl:choose>
        <xsl:when test="string(/cp/form/notify_service_vsapd)">
          <xsl:value-of select="/cp/form/notify_service_vsapd"/>
        </xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='sys:monitor:get']/notify_service_vsapd">
      <xsl:value-of select="/cp/vsap/vsap[@type='sys:monitor:get']/notify_service_vsapd"/>
    </xsl:when>
    <xsl:otherwise>1</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="notify_server_reboot">
  <xsl:choose>
    <xsl:when test="string(/cp/form/btnSave)">
      <xsl:choose>
        <xsl:when test="string(/cp/form/notify_server_reboot)">
          <xsl:value-of select="/cp/form/notify_server_reboot"/>
        </xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='sys:monitor:get']/notify_server_reboot">
      <xsl:value-of select="/cp/vsap/vsap[@type='sys:monitor:get']/notify_server_reboot"/>
    </xsl:when>
    <xsl:otherwise>1</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="shell_enabled">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='auth']/siteprefs/disable-shell">0</xsl:when>
    <xsl:otherwise>1</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:template match="/">
  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title">
      <xsl:copy-of select="/cp/strings/cp_title" />
      v<xsl:value-of select="/cp/vsap/vsap[@type='auth']/version" /> :
      <xsl:copy-of select="/cp/strings/bc_system_monitor_services" />
    </xsl:with-param>
    <xsl:with-param name="formaction">monitor.xsl</xsl:with-param>
    <xsl:with-param name="onload">monitorFormVisibility();</xsl:with-param>
    <xsl:with-param name="feedback" select="$feedback" />
    <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_admin_monitor_services" />
    <xsl:with-param name="help_short" select="/cp/strings/system_admin_hlp_short" />
    <xsl:with-param name="help_long"><xsl:copy-of select="/cp/strings/system_admin_hlp_long" /></xsl:with-param>
    <xsl:with-param name="breadcrumb">
      <breadcrumb>
        <section>
          <name><xsl:copy-of select="/cp/strings/bc_system_monitor_services" /></name>
          <url>#</url>
          <image>SystemAdministration</image>
        </section>
      </breadcrumb>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

  <script src="{concat($base_url, '/cp/cp.js')}" language="javascript"/>
  <script src="{concat($base_url, '/cp/admin/monitor.js')}" language="javascript"/>

  <input type="hidden" name="dovecot_installed" value="{$dovecot_installed}" /> 
  <input type="hidden" name="mailman_installed" value="{$mailman_installed}" /> 
  <input type="hidden" name="mysql_installed" value="{$mysql_installed}" /> 
  <input type="hidden" name="postfix_installed" value="{$postfix_installed}" /> 
  <input type="hidden" name="postgresql_installed" value="{$postgresql_installed}" /> 
  <input type="hidden" name="sendmail_installed" value="{$sendmail_installed}" /> 
  <input type="hidden" name="shell_enabled" value="{$shell_enabled}" /> 
  <input type="hidden" name="password_on_file" value="{$password_on_file}" /> 

  <table class="formview" border="0" cellspacing="0" cellpadding="0">

    <tr class="title">
      <td colspan="2"><xsl:copy-of select="/cp/strings/monitor_service_preferences" /></td>
    </tr>
    <tr class="instructionrow">
      <td colspan="2"><xsl:copy-of select="/cp/strings/monitor_service_preferences_info" /></td>
    </tr>

    <tr class="rowodd">
      <td class="label"><xsl:copy-of select="/cp/strings/monitor_service_interval" /></td>
      <td class="contentwidth">

        <input type="radio" id="monitor_service_off" name="monitor_interval" value="0" onClick="monitorFormVisibility();" border="0">
          <xsl:if test="$monitor_interval = '0'">
            <xsl:attribute name="checked" value="checked"/>
          </xsl:if>
        </input>
        <label for="monitor_service_off"><xsl:value-of select="/cp/strings/monitor_service_interval_off"/></label>
        <br />

        <input type="radio" id="monitor_service_1" name="monitor_interval" value="1" onClick="monitorFormVisibility();" border="0">
          <xsl:if test="$monitor_interval = '1'">
            <xsl:attribute name="checked" value="checked"/>
          </xsl:if>
        </input>
        <label for="monitor_service_1"><xsl:value-of select="/cp/strings/monitor_service_interval_1"/></label>
        <br />

        <input type="radio" id="monitor_service_5" name="monitor_interval" value="5" onClick="monitorFormVisibility();" border="0">
          <xsl:if test="$monitor_interval = '5'">
            <xsl:attribute name="checked" value="checked"/>
          </xsl:if>
        </input>
        <label for="monitor_service_5"><xsl:value-of select="/cp/strings/monitor_service_interval_5"/></label>
        <br />

        <input type="radio" id="monitor_service_15" name="monitor_interval" value="15" onClick="monitorFormVisibility();" border="0">
          <xsl:if test="$monitor_interval = '15'">
            <xsl:attribute name="checked" value="checked"/>
          </xsl:if>
        </input>
        <label for="monitor_service_15"><xsl:value-of select="/cp/strings/monitor_service_interval_15"/></label>
        <br />

      </td>
    </tr>

    <tr class="rowodd">
      <td class="label"><xsl:copy-of select="/cp/strings/monitor_service_restart" /></td>
      <td class="contentwidth">

        <xsl:if test="$dovecot_installed = '1'">
          <input type="checkbox" id="monitor_dovecot" name="autorestart_service_dovecot" value="1">
            <xsl:if test="$autorestart_service_dovecot = '1'">
              <xsl:attribute name="checked">checked</xsl:attribute>
            </xsl:if>
          </input>
          <label for="monitor_dovecot">dovecot (<xsl:value-of select="/cp/strings/service_desc_dovecot" />)</label>
          <br />
        </xsl:if>

        <input type="checkbox" id="monitor_ftp" name="autorestart_service_ftp" value="1">
          <xsl:if test="$autorestart_service_ftp = '1'">
            <xsl:attribute name="checked">checked</xsl:attribute>
          </xsl:if>
        </input>
        <label for="monitor_ftp">ftp (<xsl:value-of select="/cp/strings/inetd_desc_ftp" />)</label>
        <br />

        <input type="checkbox" id="monitor_httpd" name="autorestart_service_httpd" value="1">
          <xsl:if test="$autorestart_service_httpd = '1'">
            <xsl:attribute name="checked">checked</xsl:attribute>
          </xsl:if>
        </input>
        <label for="monitor_httpd">httpd (<xsl:value-of select="/cp/strings/service_desc_httpd" />)</label>
        <br />

        <xsl:if test="$dovecot_installed = '0'">
          <input type="checkbox" id="monitor_imap" name="autorestart_service_imap" value="1">
            <xsl:if test="$autorestart_service_imap = '1'">
              <xsl:attribute name="checked">checked</xsl:attribute>
            </xsl:if>
          </input>
          <label for="monitor_imap">imap (<xsl:value-of select="/cp/strings/inetd_desc_imap" />)</label>
          <br />

          <input type="checkbox" id="monitor_imaps" name="autorestart_service_imaps" value="1">
            <xsl:if test="$autorestart_service_imaps = '1'">
              <xsl:attribute name="checked">checked</xsl:attribute>
            </xsl:if>
          </input>
          <label for="monitor_imaps">imaps (<xsl:value-of select="/cp/strings/inetd_desc_imaps" />)</label>
          <br />
        </xsl:if>

        <input type="hidden" name="autorestart_service_inetd" value="1"/>

        <xsl:if test="$mailman_installed = '1'">
          <input type="checkbox" id="monitor_mailman" name="autorestart_service_mailman" value="1">
            <xsl:if test="$autorestart_service_mailman = '1'">
              <xsl:attribute name="checked">checked</xsl:attribute>
            </xsl:if>
          </input>
          <label for="monitor_mailman">mailman (<xsl:value-of select="/cp/strings/service_desc_mailman" />)</label>
          <br />
        </xsl:if>

        <xsl:if test="$mysql_installed = '1'">
          <input type="checkbox" id="monitor_mysqld" name="autorestart_service_mysqld" value="1">
            <xsl:if test="$autorestart_service_mysqld = '1'">
              <xsl:attribute name="checked">checked</xsl:attribute>
            </xsl:if>
          </input>
          <label for="monitor_mysqld">mysqld (<xsl:value-of select="/cp/strings/service_desc_mysqld" />)</label>
          <br />
        </xsl:if>

        <xsl:if test="$dovecot_installed = '0'">
          <input type="checkbox" id="monitor_pop3" name="autorestart_service_pop3" value="1">
            <xsl:if test="$autorestart_service_pop3 = '1'">
              <xsl:attribute name="checked">checked</xsl:attribute>
            </xsl:if>
          </input>
          <label for="monitor_pop3">pop3 (<xsl:value-of select="/cp/strings/inetd_desc_pop3" />)</label>
          <br />

          <input type="checkbox" id="monitor_pop3s" name="autorestart_service_pop3s" value="1">
            <xsl:if test="$autorestart_service_pop3s = '1'">
              <xsl:attribute name="checked">checked</xsl:attribute>
            </xsl:if>
          </input>
          <label for="monitor_pop3s">pop3s (<xsl:value-of select="/cp/strings/inetd_desc_pop3s" />)</label>
          <br />
        </xsl:if>

        <xsl:if test="$postfix_installed = '1'">
          <input type="checkbox" id="monitor_postfix" name="autorestart_service_postfix" value="1">
            <xsl:if test="$autorestart_service_postfix = '1'">
              <xsl:attribute name="checked">checked</xsl:attribute>
            </xsl:if>
          </input>
          <label for="monitor_postfix">postfix (<xsl:value-of select="/cp/strings/service_desc_postfix" />)</label>
          <br />
        </xsl:if>

        <xsl:if test="$postgresql_installed = '1'">
          <input type="checkbox" id="monitor_postgresql" name="autorestart_service_postgresql" value="1">
            <xsl:if test="$autorestart_service_postgresql = '1'">
              <xsl:attribute name="checked">checked</xsl:attribute>
            </xsl:if>
          </input>
          <label for="monitor_postgresql">postgresql (<xsl:value-of select="/cp/strings/service_desc_postgresql" />)</label>
          <br />
        </xsl:if>

        <xsl:if test="$sendmail_installed = '1'">
          <input type="checkbox" id="monitor_sendmail" name="autorestart_service_sendmail" value="1">
            <xsl:if test="$autorestart_service_sendmail = '1'">
              <xsl:attribute name="checked">checked</xsl:attribute>
            </xsl:if>
          </input>
          <label for="monitor_sendmail">sendmail (<xsl:value-of select="/cp/strings/service_desc_sendmail" />)</label>
          <br />
        </xsl:if>

        <xsl:if test="$shell_enabled = '1'">
          <input type="checkbox" id="monitor_ssh" name="autorestart_service_ssh" value="1">
            <xsl:if test="$autorestart_service_ssh = '1'">
              <xsl:attribute name="checked">checked</xsl:attribute>
            </xsl:if>
          </input>
          <label for="monitor_ssh">ssh (<xsl:value-of select="/cp/strings/inetd_desc_ssh" />)</label>
          <br />
        </xsl:if>

        <input type="checkbox" id="monitor_vsapd" name="autorestart_service_vsapd" value="1">
          <xsl:if test="$autorestart_service_vsapd = '1'">
            <xsl:attribute name="checked">checked</xsl:attribute>
          </xsl:if>
        </input>
        <label for="monitor_vsapd">vsapd (<xsl:value-of select="/cp/strings/service_desc_vsapd" />)</label>
        <br />

      </td>
    </tr>

    <tr class="controlrow">
      <td colspan="2"> <!-- this space intentionally left blank --> </td>
    </tr>

    <tr class="title">
      <td colspan="2"><xsl:copy-of select="/cp/strings/monitor_notify_preferences" /></td>
    </tr>
    <tr class="instructionrow">
      <td colspan="2"><xsl:copy-of select="/cp/strings/monitor_notify_preferences_info" /></td>
    </tr>

    <tr class="rowodd">
      <td class="label"><xsl:copy-of select="/cp/strings/monitor_notify_events" /></td>
      <td class="contentwidth">

        <input type="radio" id="monitor_notify_off" name="notify_events" value="0" onClick="monitorFormVisibility();" border="0">
          <xsl:if test="$notify_events = '0'">
            <xsl:attribute name="checked" value="checked"/>
          </xsl:if>
        </input>
        <label for="monitor_notify_off"><xsl:value-of select="/cp/strings/monitor_notify_events_off"/></label>
        <br />

        <input type="radio" id="monitor_notify_restart" name="notify_events" value="-1" onClick="monitorFormVisibility();" border="0">
          <xsl:if test="$notify_events = '-1'">
            <xsl:attribute name="checked" value="checked"/>
          </xsl:if>
        </input>
        <label for="monitor_notify_restart"><xsl:value-of select="/cp/strings/monitor_notify_events_restarted"/></label>
        <br />

        <input type="radio" id="monitor_notify_N" name="notify_events" value="N" onClick="monitorFormVisibility();" border="0">
          <xsl:choose>
            <xsl:when test="$notify_events = '0' or $notify_events = '-1'" />
            <xsl:otherwise>
              <xsl:attribute name="checked" value="checked"/>
            </xsl:otherwise>
          </xsl:choose>
        </input>
        <label for="monitor_notify_N">
          <xsl:value-of select="/cp/strings/monitor_notify_events_max"/>
        </label>
        <input type="text" name="notify_events_max" size="4" value="{$notify_events_max}" />
        <label for="monitor_notify_N">
          <xsl:value-of select="/cp/strings/monitor_notify_events_N"/>
        </label>
        <br />

      </td>
    </tr>

    <tr class="rowodd">
      <td class="label"><xsl:copy-of select="/cp/strings/monitor_notify_alerts" /></td>
      <td class="contentwidth">

        <xsl:if test="$dovecot_installed = '1'">
          <input type="checkbox" id="notify_dovecot" name="notify_service_dovecot" value="1">
            <xsl:if test="$notify_service_dovecot = '1'">
              <xsl:attribute name="checked">checked</xsl:attribute>
            </xsl:if>
          </input>
          <label for="notify_dovecot">dovecot (<xsl:value-of select="/cp/strings/service_desc_dovecot" />)</label>
          <br />
        </xsl:if>

        <input type="checkbox" id="notify_ftp" name="notify_service_ftp" value="1">
          <xsl:if test="$notify_service_ftp = '1'">
            <xsl:attribute name="checked">checked</xsl:attribute>
          </xsl:if>
        </input>
        <label for="notify_ftp">ftp (<xsl:value-of select="/cp/strings/inetd_desc_ftp" />)</label>
        <br />

        <input type="checkbox" id="notify_httpd" name="notify_service_httpd" value="1">
          <xsl:if test="$notify_service_httpd = '1'">
            <xsl:attribute name="checked">checked</xsl:attribute>
          </xsl:if>
        </input>
        <label for="notify_httpd">httpd (<xsl:value-of select="/cp/strings/service_desc_httpd" />)</label>
        <br />

        <xsl:if test="$dovecot_installed = '0'">
          <input type="checkbox" id="notify_imap" name="notify_service_imap" value="1">
            <xsl:if test="$notify_service_imap = '1'">
              <xsl:attribute name="checked">checked</xsl:attribute>
            </xsl:if>
          </input>
          <label for="notify_imap">imap (<xsl:value-of select="/cp/strings/inetd_desc_imap" />)</label>
          <br />

          <input type="checkbox" id="notify_imaps" name="notify_service_imaps" value="1">
            <xsl:if test="$notify_service_imaps = '1'">
              <xsl:attribute name="checked">checked</xsl:attribute>
            </xsl:if>
          </input>
          <label for="notify_imaps">imaps (<xsl:value-of select="/cp/strings/inetd_desc_imaps" />)</label>
          <br />
        </xsl:if>

        <input type="hidden" name="notify_service_inetd" value="1" />

        <xsl:if test="$mailman_installed = '1'">
          <input type="checkbox" id="notify_mailman" name="notify_service_mailman" value="1">
            <xsl:if test="$notify_service_mailman = '1'">
              <xsl:attribute name="checked">checked</xsl:attribute>
            </xsl:if>
          </input>
          <label for="notify_mailman">mailman (<xsl:value-of select="/cp/strings/service_desc_mailman" />)</label>
          <br />
        </xsl:if>

        <xsl:if test="$mysql_installed = '1'">
          <input type="checkbox" id="notify_mysqld" name="notify_service_mysqld" value="1">
            <xsl:if test="$notify_service_mysqld = '1'">
              <xsl:attribute name="checked">checked</xsl:attribute>
            </xsl:if>
          </input>
          <label for="notify_mysqld">mysqld (<xsl:value-of select="/cp/strings/service_desc_mysqld" />)</label>
          <br />
        </xsl:if>

        <xsl:if test="$dovecot_installed = '0'">
          <input type="checkbox" id="notify_pop3" name="notify_service_pop3" value="1">
            <xsl:if test="$notify_service_pop3 = '1'">
              <xsl:attribute name="checked">checked</xsl:attribute>
            </xsl:if>
          </input>
          <label for="notify_pop3">pop3 (<xsl:value-of select="/cp/strings/inetd_desc_pop3" />)</label>
          <br />

          <input type="checkbox" id="notify_pop3s" name="notify_service_pop3s" value="1">
            <xsl:if test="$notify_service_pop3s = '1'">
              <xsl:attribute name="checked">checked</xsl:attribute>
            </xsl:if>
          </input>
          <label for="notify_pop3s">pop3s (<xsl:value-of select="/cp/strings/inetd_desc_pop3s" />)</label>
          <br />
        </xsl:if>

        <xsl:if test="$postfix_installed = '1'">
          <input type="checkbox" id="notify_postfix" name="notify_service_postfix" value="1">
            <xsl:if test="$notify_service_postfix = '1'">
              <xsl:attribute name="checked">checked</xsl:attribute>
            </xsl:if>
          </input>
          <label for="notify_postfix">postfix (<xsl:value-of select="/cp/strings/service_desc_postfix" />)</label>
          <br />
        </xsl:if>

        <xsl:if test="$postgresql_installed = '1'">
          <input type="checkbox" id="notify_postgresql" name="notify_service_postgresql" value="1">
            <xsl:if test="$notify_service_postgresql = '1'">
              <xsl:attribute name="checked">checked</xsl:attribute>
            </xsl:if>
          </input>
          <label for="notify_postgresql">postgresql (<xsl:value-of select="/cp/strings/service_desc_postgresql" />)</label>
          <br />
        </xsl:if>

        <xsl:if test="$sendmail_installed = '1'">
          <input type="checkbox" id="notify_sendmail" name="notify_service_sendmail" value="1">
            <xsl:if test="$notify_service_sendmail = '1'">
              <xsl:attribute name="checked">checked</xsl:attribute>
            </xsl:if>
          </input>
          <label for="notify_sendmail">sendmail (<xsl:value-of select="/cp/strings/service_desc_sendmail" />)</label>
          <br />
        </xsl:if>

        <xsl:if test="$shell_enabled = '1'">
          <input type="checkbox" id="notify_ssh" name="notify_service_ssh" value="1">
            <xsl:if test="$notify_service_ssh = '1'">
              <xsl:attribute name="checked">checked</xsl:attribute>
            </xsl:if>
          </input>
          <label for="notify_ssh">ssh (<xsl:value-of select="/cp/strings/inetd_desc_ssh" />)</label>
          <br />
        </xsl:if>

        <input type="checkbox" id="notify_vsapd" name="notify_service_vsapd" value="1">
          <xsl:if test="$notify_service_vsapd = '1'">
            <xsl:attribute name="checked">checked</xsl:attribute>
          </xsl:if>
        </input>
        <label for="notify_vsapd">vsapd (<xsl:value-of select="/cp/strings/service_desc_vsapd" />)</label>
        <br />

      </td>
    </tr>

    <tr class="rowodd">
      <td class="label"><xsl:copy-of select="/cp/strings/monitor_notify_reboot" /></td>
      <td class="contentwidth">

        <input type="checkbox" id="notify_server" name="notify_server_reboot" value="1">
          <xsl:if test="$notify_server_reboot = '1'">
            <xsl:attribute name="checked">checked</xsl:attribute>
          </xsl:if>
        </input>
        <label for="notify_server">server (<xsl:value-of select="/cp/strings/monitor_notify_uptime" />)</label>
        <br />

      </td>
    </tr>

    <tr class="controlrow">
      <td colspan="2"> <!-- this space intentionally left blank --> </td>
    </tr>

    <tr class="title">
      <td colspan="2"><xsl:copy-of select="/cp/strings/monitor_email_settings" /></td>
    </tr>
    <tr class="instructionrow">
      <td colspan="2"><xsl:copy-of select="/cp/strings/monitor_email_settings_info" /></td>
    </tr>

    <tr class="rowodd">
      <td class="label"><xsl:copy-of select="/cp/strings/monitor_notify_email_address" /></td>
      <td class="contentwidth">
        <input type="text" name="notify_email_address" size="40" value="{$notify_email_address}" />
        <xsl:copy-of select="/cp/strings/monitor_notify_email_address_note" />
      </td>
    </tr>

    <tr class="rowodd">
      <td class="label"><xsl:copy-of select="/cp/strings/monitor_notify_email_server" /></td>
      <td class="contentwidth">
        <input type="text" autocomplete="off" name="notify_email_server" size="30" value="{$notify_email_server}" />
        <xsl:copy-of select="/cp/strings/monitor_notify_email_server_note" />
      </td>
    </tr>

    <tr class="rowodd">
      <td class="label"><xsl:copy-of select="/cp/strings/monitor_notify_smtp_auth_username" /></td>
      <td class="contentwidth">
        <input type="text" autocomplete="off" name="notify_smtp_auth_username" size="20" value="{$notify_smtp_auth_username}" />
      </td>
    </tr>

    <tr class="rowodd">
      <td class="label"><xsl:copy-of select="/cp/strings/monitor_notify_smtp_auth_password" /></td>
      <td class="contentwidth">
        <input type="password" autocomplete="off" name="notify_smtp_auth_password" size="20" value="" />
      </td>
    </tr>

    <tr class="controlrow">
      <td colspan="2">
        <input class="floatright" type="submit" name="btnCancel" value="{/cp/strings/server_security_btn_cancel}"/>
        <input class="floatright" type="submit" name="btnSave" value="{/cp/strings/server_security_btn_save}" 
          onClick="return validateMonitorForm(
               '{cp:js-escape(/cp/strings/monitor_err_nothing_to_monitor)}',
               '{cp:js-escape(/cp/strings/monitor_err_no_notify_service_selected)}',
               '{cp:js-escape(/cp/strings/monitor_err_max_notify_blank)}',
               '{cp:js-escape(/cp/strings/monitor_err_max_notify_invalid)}',
               '{cp:js-escape(/cp/strings/monitor_err_email_address_blank)}',
               '{cp:js-escape(/cp/strings/monitor_err_email_address_invalid)}',
               '{cp:js-escape(/cp/strings/monitor_err_mail_server_invalid)}',
               '{cp:js-escape(/cp/strings/monitor_err_auth_username_blank)}',
               '{cp:js-escape(/cp/strings/monitor_err_auth_password_blank)}');"
        />
      </td>
    </tr>
  </table>

</xsl:template>

</xsl:stylesheet>
