<?xml version="1.0" encoding="utf-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../cp_global.xsl" />

<xsl:variable name="message">
  <xsl:choose>
    <xsl:when test="/cp/msgs/msg[@name='user_domain_permission']">
      <xsl:copy-of select="/cp/strings/user_domain_err_domain_permission" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='user_domain_add_exists']">
      <xsl:copy-of select="/cp/strings/user_domain_err_add_exists" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='user_domain_admin_bad']">
      <xsl:copy-of select="/cp/strings/user_domain_err_admin_bad" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='user_domain_log_rotate_bad']">
      <xsl:copy-of select="/cp/strings/user_domain_err_log_rotate_bad" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='user_domain_httpd_conf']">
      <xsl:copy-of select="/cp/strings/user_domain_err_httpd_conf" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='user_domain_email_addrs_bad']">
      <xsl:copy-of select="/cp/strings/user_domain_err_email_addrs_bad" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='user_domain_email_addrs_bad']">
      <xsl:copy-of select="/cp/strings/user_domain_err_email_addrs_bad" />
    </xsl:when>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="feedback">
  <xsl:if test="$message != ''">
    <xsl:call-template name="feedback_table">
      <xsl:with-param name="image">
        <xsl:choose>
          <xsl:when test="/cp/vsap/vsap[@type='error']">error</xsl:when>
          <xsl:otherwise>success</xsl:otherwise>
        </xsl:choose>
      </xsl:with-param>
      <xsl:with-param name="message">
        <xsl:copy-of select="$message" />
      </xsl:with-param>
    </xsl:call-template>
  </xsl:if>
</xsl:variable>

<xsl:variable name="type">
  <xsl:value-of select="/cp/form/type" />
</xsl:variable>

<xsl:variable name="src">useradd</xsl:variable>

<xsl:variable name="domain">
  <xsl:value-of select="/cp/form/txtDomain" />
</xsl:variable>

