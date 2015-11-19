<?xml version="1.0" encoding="utf-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../cp_global.xsl" />

<xsl:template match="/">
  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title">
      <xsl:copy-of select="/cp/strings/cp_title" />
      v<xsl:value-of select="/cp/vsap/vsap[@type='auth']/version" /> :
      <xsl:copy-of select="/cp/strings/bc_domain_add_preview" />
    </xsl:with-param>
    <xsl:with-param name="formaction">domain_add.xsl</xsl:with-param>
    <xsl:with-param name="feedback" />
    <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_add_domain" />
    <xsl:with-param name="help_short" select="/cp/strings/domain_add_preview_hlp_short" />
    <xsl:with-param name="help_long" select="/cp/strings/domain_add_preview_hlp_long" />
    <xsl:with-param name="breadcrumb">
      <breadcrumb>
        <section>
          <name><xsl:copy-of select="/cp/strings/bc_domain_add_preview" /></name>
          <url>#</url>
          <image>DomainManagement</image>
        </section>
      </breadcrumb>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

      <input type="hidden" name="admin" value="{/cp/form/admin}" />
      <input type="hidden" name="domain" value="{/cp/form/domain}" />
      <xsl:if test="/cp/form/ip_address">
        <input type="hidden" name="ip_address" value="{/cp/form/ip_address}" />
      </xsl:if>
      <input type="hidden" name="www_alias" value="{/cp/form/www_alias}" />
      <input type="hidden" name="other_aliases" value="{/cp/form/other_aliases}" />
      <input type="hidden" name="cgi" value="{/cp/form/cgi}" />
      <input type="hidden" name="ssl" value="{/cp/form/ssl}" />
      <input type="hidden" name="end_users" value="{/cp/form/end_users}" />
      <input type="hidden" name="end_users_limit" value="{/cp/form/end_users_limit}" />
      <input type="hidden" name="email_addr" value="{/cp/form/email_addr}" />
      <input type="hidden" name="email_addr_limit" value="{/cp/form/email_addr_limit}" />
      <input type="hidden" name="website_logs" value="{/cp/form/website_logs}" />
      <input type="hidden" name="log_rotate_select" value="{/cp/form/log_rotate_select}" />
      <input type="hidden" name="log_rotate" value="{/cp/form/log_rotate}" />
      <input type="hidden" name="log_save" value="{/cp/form/log_save}" />
      <input type="hidden" name="domain_contact" value="{/cp/form/domain_contact}" />
      <input type="hidden" name="mail_catchall" value="{/cp/form/mail_catchall}" />
      <input type="hidden" name="mail_catchall_custom" value="{/cp/form/mail_catchall_custom}" />

      <table class="formview" border="0" cellspacing="0" cellpadding="0">
        <tr class="title">
          <td colspan="2"><xsl:copy-of select="/cp/strings/cp_title_domain_add_preview" /></td>
        </tr>
        <tr class="instructionrowhighlight">
          <td colspan="2"><xsl:copy-of select="/cp/strings/cp_instr_domain_add_preview" /></td>
        </tr>
        <tr class="title">
          <td colspan="2"><xsl:copy-of select="/cp/strings/cp_title_domain_setup" /></td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:copy-of select="/cp/strings/cp_label_da" /></td>
          <td class="contentwidth"><xsl:value-of select="/cp/form/admin" /><br /></td>
        </tr>
        <tr class="roweven">
          <td class="label"><xsl:copy-of select="/cp/strings/cp_label_domain" /></td>
          <td class="contentwidth"><xsl:value-of select="/cp/form/domain" />
            <xsl:if test="/cp/form/www_alias = 1">&#160;
              <xsl:copy-of select="/cp/strings/domain_add_alias_1" />
              <xsl:value-of select="/cp/form/domain" />
              <xsl:copy-of select="/cp/strings/domain_add_alias_2" />
            </xsl:if>
            <br />
          </td>
        </tr>

        <xsl:if test="/cp/form/ip_address">
          <tr class="roweven">
            <td class="label"><xsl:copy-of select="/cp/strings/cp_label_ip_address"/></td>
            <td class="contentwidth"><xsl:value-of select="/cp/form/ip_address"/></td>
          </tr>
        </xsl:if>

        <tr class="rowodd">
          <td class="label"><xsl:value-of select="/cp/strings/cp_label_domain_aliases" /></td>
          <td class="contentwidth"><xsl:value-of select="/cp/form/other_aliases" /></td>
        </tr>
        <tr class="roweven">
          <td class="label"><xsl:copy-of select="/cp/strings/cp_label_web_services" /></td>
          <td class="contentwidth">
            <xsl:if test="/cp/form/cgi = 1"><xsl:copy-of select="/cp/strings/cp_service_cgi" /></xsl:if>
            <xsl:if test="/cp/form/cgi = 1 and /cp/form/ssl = 1">, </xsl:if>
            <xsl:if test="/cp/form/ssl = 1"><xsl:copy-of select="/cp/strings/cp_service_ssl" /></xsl:if>
            <br />
          </td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:copy-of select="/cp/strings/cp_label_eus" /></td>
          <td class="contentwidth">
            <xsl:choose>
              <xsl:when test="/cp/form/end_users = 'limit'">
                <xsl:copy-of select="/cp/strings/cp_domains_max_eu_1" />
                <xsl:value-of select="/cp/form/end_users_limit" />
              </xsl:when>
              <xsl:otherwise>
                <xsl:copy-of select="/cp/strings/cp_domains_unlimited" />
              </xsl:otherwise>
            </xsl:choose>
            <br />
          </td>
        </tr>
        <tr class="roweven">
          <td class="label"><xsl:copy-of select="/cp/strings/cp_label_email_addresses" /></td>
          <td class="contentwidth">
            <xsl:choose>
              <xsl:when test="/cp/form/email_addr = 'limit'">
                <xsl:copy-of select="/cp/strings/cp_domains_max_emails_1" />
                <xsl:value-of select="/cp/form/email_addr_limit" />
              </xsl:when>
              <xsl:otherwise>
                <xsl:copy-of select="/cp/strings/cp_domains_unlimited" />
              </xsl:otherwise>
            </xsl:choose>
            <br />
          </td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:copy-of select="/cp/strings/cp_label_ws_logs" /></td>
          <td class="contentwidth">
            <xsl:choose>
              <xsl:when test="/cp/form/website_logs = 'yes'">
                <xsl:copy-of select="/cp/strings/cp_domains_logs_yes" /><br />
                <xsl:choose>
                  <xsl:when test="/cp/form/log_rotate_select = 'yes'">
                    <xsl:copy-of select="/cp/strings/cp_domains_rotate_yes_1" />
                    <xsl:choose>
                      <xsl:when test="/cp/form/log_rotate = 'daily'">
                        <xsl:copy-of select="/cp/strings/cp_domains_daily" />
                      </xsl:when>
                      <xsl:when test="/cp/form/log_rotate = 'weekly'">
                        <xsl:copy-of select="/cp/strings/cp_domains_weekly" />
                      </xsl:when>
                      <xsl:when test="/cp/form/log_rotate = 'monthly'">
                        <xsl:copy-of select="/cp/strings/cp_domains_monthly" />
                      </xsl:when>
                    </xsl:choose>
                    <xsl:copy-of select="/cp/strings/cp_domains_rotate_yes_2" />
                    <xsl:choose>
                      <xsl:when test="/cp/form/log_save = 'all'">
                        <xsl:copy-of select="/cp/strings/cp_domains_logs_save_all" />
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="/cp/form/log_save" />
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
              <xsl:when test="/cp/form/website_logs = 'yes'">
                /www/logs/<xsl:value-of select="/cp/form/admin" />/<xsl:value-of select="/cp/form/domain" />-access_log<br />
                /www/logs/<xsl:value-of select="/cp/form/admin" />/<xsl:value-of select="/cp/form/domain" />-error_log
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="/cp/strings/cp_label_web_log_files_na" />
              </xsl:otherwise>
            </xsl:choose>
          </td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:copy-of select="/cp/strings/cp_label_domain_contact" /></td>
          <td class="contentwidth"><xsl:value-of select="/cp/form/domain_contact" /><br />
          </td>
        </tr>
        <tr class="roweven">
          <td class="label"><xsl:copy-of select="/cp/strings/cp_label_mail_catchall" /></td>
          <td class="contentwidth">
            <xsl:choose>
              <xsl:when test="/cp/form/mail_catchall = 'reject'">
                <xsl:copy-of select="/cp/strings/cp_domains_catchall_1" />
              </xsl:when>
              <xsl:when test="/cp/form/mail_catchall = 'delete'">
                <xsl:copy-of select="/cp/strings/cp_domains_catchall_2" />
              </xsl:when>
              <xsl:when test="/cp/form/mail_catchall = 'admin'">
                <xsl:copy-of select="/cp/strings/cp_domains_catchall_3" />
              </xsl:when>
              <xsl:when test="/cp/form/mail_catchall = 'custom'">
                <xsl:copy-of select="/cp/strings/cp_domains_catchall_4" />
                <xsl:value-of select="/cp/form/mail_catchall_custom" />
              </xsl:when>
            </xsl:choose>
            <br />
          </td>
        </tr>
        <tr class="controlrow">
          <td colspan="2">
            <input class="floatright" type="submit" name="cancel" value="{/cp/strings/domain_add_btn_cancel}" />
            <input class="floatright" type="submit" name="save_another" value="{/cp/strings/domain_add_btn_save_another}" />
            <input class="floatright" type="submit" name="save" value="{/cp/strings/domain_add_btn_save}" />
            <input class="floatright" type="submit" name="previous" value="{/cp/strings/domain_add_btn_previous}" />
          </td>
        </tr>
      </table>

</xsl:template>

</xsl:stylesheet>
