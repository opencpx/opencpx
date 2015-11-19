<?xml version="1.0" encoding="utf-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../cp_global.xsl" />

<xsl:variable name="message">
  <xsl:choose>
    <xsl:when test="/cp/msgs/msg[@name='domain_permission']">
      '<xsl:copy-of select="/cp/strings/domain_err_domain_permission" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='domain_add_exists']">
      '<xsl:copy-of select="/cp/strings/domain_err_add_exists" />
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

<xsl:variable name="src">
  <xsl:value-of select="concat('domainedit',$user_type)" />
</xsl:variable>

<xsl:variable name="domain">
  <xsl:value-of select="/cp/form/domain" />
</xsl:variable>

<xsl:variable name="admin">
  <xsl:choose>
    <xsl:when test="/cp/form/admin">
      <xsl:value-of select="/cp/form/admin" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/admin" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="www_alias">
  <xsl:choose>
    <xsl:when test="/cp/form/www_alias">
      <xsl:value-of select="/cp/form/www_alias" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/www_alias" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="other_aliases">
  <xsl:choose>
    <xsl:when test="/cp/form/other_aliases">
      <xsl:value-of select="/cp/form/other_aliases" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/other_aliases" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="cgi">
  <xsl:choose>
    <xsl:when test="/cp/form/cgi">
      <xsl:value-of select="/cp/form/cgi" />
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/services/cgi">
      <xsl:value-of select="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/services/cgi" />
    </xsl:when>
    <xsl:otherwise>0</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="ssl">
  <xsl:choose>
    <xsl:when test="/cp/form/ssl">
      <xsl:value-of select="/cp/form/ssl" />
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/services/ssl">
      <xsl:value-of select="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/services/ssl" />
    </xsl:when>
    <xsl:otherwise>0</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="end_users_choice">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/users/limit != 'unlimited'">limit</xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/users/limit = 'unlimited'">unlimited</xsl:when>
    <xsl:otherwise>limit</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="end_users">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/users/usage">
      <xsl:value-of select="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/users/usage" />
    </xsl:when>
    <xsl:otherwise>0</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="end_users_limit">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/users/limit != 'unlimited'">
      <xsl:value-of select="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/users/limit" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="/cp/strings/cp_domains_eu_limit" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="email_addr_choice">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/mail_aliases/limit != 'unlimited'">limit</xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/mail_aliases/limit = 'unlimited'">unlimited</xsl:when>
    <xsl:otherwise>limit</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="email_addr">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/mail_aliases/usage">
      <xsl:value-of select="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/mail_aliases/usage" />
    </xsl:when>
    <xsl:otherwise>0</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="email_addr_limit">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/mail_aliases/limit != 'unlimited'">
      <xsl:value-of select="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/mail_aliases/limit" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="/cp/strings/cp_domains_email_limit" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="domain_contact">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/domain_contact">
      <xsl:value-of select="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/domain_contact" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="website_logs">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/www_logs='none'">none</xsl:when>
    <xsl:when test="string(/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/www_logs)">yes</xsl:when>
    <xsl:otherwise>none</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="log_rotate">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/log_rotation">
      <xsl:value-of select="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/log_rotation" />
    </xsl:when>
    <xsl:otherwise>none</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="log_rotate_select">
  <xsl:choose>
    <xsl:when test="$log_rotate='none'">no</xsl:when>
    <xsl:otherwise>yes</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="log_save">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/log_period">
      <xsl:value-of select="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/log_period" />
    </xsl:when>
    <xsl:otherwise>none</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="mail_catchall">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/catchall='reject'">reject</xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/catchall='none'">reject</xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/catchall='/dev/null'">delete</xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/catchall='delete'">delete</xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/catchall='bit-bucket'">delete</xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/catchall='admin'">admin</xsl:when>
    <xsl:when test="string(/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/catchall)" >custom</xsl:when>
    <xsl:otherwise>reject</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="mail_catchall_custom">
  <xsl:choose>
    <xsl:when test="$mail_catchall='custom'">
      <xsl:choose>
        <xsl:when test="string(/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/catchall)">
          <xsl:value-of select="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/catchall" />
        </xsl:when>
        <xsl:otherwise></xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:template match="/">
  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title">
      <xsl:copy-of select="/cp/strings/cp_title" />
      v<xsl:value-of select="/cp/vsap/vsap[@type='auth']/version" /> :
      <xsl:copy-of select="/cp/strings/bc_domain_edit_domain_list" /> : 
      <xsl:copy-of select="/cp/strings/bc_domain_edit_setup"/>
      <xsl:value-of select="$domain"/>
    </xsl:with-param>
    <xsl:with-param name="formaction">domain_edit.xsl</xsl:with-param>
    <xsl:with-param name="feedback" select="$feedback" />
    <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_domain_list" />
    <xsl:with-param name="help_short" select="/cp/strings/domain_edit_hlp_short" />
    <xsl:with-param name="help_long">
      <xsl:choose>
        <xsl:when test="$user_type='sa'">
          <xsl:copy-of select="/cp/strings/domain_edit_hlp_long_sa" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:copy-of select="/cp/strings/domain_edit_hlp_long_da" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:with-param>
    <xsl:with-param name="breadcrumb">
      <breadcrumb>
        <section>
          <name><xsl:copy-of select="/cp/strings/bc_domain_edit_domain_list" /></name>
          <url>index.xsl</url>
        </section>
        <section>
          <name><xsl:copy-of select="concat(/cp/strings/bc_domain_edit_properties,$domain)" /></name>
          <url>domain_properties.xsl?domain=<xsl:value-of select="$domain" /></url>
        </section>
        <section>
          <name><xsl:copy-of select="concat(/cp/strings/bc_domain_edit_setup,$domain)" /></name>
          <url>#</url>
          <image>DomainManagement</image>
        </section>
      </breadcrumb>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

      <script src="{concat($base_url, '/cp/cp.js')}" language="JavaScript"></script>

      <input type="hidden" name="save" value="" />
      <input type="hidden" name="cancel" value="" />
      <input type="hidden" name="usertype" value="{$user_type}" />
      <input type="hidden" name="admin" value="{$admin}" />
      <input type="hidden" name="domain" value="{$domain}" />
      <input type="hidden" name="chk_mail_catchall" value="{$mail_catchall}" />

      <!-- copies of original form values (to keep track of what is modified) -->
      <input type="hidden" name="orig_www_alias" value="{$www_alias}" />
      <input type="hidden" name="orig_other_aliases" value="{$other_aliases}" />
      <input type="hidden" name="orig_cgi" value="{$cgi}" />
      <input type="hidden" name="orig_ssl" value="{$ssl}" />
      <input type="hidden" name="orig_end_users" value="{$end_users}" />
      <input type="hidden" name="orig_end_users_limit" value="{$end_users_limit}" />
      <input type="hidden" name="orig_email_addr" value="{$email_addr}" />
      <input type="hidden" name="orig_email_addr_limit" value="{$email_addr_limit}" />
      <input type="hidden" name="orig_website_logs" value="{$website_logs}" />
      <input type="hidden" name="orig_log_rotate_select" value="{$log_rotate_select}" />
      <input type="hidden" name="orig_log_rotate" value="{$log_rotate}" />
      <input type="hidden" name="orig_log_save" value="{$log_save}" />
      <input type="hidden" name="orig_domain_contact" value="{$domain_contact}" />
      <input type="hidden" name="orig_mail_catchall" value="{$mail_catchall}" />
      <input type="hidden" name="orig_mail_catchall_custom" value="{$mail_catchall_custom}" />

      <table class="formview" border="0" cellspacing="0" cellpadding="0">
        <tr class="title">
          <td colspan="2"><xsl:copy-of select="concat(/cp/strings/cp_title_domain_edit_setup,$domain)" /></td>
        </tr>
        <tr class="instructionrow">
          <td colspan="2"><xsl:copy-of select="/cp/strings/cp_instr_domain_edit" /></td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:copy-of select="/cp/strings/cp_label_da" /></td>
          <td class="contentwidth">
            <xsl:value-of select="$admin" />
          </td>
        </tr>
        <tr class="roweven">
          <td class="label"><xsl:copy-of select="/cp/strings/cp_label_domain" /></td>
          <td class="contentwidth">
            <xsl:choose>
              <xsl:when test="$user_type='sa'">
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
                    <xsl:copy-of select="/cp/strings/cp_domains_enable_www" />
                    <span class="parenthetichelp"><xsl:copy-of select="concat(' (www.',$domain,')')" /></span>
                  </label>
                  <br />
                </xsl:if>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$domain" />
                <xsl:if test="$www_alias = 1">
                  <xsl:copy-of select="concat(' ',/cp/strings/domain_properties_alias_1,/cp/form/domain,/cp/strings/domain_properties_alias_2)" />
                </xsl:if>
              </xsl:otherwise>
            </xsl:choose>

          </td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:value-of select="/cp/strings/cp_label_domain_aliases" /></td>
          <td class="contentwidth">
            <xsl:choose>
              <xsl:when test="$user_type='sa'">
                <input type="text" name="other_aliases" value="{$other_aliases}" size="60" />
                <span class="parenthetichelp"><xsl:value-of select="/cp/strings/cp_instr_other_aliases" /></span>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$other_aliases" />
              </xsl:otherwise>
            </xsl:choose>
          </td>
        </tr>

        <xsl:if test="/cp/vsap/vsap[@type='auth']/platform='freebsd6' or /cp/vsap/vsap[@type='auth']/platform='linux'">
        <xsl:if test="$user_type = 'sa'">

        <tr class="roweven">
          <td class="label"><xsl:copy-of select="/cp/strings/cp_label_ip_address" /></td>
          <td class="contentwidth">
            <select name="ip_address" size="1">
                <xsl:for-each select="/cp/vsap/vsap[@type='domain:list_ips']/ip">
                    <option value="{.}">
                        <xsl:if test=". = /cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/ip">
                          <xsl:attribute name="selected" value="selected"/>
                        </xsl:if>
                        <xsl:value-of select="."/>
                        <xsl:if test="position() = 1">
                         (main) 
                        </xsl:if>
                    </option>

                </xsl:for-each>
            </select>
          </td>
        </tr>

        </xsl:if>
        </xsl:if>

        <tr class="rowodd">
          <td class="label"><xsl:copy-of select="/cp/strings/cp_label_web_services" /></td>
          <td class="contentwidth">
            <xsl:choose>
              <xsl:when test="$user_type='sa'">
                <input type="checkbox" id="cgi" name="cgi" value="1">
                  <xsl:if test="$cgi = '1'">
                    <!-- defaults to ON -->
                    <xsl:attribute name="checked">true</xsl:attribute>
                  </xsl:if>
                </input>
                <label for="cgi">
                  <xsl:copy-of select="/cp/strings/cp_service_cgi" />
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
                      <xsl:copy-of select="/cp/strings/cp_service_ssl" />
                    </label>
                    <br />
                    
                  </xsl:otherwise>
                </xsl:choose>

              </xsl:when>
              <xsl:otherwise>
                <xsl:if test="$cgi = '1'"><xsl:copy-of select="/cp/strings/cp_service_cgi" /></xsl:if>
                <xsl:if test="$cgi = '1' and $ssl = '1'">, </xsl:if>   
                <xsl:if test="$ssl = '1'"><xsl:copy-of select="/cp/strings/cp_service_ssl" /></xsl:if>
                <br />
              </xsl:otherwise>
            </xsl:choose>
          </td>
        </tr>
        <tr class="roweven">
          <td class="label"><xsl:copy-of select="/cp/strings/cp_label_eus" /></td>
          <td class="contentwidth">
            <xsl:choose>
              <xsl:when test="$user_type='sa'">
                <xsl:copy-of select="/cp/strings/cp_domains_admin_eus" /><br />
                <input type="radio" id="limit_end_users" name="end_users" value="limit">
                  <xsl:if test="$end_users_choice = 'limit'">
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
                <input type="radio" id="unlimited_end_users" name="end_users" value="unlimited">
                  <xsl:if test="$end_users_choice = 'unlimited'">
                    <xsl:attribute name="checked">true</xsl:attribute>
                  </xsl:if>
                </input>
                <label for="unlimited_end_users">
                  <xsl:copy-of select="/cp/strings/cp_domains_unlimited_eu" />
                </label>
                <br />
              </xsl:when>
              <xsl:otherwise>
                <xsl:choose>
                  <xsl:when test="$end_users_choice != 'unlimited'">
                    <xsl:copy-of select="/cp/strings/cp_domains_max_eu_1" />
                    <xsl:value-of select="$end_users_limit" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:copy-of select="/cp/strings/cp_domains_unlimited" />         
                  </xsl:otherwise>
                </xsl:choose>
                <br />
              </xsl:otherwise>
            </xsl:choose>
          </td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:copy-of select="/cp/strings/cp_label_email_addresses" /></td>
          <td class="contentwidth">
            <xsl:choose>
              <xsl:when test="$user_type='sa'">
                <xsl:copy-of select="/cp/strings/cp_domains_admin_emails" /><br />
                <input type="radio" id="limit_email_addr" name="email_addr" value="limit">
                  <xsl:if test="$email_addr_choice = 'limit'">
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
                <input type="radio" id="unlimited_email_addr" name="email_addr" value="unlimited">
                  <xsl:if test="$email_addr_choice = 'unlimited'">
                    <xsl:attribute name="checked">true</xsl:attribute>
                  </xsl:if>
                </input>
                <label for="unlimited_email_addr">
                  <xsl:copy-of select="/cp/strings/cp_domains_unlimited_emails" />
                </label>
                <br />
              </xsl:when>
              <xsl:otherwise>
                <xsl:choose>
                  <xsl:when test="$email_addr_choice != 'unlimited'">
                    <xsl:copy-of select="/cp/strings/cp_domains_max_emails_1" />
                    <xsl:value-of select="$email_addr_limit" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:copy-of select="/cp/strings/cp_domains_unlimited" />
                  </xsl:otherwise>
                </xsl:choose>
                <br />
              </xsl:otherwise>
            </xsl:choose>
          </td>
        </tr>
        <tr class="roweven">
          <td class="label"><xsl:copy-of select="/cp/strings/cp_label_ws_logs" /></td>
          <td class="contentwidth">
            <xsl:choose>

              <xsl:when test="$user_type='sa'">
                <input type="radio" id="no_website_logs" name="website_logs" value="no" onClick="switchRotationSwitches(this);" >
                  <xsl:if test="$website_logs = 'none'">
                    <xsl:attribute name="checked">true</xsl:attribute>
                  </xsl:if>
                </input>
                <label for="no_website_logs">
                  <xsl:copy-of select="/cp/strings/cp_domains_logs_no" />
                </label>
                <br />
                <input type="radio" id="rotate_website_logs" name="website_logs" value="yes" onClick="switchRotationSwitches(this);" >
                  <xsl:if test="$website_logs = 'yes'">
                    <!-- defaults to ON -->
                    <xsl:attribute name="checked">true</xsl:attribute>
                  </xsl:if>
                </input>
                <label for="rotate_website_logs">
                  <xsl:copy-of select="/cp/strings/cp_domains_logs_yes" />
                  <xsl:copy-of select="/cp/strings/cp_domains_logs_stats" />
                </label>
                <br />
                <input class="indent" type="radio" id="periodic_log_rotation" name="log_rotate_select" value="yes">
                  <xsl:if test="$website_logs = 'none'">
                    <xsl:attribute name="disabled">disabled</xsl:attribute>
                  </xsl:if>
                  <xsl:if test="$log_rotate_select != 'no'">
                    <!-- defaults to ON -->
                    <xsl:attribute name="checked">true</xsl:attribute>
                  </xsl:if>
                </input>
                <label for="periodic_log_rotation">
                  <xsl:copy-of select="/cp/strings/cp_domains_rotate_yes_1" />
                </label>
                  <select name="log_rotate" size="1">
                    <xsl:if test="$website_logs = 'none'">
                      <xsl:attribute name="disabled">disabled</xsl:attribute>
                    </xsl:if>
                    <option selected="selected" value="daily">
                      <xsl:if test="$log_rotate = 'daily' or not(string(/cp/form/log_rotate))">
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
                    <xsl:if test="$website_logs = 'none'">
                      <xsl:attribute name="disabled">disabled</xsl:attribute>
                    </xsl:if>
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
                      <xsl:if test="$log_save = 30 and not(string(/cp/form/log_save))">
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
                  <xsl:if test="$website_logs = 'none'">
                    <xsl:attribute name="disabled">disabled</xsl:attribute>
                  </xsl:if>
                  <xsl:if test="$log_rotate = 'none'">
                    <xsl:attribute name="checked">true</xsl:attribute>
                  </xsl:if>
                </input>
                <label for="no_log_rotation">
                  <xsl:copy-of select="/cp/strings/cp_domains_rotate_no" />
                </label>
                <br />
              </xsl:when>

              <xsl:otherwise>
                <xsl:choose>
                  <xsl:when test="$website_logs = 'yes'">
                    <xsl:copy-of select="/cp/strings/cp_domains_logs_yes" /><br />
                    <xsl:choose>
                      <xsl:when test="$log_rotate_select = 'yes'">
                        <xsl:copy-of select="/cp/strings/cp_domains_rotate_yes_1" />
                        <xsl:choose>
                          <xsl:when test="$log_rotate = 'daily'">
                                <xsl:copy-of select="/cp/strings/cp_domains_daily" />
                          </xsl:when>
                          <xsl:when test="$log_rotate = 'weekly'">
                                <xsl:copy-of select="/cp/strings/cp_domains_weekly" />
                          </xsl:when>
                          <xsl:when test="$log_rotate = 'monthly'">
                                <xsl:copy-of select="/cp/strings/cp_domains_monthly" />
                          </xsl:when>
                        </xsl:choose>
                        <xsl:copy-of select="/cp/strings/cp_domains_rotate_yes_2" />
                        <xsl:choose>
                          <xsl:when test="$log_save = 'all'">
                                <xsl:copy-of select="/cp/strings/cp_domains_logs_save_all" />
                          </xsl:when>
                          <xsl:when test="$log_save = '1'">
                                <xsl:copy-of select="/cp/strings/cp_domains_logs_save_1" />
                          </xsl:when>
                          <xsl:otherwise>
                                <xsl:value-of select="$log_save" />
                          </xsl:otherwise>
                        </xsl:choose>
                        <xsl:copy-of select="/cp/strings/cp_domains_rotate_yes_3" />
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:copy-of select="/cp/strings/cp_domains_rotate_no" />
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:copy-of select="/cp/strings/cp_domains_logs_no" />
                  </xsl:otherwise>
                </xsl:choose>
                <br />
              </xsl:otherwise>
            </xsl:choose>



          </td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:copy-of select="/cp/strings/cp_label_domain_contact" /></td>
          <td class="contentwidth">
            <input type="text" name="domain_contact" value="{$domain_contact}" size="60" />
          </td>
        </tr>
        <tr class="roweven">
          <td class="label"><xsl:copy-of select="/cp/strings/cp_label_mail_catchall" /></td>
          <td class="contentwidth">
            <input type="radio" id="mail_catchall_reject" name="mail_catchall" value="reject">
              <xsl:if test="$mail_catchall = 'reject'">
                <!-- default -->
                <xsl:attribute name="checked">true</xsl:attribute>
              </xsl:if>
            </input>
            <label for="mail_catchall_reject">
              <xsl:copy-of select="/cp/strings/cp_domains_catchall_1" />
            </label>
            <br />
            <input type="radio" id="mail_catchall_delete" name="mail_catchall" value="delete">
              <xsl:if test="$mail_catchall = 'delete'">
                <!-- default -->
                <xsl:attribute name="checked">true</xsl:attribute>
              </xsl:if>
            </input>
            <label for="mail_catchall_delete">
              <xsl:copy-of select="/cp/strings/cp_domains_catchall_2" />
            </label>
            <br />
            <input type="radio" id="mail_catchall_admin" name="mail_catchall" value="admin">
              <xsl:if test="$mail_catchall = 'admin'">
                <!-- default -->
                <xsl:attribute name="checked">true</xsl:attribute>
              </xsl:if>
            </input>
            <label for="mail_catchall_admin">
              <xsl:copy-of select="/cp/strings/cp_domains_catchall_3" />
            </label>
            <br />
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
            <input class="floatright" type="button" name="btn_cancel" value="{/cp/strings/domain_edit_btn_cancel}" 
              onClick="document.forms[0].cancel.value='yes';document.forms[0].submit();" />
            <input class="floatright" type="submit" name="btn_save" value="{/cp/strings/domain_edit_btn_save}" 
              onClick="return validateDomainEdit(
                        '{$src}',
                        '{cp:js-escape(/cp/strings/domain_edit_error_null_eus)}',
                        '{cp:js-escape(/cp/strings/domain_edit_error_fmt_eus)}',
                        '{cp:js-escape(/cp/strings/domain_edit_error_null_ems)}',
                        '{cp:js-escape(/cp/strings/domain_edit_error_fmt_ems)}',
                        '{cp:js-escape(/cp/strings/domain_edit_error_null_contact)}',
                        '{cp:js-escape(/cp/strings/domain_edit_error_invalid_contact)}',
                        '{cp:js-escape(/cp/strings/domain_edit_error_invalid_domain)}',
                        '{cp:js-escape(/cp/strings/domain_edit_error_null_catchall)}',
                        '{cp:js-escape(/cp/strings/domain_edit_error_invalid_catchall)}',
                        '{cp:js-escape(/cp/strings/domain_edit_error_invalid_domain_alias)}');" 
            />
          </td>
        </tr>
      </table>

</xsl:template>

</xsl:stylesheet>
