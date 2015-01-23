<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../../global.meta.xsl" />
<xsl:import href="../cp_global.meta.xsl" />
<xsl:template match="/">
<meta>

<xsl:if test="string(/cp/form/btnCancel)">
  <redirect>
    <path>cp/users/index.xsl</path>
  </redirect>
</xsl:if>

<xsl:call-template name="auth">
  <xsl:with-param name="require_class">ma</xsl:with-param>
  <xsl:with-param name="check_diskspace">0</xsl:with-param>
</xsl:call-template>

<xsl:call-template name="cp_global"/>

<xsl:call-template name="dovsap">
  <xsl:with-param name="vsap">
    <vsap>
    <xsl:if test="string(/cp/form/btnSave) or string(/cp/form/btnSaveAnother)">
      <vsap type="user:add">
        <fullname><xsl:value-of select="/cp/form/txtFullName" /></fullname>
        <comments><xsl:value-of select="/cp/form/txtComments" /></comments>
        <login_id><xsl:value-of select="/cp/form/txtLoginID_Prefix" /><xsl:value-of select="/cp/form/txtLoginID" /></login_id>
        <password><xsl:value-of select="/cp/form/txtPassword" /></password>
        <confirm_password><xsl:value-of select="/cp/form/txtConfirmPassword" /></confirm_password>
        <email_prefix><xsl:value-of select="/cp/form/txtAlias" /></email_prefix>
        <quota><xsl:value-of select="/cp/form/txtQuota" /></quota>
        <xsl:choose>
          <xsl:when test="/cp/form/type='da'">
            <da>
              <domain><xsl:value-of select="/cp/form/txtDomain" /></domain>
              <xsl:if test="/cp/vsap/vsap[@type='auth']/platform='freebsd6' or /cp/vsap/vsap[@type='auth']/platform='linux'">
                <xsl:if test="/cp/form/ip_address">
                  <ip><xsl:value-of select="/cp/form/ip_address"/></ip>
                </xsl:if>
              </xsl:if>
              <xsl:if test="string(/cp/form/checkboxUserMail)">
                <mail_privs/>
              </xsl:if>
              <xsl:if test="string(/cp/form/checkboxUserMail) and string(/cp/form/checkboxWebmail)">
                <webmail_privs/>
              </xsl:if>
              <xsl:if test="string(/cp/form/checkboxEndUserMail)">
                <eu_capa_mail/>
              </xsl:if>
              <xsl:if test="string(/cp/form/checkboxUserFtp)">
                <ftp_privs/>
              </xsl:if>
              <xsl:if test="string(/cp/form/checkboxUserFM)">
                <fileman_privs/>
              </xsl:if>
              <xsl:if test="string(/cp/form/checkboxUserPC)">
                <podcast_privs/>
              </xsl:if>
              <xsl:if test="string(/cp/form/checkboxEndUserFtp)">
                <eu_capa_ftp/>
              </xsl:if>
              <xsl:if test="string(/cp/form/checkboxEndUserFM)">
                <eu_capa_fileman/>
              </xsl:if>
              <xsl:if test="string(/cp/form/checkboxUserShell)">
                <shell_privs/>
                <shell><xsl:value-of select="/cp/form/selectShell" /></shell>
              </xsl:if>
              <xsl:if test="string(/cp/form/checkboxEndUserShell)">
                <eu_capa_shell/>
              </xsl:if>
              <xsl:if test="string(/cp/form/checkboxEndUserZeroQuota)">
                <eu_capa_zeroquota/>
              </xsl:if>
            </da>
            <eu_prefix><xsl:value-of select="/cp/form/eu_prefix" /></eu_prefix>
          </xsl:when>
          <xsl:otherwise>
            <eu>
              <domain><xsl:value-of select="/cp/form/selectName" /></domain>
              <xsl:if test="string(/cp/form/checkboxUserMail)">
                <mail_privs/>
              </xsl:if>
              <xsl:if test="string(/cp/form/checkboxUserMail) and string(/cp/form/checkboxWebmail)">
                <webmail_privs/>
              </xsl:if>
              <xsl:if test="string(/cp/form/checkboxUserFtp)">
                <ftp_privs/>
              </xsl:if>
              <xsl:if test="string(/cp/form/checkboxUserFM)">
                <fileman_privs/>
              </xsl:if>
              <xsl:if test="string(/cp/form/checkboxUserShell)">
                <shell_privs/>
                <shell><xsl:value-of select="/cp/form/selectShell" /></shell>
              </xsl:if>
            </eu>
            <xsl:choose>
              <xsl:when test="/cp/form/type='ma'">
                <mail_admin>1</mail_admin>
              </xsl:when>
              <xsl:otherwise>
                <mail_admin>0</mail_admin>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>
      </vsap>
  
      <xsl:if test="/cp/form/type='da'">
        <vsap type="domain:add">
          <admin><xsl:value-of select="/cp/form/txtLoginID" /></admin>
          <domain><xsl:value-of select="/cp/form/txtDomain" /></domain>
          <xsl:if test="/cp/vsap/vsap[@type='auth']/platform='freebsd6' or /cp/vsap/vsap[@type='auth']/platform='linux'">
            <xsl:if test="/cp/form/ip_address">
              <ip><xsl:value-of select="/cp/form/ip_address"/></ip>
            </xsl:if>
          </xsl:if>
          <www_alias>
            <xsl:choose>
              <xsl:when test="/cp/form/www_alias = 1">1</xsl:when>
              <xsl:otherwise>0</xsl:otherwise>
            </xsl:choose>
          </www_alias>
          <other_aliases><xsl:value-of select="/cp/form/other_aliases" /></other_aliases>
          <cgi>
            <xsl:choose>
              <xsl:when test="/cp/form/cgi = 1">1</xsl:when>
              <xsl:otherwise>0</xsl:otherwise>
            </xsl:choose>
          </cgi>
          <ssl>
            <xsl:choose>
              <xsl:when test="/cp/form/ssl = 1">1</xsl:when>
              <xsl:otherwise>0</xsl:otherwise>
            </xsl:choose>
          </ssl>
          <end_users>
            <xsl:choose>
              <xsl:when test="/cp/form/end_users = 'limit'"><xsl:value-of select="/cp/form/end_users_limit" /></xsl:when>
              <xsl:otherwise>unlimited</xsl:otherwise>
            </xsl:choose>
          </end_users>
          <email_addrs>
            <xsl:choose>
              <xsl:when test="/cp/form/email_addr = 'limit'"><xsl:value-of select="/cp/form/email_addr_limit" /></xsl:when>
              <xsl:otherwise>unlimited</xsl:otherwise>
            </xsl:choose>
          </email_addrs>
          <website_logs><xsl:value-of select="/cp/form/website_logs" /></website_logs>
          <xsl:if test="/cp/form/log_rotate_select != 'no'">
            <log_rotate><xsl:value-of select="/cp/form/log_rotate" /></log_rotate>
            <log_save><xsl:value-of select="/cp/form/log_save" /></log_save>
          </xsl:if>
          <domain_contact><xsl:value-of select="/cp/form/domain_contact" /></domain_contact>
          <mail_catchall>
            <xsl:choose>
              <xsl:when test="/cp/form/mail_catchall = 'custom'">
                <xsl:value-of select="/cp/form/mail_catchall_custom" />
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="/cp/form/mail_catchall" />
              </xsl:otherwise>
            </xsl:choose>
          </mail_catchall>
        </vsap>

        <!-- add a mail entry for the domain contact -->
        <vsap type="mail:addresses:add">
          <source><xsl:value-of select="/cp/form/domain_contact" /></source>
          <dest><xsl:value-of select="/cp/form/txtLoginID" /></dest>
        </vsap>
      </xsl:if>

      <xsl:if test="string(/cp/form/checkboxUserMail)">
        <vsap type="user:mail:setup">
          <user><xsl:value-of select="/cp/form/txtLoginID_Prefix" /><xsl:value-of select="/cp/form/txtLoginID" /></user>
          <xsl:choose>
            <xsl:when test="/cp/form/type='da'">
              <domain><xsl:value-of select="/cp/form/txtDomain" /></domain>
            </xsl:when>
            <xsl:otherwise>
              <domain><xsl:value-of select="/cp/form/selectName" /></domain>
            </xsl:otherwise>
          </xsl:choose>
          <email_prefix><xsl:value-of select="/cp/form/txtAlias" /></email_prefix>
          <xsl:if test="string(/cp/form/checkboxWebmail)">
            <capa_webmail/>
          </xsl:if>
          <xsl:if test="string(/cp/form/checkboxSpamassassin)">
            <capa_spamassassin/>
          </xsl:if>
          <xsl:if test="string(/cp/form/checkboxClamav)">
            <capa_clamav/>
          </xsl:if>
        </vsap>
        <!-- enable SpamAssassin for user by default when capa is granted (per USE08994) -->
        <xsl:if test="string(/cp/form/checkboxSpamassassin)">
          <vsap type="mail:spamassassin:enable">
            <user><xsl:value-of select="/cp/form/txtLoginID_Prefix" /><xsl:value-of select="/cp/form/txtLoginID" /></user>
          </vsap>
        </xsl:if>
        <!-- enable ClamAV for user by default when capa is granted (per USE08994) -->
        <xsl:if test="string(/cp/form/checkboxClamav)">
          <vsap type="mail:clamav:enable">
            <user><xsl:value-of select="/cp/form/txtLoginID_Prefix" /><xsl:value-of select="/cp/form/txtLoginID" /></user>
          </vsap>
        </xsl:if>
      </xsl:if>
    </xsl:if> <!-- btnSave, btnSaveAnother -->

      <vsap type="user:properties">
        <user><xsl:value-of select="/cp/vsap/vsap[@type='auth']/username"/></user>
      </vsap>
