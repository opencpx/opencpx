<?xml version="1.0" encoding="utf-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../cp_global.xsl" />

<xsl:variable name="message">
  <xsl:choose>
    <xsl:when test="/cp/msgs/msg[@name='domain_add_successful']">
      '<xsl:copy-of select="/cp/form/domain" />'<xsl:copy-of select="/cp/strings/cp_msg_domain_add" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='domain_permission']">
      '<xsl:copy-of select="/cp/strings/domain_err_domain_permission" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='domain_add_exists']">
      '<xsl:value-of select="/cp/form/domain" />'<xsl:copy-of select="/cp/strings/domain_err_add_exists" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='domain_admin_bad']">
      '<xsl:copy-of select="/cp/strings/domain_err_admin_bad" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='domain_log_rotate_bad']">
      '<xsl:copy-of select="/cp/strings/domain_err_log_rotate_bad" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='domain_httpd_conf']">
      '<xsl:copy-of select="/cp/strings/domain_err_httpd_conf" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='domain_email_addrs_bad']">
      '<xsl:copy-of select="/cp/strings/domain_err_email_addrs_bad" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='domain_email_addrs_bad']">
      '<xsl:copy-of select="/cp/strings/domain_err_email_addrs_bad" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='vaddhost_failed']">
      '<xsl:copy-of select="/cp/strings/domain_add_error_vaddhost_failed" />
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