<xsl:variable name="www_alias">
  <xsl:choose>
    <xsl:when test="string(/cp/form/www_alias)">
      <xsl:value-of select="/cp/form/www_alias" />
    </xsl:when>
    <xsl:otherwise>1</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="other_aliases">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='error'] or /cp/form/previous!=''">
      <xsl:value-of select="/cp/form/other_aliases" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="cgi">
  <xsl:choose>
    <xsl:when test="string(/cp/form/cgi)">
      <xsl:value-of select="/cp/form/cgi" />
    </xsl:when>
    <xsl:otherwise>1</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="ssl">
  <xsl:choose>
    <xsl:when test="/cp/form/ssl">
      <xsl:value-of select="/cp/form/ssl" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="end_users">
  <xsl:choose>
    <xsl:when test="/cp/form/end_users">
      <xsl:value-of select="/cp/form/end_users" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="end_users_limit">
  <xsl:choose>
    <xsl:when test="/cp/form/end_users_limit">
      <xsl:value-of select="/cp/form/end_users_limit" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="email_addr">
  <xsl:choose>
    <xsl:when test="/cp/form/email_addr">
      <xsl:value-of select="/cp/form/email_addr" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="email_addr_limit">
  <xsl:choose>
    <xsl:when test="/cp/form/email_addr_limit">
      <xsl:value-of select="/cp/form/email_addr_limit" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="website_logs">
  <xsl:choose>
    <xsl:when test="string(/cp/form/website_logs)">
      <xsl:value-of select="/cp/form/website_logs" />
    </xsl:when>
    <xsl:otherwise>yes</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="log_rotate_select">
  <xsl:choose>
    <xsl:when test="/cp/form/log_rotate_select!=''">
      <xsl:value-of select="/cp/form/log_rotate_select" />
    </xsl:when>
    <xsl:otherwise>yes</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="log_rotate">
  <xsl:choose>
    <xsl:when test="/cp/form/log_rotate!=''">
      <xsl:value-of select="/cp/form/log_rotate" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="log_save">
  <xsl:choose>
    <xsl:when test="/cp/form/log_save">
      <xsl:value-of select="/cp/form/log_save" />
    </xsl:when>
    <xsl:otherwise>yes</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="domain_contact">
  <xsl:choose>
    <xsl:when test="string(/cp/form/domain_contact)">
      <xsl:choose>
        <xsl:when test="/cp/form/old_domain = /cp/form/txtDomain">
          <xsl:value-of select="/cp/form/domain_contact" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="user_name">
            <xsl:value-of select="substring-before(/cp/form/domain_contact,'@')" />
          </xsl:variable>
          <xsl:variable name="domain_name">
            <xsl:value-of select="substring-after(/cp/form/domain_contact,'@')" />
          </xsl:variable>
          <xsl:choose>
            <xsl:when test="$domain_name = /cp/form/old_domain">
              <xsl:value-of select="concat($user_name,'@',/cp/form/txtDomain)" />
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="/cp/form/domain_contact" />
            </xsl:otherwise>
          </xsl:choose>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="concat('root@',/cp/form/txtDomain)" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="eu_prefix">
  <xsl:choose>
    <xsl:when test="$type='eu' or $type='ma'">
      <xsl:variable name="admin">
        <xsl:value-of select="/cp/vsap/vsap[@type='auth']/username" />
      </xsl:variable>
      <xsl:value-of select="/cp/vsap/vsap[@type='user:list']/user[login_id=$admin]/eu_prefix" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="/cp/form/eu_prefix" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="mail_catchall">
  <xsl:choose>
    <xsl:when test="/cp/form/mail_catchall">
      <xsl:value-of select="/cp/form/mail_catchall" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="mail_catchall_custom">
  <xsl:choose>
    <xsl:when test="/cp/form/mail_catchall_custom">
      <xsl:value-of select="/cp/form/mail_catchall_custom" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:template match="/">
  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title">
      <xsl:copy-of select="/cp/strings/cp_title" />
      v<xsl:value-of select="/cp/vsap/vsap[@type='auth']/version" /> : 
      <xsl:copy-of select="/cp/strings/bc_user_add_domain" />
    </xsl:with-param>
    <xsl:with-param name="formaction">user_add_domain.xsl</xsl:with-param>
    <xsl:with-param name="feedback" select="$feedback" />
    <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_add_da" />
    <xsl:with-param name="help_short" select="/cp/strings/user_add_hlp_short" />
    <xsl:with-param name="help_long" select="/cp/strings/user_add_domain_hlp_long" />>
    <xsl:with-param name="breadcrumb">
      <breadcrumb>
        <section>
          <name><xsl:copy-of select="/cp/strings/bc_user_add_domain" /></name>
          <url>#</url>
          <image>UserManagement</image>
        </section>
      </breadcrumb>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

      <script src="{concat($base_url, '/cp/cp.js')}" language="JavaScript"></script>

      <input type="hidden" name="type" value="{/cp/form/type}" />
      <input type="hidden" name="cancel" value="" />

<!--  for user_add_profile.xsl -->
      <input type="hidden" name="save" value="" />
      <input type="hidden" name="mail_next" value="" />
      <input type="hidden" name="preview_next" value="" />
      <input type="hidden" name="old_domain" value="{/cp/form/old_domain}" />
      <input type="hidden" name="old_login" value="{/cp/form/old_login}" />
      <input type="hidden" name="txtFullName" value="{/cp/form/txtFullName}" />
      <input type="hidden" name="txtComments" value="{/cp/form/txtComments}" />
      <input type="hidden" name="txtLoginID" value="{/cp/form/txtLoginID}" />
      <input type="hidden" name="eu_prefix" value="{/cp/form/eu_prefix}" />
      <input type="hidden" name="txtPassword" value="{/cp/form/txtPassword}" />
      <input type="hidden" name="txtConfirmPassword" value="{/cp/form/txtConfirmPassword}" />
      <input type="hidden" name="txtQuota" value="{/cp/form/txtQuota}" />
      <input type="hidden" name="selectName" value="{/cp/form/selectName}" />
      <input type="hidden" name="checkboxUserMail" value="{/cp/form/checkboxUserMail}" />
      <input type="hidden" name="checkboxUserFtp" value="{/cp/form/checkboxUserFtp}" />
      <input type="hidden" name="checkboxUserFM" value="{/cp/form/checkboxUserFM}" />
      <input type="hidden" name="checkboxUserPC" value="{/cp/form/checkboxUserPC}" />
      <input type="hidden" name="checkboxUserShell" value="{/cp/form/checkboxUserShell}" />
      <input type="hidden" name="selectShell" value="{/cp/form/selectShell}" />
      <input type="hidden" name="txtDomain" value="{/cp/form/txtDomain}" />
      <xsl:if test="/cp/form/ip_address">
        <input type="hidden" name="ip_address" value="{/cp/form/ip_address}" />
      </xsl:if>
      <input type="hidden" name="checkboxEndUserMail" value="{/cp/form/checkboxEndUserMail}" />
      <input type="hidden" name="checkboxEndUserFtp" value="{/cp/form/checkboxEndUserFtp}" />
      <input type="hidden" name="checkboxEndUserFM" value="{/cp/form/checkboxEndUserFM}" />
      <input type="hidden" name="checkboxEndUserShell" value="{/cp/form/checkboxEndUserShell}" />
      <input type="hidden" name="checkboxEndUserZeroQuota" value="{/cp/form/checkboxEndUserZeroQuota}" />

