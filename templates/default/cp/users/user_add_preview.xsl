<?xml version="1.0" encoding="utf-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../cp_global.xsl" />

<xsl:variable name="message">
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

<xsl:variable name="sel_navandcontent">
  <xsl:choose>
    <xsl:when test="$type='da'">
      <xsl:value-of select="/cp/strings/nv_add_da" />
    </xsl:when>
    <xsl:when test="$type='ma'">
      <xsl:value-of select="/cp/strings/nv_add_ma" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="/cp/strings/nv_add_eu" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="hlp_long">
  <xsl:choose>
    <xsl:when test="$type='da'">
      <xsl:copy-of select="/cp/strings/user_add_da_preview_hlp_long" />
    </xsl:when>
    <xsl:when test="$type='ma'">
      <xsl:copy-of select="/cp/strings/user_add_ma_preview_hlp_long" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:copy-of select="/cp/strings/user_add_eu_preview_hlp_long" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="bc_name">
  <xsl:choose>
    <xsl:when test="$type='da'">
      <xsl:value-of select="/cp/strings/bc_user_add_da_preview" />
    </xsl:when>
    <xsl:when test="$type='ma'">
      <xsl:value-of select="/cp/strings/bc_user_add_ma_preview" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="/cp/strings/bc_user_add_eu_preview" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="eu_prefix">
  <xsl:if test="$type='da'">
    <xsl:value-of select="/cp/form/eu_prefix" />
  </xsl:if>
</xsl:variable>

<xsl:variable name="login_prefix">
  <xsl:if test="$type='eu' or $type='ma'">
    <xsl:variable name="admin">
      <xsl:value-of select="/cp/vsap/vsap[@type='auth']/username" />
    </xsl:variable>
    <xsl:value-of select="/cp/vsap/vsap[@type='user:properties']/user[login_id=$admin]/eu_prefix" />
  </xsl:if>
</xsl:variable>

<xsl:template match="/">
  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title">
      <xsl:copy-of select="/cp/strings/cp_title" />
      v<xsl:value-of select="/cp/vsap/vsap[@type='auth']/version" /> : 
      <xsl:copy-of select="$bc_name" />
    </xsl:with-param>
    <xsl:with-param name="formaction">user_add_preview.xsl</xsl:with-param>
    <xsl:with-param name="feedback" select="$feedback" />
    <xsl:with-param name="selected_navandcontent" select="$sel_navandcontent" />
    <xsl:with-param name="help_short" select="/cp/strings/user_add_hlp_short" />
    <xsl:with-param name="help_long" select="$hlp_long" />
    <xsl:with-param name="breadcrumb">
      <breadcrumb>
        <section>
          <name><xsl:copy-of select="$bc_name" /></name>
          <url>#</url>
          <image>UserManagement</image>
        </section>
      </breadcrumb>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">
<!--  for user_add_profile.xsl -->
      <input type="hidden" name="mail_next" value="" />
      <input type="hidden" name="preview_next" value="" />
      <input type="hidden" name="type" value="{/cp/form/type}" />
      <input type="hidden" name="old_domain" value="{/cp/form/old_domain}" />
      <input type="hidden" name="txtFullName" value="{/cp/form/txtFullName}" />
      <input type="hidden" name="txtComments" value="{/cp/form/txtComments}" />
      <input type="hidden" name="txtLoginID" value="{/cp/form/txtLoginID}" />
      <input type="hidden" name="txtPassword" value="{/cp/form/txtPassword}" />
      <input type="hidden" name="txtConfirmPassword" value="{/cp/form/txtConfirmPassword}" />
      <input type="hidden" name="txtQuota" value="{/cp/form/txtQuota}" />
      <xsl:if test="$type='eu' or $type='ma'">
        <input type="hidden" name="selectName" value="{/cp/form/selectName}" />
      </xsl:if> 
      <input type="hidden" name="checkboxUserMail" value="{/cp/form/checkboxUserMail}" />
      <input type="hidden" name="checkboxUserFtp" value="{/cp/form/checkboxUserFtp}" />
      <input type="hidden" name="checkboxUserFM" value="{/cp/form/checkboxUserFM}" />
      <input type="hidden" name="checkboxUserPC" value="{/cp/form/checkboxUserPC}" />
      <input type="hidden" name="checkboxUserShell" value="{/cp/form/checkboxUserShell}" />
      <input type="hidden" name="selectShell" value="{/cp/form/selectShell}" />
      <xsl:if test="$type='da'">
        <input type="hidden" name="txtDomain" value="{/cp/form/txtDomain}" />
        <xsl:if test="/cp/form/ip_address">
          <input type="hidden" name="ip_address" value="{/cp/form/ip_address}" />
        </xsl:if>
        <input type="hidden" name="checkboxEndUserMail" value="{/cp/form/checkboxEndUserMail}" />
        <input type="hidden" name="checkboxEndUserFtp" value="{/cp/form/checkboxEndUserFtp}" />
        <input type="hidden" name="checkboxEndUserFM" value="{/cp/form/checkboxEndUserFM}" />
        <input type="hidden" name="checkboxEndUserShell" value="{/cp/form/checkboxEndUserShell}" />
        <input type="hidden" name="checkboxEndUserZeroQuota" value="{/cp/form/checkboxEndUserZeroQuota}" />
      </xsl:if> 