<xsl:variable name="admin">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='error'] or /cp/form/previous!=''">
      <xsl:value-of select="/cp/form/admin" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="domain">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='error'] or /cp/form/previous!=''">
      <xsl:value-of select="/cp/form/domain" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="www_alias">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='error'] or /cp/form/previous!=''">
      <xsl:value-of select="/cp/form/www_alias" />
    </xsl:when>
    <xsl:otherwise>1</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="ip_address">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='error'] or /cp/form/previous!=''">
      <xsl:value-of select="/cp/form/ip_address" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
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
    <xsl:when test="/cp/vsap/vsap[@type='error'] or /cp/form/previous!=''">
      <xsl:value-of select="/cp/form/cgi" />
    </xsl:when>
    <xsl:otherwise>0</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="ssl">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='error'] or /cp/form/previous!=''">
      <xsl:value-of select="/cp/form/ssl" />
    </xsl:when>
    <xsl:otherwise>0</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="end_users">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='error'] or /cp/form/previous!=''">
      <xsl:value-of select="/cp/form/end_users" />
    </xsl:when>
    <xsl:otherwise>0</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="end_users_limit">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='error'] or /cp/form/previous!=''">
      <xsl:value-of select="/cp/form/end_users_limit" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="/cp/strings/cp_domains_eu_limit" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="email_addr">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='error'] or /cp/form/previous!=''">
      <xsl:value-of select="/cp/form/email_addr" />
    </xsl:when>
    <xsl:otherwise>0</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="email_addr_limit">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='error'] or /cp/form/previous!=''">
      <xsl:value-of select="/cp/form/email_addr_limit" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="/cp/strings/cp_domains_email_limit" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="website_logs">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='error'] or /cp/form/previous!=''">
      <xsl:value-of select="/cp/form/website_logs" />
    </xsl:when>
    <xsl:otherwise>yes</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="log_rotate_select">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='error'] or /cp/form/previous!=''">
      <xsl:value-of select="/cp/form/log_rotate_select" />
    </xsl:when>
    <xsl:otherwise>yes</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="log_rotate">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='error'] or /cp/form/previous!=''">
      <xsl:value-of select="/cp/form/log_rotate" />
    </xsl:when>
    <xsl:otherwise>daily</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="log_save">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='error'] or /cp/form/previous!=''">
      <xsl:value-of select="/cp/form/log_save" />
    </xsl:when>
    <xsl:otherwise>30</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="domain_contact">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='error'] or /cp/form/previous!=''">
      <xsl:value-of select="/cp/form/domain_contact" />
    </xsl:when>
    <xsl:otherwise>root@</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="mail_catchall">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='error'] or /cp/form/previous!=''">
      <xsl:value-of select="/cp/form/mail_catchall" />
    </xsl:when>
    <xsl:otherwise>reject</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="mail_catchall_custom">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='error'] or /cp/form/previous!=''">
      <xsl:value-of select="/cp/form/mail_catchall_custom" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:template match="/">
  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title"><xsl:copy-of select="/cp/strings/cp_title" /> : <xsl:copy-of select="/cp/strings/bc_domain_add_setup" /></xsl:with-param>
    <xsl:with-param name="formaction">domain_add.xsl</xsl:with-param>
    <xsl:with-param name="feedback" select="$feedback" />
    <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_add_domain" />
    <xsl:with-param name="help_short" select="/cp/strings/domain_add_setup_hlp_short" />
    <xsl:with-param name="help_long" select="/cp/strings/domain_add_setup_hlp_long" />
    <xsl:with-param name="breadcrumb">
      <breadcrumb>
        <section>
          <name><xsl:copy-of select="/cp/strings/bc_domain_add_setup" /></name>
          <url>#</url>
          <image>DomainManagement</image>
        </section>
      </breadcrumb>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

      <script src="{concat($base_url, '/cp/cp.js')}" language="JavaScript"></script>

      <input type="hidden" name="cancel" value="" />
      <input type="hidden" name="next" value="" />

      <table class="formview" border="0" cellspacing="0" cellpadding="0">
        <tr class="title">
          <td colspan="2"><xsl:copy-of select="/cp/strings/cp_title_domain_add_setup" /></td>
        </tr>
        <tr class="instructionrow">
          <td colspan="2"><xsl:copy-of select="/cp/strings/cp_instr_domain_add" /></td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:copy-of select="/cp/strings/cp_label_da" /></td>
          <td class="contentwidth">
            <xsl:copy-of select="/cp/strings/cp_instr_domain_add_da" /><br />
            <select name="admin" size="1">
              <xsl:for-each select="/cp/vsap/vsap[@type='user:list_da_eligible']/admin">
                <xsl:sort select="translate(., 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')" />
                <option value="{.}">
                  <xsl:if test="$admin = .">
                    <xsl:attribute name="selected">true</xsl:attribute>
                  </xsl:if>
                  <xsl:choose>
                    <xsl:when test=". = 'apache'">
                      <xsl:value-of select="/cp/strings/domain_list_primary_admin" /> (apache)
                    </xsl:when>
                    <xsl:when test=". = 'www'">
                      <xsl:value-of select="/cp/strings/domain_list_primary_admin" /> (www)
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="." />
                    </xsl:otherwise>
                  </xsl:choose>
                </option>
              </xsl:for-each>
            </select>
          </td>
        </tr>
        <tr class="roweven">
          <td class="label"><xsl:copy-of select="/cp/strings/cp_label_domain" /></td>
          <td class="contentwidth">
            <xsl:choose>
              <xsl:when test="/cp/vsap/vsap[@type='auth']/product = 'cloud'">
                <input type="text" id="domain" name="domain" size="42" value="{$domain}" onBlur="checkWwwDomainAlias('{cp:js-escape(/cp/strings/domain_add_confirm_www_not_alias)}');" />
              </xsl:when>
              <xsl:otherwise>
                <input type="text" name="domain" size="42" value="{$domain}" onChange="populateDomainContact(this.value,'root@');" />
              </xsl:otherwise>
            </xsl:choose>
            <span class="parenthetichelp">&#160;<xsl:copy-of select="/cp/strings/cp_instr_domain" /></span><br />
              <input type="checkbox" id="www_alias" name="www_alias" value="1">
              <xsl:if test="$www_alias = 1">
                <!-- TRUE if: default case - we aren't coming back from the "preview" page 
                     OR if the value was previously set. -->
                <xsl:attribute name="checked">true</xsl:attribute>
              </xsl:if>
            </input>
            <label class="textElementEnabled" id="enableWwwDomAlias" for="www_alias">
              <xsl:copy-of select="/cp/strings/cp_domains_enable_www" />
              <span class="parenthetichelp"><xsl:copy-of select="/cp/strings/cp_instr_www" /></span><br />
            </label>
          </td>
        </tr>
        <xsl:choose>
          <xsl:when test="/cp/vsap/vsap[@type='auth']/platform='freebsd6' or /cp/vsap/vsap[@type='auth']/platform='linux'">

            <tr class="roweven">
              <td class="label"><xsl:copy-of select="/cp/strings/cp_label_ip_address" /></td>
              <td class="contentwidth">
                <select name="ip_address" size="1">
                    <xsl:for-each select="/cp/vsap/vsap[@type='domain:list_ips']/ip">
                      <xsl:choose>
                        <xsl:when test=". = $ip_address">
                          <option value="{.}" selected="true">
                            <xsl:value-of select="."/>
                            <xsl:if test="position() = 1">
                              (main)
                            </xsl:if>
                          </option>
                        </xsl:when>
                        <xsl:otherwise>
                          <option value="{.}">
                            <xsl:value-of select="."/>
                            <xsl:if test="position() = 1">
                              (main)
                            </xsl:if>
                          </option>
                        </xsl:otherwise>
                      </xsl:choose>
                    </xsl:for-each>
                </select>
              </td>
            </tr>
          </xsl:when>
          <xsl:otherwise>  <!-- freebsd4 -->
            <tr class="roweven">
              <td class="label"><xsl:copy-of select="/cp/strings/cp_label_ip_address" /></td>
              <td class="contentwidth">
                <xsl:value-of select="/cp/vsap/vsap[@type='domain:list_ips']/ip[1]"/>
                <input type="hidden" name="ip_address" value="{/cp/vsap/vsap[@type='domain:list_ips']/ip[1]}" />
              </td>
            </tr>
          </xsl:otherwise>
        </xsl:choose>

        <tr class="rowodd">
          <td class="label"><xsl:value-of select="/cp/strings/cp_label_domain_aliases" /></td>
          <td class="contentwidth">
            <input type="text" name="other_aliases" size="60" value="{$other_aliases}" />
            <span class="parenthetichelp"><xsl:value-of select="/cp/strings/cp_instr_other_aliases" /></span>
          </td>
        </tr>
        <tr class="roweven">
          <td class="label"><xsl:copy-of select="/cp/strings/cp_label_web_services" /></td>
          <td class="contentwidth">
            <input type="checkbox" id="cgi" name="cgi" value="1">
              <xsl:if test="$cgi = 1">
                <!-- defaults to ON -->
                <xsl:attribute name="checked">true</xsl:attribute>
              </xsl:if>
            </input>
            <label for="cgi"><xsl:copy-of select="/cp/strings/cp_service_cgi" /></label><br />

            <xsl:choose>
              <xsl:when test="/cp/vsap/vsap[@type='auth']/product = 'cloud'">
                <input type="hidden" id="ssl" name="ssl" value="1" />
              </xsl:when>
              <xsl:otherwise>

                <input type="checkbox" id="ssl" name="ssl" value="1">
                  <xsl:if test="$ssl = 1">
                    <!-- defaults to OFF -->
                    <xsl:attribute name="checked">true</xsl:attribute>
                  </xsl:if>
                </input>
                <label for="ssl"><xsl:copy-of select="/cp/strings/cp_service_ssl" /></label><br />

              </xsl:otherwise>
            </xsl:choose>

          </td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:copy-of select="/cp/strings/cp_label_eus" /></td>
          <td class="contentwidth">
            <xsl:copy-of select="/cp/strings/cp_domains_admin_eus" /><br />
            <input type="radio" id="limit_end_users" name="end_users" value="limit">
              <xsl:if test="$end_users = 'limit'">
                <!-- defaults to ON -->
                <xsl:attribute name="checked">true</xsl:attribute>
              </xsl:if>
            </input>
            <label for="limit_end_users">
              <xsl:copy-of select="/cp/strings/cp_domains_max_eu_1" />
            </label>
            <input type="text" name="end_users_limit" size="4" value="{$end_users_limit}" /> 
            <label for="limit_end_users">
              <xsl:copy-of select="/cp/strings/cp_domains_max_eu_2" />
            </label>
            <br />
            <input type="radio" id="unlimited_end_users" name="end_users" value="0">
              <xsl:if test="$end_users = 0">
                <xsl:attribute name="checked">true</xsl:attribute>
              </xsl:if>
            </input>
            <label for="unlimited_end_users">
              <xsl:copy-of select="/cp/strings/cp_domains_unlimited_eu" />
            </label>
            <br />
          </td>
        </tr>
        <tr class="roweven">
          <td class="label"><xsl:copy-of select="/cp/strings/cp_label_email_addresses" /></td>
          <td class="contentwidth">
            <xsl:copy-of select="/cp/strings/cp_domains_admin_emails" /><br />
            <input type="radio" id="limit_email_addr" name="email_addr" value="limit">
              <xsl:if test="$email_addr = 'limit'">
                <!-- defaults to ON -->
                <xsl:attribute name="checked">true</xsl:attribute>
              </xsl:if>
            </input>
            <label for="limit_email_addr">
              <xsl:copy-of select="/cp/strings/cp_domains_max_emails_1" />
            </label>
            <input type="text" name="email_addr_limit" size="4" value="{$email_addr_limit}" /> 
            <label for="limit_email_addr">
              <xsl:copy-of select="/cp/strings/cp_domains_max_emails_2" />
            </label>
            <br />
            <input type="radio" id="unlimited_email_addr" name="email_addr" value="0">
              <xsl:if test="$email_addr = 0">
                <xsl:attribute name="checked">true</xsl:attribute>
              </xsl:if>
            </input>
            <label for="unlimited_email_addr">
              <xsl:copy-of select="/cp/strings/cp_domains_unlimited_emails" />
            </label>
            <br />
          </td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:copy-of select="/cp/strings/cp_label_ws_logs" /></td>
          <td class="contentwidth">
            <input type="radio" id="no_website_logs" name="website_logs" value="no" onClick="switchRotationSwitches(this);" >
              <xsl:if test="$website_logs = 'no'">
                <xsl:attribute name="checked">true</xsl:attribute>
              </xsl:if>
            </input>
            <label for="no_website_logs">
              <xsl:copy-of select="/cp/strings/cp_domains_logs_no" />
            </label>
            <br />
            <input type="radio" id="store_website_logs" name="website_logs" value="yes" onClick="switchRotationSwitches(this);" >
              <xsl:if test="$website_logs = 'yes'">
                <!-- defaults to ON -->
                <xsl:attribute name="checked">true</xsl:attribute>
              </xsl:if>
            </input>
             <label for="store_website_logs">
              <xsl:copy-of select="/cp/strings/cp_domains_logs_yes" />
              <xsl:copy-of select="/cp/strings/cp_domains_logs_stats" />
            </label>
            <br />
            <input class="indent" type="radio" id="periodic_log_rotation" name="log_rotate_select" value="yes">
              <xsl:if test="$log_rotate_select = 'yes'">
                <!-- defaults to ON -->
                <xsl:attribute name="checked">true</xsl:attribute>
              </xsl:if>
            </input>
            <label for="periodic_log_rotation">
              <xsl:copy-of select="/cp/strings/cp_domains_rotate_yes_1" />
            </label>
              <select name="log_rotate" size="1">
                <option selected="selected" value="daily">
                  <xsl:if test="$log_rotate = 'daily'">
                    <!-- default -->
                    <xsl:attribute name="selected">true</xsl:attribute>
                  </xsl:if>
                  <xsl:copy-of select="/cp/strings/cp_domains_daily" />
                </option>
                <option value="weekly">
                  <xsl:if test="$log_rotate = 'weekly'">
                    <xsl:attribute name="selected">true</xsl:attribute>
                  </xsl:if>
                  <xsl:copy-of select="/cp/strings/cp_domains_weekly" />
                </option>
                <option value="monthly">
                  <xsl:if test="$log_rotate = 'monthly'">
                    <xsl:attribute name="selected">true</xsl:attribute>
                  </xsl:if>
                  <xsl:copy-of select="/cp/strings/cp_domains_monthly" />
                </option>
              </select>
            <label for="periodic_log_rotation">
              <xsl:copy-of select="/cp/strings/cp_domains_rotate_yes_2" />
            </label>
              <select name="log_save" size="1">
                <option value="1">
                  <xsl:if test="$log_save = 1">
                    <xsl:attribute name="selected">true</xsl:attribute>
                  </xsl:if>
                  <xsl:copy-of select="/cp/strings/cp_domains_logs_save_1" />
                </option>
                <option value="7">
                  <xsl:if test="$log_save = 7">
                    <xsl:attribute name="selected">true</xsl:attribute>
                  </xsl:if>
                  <xsl:copy-of select="/cp/strings/cp_domains_logs_save_7" />
                </option>
                <option value="14">
                  <xsl:if test="$log_save = 14">
                    <xsl:attribute name="selected">true</xsl:attribute>
                  </xsl:if>
                  <xsl:copy-of select="/cp/strings/cp_domains_logs_save_14" />
                </option>
                <option value="30">
                  <xsl:if test="$log_save = 30">
                    <!-- default -->
                    <xsl:attribute name="selected">true</xsl:attribute>
                  </xsl:if>
                  <xsl:copy-of select="/cp/strings/cp_domains_logs_save_30" />
                </option>
                <option value="60">
                  <xsl:if test="$log_save = 60">
                    <xsl:attribute name="selected">true</xsl:attribute>
                  </xsl:if>
                  <xsl:copy-of select="/cp/strings/cp_domains_logs_save_60" />
                </option>
                <option value="90">
                  <xsl:if test="$log_save = 90">
                    <xsl:attribute name="selected">true</xsl:attribute>
                  </xsl:if>
                  <xsl:copy-of select="/cp/strings/cp_domains_logs_save_90" />
                </option>
                <option value="all">
                  <xsl:if test="$log_save = 'all'">
                    <xsl:attribute name="selected">true</xsl:attribute>
                  </xsl:if>
                  <xsl:copy-of select="/cp/strings/cp_domains_logs_save_all" />
                </option>
              </select>
            <label for="periodic_log_rotation">
              <xsl:copy-of select="/cp/strings/cp_domains_rotate_yes_3" />
            </label>
            <br />
            <input class="indent" type="radio" id="no_log_rotation" name="log_rotate_select" value="no">
              <xsl:if test="$log_rotate_select = 'no'">
                <xsl:attribute name="checked">true</xsl:attribute>
              </xsl:if>
            </input>
            <label for="no_log_rotation">
              <xsl:copy-of select="/cp/strings/cp_domains_rotate_no" />
            </label>
            <br />
          </td>
        </tr>
        <tr class="roweven">
          <td class="label"><xsl:copy-of select="/cp/strings/cp_label_domain_contact" /></td>
          <td class="contentwidth">
            <input type="text" name="domain_contact" value="{$domain_contact}" size="60" />
          </td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:copy-of select="/cp/strings/cp_label_mail_catchall" /></td>
          <td class="contentwidth">
            <input type="radio" id="mail_catchall_reject" name="mail_catchall" value="reject">
              <xsl:if test="$mail_catchall = 'reject'">
                <!-- default -->
                <xsl:attribute name="checked">true</xsl:attribute>
              </xsl:if>
            </input>
            <label for="mail_catchall_reject"><xsl:copy-of select="/cp/strings/cp_domains_catchall_1" /></label><br />
            <input type="radio" id="mail_catchall_delete" name="mail_catchall" value="delete">
              <xsl:if test="$mail_catchall = 'delete'">
                <!-- default -->
                <xsl:attribute name="checked">true</xsl:attribute>
              </xsl:if>
            </input>
            <label for="mail_catchall_delete"><xsl:copy-of select="/cp/strings/cp_domains_catchall_2" /></label><br />
            <input type="radio" id="mail_catchall_admin" name="mail_catchall" value="admin">
              <xsl:if test="$mail_catchall = 'admin'">
                <!-- default -->
                <xsl:attribute name="checked">true</xsl:attribute>
              </xsl:if>
            </input>
            <label for="mail_catchall_admin"><xsl:copy-of select="/cp/strings/cp_domains_catchall_3" /></label><br />
            <input type="radio" id="mail_catchall_custom" name="mail_catchall" value="custom">
              <xsl:if test="$mail_catchall = 'custom'">
                <!-- default -->
                <xsl:attribute name="checked">true</xsl:attribute>
              </xsl:if>
            </input>
            <label for="mail_catchall_custom">
              <xsl:copy-of select="/cp/strings/cp_domains_catchall_4" />
            </label>
            <input type="text" name="mail_catchall_custom" size="60" value="{$mail_catchall_custom}" />
            <br />
          </td>
        </tr>
        <tr class="controlrow">
          <td colspan="2">
            <input class="floatright" type="button" name="btn_cancel" value="{/cp/strings/domain_add_btn_cancel}" 
              onClick="document.forms[0].cancel.value='yes';document.forms[0].submit();" />
            <input class="floatright" type="submit" name="next" value="{/cp/strings/domain_add_btn_next}" 
              onClick="return validateDomain(
                   '{cp:js-escape(/cp/strings/domain_add_error_null_domain)}',
                   '{cp:js-escape(/cp/strings/domain_add_error_invalid_domain)}',
                   '{cp:js-escape(/cp/strings/domain_add_error_null_eus)}',
                   '{cp:js-escape(/cp/strings/domain_add_error_fmt_eus)}',
                   '{cp:js-escape(/cp/strings/domain_add_error_null_ems)}',
                   '{cp:js-escape(/cp/strings/domain_add_error_fmt_ems)}',
                   '{cp:js-escape(/cp/strings/domain_add_error_null_contact)}',
                   '{cp:js-escape(/cp/strings/domain_add_error_invalid_contact)}',
                   '{cp:js-escape(/cp/strings/domain_add_error_null_catchall)}',
                   '{cp:js-escape(/cp/strings/domain_add_error_invalid_catchall)}',
                   '{cp:js-escape(/cp/strings/domain_add_error_invalid_domain_alias)}');" 
            />
          </td>
        </tr>
      </table>

</xsl:template>

</xsl:stylesheet>
