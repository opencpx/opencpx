<?xml version="1.0" encoding="utf-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../cp_global.xsl" />

<xsl:variable name="message">
  <xsl:choose>
    <xsl:when test="/cp/msgs/msg[@name='domain_edit_failure']">
      <!-- FIXME: no delete error message defined -->
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='domain_edit_successful']">
      '<xsl:value-of select="/cp/form/domain" />'<xsl:copy-of select="/cp/strings/cp_msg_domain_edit" />
    </xsl:when>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="feedback">
  <xsl:if test="$message != ''">
    <xsl:call-template name="feedback_table">
      <xsl:with-param name="image">
        <xsl:choose>
          <xsl:when test="/cp/msgs/msg[@name='domain_edit_failure']">error</xsl:when>
          <xsl:otherwise>success</xsl:otherwise>                  
        </xsl:choose>
      </xsl:with-param>
      <xsl:with-param name="message">
        <xsl:copy-of select="$message" />
      </xsl:with-param>
    </xsl:call-template>
  </xsl:if>          
</xsl:variable>        

<xsl:variable name="domain">
  <xsl:value-of select="/cp/form/domain" />
</xsl:variable>

<xsl:variable name="admin">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/admin">
      <xsl:value-of select="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/admin" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="www_alias">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/www_alias">
      <xsl:value-of select="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/www_alias" />
    </xsl:when>
    <xsl:otherwise>0</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="other_aliases">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/other_aliases">
      <xsl:value-of select="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/other_aliases" />
    </xsl:when>
    <xsl:otherwise><xsl:value-of select="/cp/strings/domain_properties_other_aliases" /></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="cgi">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/services/cgi">
      <xsl:value-of select="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/services/cgi" />
    </xsl:when>
    <xsl:otherwise>0</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="ssl">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/services/ssl">
      <xsl:value-of select="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/services/ssl" />
    </xsl:when>
    <xsl:otherwise>0</xsl:otherwise>
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
    <xsl:when test="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/users/limit">
      <xsl:value-of select="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/users/limit" />
    </xsl:when>
    <xsl:otherwise>0</xsl:otherwise>
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
    <xsl:when test="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/mail_aliases/limit">
      <xsl:value-of select="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/mail_aliases/limit" />
    </xsl:when>
    <xsl:otherwise>0</xsl:otherwise>
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
    <xsl:when test="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/www_logs='none'">no</xsl:when>
    <xsl:when test="string(/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/www_logs)">yes</xsl:when>
    <xsl:otherwise>none</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="log_rotation">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/log_rotation">
      <xsl:value-of select="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/log_rotation" />
    </xsl:when>
    <xsl:otherwise>none</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="log_rotation_select">
  <xsl:choose>
    <xsl:when test="$log_rotation='none'">no</xsl:when>
    <xsl:otherwise>yes</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="log_period">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/log_period">
      <xsl:value-of select="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/log_period" />
    </xsl:when>
    <xsl:otherwise>none</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="mail_catchall">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/catchall">
      <xsl:value-of select="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/catchall" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="mail_catchall_custom">
  <xsl:choose>
    <xsl:when test="$mail_catchall='custom'">
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/mail_catchall_custom">
          <xsl:value-of select="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/mail_catchall_custom" />
        </xsl:when>
        <xsl:otherwise></xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:template match="/">
  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title"><xsl:copy-of select="/cp/strings/cp_title" /> : <xsl:copy-of select="/cp/strings/bc_domain_list" /> : <xsl:copy-of select="/cp/strings/domain_properties_title"/><xsl:value-of select="$domain"/></xsl:with-param>
    <xsl:with-param name="formaction">domain_properties.xsl</xsl:with-param>
    <xsl:with-param name="feedback" select="$feedback" />
    <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_domain_list" />
    <xsl:with-param name="help_short" select="/cp/strings/domain_properties_preview_hlp_short" />
    <xsl:with-param name="help_long" select="/cp/strings/domain_properties_preview_hlp_long" />
    <xsl:with-param name="breadcrumb">
      <breadcrumb>
        <section>
          <name><xsl:copy-of select="/cp/strings/bc_domain_properties_domain_list" /></name>
          <url>index.xsl</url>
        </section>
        <section>
          <name><xsl:copy-of select="concat(/cp/strings/bc_domain_properties,$domain)" /></name>
          <url>#</url>
          <image>DomainManagement</image>
        </section>
      </breadcrumb>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

      <table class="formview" border="0" cellspacing="0" cellpadding="0">
        <tr class="title">
          <td colspan="2"><xsl:copy-of select="concat(/cp/strings/domain_properties_title,$domain)" /></td>
        </tr>
        <tr class="instructionrow">
          <td colspan="2"><xsl:copy-of select="/cp/strings/cp_instr_domain_properties" /></td>
        </tr>
        <tr class="title">
          <td colspan="2"><xsl:copy-of select="/cp/strings/domain_properties_domain_setup" />&#160;<a href="domain_edit.xsl?domain={$domain}">[<xsl:value-of select="/cp/strings/domain_properties_edit" />]</a></td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:copy-of select="/cp/strings/cp_label_da" /></td>
          <td class="contentwidth"><xsl:value-of select="$admin" /><br /></td>
        </tr>
        <tr class="roweven">
          <td class="label"><xsl:copy-of select="/cp/strings/cp_label_domain" /></td>
          <td class="contentwidth"><xsl:value-of select="/cp/form/domain" />
            <xsl:if test="$www_alias = 1">
              <xsl:copy-of select="concat(' ',/cp/strings/domain_properties_alias_1,/cp/form/domain,/cp/strings/domain_properties_alias_2)" />
            </xsl:if>
            <br />
          </td>
        </tr>

        <tr class="rowodd">
          <td class="label"><xsl:value-of select="/cp/strings/cp_label_ip_address" /></td>
          <td class="contentwidth"><xsl:value-of select="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/ip"/><br /></td>
        </tr>

        <tr class="rowodd">
          <td class="label"><xsl:value-of select="/cp/strings/cp_label_domain_aliases" /></td>
          <td class="contentwidth"><xsl:value-of select="$other_aliases" /></td>
        </tr>
        <tr class="roweven">
          <td class="label"><xsl:copy-of select="/cp/strings/cp_label_web_services" /></td>
          <td class="contentwidth">
            <xsl:if test="$cgi = '1'"><xsl:copy-of select="/cp/strings/cp_service_cgi" /></xsl:if>
            <xsl:if test="$cgi = '1' and $ssl = '1'">, </xsl:if>
            <xsl:if test="$ssl = '1'"><xsl:copy-of select="/cp/strings/cp_service_ssl" /></xsl:if>
            <br />
          </td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:copy-of select="/cp/strings/cp_label_eus" /></td>
          <td class="contentwidth">
            <xsl:choose>
              <xsl:when test="$end_users_limit != 'unlimited'">
                <xsl:variable name="users_avail">
                  <xsl:choose>
                    <xsl:when test="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/users/limit - /cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/users/usage &gt;= 0">
                      <xsl:value-of select="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/users/limit - /cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/users/usage" />
                    </xsl:when>
                    <xsl:otherwise>0</xsl:otherwise>
                  </xsl:choose>
                </xsl:variable>
                <xsl:copy-of select="/cp/strings/cp_domains_max_eu_1" />
                <xsl:value-of select="$end_users_limit" />
                <xsl:value-of select="concat('&#160;&#160;&#160;(',/cp/strings/domain_properties_used,' ',/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/users/usage,'&#160;&#160;&#160;',/cp/strings/domain_properties_available,' ',$users_avail,')')" />
              </xsl:when>
              <xsl:otherwise>
                <xsl:copy-of select="/cp/strings/cp_domains_unlimited" />
                <xsl:value-of select="concat('&#160;&#160;&#160;(',/cp/strings/domain_properties_used,' ',/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/users/usage,')')" />
              </xsl:otherwise>
            </xsl:choose>
            <br />
          </td>
        </tr>
        <tr class="roweven">
          <td class="label"><xsl:copy-of select="/cp/strings/cp_label_email_addresses" /></td>
          <td class="contentwidth">
            <xsl:choose>
              <xsl:when test="$email_addr_limit != 'unlimited'">
                <xsl:variable name="email_avail">
                  <xsl:choose>
                    <xsl:when test="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/mail_aliases/limit - /cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/mail_aliases/usage &gt;=0">
                      <xsl:value-of select="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/mail_aliases/limit - /cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/mail_aliases/usage" />
                    </xsl:when>
                    <xsl:otherwise>0</xsl:otherwise>
                  </xsl:choose>
                </xsl:variable>
                <xsl:copy-of select="/cp/strings/cp_domains_max_emails_1" />
                <xsl:value-of select="$email_addr_limit" />
                <xsl:value-of select="concat('&#160;&#160;&#160;(',/cp/strings/domain_properties_used,' ',/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/mail_aliases/usage,'&#160;&#160;&#160;',/cp/strings/domain_properties_available,' ',$email_avail,')')" />
              </xsl:when>
              <xsl:otherwise>
                <xsl:copy-of select="/cp/strings/cp_domains_unlimited" />
                <xsl:value-of select="concat('&#160;&#160;&#160;(',/cp/strings/domain_properties_used,' ',/cp/vsap/vsap[@type='domain:list']/domain[name=$domain]/mail_aliases/usage,')')" />
              </xsl:otherwise>
            </xsl:choose>
            <br />
          </td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:copy-of select="/cp/strings/cp_label_ws_logs" /></td>
          <td class="contentwidth">
            <xsl:choose>
              <xsl:when test="$website_logs = 'yes'">
                <xsl:copy-of select="/cp/strings/cp_domains_logs_yes" /><br />
                <xsl:choose>
                  <xsl:when test="$log_rotation_select = 'yes'">
                    <xsl:copy-of select="/cp/strings/cp_domains_rotate_yes_1" />
                    <xsl:choose>
                      <xsl:when test="$log_rotation = 'daily'">
                        <xsl:copy-of select="/cp/strings/cp_domains_daily" />
                      </xsl:when>
                      <xsl:when test="$log_rotation = 'weekly'">
                        <xsl:copy-of select="/cp/strings/cp_domains_weekly" />
                      </xsl:when>
                      <xsl:when test="$log_rotation = 'monthly'">
                        <xsl:copy-of select="/cp/strings/cp_domains_monthly" />
                      </xsl:when>
                    </xsl:choose>
                    <xsl:copy-of select="/cp/strings/cp_domains_rotate_yes_2" />
                    <xsl:choose>
                      <xsl:when test="$log_period = 'all'">
                        <xsl:copy-of select="/cp/strings/cp_domains_logs_save_all" />
                      </xsl:when>
                      <xsl:when test="$log_period = '1'">
                        <xsl:copy-of select="/cp/strings/cp_domains_logs_save_1" />
                      </xsl:when>
                      <xsl:when test="$log_period = '7'">
                        <xsl:copy-of select="/cp/strings/cp_domains_logs_save_7" />
                      </xsl:when>
                      <xsl:when test="$log_period = '14'">
                        <xsl:copy-of select="/cp/strings/cp_domains_logs_save_14" />
                      </xsl:when>
                      <xsl:when test="$log_period = '30'">
                        <xsl:copy-of select="/cp/strings/cp_domains_logs_save_30" />
                      </xsl:when>
                      <xsl:when test="$log_period = '60'">
                        <xsl:copy-of select="/cp/strings/cp_domains_logs_save_60" />
                      </xsl:when>
                      <xsl:when test="$log_period = '90'">
                        <xsl:copy-of select="/cp/strings/cp_domains_logs_save_90" />
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="$log_period" />
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
          </td>
        </tr>
        <tr class="roweven">
          <td class="label"><xsl:copy-of select="/cp/strings/cp_label_web_log_files" /></td>
          <td class="contentwidth">
            <xsl:choose>
              <xsl:when test="$website_logs = 'yes'">
                /www/logs/<xsl:value-of select="$admin" />/<xsl:value-of select="$domain" />-access_log<br />
                /www/logs/<xsl:value-of select="$admin" />/<xsl:value-of select="$domain" />-error_log<br />
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="/cp/strings/cp_label_web_log_files_na" />
              </xsl:otherwise>
            </xsl:choose>
          </td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:copy-of select="/cp/strings/cp_label_domain_contact" /></td>
          <td class="contentwidth"><xsl:value-of select="$domain_contact" /><br />
          </td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:copy-of select="/cp/strings/cp_label_mail_catchall" /></td>
          <td class="contentwidth">
            <xsl:choose>
              <xsl:when test="$mail_catchall = 'reject'">
                <xsl:copy-of select="/cp/strings/cp_domains_catchall_1" />
              </xsl:when>
              <xsl:when test="$mail_catchall = 'none'">
                <xsl:copy-of select="/cp/strings/cp_domains_catchall_1" />
              </xsl:when>
              <xsl:when test="$mail_catchall = '/dev/null' or $mail_catchall = 'delete' or $mail_catchall = 'bit-bucket'">
                <xsl:copy-of select="/cp/strings/cp_domains_catchall_2" />
              </xsl:when>
              <xsl:when test="$mail_catchall = 'admin'">
                <xsl:copy-of select="/cp/strings/cp_domains_catchall_3" />
              </xsl:when>
              <xsl:when test="string($mail_catchall)">
                <xsl:copy-of select="/cp/strings/cp_domains_catchall_4" />
                <xsl:value-of select="$mail_catchall" />
              </xsl:when>
            </xsl:choose>
            <br />
          </td>
        </tr>
        <tr class="controlrow">
          <td colspan="2">
            <input class="floatright" type="submit" name="ok" value="{/cp/strings/domain_properties_btn_ok}" />
          </td>
        </tr>
      </table>

</xsl:template>

</xsl:stylesheet>