<!--  for user_add_mail.xsl -->
      <input type="hidden" name="txtAlias" value="{/cp/form/txtAlias}" />
      <input type="hidden" name="checkboxWebmail" value="{/cp/form/checkboxWebmail}" />
      <input type="hidden" name="checkboxSpamassassin" value="{/cp/form/checkboxSpamassassin}" />
      <input type="hidden" name="checkboxClamav" value="{/cp/form/checkboxClamav}" />

      <table class="formview" border="0" cellspacing="0" cellpadding="0">
        <tr class="title">
          <td colspan="2"><xsl:copy-of select="/cp/strings/cp_title_user_add_domain" /></td>
        </tr>
        <tr class="instructionrow">
          <td colspan="2"><xsl:copy-of select="/cp/strings/cp_instr_user_add_domain" /></td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:copy-of select="/cp/strings/user_add_domain_da" /></td>
          <td class="contentwidth">
            <xsl:value-of select="/cp/form/txtLoginID" />
          </td>
        </tr>
        <tr class="roweven">
          <td class="label"><xsl:copy-of select="/cp/strings/user_add_domain_name" /></td>
          <td class="contentwidth">
            <xsl:value-of select="$domain" /><br />
            <xsl:if test="substring($domain, 1, 4) != 'www.'">
              <input type="checkbox" id="www_alias" name="www_alias" value="1">
                <xsl:if test="$www_alias = '1'">
                  <!-- TRUE if: default case - we aren't coming back from the "preview" page 
                       OR if the value was previously set. -->
                  <xsl:attribute name="checked">true</xsl:attribute>
                </xsl:if>
              </input>
              <label for="www_alias">
                <xsl:copy-of select="/cp/strings/user_add_domain_www_enable" />
                <span class="parenthetichelp"><xsl:copy-of select="concat('(www.',/cp/form/txtDomain,')')" /></span><br />
              </label>
            </xsl:if>
          </td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:value-of select="/cp/strings/cp_label_domain_aliases" /></td>
          <td class="contentwidth">
            <input type="text" name="other_aliases" size="60" value="{$other_aliases}" /> &#160;
            <span class="parenthetichelp"><xsl:value-of select="/cp/strings/cp_instr_other_aliases" /></span>
          </td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:copy-of select="/cp/strings/user_add_domain_web_services" /></td>
          <td class="contentwidth">
            <input type="checkbox" id="cgi" name="cgi" value="1">
              <xsl:if test="$cgi = '1'">
                <!-- defaults to ON -->
                <xsl:attribute name="checked">true</xsl:attribute>
              </xsl:if>
            </input>
            <label for="cgi">
              <xsl:copy-of select="/cp/strings/user_add_domain_web_services_cgi" />
            </label>
            <br />

            <xsl:choose>
              <xsl:when test="/cp/vsap/vsap[@type='auth']/product = 'cloud'">
                <input type="hidden" id="ssl" name="ssl" value="1" />
              </xsl:when>
              <xsl:otherwise>
                
                <input type="checkbox" id="ssl" name="ssl" value="1">
                  <xsl:if test="$ssl = '1'">
                    <!-- defaults to OFF -->
                    <xsl:attribute name="checked">true</xsl:attribute>
                  </xsl:if>
                </input>
                <label for="ssl">
                  <xsl:copy-of select="/cp/strings/user_add_domain_web_services_ssl" />
                  <xsl:copy-of select="/cp/strings/user_add_domain_web_services_ssl_hlp" />
                </label>
                <br />
                
              </xsl:otherwise>
            </xsl:choose>

          </td>
        </tr>
        <tr class="roweven">
          <td class="label"><xsl:copy-of select="/cp/strings/user_add_domain_eu" /></td>
          <td class="contentwidth">
            <xsl:copy-of select="/cp/strings/user_add_domain_eu_hlp" /><br />
            <input type="radio" id="limit_end_users" name="end_users" value="limit">
              <xsl:if test="/cp/form/end_users = 'limit'">
                <!-- defaults to ON -->
                <xsl:attribute name="checked">true</xsl:attribute>
              </xsl:if>
            </input>
            <label for="limit_end_users">
              <xsl:copy-of select="/cp/strings/user_add_domain_max_eu_1" />
            </label>
            <input type="text" name="end_users_limit" size="4" value="{$end_users_limit}" />
            <label for="limit_end_users">
              <xsl:copy-of select="/cp/strings/user_add_domain_max_eu_2" />
            </label>
            <br />
            <input type="radio" id="unlimited_end_users" name="end_users" value="0">
              <xsl:if test="/cp/form/end_users != 'limit'">
                <xsl:attribute name="checked">true</xsl:attribute>
              </xsl:if>
            </input>
            <label for="unlimited_end_users">
              <xsl:copy-of select="/cp/strings/user_add_domain_unlimited_eu" />
            </label>
            <br />
          </td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:copy-of select="/cp/strings/user_add_domain_email" /></td>
          <td class="contentwidth">
            <xsl:copy-of select="/cp/strings/user_add_domain_email_hlp" /><br />
            <input type="radio" id="limit_email_addr" name="email_addr" value="limit">
              <xsl:if test="/cp/form/email_addr = 'limit'">
                <!-- defaults to ON -->
                <xsl:attribute name="checked">true</xsl:attribute>
              </xsl:if>
            </input>
            <label for="limit_email_addr">
              <xsl:copy-of select="/cp/strings/user_add_domain_max_email_1" />
            </label>
            <input type="text" name="email_addr_limit" size="4" value="{$email_addr_limit}" />
            <label for="limit_email_addr">
              <xsl:copy-of select="/cp/strings/user_add_domain_max_email_2" />
            </label>
            <br />
            <input type="radio" id="unlimited_email_addr" name="email_addr" value="0">
              <xsl:if test="/cp/form/email_addr != 'limit'">
                <xsl:attribute name="checked">true</xsl:attribute>
              </xsl:if>
            </input>
            <label for="unlimited_email_addr">
              <xsl:copy-of select="/cp/strings/user_add_domain_unlimited_email" />
            </label>
            <br />
          </td>
        </tr>
        <tr class="roweven">
          <td class="label"><xsl:copy-of select="/cp/strings/user_add_domain_logs" /></td>
          <td class="contentwidth">
            <input type="radio" id="no_website_logs" name="website_logs" value="no" onClick="switchRotationSwitches(this);" >
              <xsl:if test="$website_logs = 'no'">
                <xsl:attribute name="checked">true</xsl:attribute>
              </xsl:if>
            </input>
            <label for="no_website_logs">
              <xsl:copy-of select="/cp/strings/user_add_domain_logs_no_create" />
            </label>
            <br />
            <input type="radio" id="store_website_logs" name="website_logs" value="yes" onClick="switchRotationSwitches(this);" >
              <xsl:if test="$website_logs = 'yes'">
                <!-- defaults to ON -->
                <xsl:attribute name="checked">true</xsl:attribute>
              </xsl:if>
            </input>
            <label for="store_website_logs">
              <xsl:copy-of select="/cp/strings/user_add_domain_logs_create" />
              <xsl:copy-of select="/cp/strings/user_add_domain_logs_create_stats" />
            </label>
            <br />
            <input class="indent" type="radio" id="periodic_log_rotation" name="log_rotate_select" value="yes">
              <xsl:if test="$log_rotate_select = 'yes'">
                <!-- defaults to ON -->
                <xsl:attribute name="checked">true</xsl:attribute>
              </xsl:if>
              <xsl:if test="$website_logs = 'no'">
                <xsl:attribute name="disabled">disabled</xsl:attribute>
              </xsl:if>
            </input>
            <label for="periodic_log_rotation">
              <xsl:copy-of select="/cp/strings/user_add_domain_logs_rotate" />
            </label>
              <select name="log_rotate" size="1">
                <xsl:if test="$website_logs = 'no'">
                  <xsl:attribute name="disabled">disabled</xsl:attribute>
                </xsl:if>
                <option selected="selected" value="daily">
                  <xsl:if test="/cp/form/log_rotate = 'daily' or not(string(/cp/form/log_rotate))">
                    <!-- default -->
                    <xsl:attribute name="selected">true</xsl:attribute>
                  </xsl:if>
                  <xsl:copy-of select="/cp/strings/user_add_domain_daily" />
                </option>
                <option value="weekly">
                  <xsl:if test="/cp/form/log_rotate = 'weekly'">
                    <xsl:attribute name="selected">true</xsl:attribute>
                  </xsl:if>
                  <xsl:copy-of select="/cp/strings/user_add_domain_weekly" />
                </option>
                <option value="monthly">
                  <xsl:if test="/cp/form/log_rotate = 'monthly'">
                    <xsl:attribute name="selected">true</xsl:attribute>
                  </xsl:if>
                  <xsl:copy-of select="/cp/strings/user_add_domain_monthly" />
                </option>
              </select>
            <label for="periodic_log_rotation">
              <xsl:copy-of select="/cp/strings/user_add_domain_logs_rotate_save" />
            </label>
              <select name="log_save" size="1">
                <xsl:if test="/cp/form/website_logs = 'no'">
                  <xsl:attribute name="disabled">disabled</xsl:attribute>
                </xsl:if>
                <option value="1">
                  <xsl:if test="/cp/form/log_save = 1">
                    <xsl:attribute name="selected">true</xsl:attribute>
                  </xsl:if>
                  <xsl:copy-of select="/cp/strings/user_add_domain_logs_save_1" />
                </option>
                <option value="7">
                  <xsl:if test="/cp/form/log_save = 7">
                    <xsl:attribute name="selected">true</xsl:attribute>
                  </xsl:if>
                  <xsl:copy-of select="/cp/strings/user_add_domain_logs_save_7" />
                </option>
                <option value="14">
                  <xsl:if test="/cp/form/log_save = 14">
                    <xsl:attribute name="selected">true</xsl:attribute>
                  </xsl:if>
                  <xsl:copy-of select="/cp/strings/user_add_domain_logs_save_14" />
                </option>
                <option value="30">
                  <xsl:if test="/cp/form/log_save = 30 or not(string(/cp/form/log_save))">
                    <!-- default -->
                    <xsl:attribute name="selected">true</xsl:attribute>
                  </xsl:if>
                  <xsl:copy-of select="/cp/strings/user_add_domain_logs_save_30" />
                </option>
                <option value="60">
                  <xsl:if test="/cp/form/log_save = 60">
                    <xsl:attribute name="selected">true</xsl:attribute>
                  </xsl:if>
                  <xsl:copy-of select="/cp/strings/user_add_domain_logs_save_60" />
                </option>
                <option value="90">
                  <xsl:if test="/cp/form/log_save = 90">
                    <xsl:attribute name="selected">true</xsl:attribute>
                  </xsl:if>
                  <xsl:copy-of select="/cp/strings/user_add_domain_logs_save_90" />
                </option>
                <option value="all">
                  <xsl:if test="/cp/form/log_save = 'all'">
                    <xsl:attribute name="selected">true</xsl:attribute>
                  </xsl:if>
                  <xsl:copy-of select="/cp/strings/user_add_domain_logs_save_all" />
                </option>
              </select>
            <label for="periodic_log_rotation">
              <xsl:copy-of select="/cp/strings/user_add_domain_logs_rotate_save_logs" />
            </label>
            <br />
            <input class="indent" type="radio" id="no_log_rotation" name="log_rotate_select" value="no">
              <xsl:if test="$log_rotate_select = 'no'">
                <xsl:attribute name="checked">true</xsl:attribute>
              </xsl:if>
              <xsl:if test="$website_logs = 'no'">
                <xsl:attribute name="disabled">disabled</xsl:attribute>
              </xsl:if>
            </input>
            <label for="no_log_rotation">
              <xsl:copy-of select="/cp/strings/user_add_domain_logs_no_rotate" />
            </label>
            <br />
          </td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:copy-of select="/cp/strings/user_add_domain_domain_contact" /></td>
          <td class="contentwidth">
            <input type="text" name="domain_contact" value="{$domain_contact}" size="60" />
          </td>
        </tr>
        <tr class="roweven">
          <td class="label"><xsl:copy-of select="/cp/strings/user_add_domain_mail_catchall" /></td>
          <td class="contentwidth">
            <input type="radio" id="mail_catchall_reject" name="mail_catchall" value="reject">
              <xsl:if test="/cp/form/mail_catchall = 'reject' or not(string(/cp/form/mail_catchall))">
                <!-- default -->
                <xsl:attribute name="checked">true</xsl:attribute>
              </xsl:if>
            </input>
            <label for="mail_catchall_reject">
              <xsl:copy-of select="/cp/strings/user_add_domain_mail_catchall_reject" />
            </label>
            <br />
            <input type="radio" id="mail_catchall_delete" name="mail_catchall" value="delete">
              <xsl:if test="/cp/form/mail_catchall = 'delete'">
                <!-- default -->
                <xsl:attribute name="checked">true</xsl:attribute>
              </xsl:if>
            </input>
            <label for="mail_catchall_delete">
              <xsl:copy-of select="/cp/strings/user_add_domain_mail_catchall_delete" />
            </label>
            <br />
            <input type="radio" id="mail_catchall_admin" name="mail_catchall" value="admin">
              <xsl:if test="/cp/form/mail_catchall = 'admin'">
                <!-- default -->
                <xsl:attribute name="checked">true</xsl:attribute>
              </xsl:if>
            </input>
            <label for="mail_catchall_admin">
              <xsl:copy-of select="/cp/strings/user_add_domain_mail_catchall_deliver_dc" />
            </label>
            <br />
            <input type="radio" id="mail_catchall_custom_radio" name="mail_catchall" value="custom">
              <xsl:if test="/cp/form/mail_catchall = 'custom'">
                <!-- default -->
                <xsl:attribute name="checked">true</xsl:attribute>
              </xsl:if>
            </input>
            <label for="mail_catchall_custom_radio">
              <xsl:copy-of select="/cp/strings/user_add_domain_mail_catchall_deliver" />
            </label>
            <input type="text" name="mail_catchall_custom" size="60" value="{/cp/form/mail_catchall_custom}" /><br />
          </td>
        </tr>
        <tr class="controlrow">
          <td colspan="2">
            <input class="floatright" type="button" name="btnCancel" value="{/cp/strings/user_add_domain_btn_cancel}" 
              onClick="document.forms[0].cancel.value='yes';document.forms[0].submit();" />
            <input class="floatright" type="submit" name="btn_next" value="{/cp/strings/user_add_domain_btn_next}" 
              onClick="return validateDomainEdit(
                '{$src}',
                '{cp:js-escape(/cp/strings/user_add_domain_error_null_eus)}',
                '{cp:js-escape(/cp/strings/user_add_domain_error_fmt_eus)}',
                '{cp:js-escape(/cp/strings/user_add_domain_error_null_ems)}',
                '{cp:js-escape(/cp/strings/user_add_domain_error_fmt_ems)}',
                '{cp:js-escape(/cp/strings/user_add_domain_error_null_contact)}',
                '{cp:js-escape(/cp/strings/user_add_domain_error_invalid_contact)}',
                '{cp:js-escape(/cp/strings/user_add_domain_error_invalid_domain)}',
                '{cp:js-escape(/cp/strings/user_add_domain_error_null_catchall)}',
                '{cp:js-escape(/cp/strings/user_add_domain_error_invalid_catchall)}',
                '{cp:js-escape(/cp/strings/user_add_domain_error_invalid_domain_alias)}');" 
            />
            <input class="floatright" type="submit" name="previous" value="{/cp/strings/user_add_domain_btn_previous}" />
          </td>
        </tr>
      </table>

</xsl:template>

</xsl:stylesheet>
