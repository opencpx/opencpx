<?xml version="1.0" encoding="utf-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../cp_global.xsl" />

<xsl:variable name="message">
  <xsl:choose>
    <xsl:when test="/cp/msgs/msg[@name='user_mail_permission']">
      <xsl:copy-of select="/cp/strings/user_mail_err_mail_permission" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='user_mail_user_missing']">
      <xsl:copy-of select="/cp/strings/user_mail_err_user_missing" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='user_mail_user_unknown']">
      <xsl:copy-of select="/cp/strings/user_mail_err_user_unknown" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='user_mail_domain_missing']">
      <xsl:copy-of select="/cp/strings/user_mail_err_domain_missing" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='user_mail_domain_unknown']">
      <xsl:copy-of select="/cp/strings/user_mail_err_domain_unknown" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='user_mail_prefix_invalid']">
      <xsl:copy-of select="/cp/strings/user_mail_err_prefix_invalid" />
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

<xsl:variable name="bc_name">
  <xsl:choose>
    <xsl:when test="$type='da'">
      <xsl:value-of select="/cp/strings/bc_user_add_da_mail" />
    </xsl:when>
    <xsl:when test="$type='ma'">
      <xsl:value-of select="/cp/strings/bc_user_add_ma_mail" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="/cp/strings/bc_user_add_eu_mail" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="eu_prefix">
  <xsl:choose>
    <xsl:when test="$type='eu' or $type='ma'">
      <xsl:variable name="admin">
        <xsl:value-of select="/cp/vsap/vsap[@type='auth']/username" />
      </xsl:variable>
      <xsl:value-of select="/cp/vsap/vsap[@type='user:properties']/user[login_id=$admin]/eu_prefix" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="alias">
  <xsl:choose>
    <xsl:when test="string(/cp/form/previous)">
      <xsl:value-of select="/cp/form/txtAlias" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="/cp/form/txtLoginID" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="opt_webmail">
  <xsl:choose>
    <xsl:when test="/cp/form/checkboxWebmail">
      <xsl:choose>
        <xsl:when test="/cp/form/checkboxWebmail != ''">1</xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:otherwise>1</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="opt_spamassassin">
  <xsl:choose>
    <xsl:when test="/cp/form/checkboxSpamassassin">
      <xsl:choose>
        <xsl:when test="/cp/form/checkboxSpamassassin != ''">1</xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:otherwise>1</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="opt_clamav">
  <xsl:choose>
    <xsl:when test="/cp/form/checkboxClamav">
      <xsl:choose>
        <xsl:when test="/cp/form/checkboxClamav != ''">1</xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:otherwise>1</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:template match="/">
  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title">
      <xsl:copy-of select="/cp/strings/cp_title" />
      v<xsl:value-of select="/cp/vsap/vsap[@type='auth']/version" /> : 
      <xsl:copy-of select="$bc_name" />
    </xsl:with-param>
    <xsl:with-param name="formaction">user_add_mail.xsl</xsl:with-param>
    <xsl:with-param name="feedback" select="$feedback" />
    <xsl:with-param name="selected_navandcontent" select="$sel_navandcontent" />
    <xsl:with-param name="help_short" select="/cp/strings/user_add_hlp_short" />
    <xsl:with-param name="help_long" select="/cp/strings/user_add_mail_hlp_long" />
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

      <script src="{concat($base_url, '/cp/cp.js')}" language="JavaScript"></script>
      <input type="hidden" name="cancel" value="" />
      <input type="hidden" name="preview_next" value="" />
      <input type="hidden" name="type" value="{/cp/form/type}" />
      <input type="hidden" name="source" value="add" />
      <input type="hidden" name="old_domain" value="{/cp/form/old_domain}" />
      <input type="hidden" name="old_login" value="{/cp/form/old_login}" />
      <input type="hidden" name="txtFullName" value="{/cp/form/txtFullName}" />
      <input type="hidden" name="txtComments" value="{/cp/form/txtComments}" />
      <input type="hidden" name="txtLoginID" value="{/cp/form/txtLoginID}" />
      <input type="hidden" name="eu_prefix" value="{/cp/form/eu_prefix}" />
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
  

              <table class="formview" border="0" cellspacing="0" cellpadding="0">
                <tr class="title">
                  <xsl:choose>
                    <xsl:when test="$type='da'">
                      <td colspan="2"><xsl:value-of select="/cp/strings/cp_title_user_add_da_mail" /></td>
                    </xsl:when>
                    <xsl:when test="$type='ma'">
                      <td colspan="2"><xsl:value-of select="/cp/strings/cp_title_user_add_ma_mail" /></td>
                    </xsl:when>
                    <xsl:otherwise>
                      <td colspan="2"><xsl:value-of select="/cp/strings/cp_title_user_add_eu_mail" /></td>
                    </xsl:otherwise>
                  </xsl:choose>
                </tr>
                <tr class="instructionrow">
                  <td colspan="2"><xsl:value-of select="/cp/strings/cp_instr_user_add_mail" /></td>
                </tr>
                <tr class="rowodd">
                  <td class="label"><xsl:value-of select="/cp/strings/user_add_mail_mailbox_name" /></td>
                  <td class="contentwidth"><xsl:value-of select="$eu_prefix"/><xsl:value-of select="/cp/form/txtLoginID" /></td>
                </tr>
                <tr class="roweven">
                  <td class="label"><xsl:value-of select="/cp/strings/user_add_mail_email_addr" /></td>
                  <td class="contentwidth">
                  <xsl:choose>
                    <xsl:when test="$type='da'">
                      <input type="text" name="txtAlias" value="{$alias}" size="16" />&#160;@ <xsl:value-of select="/cp/form/txtDomain" /> <br />
                    </xsl:when>
                    <xsl:otherwise>
                      <input type="text" name="txtAlias" value="{/cp/form/txtLoginID}" size="16" />&#160;@ <xsl:value-of select="/cp/form/selectName" /> <br />
                    </xsl:otherwise>
                  </xsl:choose>
                    <span class="parenthetichelp"><xsl:value-of select="/cp/strings/user_add_mail_email_addr_help" /></span></td>
                </tr>

                <xsl:if test="($webmail_package='1') or ($spamassassin_package='1') or ($clamav_package='1')">
                  <tr class="rowodd">
                    <td class="label"><xsl:value-of select="/cp/strings/user_add_mail_apps" /></td>
                    <td class="contentwidth">
                     <xsl:choose>
                      <xsl:when test="$type='da'">
                        <xsl:value-of select="/cp/strings/cp_instr_user_add_da_mail_apps" /><br />
                      </xsl:when>
                      <xsl:when test="$type='ma'">
                        <xsl:value-of select="/cp/strings/cp_instr_user_add_ma_mail_apps" /><br />
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="/cp/strings/cp_instr_user_add_eu_mail_apps" /><br />
                      </xsl:otherwise>
                     </xsl:choose>
                     <xsl:choose>
                       <xsl:when test="$webmail_package='1'">
                         <xsl:if test="/cp/vsap/vsap[@type='auth']/server_admin or /cp/vsap/vsap[@type='auth']/capabilities/webmail">
                          <xsl:choose>
                            <xsl:when test="$opt_webmail='0'">
                              <input type="checkbox" id="webmail_app" name="checkboxWebmail" value="checkboxValue" /><label for="webmail_app"><xsl:value-of select="/cp/strings/user_add_mail_apps_webmail" /></label><br />
                            </xsl:when>
                            <xsl:otherwise>
                              <input type="checkbox" id="webmail_app" name="checkboxWebmail" value="checkboxValue" checked="checked" /><label for="webmail_app"><xsl:value-of select="/cp/strings/user_add_mail_apps_webmail" /></label><br />
                            </xsl:otherwise>
                          </xsl:choose>
                         </xsl:if>
                       </xsl:when>
                       <xsl:otherwise>
                         <input type="hidden" name="checkboxWebmail" value="" />
                       </xsl:otherwise>
                     </xsl:choose>
                     <xsl:choose>
                       <xsl:when test="$spamassassin_package='1'">
                         <xsl:if test="/cp/vsap/vsap[@type='auth']/server_admin or /cp/vsap/vsap[@type='auth']/capabilities/mail-spamassassin">
                          <xsl:choose>
                            <xsl:when test="$opt_spamassassin='0'">
                              <input type="checkbox" id="spamassassin_app" name="checkboxSpamassassin" value="checkboxValue" /><label for="spamassassin_app"><xsl:value-of select="/cp/strings/user_add_mail_apps_spamassassin" /></label><br />
                            </xsl:when>
                            <xsl:otherwise>
                              <input type="checkbox" id="spamassassin_app" name="checkboxSpamassassin" value="checkboxValue" checked="checked" /><label for="spamassassin_app"><xsl:value-of select="/cp/strings/user_add_mail_apps_spamassassin" /></label><br />
                            </xsl:otherwise>
                          </xsl:choose>
                         </xsl:if>
                       </xsl:when>
                       <xsl:otherwise>
                         <input type="hidden" name="checkboxSpamassassin" value="" />
                       </xsl:otherwise>
                     </xsl:choose>
                     <xsl:choose>
                       <xsl:when test="$clamav_package='1'">
                         <xsl:if test="/cp/vsap/vsap[@type='auth']/server_admin or /cp/vsap/vsap[@type='auth']/capabilities/mail-clamav">
                          <xsl:choose>
                            <xsl:when test="/cp/vsap/vsap[@type='mail:clamav:milter_installed']/installed='yes'">
                              <input type="hidden" name="checkboxClamav" value="on" />
                              <input type="checkbox" id="clamav_app" name="checkboxClamavSystem" value="checkboxValue" checked="checked" disabled="true" /><label for="clamav_app"><xsl:value-of select="/cp/strings/user_add_mail_apps_clamav" /></label> *<br />
                            </xsl:when>
                            <xsl:when test="$opt_clamav='0'">
                              <input type="checkbox" id="clamav_app" name="checkboxClamav" value="checkboxValue" /><label for="clamav_app"><xsl:value-of select="/cp/strings/user_add_mail_apps_clamav" /></label><br />
                            </xsl:when>
                            <xsl:otherwise>
                              <input type="checkbox" id="clamav_app" name="checkboxClamav" value="checkboxValue" checked="checked" /><label for="clamav_app"><xsl:value-of select="/cp/strings/user_add_mail_apps_clamav" /></label><br />
                            </xsl:otherwise>
                          </xsl:choose>
                         </xsl:if>
                       </xsl:when>
                       <xsl:otherwise>
                         <input type="hidden" name="checkboxClamav" value="" />
                       </xsl:otherwise>
                     </xsl:choose>
                    </td>
                  </tr>
                </xsl:if>

                <tr class="controlrow">
                  <td colspan="2">
                    <input class="floatright" type="button" name="btnCancel" value="{/cp/strings/user_add_mail_btn_cancel}" 
                      onClick="document.forms[0].cancel.value='yes';document.forms[0].submit();" />
                    <input class="floatright" type="submit" name="btnNext" value="{/cp/strings/user_add_mail_btn_next}" 
                      onClick="return validate_mail('{cp:js-escape(/cp/strings/user_mail_js_error_email_fmt)}');" />
                    <input class="floatright" type="submit" name="btnPrevious" value="{/cp/strings/user_add_mail_btn_previous}" />
                  </td>
                </tr>
              </table>

              <xsl:if test="$clamav_package='1'">
                <xsl:if test="/cp/vsap/vsap[@type='mail:clamav:milter_installed']/installed='yes'">
                  <table class="formview" border="0" cellspacing="0" cellpadding="0">
                    <tr class="errorrow">
                      <td><xsl:copy-of select="/cp/strings/user_add_mail_apps_clamav_installed_as_milter" /></td>
                    </tr>
                  </table>
                </xsl:if>
              </xsl:if>

</xsl:template>
          
</xsl:stylesheet>