<!--  for user_add_mail.xsl -->
      <xsl:if test="string(/cp/form/checkboxUserMail)">
        <input type="hidden" name="txtAlias" value="{/cp/form/txtAlias}" />
        <input type="hidden" name="checkboxWebmail" value="{/cp/form/checkboxWebmail}" />
        <input type="hidden" name="checkboxSpamassassin" value="{/cp/form/checkboxSpamassassin}" />
        <input type="hidden" name="checkboxClamav" value="{/cp/form/checkboxClamav}" />
      </xsl:if>  

<!--  for user_add_domain.xsl -->
      <xsl:if test="/cp/form/type = 'da'">
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
      </xsl:if>

      <xsl:if test="/cp/form/type = 'da'">
        <input type="hidden" name="eu_prefix" value="{/cp/form/eu_prefix}" />
      </xsl:if>
      <xsl:if test="/cp/form/type='eu' or /cp/form/type='ma'">
        <input type="hidden" name="txtLoginID_Prefix" value="{$login_prefix}" />
      </xsl:if>

              <table class="formview" border="0" cellspacing="0" cellpadding="0">
                <tr class="title">
                  <td colspan="2">
                    <xsl:choose>
                      <xsl:when test="$type='da'">
                        <xsl:value-of select="/cp/strings/cp_title_user_add_da_preview" />
                      </xsl:when>
                      <xsl:when test="$type='ma'">
                        <xsl:value-of select="/cp/strings/cp_title_user_add_ma_preview" />
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="/cp/strings/cp_title_user_add_eu_preview" />
                      </xsl:otherwise>
                    </xsl:choose>
                  </td>
                </tr>
                <tr class="instructionrowhighlight">
                  <td colspan="2">
                    <xsl:choose>
                      <xsl:when test="$type='da'">
                        <xsl:value-of select="/cp/strings/cp_instr_user_add_da_preview_1" /><br />
                      </xsl:when>
                      <xsl:when test="$type='ma'">
                        <xsl:value-of select="/cp/strings/cp_instr_user_add_ma_preview_1" /><br />
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="/cp/strings/cp_instr_user_add_eu_preview_1" /><br />
                      </xsl:otherwise>
                    </xsl:choose>
                    <strong><xsl:value-of select="/cp/strings/cp_instr_user_add_preview_2" /></strong></td>
                </tr>
                <tr class="title">
                  <td colspan="2"><xsl:value-of select="/cp/strings/user_add_preview_profile" /></td>
                </tr>
                <tr class="rowodd">
                  <td class="label"><xsl:value-of select="/cp/strings/user_add_preview_full_name" /></td>
                  <td class="contentwidth"><xsl:value-of select="/cp/form/txtFullName" /></td>
                </tr>
                <tr class="roweven">
                  <td class="label"><xsl:value-of select="/cp/strings/user_add_preview_login_id" /></td>
                  <td class="contentwidth"><xsl:value-of select="$login_prefix" /><xsl:value-of select="/cp/form/txtLoginID" /></td>
                </tr>
                <tr class="rowodd">
                  <td class="label"><xsl:value-of select="/cp/strings/user_add_preview_password" /></td>
                  <td class="contentwidth">********</td>
                </tr>
                <tr class="roweven">
                  <td class="label"><xsl:value-of select="/cp/strings/user_add_preview_user_disk_space" /></td>
                  <xsl:variable name="limit">
                    <xsl:value-of select="concat(/cp/strings/user_add_preview_user_disk_space_limit,/cp/form/txtQuota,' ',/cp/strings/user_add_preview_user_disk_space_mb)" />
                  </xsl:variable>
                  <td class="contentwidth"><xsl:value-of select="$limit" /></td>
                </tr>
                <tr class="rowodd">
                  <td class="label"><xsl:value-of select="/cp/strings/user_add_preview_home_dir" /></td>
                  <td class="contentwidth"><xsl:value-of select="concat('/home/',$login_prefix,/cp/form/txtLoginID,'/')" /></td>
                </tr>
                <tr class="roweven">
                  <td class="label">
                    <xsl:choose>
                      <xsl:when test="$type='da'">
                        <xsl:value-of select="/cp/strings/user_add_preview_privileges_da" />
                      </xsl:when>
                      <xsl:when test="$type='ma'">
                        <xsl:value-of select="/cp/strings/user_add_preview_privileges_ma" />
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="/cp/strings/user_add_preview_privileges_eu" />
                      </xsl:otherwise>
                    </xsl:choose>
                  </td>
                  <xsl:variable name="privs">
                    <xsl:if test="string(/cp/form/checkboxUserMail)">
                      <xsl:value-of select="/cp/strings/user_add_preview_priv_mail" />
                      <xsl:if test="string(/cp/form/checkboxUserFtp) or string(/cp/form/checkboxUserFM) or string(/cp/form/checkboxUserPC) or string(/cp/form/checkboxUserShell)">, </xsl:if>
                    </xsl:if>
                    <xsl:if test="string(/cp/form/checkboxUserFtp)">
                      <xsl:value-of select="/cp/strings/user_add_preview_priv_ftp" />
                      <xsl:if test="string(/cp/form/checkboxUserFM) or string(/cp/form/checkboxUserPC) or string(/cp/form/checkboxUserShell)">, </xsl:if>
                    </xsl:if>
                    <xsl:if test="string(/cp/form/checkboxUserFM)">
                      <xsl:value-of select="/cp/strings/user_add_preview_priv_fm" />
                      <xsl:if test="string(/cp/form/checkboxUserPC) or string(/cp/form/checkboxUserShell)">, </xsl:if>
                    </xsl:if>
                    <xsl:if test="string(/cp/form/checkboxUserPC)">
                      <xsl:value-of select="/cp/strings/user_add_preview_priv_pc" />
                      <xsl:if test="string(/cp/form/checkboxUserShell)">, </xsl:if>
                    </xsl:if>
                    <xsl:if test="string(/cp/form/checkboxUserShell)">
                      <xsl:value-of select="/cp/strings/user_add_preview_priv_shell" />
                    </xsl:if>
                  </xsl:variable>
                  <td class="contentwidth"><xsl:value-of select="$privs" /></td>
                </tr>
                <xsl:if test="$type='da'">
                  <tr class="rowodd">
                    <td class="label">
                      <xsl:value-of select="/cp/strings/user_add_preview_da_privileges_eu" />
                    </td>
                    <xsl:variable name="eu_privs">
                      <xsl:if test="string(/cp/form/checkboxEndUserMail)">
                        <xsl:value-of select="/cp/strings/user_add_preview_priv_mail" />
                        <xsl:if test="string(/cp/form/checkboxEndUserFtp) or string(/cp/form/checkboxEndUserFM) or string(/cp/form/checkboxEndUserShell) or string(/cp/form/checkboxEndUserZeroQuota)">, </xsl:if>
                      </xsl:if>
                      <xsl:if test="string(/cp/form/checkboxEndUserFtp)">
                        <xsl:value-of select="/cp/strings/user_add_preview_priv_ftp" />
                        <xsl:if test="string(/cp/form/checkboxEndUserFM) or string(/cp/form/checkboxEndUserShell) or string(/cp/form/checkboxEndUserZeroQuota)">, </xsl:if>
                      </xsl:if>
                      <xsl:if test="string(/cp/form/checkboxEndUserFM)">
                        <xsl:value-of select="/cp/strings/user_add_preview_priv_fm" />
                        <xsl:if test="string(/cp/form/checkboxEndUserShell) or string(/cp/form/checkboxEndUserZeroQuota)">, </xsl:if>
                      </xsl:if>
                      <xsl:if test="string(/cp/form/checkboxEndUserShell)">
                        <xsl:value-of select="/cp/strings/user_add_preview_priv_shell" />
                        <xsl:if test="string(/cp/form/checkboxEndUserZeroQuota)">, </xsl:if>
                      </xsl:if>
                      <xsl:if test="string(/cp/form/checkboxEndUserZeroQuota)">
                        <xsl:value-of select="/cp/strings/user_add_preview_priv_zeroquota" />
                      </xsl:if>
                    </xsl:variable>
                    <td class="contentwidth"><xsl:value-of select="$eu_privs" /></td>
                  </tr>
                  <tr class="roweven">
                    <td class="label"><xsl:value-of select="/cp/strings/user_add_domain_eu_prefix" /></td>
                    <td class="contentwidth"><xsl:value-of select="/cp/form/eu_prefix" /></td>
                  </tr>
                </xsl:if>
                <xsl:choose>
                  <xsl:when test="$type='da'">
                    <tr class="rowodd">
                      <td class="label"><xsl:value-of select="/cp/strings/user_add_preview_domain" /></td>
                      <td class="contentwidth"><a href="http://{/cp/form/txtDomain}" target="_blank"><xsl:value-of select="/cp/form/txtDomain" /></a></td>
                    </tr>

                   <tr class="rowodd">
                     <td class="label"><xsl:value-of select="/cp/strings/cp_label_ip_address" /></td>
                     <td class="contentwidth"><xsl:value-of select="/cp/form/ip_address"/><br /></td>
                   </tr>

                  </xsl:when>
                  <xsl:otherwise>
                    <tr class="roweven">
                      <td class="label"><xsl:value-of select="/cp/strings/user_add_preview_domain" /></td>
                      <td class="contentwidth"><a href="http://{/cp/form/selectName}" target="_blank"><xsl:value-of select="/cp/form/selectName" /></a></td>
                    </tr>
                  </xsl:otherwise>
                </xsl:choose>
                <tr class="rowodd">
                  <td class="label"><xsl:value-of select="/cp/strings/user_add_preview_comments" /></td>
                  <td class="contentwidth"><xsl:value-of select="/cp/form/txtComments" /></td>
                </tr>
                <xsl:if test="string(/cp/form/checkboxUserMail)">
                  <tr class="title">
                    <td colspan="2"><xsl:value-of select="/cp/strings/user_add_preview_mail_setup" /></td>
                  </tr>
                  <tr class="rowodd">
                    <td class="label"><xsl:value-of select="/cp/strings/user_add_preview_mailbox_name" /></td>
                    <td class="contentwidth"><xsl:value-of select="$login_prefix" /><xsl:value-of select="/cp/form/txtLoginID" /></td>
                  </tr>
                  <tr class="roweven">
                    <td class="label"><xsl:value-of select="/cp/strings/user_add_preview_email_addr" /></td>
                    <xsl:variable name="email">
                      <xsl:choose>
                        <xsl:when test="$type='da'">
                          <xsl:value-of select="concat(/cp/form/txtAlias,'@',/cp/form/txtDomain)" />
                        </xsl:when>
                        <xsl:otherwise>
                          <xsl:value-of select="concat(/cp/form/txtAlias,'@',/cp/form/selectName)" />
                        </xsl:otherwise>
                      </xsl:choose>
                    </xsl:variable>
                    <td class="contentwidth"><xsl:value-of select="$email" /></td>
                  </tr>
                  <tr class="rowodd">
                    <td class="label"><xsl:value-of select="/cp/strings/user_add_preview_mail_apps" /></td>
                    <xsl:variable name="mail_apps">
                      <xsl:if test="string(/cp/form/checkboxWebmail)">
                        <xsl:value-of select="/cp/strings/user_add_preview_mail_apps_webmail" />
                        <xsl:if test="string(/cp/form/checkboxSpamassassin) or string(/cp/form/checkboxClamav)">, </xsl:if>
                      </xsl:if>
                      <xsl:if test="string(/cp/form/checkboxSpamassassin)">
                        <xsl:value-of select="/cp/strings/user_add_preview_mail_apps_spamassassin" />
                        <xsl:if test="string(/cp/form/checkboxClamav)">, </xsl:if>
                      </xsl:if>
                      <xsl:if test="string(/cp/form/checkboxClamav)">
                        <xsl:value-of select="/cp/strings/user_add_preview_mail_apps_clamav" />
                      </xsl:if>
                    </xsl:variable>
                    <td class="contentwidth"><xsl:value-of select="$mail_apps" /></td>
                  </tr>
                </xsl:if>   

                <xsl:if test="$type='da'">
                  <tr class="title">
                    <td colspan="2"><xsl:value-of select="/cp/strings/user_add_preview_domain_setup" /></td>
                  </tr>
                  <tr class="rowodd">
                    <td class="label"><xsl:value-of select="/cp/strings/user_add_preview_domain_admin" /></td>
                    <td class="contentwidth"><xsl:value-of select="/cp/form/txtLoginID" /></td>
                  </tr>
                  <tr class="roweven">
                    <td class="label"><xsl:value-of select="/cp/strings/user_add_preview_domain" /></td>
                    <xsl:variable name="www_status">
                      <xsl:choose>
                        <xsl:when test="/cp/form/www_alias='1'">
                          <xsl:value-of select="concat(' (www.',/cp/form/txtDomain,' ',/cp/strings/user_add_preview_domain_www_enabled,')')" />
                        </xsl:when>
                        <xsl:otherwise>
                          <xsl:value-of select="concat(' (www.',/cp/form/txtDomain,' ',/cp/strings/user_add_preview_domain_www_disabled,')')" />
                        </xsl:otherwise>
                      </xsl:choose>
                    </xsl:variable>
                    <td class="contentwidth"><xsl:value-of select="/cp/form/txtDomain" /> 
                      <xsl:value-of select="$www_status" />
                    </td>
                  </tr>
                  <tr class="roweven">
                    <td class="label"><xsl:value-of select="/cp/strings/cp_label_domain_aliases" /></td>
                    <td class="contentwidth"><xsl:value-of select="/cp/form/other_aliases" /></td>
                  </tr>
                  <tr class="rowodd">
                    <td class="label"><xsl:value-of select="/cp/strings/user_add_preview_domain_webservices" /></td>
                    <td class="contentwidth">
                      <xsl:if test="/cp/form/cgi = '1'"><xsl:copy-of select="/cp/strings/user_add_preview_domain_ws_cgi" /></xsl:if>
                      <xsl:if test="/cp/form/cgi = '1' and /cp/form/ssl = '1'">, </xsl:if>
                      <xsl:if test="/cp/form/ssl = '1'"><xsl:copy-of select="/cp/strings/user_add_preview_domain_ws_ssl" /></xsl:if><br />
                    </td>
                  </tr>
                  <tr class="roweven">
                    <td class="label"><xsl:value-of select="/cp/strings/user_add_preview_domain_eus" /></td>
                    <td class="contentwidth">
                      <xsl:choose>
                        <xsl:when test="/cp/form/end_users = 'limit'">
                          <xsl:copy-of select="/cp/strings/user_add_preview_domain_max_eus" />
                          <xsl:value-of select="/cp/form/end_users_limit" />
                        </xsl:when>
                        <xsl:otherwise>
                          <xsl:copy-of select="/cp/strings/user_add_preview_domain_unlimited_eus" />
                        </xsl:otherwise>
                      </xsl:choose>
                    </td>
                  </tr>
                  <tr class="rowodd">
                    <td class="label"><xsl:value-of select="/cp/strings/user_add_preview_domain_email_addrs" /></td>
                    <td class="contentwidth">
                      <xsl:choose>
                        <xsl:when test="/cp/form/email_addr = 'limit'">
                          <xsl:copy-of select="/cp/strings/user_add_preview_domain_max_email_addrs" />
                          <xsl:value-of select="/cp/form/email_addr_limit" />
                        </xsl:when>
                        <xsl:otherwise>
                          <xsl:copy-of select="/cp/strings/user_add_preview_domain_unlimited_email_addrs" />
                        </xsl:otherwise>
                      </xsl:choose>
                    </td>
                  </tr>
                  <tr class="roweven">
                    <td class="label"><xsl:value-of select="/cp/strings/user_add_preview_domain_website_logs" /></td>
                    <td class="contentwidth">
                      <xsl:choose>
                        <xsl:when test="/cp/form/website_logs = 'yes'">
                          <xsl:copy-of select="/cp/strings/user_add_preview_domain_ws_logs_yes" /><br />
                          <xsl:choose>
                            <xsl:when test="/cp/form/log_rotate_select = 'yes'">
                              <xsl:copy-of select="/cp/strings/user_add_preview_domain_ws_rotate_yes_1" />
                              <xsl:choose>
                                <xsl:when test="/cp/form/log_rotate = 'daily'">
                                  <xsl:copy-of select="/cp/strings/user_add_preview_domain_ws_rotate_daily" />
                                </xsl:when>
                                <xsl:when test="/cp/form/log_rotate = 'weekly'">
                                  <xsl:copy-of select="/cp/strings/user_add_preview_domain_ws_rotate_weekly" />
                                </xsl:when>
                                <xsl:when test="/cp/form/log_rotate = 'monthly'">
                                  <xsl:copy-of select="/cp/strings/user_add_preview_domain_ws_rotate_monthly" />
                                </xsl:when>
                              </xsl:choose>
                              <xsl:copy-of select="/cp/strings/user_add_preview_domain_ws_rotate_yes_2" />
                              <xsl:choose>
                                <xsl:when test="/cp/form/log_save = 'all'">
                                  <xsl:copy-of select="/cp/strings/user_add_preview_domain_ws_logs_save_all" />
                                </xsl:when>
                                <xsl:otherwise>
                                  <xsl:value-of select="/cp/form/log_save" />
                                </xsl:otherwise>
                              </xsl:choose>
                              <xsl:copy-of select="/cp/strings/user_add_preview_domain_ws_rotate_yes_3" />
                            </xsl:when>
                            <xsl:otherwise>
                              <xsl:copy-of select="/cp/strings/user_add_preview_ws_rotate_no" />
                            </xsl:otherwise>
                          </xsl:choose>
                        </xsl:when>
                        <xsl:otherwise>
                          <xsl:copy-of select="/cp/strings/user_add_preview_domain_ws_logs_no" />
                        </xsl:otherwise>
                      </xsl:choose>
                      <br />
                    </td>
                  </tr>
                  <tr class="rowodd">
                    <td class="label"><xsl:value-of select="/cp/strings/user_add_preview_domain_website_files" /></td>
                    <td class="contentwidth">
                      <xsl:choose>
                        <xsl:when test="/cp/form/website_logs='no'">
                          <xsl:value-of select="/cp/strings/user_add_preview_domain_website_files_na" />
                        </xsl:when>
                        <xsl:otherwise>
                          /www/logs/<xsl:value-of select="/cp/form/txtLoginID" />/<xsl:value-of select="/cp/form/txtDomain" />-access_log<br />
                         /www/logs/<xsl:value-of select="/cp/form/txtLoginID" />/<xsl:value-of select="/cp/form/txtDomain" />-error_log<br />
                        </xsl:otherwise>
                      </xsl:choose>
                    </td>
                  </tr>
                  <tr class="roweven">
                    <td class="label"><xsl:value-of select="/cp/strings/user_add_preview_domain_contact" /></td>
                    <td class="contentwidth"><xsl:value-of select="/cp/form/domain_contact" /></td>
                  </tr>
                  <tr class="rowodd">
                    <td class="label"><xsl:value-of select="/cp/strings/user_add_preview_domain_mail_catchall" /></td>
                    <td class="contentwidth">
                      <xsl:choose>
                        <xsl:when test="/cp/form/mail_catchall = 'reject'">
                          <xsl:copy-of select="/cp/strings/user_add_preview_domain_catchall_1" />
                        </xsl:when>
                        <xsl:when test="/cp/form/mail_catchall = 'delete'">
                          <xsl:copy-of select="/cp/strings/user_add_preview_domain_catchall_2" />
                        </xsl:when>
                        <xsl:when test="/cp/form/mail_catchall = 'admin'">
                          <xsl:copy-of select="/cp/strings/user_add_preview_domain_catchall_3" />
                        </xsl:when>
                        <xsl:when test="/cp/form/mail_catchall = 'custom'">
                          <xsl:copy-of select="/cp/strings/user_add_preview_domain_catchall_4" />
                          <xsl:value-of select="/cp/form/mail_catchall_custom" />
                        </xsl:when>
                      </xsl:choose>
                    </td>
                  </tr>
                </xsl:if>

                <tr class="controlrow">
                  <td colspan="2"><input class="floatright" type="submit" name="btnCancel" value="{/cp/strings/user_add_preview_btn_cancel}" /><input class="floatright" type="submit" name="btnSaveAnother" value="{/cp/strings/user_add_preview_btn_saveanother}" /><input class="floatright" type="submit" name="btnSave" value="{/cp/strings/user_add_preview_btn_save}" /> <input class="floatright" type="submit" name="btnPreviewPrevious" value="{/cp/strings/user_add_preview_btn_previous}" /></td>
                </tr>
              </table>
             
</xsl:template>
          
</xsl:stylesheet>
