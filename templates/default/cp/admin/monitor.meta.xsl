<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
 <xsl:import href="../../global.meta.xsl"/>
 <xsl:import href="../cp_global.meta.xsl"/>
 <xsl:template match="/">
  <meta>

    <xsl:if test="string(/cp/form/btnCancel)">
      <redirect>
        <path>cp/admin/services.xsl</path>
      </redirect>
    </xsl:if>

    <xsl:call-template name="auth">
      <xsl:with-param name="require_class">sa</xsl:with-param>
    </xsl:call-template>

    <xsl:call-template name="cp_global"/>

    <xsl:call-template name="dovsap">
      <xsl:with-param name="vsap">
        <vsap>
         <xsl:choose>
          <xsl:when test="string(/cp/form/btnSave)">
            <vsap type="sys:monitor:set">
              <monitor_interval><xsl:value-of select="/cp/form/monitor_interval"/></monitor_interval>
              <xsl:if test="/cp/form/dovecot_installed = '1'">
                <autorestart_service_dovecot>
                  <xsl:choose>
                    <xsl:when test="string(/cp/form/autorestart_service_dovecot)">1</xsl:when>
                    <xsl:otherwise>0</xsl:otherwise>
                  </xsl:choose>
                </autorestart_service_dovecot>
              </xsl:if>
              <autorestart_service_ftp>
                <xsl:choose>
                  <xsl:when test="string(/cp/form/autorestart_service_ftp)">1</xsl:when>
                  <xsl:otherwise>0</xsl:otherwise>
                </xsl:choose>
              </autorestart_service_ftp>
              <autorestart_service_httpd>
                <xsl:choose>
                  <xsl:when test="string(/cp/form/autorestart_service_httpd)">1</xsl:when>
                  <xsl:otherwise>0</xsl:otherwise>
                </xsl:choose>
              </autorestart_service_httpd>
              <xsl:if test="/cp/form/dovecot_installed = '0'">
                <autorestart_service_imap>
                  <xsl:choose>
                    <xsl:when test="string(/cp/form/autorestart_service_imap)">1</xsl:when>
                    <xsl:otherwise>0</xsl:otherwise>
                  </xsl:choose>
                </autorestart_service_imap>
                <autorestart_service_imaps>
                  <xsl:choose>
                    <xsl:when test="string(/cp/form/autorestart_service_imaps)">1</xsl:when>
                    <xsl:otherwise>0</xsl:otherwise>
                  </xsl:choose>
                </autorestart_service_imaps>
              </xsl:if>
              <autorestart_service_inetd>
                <xsl:choose>
                  <xsl:when test="string(/cp/form/autorestart_service_inetd)">1</xsl:when>
                  <xsl:otherwise>0</xsl:otherwise>
                </xsl:choose>
              </autorestart_service_inetd>
              <xsl:if test="/cp/form/mailman_installed = '1'">
                <autorestart_service_mailman>
                  <xsl:choose>
                    <xsl:when test="string(/cp/form/autorestart_service_mailman)">1</xsl:when>
                    <xsl:otherwise>0</xsl:otherwise>
                  </xsl:choose>
                </autorestart_service_mailman>
              </xsl:if>
              <xsl:if test="/cp/form/mysql_installed = '1'">
                <autorestart_service_mysqld>
                  <xsl:choose>
                    <xsl:when test="string(/cp/form/autorestart_service_mysqld)">1</xsl:when>
                    <xsl:otherwise>0</xsl:otherwise>
                  </xsl:choose>
                </autorestart_service_mysqld>
              </xsl:if>
              <xsl:if test="/cp/form/dovecot_installed = '0'">
                <autorestart_service_pop3>
                  <xsl:choose>
                    <xsl:when test="string(/cp/form/autorestart_service_pop3)">1</xsl:when>
                    <xsl:otherwise>0</xsl:otherwise>
                  </xsl:choose>
                </autorestart_service_pop3>
                <autorestart_service_pop3s>
                  <xsl:choose>
                    <xsl:when test="string(/cp/form/autorestart_service_pop3s)">1</xsl:when>
                    <xsl:otherwise>0</xsl:otherwise>
                  </xsl:choose>
                </autorestart_service_pop3s>
              </xsl:if>
              <xsl:if test="/cp/form/postfix_installed = '1'">
                <autorestart_service_postfix>
                  <xsl:choose>
                    <xsl:when test="string(/cp/form/autorestart_service_postfix)">1</xsl:when>
                    <xsl:otherwise>0</xsl:otherwise>
                  </xsl:choose>
                </autorestart_service_postfix>
              </xsl:if>
              <xsl:if test="/cp/form/postgresql_installed = '1'">
                <autorestart_service_postgresql>
                  <xsl:choose>
                    <xsl:when test="string(/cp/form/autorestart_service_postgresql)">1</xsl:when>
                    <xsl:otherwise>0</xsl:otherwise>
                  </xsl:choose>
                </autorestart_service_postgresql>
              </xsl:if>
              <autorestart_service_sendmail>
                <xsl:choose>
                  <xsl:when test="string(/cp/form/autorestart_service_sendmail)">1</xsl:when>
                  <xsl:otherwise>0</xsl:otherwise>
                </xsl:choose>
              </autorestart_service_sendmail>
              <autorestart_service_ssh>
                <xsl:choose>
                  <xsl:when test="string(/cp/form/autorestart_service_ssh)">1</xsl:when>
                  <xsl:otherwise>0</xsl:otherwise>
                </xsl:choose>
              </autorestart_service_ssh>
              <autorestart_service_vsapd>
                <xsl:choose>
                  <xsl:when test="string(/cp/form/autorestart_service_vsapd)">1</xsl:when>
                  <xsl:otherwise>0</xsl:otherwise>
                </xsl:choose>
              </autorestart_service_vsapd>
              <notify_events><xsl:value-of select="/cp/form/notify_events"/></notify_events>
              <notify_events_max><xsl:value-of select="/cp/form/notify_events_max"/></notify_events_max>
              <xsl:if test="/cp/form/dovecot_installed = '1'">
                <notify_service_dovecot>
                  <xsl:choose>
                    <xsl:when test="string(/cp/form/notify_service_dovecot)">1</xsl:when>
                    <xsl:otherwise>0</xsl:otherwise>
                  </xsl:choose>
                </notify_service_dovecot>
              </xsl:if>
              <notify_service_ftp>
                <xsl:choose>
                  <xsl:when test="string(/cp/form/notify_service_ftp)">1</xsl:when>
                  <xsl:otherwise>0</xsl:otherwise>
                </xsl:choose>
              </notify_service_ftp>
              <notify_service_httpd>
                <xsl:choose>
                  <xsl:when test="string(/cp/form/notify_service_httpd)">1</xsl:when>
                  <xsl:otherwise>0</xsl:otherwise>
                </xsl:choose>
              </notify_service_httpd>
              <xsl:if test="/cp/form/dovecot_installed = '0'">
                <notify_service_imap>
                  <xsl:choose>
                    <xsl:when test="string(/cp/form/notify_service_imap)">1</xsl:when>
                    <xsl:otherwise>0</xsl:otherwise>
                  </xsl:choose>
                </notify_service_imap>
                <notify_service_imaps>
                  <xsl:choose>
                    <xsl:when test="string(/cp/form/notify_service_imaps)">1</xsl:when>
                    <xsl:otherwise>0</xsl:otherwise>
                  </xsl:choose>
                </notify_service_imaps>
              </xsl:if>
              <notify_service_inetd>
                <xsl:choose>
                  <xsl:when test="string(/cp/form/notify_service_inetd)">1</xsl:when>
                  <xsl:otherwise>0</xsl:otherwise>
                </xsl:choose>
              </notify_service_inetd>
              <xsl:if test="/cp/form/mailman_installed = '1'">
                <notify_service_mailman>
                  <xsl:choose>
                    <xsl:when test="string(/cp/form/notify_service_mailman)">1</xsl:when>
                    <xsl:otherwise>0</xsl:otherwise>
                  </xsl:choose>
                </notify_service_mailman>
              </xsl:if>
              <xsl:if test="/cp/form/mysql_installed = '1'">
                <notify_service_mysqld>
                  <xsl:choose>
                    <xsl:when test="string(/cp/form/notify_service_mysqld)">1</xsl:when>
                    <xsl:otherwise>0</xsl:otherwise>
                  </xsl:choose>
                </notify_service_mysqld>
              </xsl:if>
              <xsl:if test="/cp/form/dovecot_installed = '0'">
                <notify_service_pop3>
                  <xsl:choose>
                    <xsl:when test="string(/cp/form/notify_service_pop3)">1</xsl:when>
                    <xsl:otherwise>0</xsl:otherwise>
                  </xsl:choose>
                </notify_service_pop3>
                <notify_service_pop3s>
                  <xsl:choose>
                    <xsl:when test="string(/cp/form/notify_service_pop3s)">1</xsl:when>
                    <xsl:otherwise>0</xsl:otherwise>
                  </xsl:choose>
                </notify_service_pop3s>
              </xsl:if>
              <xsl:if test="/cp/form/postfix_installed = '1'">
                <notify_service_postfix>
                  <xsl:choose>
                    <xsl:when test="string(/cp/form/notify_service_postfix)">1</xsl:when>
                    <xsl:otherwise>0</xsl:otherwise>
                  </xsl:choose>
                </notify_service_postfix>
              </xsl:if>
              <xsl:if test="/cp/form/postgresql_installed = '1'">
                <notify_service_postgresql>
                  <xsl:choose>
                    <xsl:when test="string(/cp/form/notify_service_postgresql)">1</xsl:when>
                    <xsl:otherwise>0</xsl:otherwise>
                  </xsl:choose>
                </notify_service_postgresql>
              </xsl:if>
              <notify_service_sendmail>
                <xsl:choose>
                  <xsl:when test="string(/cp/form/notify_service_sendmail)">1</xsl:when>
                  <xsl:otherwise>0</xsl:otherwise>
                </xsl:choose>
              </notify_service_sendmail>
              <notify_service_ssh>
                <xsl:choose>
                  <xsl:when test="string(/cp/form/notify_service_ssh)">1</xsl:when>
                  <xsl:otherwise>0</xsl:otherwise>
                </xsl:choose>
              </notify_service_ssh>
              <notify_service_vsapd>
                <xsl:choose>
                  <xsl:when test="string(/cp/form/notify_service_vsapd)">1</xsl:when>
                  <xsl:otherwise>0</xsl:otherwise>
                </xsl:choose>
              </notify_service_vsapd>
              <notify_server_reboot>
                <xsl:choose>
                  <xsl:when test="string(/cp/form/notify_server_reboot)">1</xsl:when>
                  <xsl:otherwise>0</xsl:otherwise>
                </xsl:choose>
              </notify_server_reboot>
              <notify_email_address><xsl:value-of select="/cp/form/notify_email_address"/></notify_email_address>
              <notify_email_server><xsl:value-of select="/cp/form/notify_email_server"/></notify_email_server>
              <notify_smtp_auth_username><xsl:value-of select="/cp/form/notify_smtp_auth_username"/></notify_smtp_auth_username>
              <notify_smtp_auth_password><xsl:value-of select="/cp/form/notify_smtp_auth_password"/></notify_smtp_auth_password>
              <locale><xsl:value-of select="/cp/request/locale"/></locale>
            </vsap>
          </xsl:when>
          <xsl:otherwise>
            <vsap type="sys:monitor:get"/>
          </xsl:otherwise>
         </xsl:choose>
	</vsap>
      </xsl:with-param>
    </xsl:call-template>

    <xsl:if test="/cp/form/btnSave != ''">
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='sys:monitor:set']/code = 100">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">monitor_err_not_authorized</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='sys:monitor:set']/code = 200">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">monitor_err_interval_invalid</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='sys:monitor:set']/code = 201">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">monitor_err_nothing_to_monitor</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='sys:monitor:set']/code = 202">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">monitor_err_no_notify_service_selected</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='sys:monitor:set']/code = 203">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">monitor_err_max_notify_blank</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='sys:monitor:set']/code = 204">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">monitor_err_max_notify_invalid</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='sys:monitor:set']/code = 205">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">monitor_err_email_address_blank</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='sys:monitor:set']/code = 206">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">monitor_err_email_address_invalid</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='sys:monitor:set']/code = 207">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">monitor_err_mail_server_invalid</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='sys:monitor:set']/code = 208">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">monitor_err_auth_username_blank</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='sys:monitor:set']/code = 209">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">monitor_err_auth_password_blank</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='sys:monitor:set']/code = 210">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">monitor_err_mail_connect_fail</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='sys:monitor:set']/code = 211">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">monitor_err_mail_auth_fail</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">monitor_set_prefs_success</xsl:with-param>
          </xsl:call-template>
          <!-- redirect on success -->
          <redirect>
           <path>/cp/admin/services.xsl</path>
          </redirect>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>

   <showpage/>

  </meta>
 </xsl:template>
</xsl:stylesheet>