<!-- fix for bug 4811 - need domain:list to determine whether to display 'add end user' and 'add email address' -->
      <vsap type="domain:list">
        <properties />
      </vsap>
    </vsap>
  </xsl:with-param>
</xsl:call-template>

<!-- this needs to be done after user:add -->
<xsl:call-template name="dovsap">
  <xsl:with-param name="vsap">
    <vsap>
      <vsap type="diskspace" />
    </vsap>
  </xsl:with-param>
</xsl:call-template>

<xsl:choose>
  <xsl:when test="/cp/form/btnPreviewPrevious">
    <xsl:choose>
      <xsl:when test="/cp/form/type='da'">
        <redirect>
          <path>cp/users/user_add_domain.xsl</path>
        </redirect>
      </xsl:when>
      <xsl:when test="string(/cp/form/checkboxUserMail)">
        <redirect>
          <path>cp/users/user_add_mail.xsl</path>
        </redirect>
      </xsl:when>
      <xsl:otherwise>
        <redirect>
          <path>cp/users/user_add_profile.xsl</path>
        </redirect>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:when>
</xsl:choose>

<!--
  This page has the following events defined:

  miscellaneious failure conditions defined 
  user_add_successful

  TODO: If user:add ok, but mail:setup failed - have to do something about rm'ing the user
        likewise if user:add,mail:setup successful, but add:domain failed

-->
<xsl:if test="/cp/form/btnSave or /cp/form/btnSaveAnother">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='error']/@caller='user:add'">
      <!-- set a generic error to notify xsl file that error did occur -->
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">user_add_failure</xsl:with-param>
      </xsl:call-template>
      <xsl:choose>
<!-- skipping 100, 200-220 : these are redundant and already tested before calling vsap -->
<!-- skipping 101-104 : inapplicable error conditions to user:add -->
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:add']/code = 105">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_permission</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:add']/code = 205">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_login_bad_chars</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:add']/code = 206">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_login_first_char_invalid</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:add']/code = 221">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_eu_quota_exceeded</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:add']/code = 222">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_unknown_domain</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:add']/code = 223">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_service_verboten</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:add']/code = 224">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_vadduser_error</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:add']/code = 225">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_login_exists</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:add']/code = 227">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_eu_quota_allocation_failure</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:add']/code = 228">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_home_exists</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:add']/code = 229">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">email_bad_chars</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:add']/code = 230">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_prefix_too_long</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:add']/code = 231">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_prefix_bad_chars</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:add']/code = 232">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_prefix_first_char_invalid</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:add']/code = 233">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_prefix_duplicate</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
      </xsl:choose>
      <redirect>
        <path>cp/users/user_add_profile.xsl</path>
      </redirect>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='error']/@caller='user:mail:setup'">
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:mail:setup']/code = 100">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_mail_permission</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:mail:setup']/code = 200">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_mail_user_missing</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:mail:setup']/code = 201">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_mail_user_unknown</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:mail:setup']/code = 202">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_mail_domain_missing</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:mail:setup']/code = 203">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_mail_domain_unknown</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:mail:setup']/code = 204">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_mail_prefix_invalid</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
      </xsl:choose>
      <redirect>
        <path>cp/users/user_add_mail.xsl</path>
      </redirect>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='error']/@caller='domain:add'">
<!-- skipping 100,102-104,111 : these are redundant and already tested before calling vsap -->
<!-- skipping 109-110,113 : inapplicable to domain:add -->
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='domain:add']/code = 101">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_domain_permission</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='domain:add']/code = 105">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_domain_add_exists</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='domain:add']/code = 106">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_domain_admin_bad</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='domain:add']/code = 107">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_domain_log_rotate_bad</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='domain:add']/code = 108">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_domain_httpd_conf</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='domain:add']/code = 112">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_domain_email_addrs_bad</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='domain:add']/code = 113">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_domain_email_addrs_bad</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
      </xsl:choose>
      <redirect>
        <path>cp/users/user_add_domain.xsl</path>
      </redirect>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='error']">
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">user_internal_error</xsl:with-param>
      </xsl:call-template>
<!-- for now redirecting to first page - may need to change domain name -->
      <redirect>
        <path>cp/users/user_add_profile.xsl</path>
      </redirect>
    </xsl:when>
    <xsl:otherwise>
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">user_add_successful</xsl:with-param>
      </xsl:call-template>
      <xsl:choose>
        <xsl:when test="string(/cp/form/btnSaveAnother)">
          <redirect>
            <path>cp/users/user_add_profile.xsl</path>
          </redirect>
        </xsl:when>
        <xsl:otherwise>
          <redirect>
            <path>cp/users/index.xsl</path>
          </redirect>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:otherwise>
  </xsl:choose>
</xsl:if>

<showpage />

</meta>
</xsl:template>
</xsl:stylesheet>
