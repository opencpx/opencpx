<?xml version="1.0" encoding="utf-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../cp_global.xsl" />

<xsl:variable name="message">
  <xsl:choose>
    <xsl:when test="/cp/msgs/msg[@name='user_add_eu_mail_successful']">
      '<xsl:copy-of select="/cp/form/domain" />'<xsl:copy-of select="/cp/strings/cp_msg_domain_add" />
    </xsl:when>
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
<!--
    <xsl:when test="/cp/msgs/msg[@name='user_add_eu_mail_failure']">
      <xsl:value-of select="concat('Error - code:',/cp/vsap/vsap[@type='error']/code,' message:',/cp/vsap/vsap[@type='error']/message)" />
    </xsl:when>
-->
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
  <xsl:value-of select="/cp/vsap/vsap[@type='user:properties']/user/usertype" />
</xsl:variable>

<xsl:variable name="sel_navandcontent">
  <xsl:value-of select="/cp/strings/nv_user_list" />
</xsl:variable>

<xsl:variable name="loginid">
  <xsl:choose>
    <xsl:when test="string(/cp/form/login_id)">
      <xsl:value-of select="/cp/form/login_id" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="/cp/vsap/vsap[@type='user:properties']/user/login_id" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="domain">
  <xsl:value-of select="/cp/vsap/vsap[@type='user:properties']/user/domain" />
</xsl:variable>
  
<xsl:variable name="opt_webmail">
  <xsl:choose>
    <xsl:when test="/cp/form/checkboxWebmail">
      <xsl:value-of select="/cp/form/checkboxWebmail" />
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='user:properties']/user/capability/webmail">on</xsl:when>
    <xsl:otherwise>off</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="opt_spamassassin">
  <xsl:choose>
    <xsl:when test="/cp/form/checkboxSpamassassin">
      <xsl:value-of select="/cp/form/checkboxSpamassassin" />
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='user:properties']/user/capability/mail-spamassassin">on</xsl:when>
    <xsl:otherwise>off</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="opt_clamav">
  <xsl:choose>
    <xsl:when test="/cp/form/checkboxClamav">
      <xsl:value-of select="/cp/form/checkboxClamav" />
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='user:properties']/user/capability/mail-clamav">on</xsl:when>
    <xsl:otherwise>off</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="mail_priv">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='user:properties']/user/services/mail">1</xsl:when>
    <xsl:otherwise>0</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:template match="/">
  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title"><xsl:copy-of select="/cp/strings/cp_title" /> : <xsl:copy-of select="/cp/strings/bc_user_list" /> : <xsl:copy-of select="/cp/strings/bc_user_edit_mail"/> <xsl:copy-of select="$loginid" /> </xsl:with-param>
    <xsl:with-param name="formaction">user_edit_mail.xsl</xsl:with-param>
    <xsl:with-param name="feedback" select="$feedback" />
    <xsl:with-param name="selected_navandcontent" select="$sel_navandcontent" />
    <xsl:with-param name="help_short" select="/cp/strings/user_add_hlp_short" />
    <xsl:with-param name="help_long" select="/cp/strings/user_add_mail_hlp_long" />
    <xsl:with-param name="breadcrumb">
      <breadcrumb>
        <section>
          <name><xsl:copy-of select="/cp/strings/bc_user_list" /></name>
          <url><xsl:value-of select="concat($base_url,'/cp/users/')" /></url>
        </section>
        <section>
          <name><xsl:copy-of select="concat(/cp/strings/bc_user_properties,$loginid)" /></name>
          <url><xsl:value-of select="concat($base_url,'/cp/users/user_properties.xsl?login_id=',$loginid)" /></url>
        </section>
        <section>
          <name><xsl:copy-of select="concat(/cp/strings/bc_user_edit_mail,$loginid)" /></name>
          <url>#</url>
          <image>UserManagement</image>
        </section>
      </breadcrumb>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

      <script src="{concat($base_url, '/cp/cp.js')}" language="JavaScript"></script>
      <input type="hidden" name="save" value="" />
      <input type="hidden" name="cancel" value="" />
      <input type="hidden" name="type" value="{$type}" />
      <input type="hidden" name="source" value="edit" />
      <input type="hidden" name="login_id" value="{$loginid}" />
      <input type="hidden" name="domain" value="{$domain}" />
      <input type="hidden" name="mail_priv" value="{$mail_priv}" />

              <table class="formview" border="0" cellspacing="0" cellpadding="0">
                <tr class="title">
                  <td colspan="2"><xsl:value-of select="concat(/cp/strings/cp_title_user_edit_mail,$loginid)" /></td>
                </tr>
                <tr class="instructionrow">
                  <xsl:choose>
                    <xsl:when test="$type='sa'">
                      <td colspan="2"><xsl:value-of select="/cp/strings/cp_instr_user_edit_sa_mail" /></td>
                    </xsl:when>
                    <xsl:when test="$type='da'">
                      <td colspan="2"><xsl:value-of select="/cp/strings/cp_instr_user_edit_da_mail" /></td>
                    </xsl:when>
                    <xsl:otherwise>
                      <td colspan="2"><xsl:value-of select="/cp/strings/cp_instr_user_edit_eu_mail" /></td>
                    </xsl:otherwise>
                  </xsl:choose>
                </tr>
                <tr class="rowodd">
                  <td class="label"><xsl:value-of select="/cp/strings/user_add_mail_mailbox_name" /></td>
                  <td class="contentwidth"><xsl:value-of select="$loginid" /></td>
                </tr>
                <tr class="roweven">
                  <td class="label"><xsl:value-of select="/cp/strings/user_add_mail_email_addr" /></td>
                  <td class="contentwidth">
                    <xsl:for-each select="/cp/vsap/vsap[@type='mail:addresses:list']/address">
                      <xsl:value-of select="source" /><br />
                    </xsl:for-each>
                    <xsl:if test="count(/cp/vsap/vsap[@type='mail:addresses:list']/address) = '0'">
                      <br />
                    </xsl:if>
                  </td>
                </tr>

                <xsl:if test="($webmail_package='1') or ($spamassassin_package='1') or ($clamav_package='1')">
                  <tr class="rowodd">
                    <td class="label"><xsl:value-of select="/cp/strings/user_add_mail_apps" /></td>
                    <td class="contentwidth">
                     <xsl:choose>
                      <xsl:when test="$type='sa'">
                        <xsl:value-of select="/cp/strings/cp_instr_user_add_sa_mail_apps" /><br />
                      </xsl:when>
                      <xsl:when test="$type='da'">
                        <xsl:value-of select="/cp/strings/cp_instr_user_add_da_mail_apps" /><br />
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="/cp/strings/cp_instr_user_add_eu_mail_apps" /><br />
                      </xsl:otherwise>
                     </xsl:choose>
  
                     <xsl:choose>
                       <xsl:when test="$webmail_package='1'">
                         <xsl:if test="/cp/vsap/vsap[@type='auth']/server_admin or /cp/vsap/vsap[@type='auth']/capabilities/webmail">
                          <xsl:choose>
                            <xsl:when test="$opt_webmail='off'">
                              <input type="checkbox" id="webmail_app" name="checkboxWebmail" value="checkboxValue" /><label for="webmail_app"><xsl:value-of select="/cp/strings/user_add_mail_apps_webmail" /></label><br />
                            </xsl:when>
                            <xsl:otherwise>
                              <input type="checkbox" id="webmail_app" name="checkboxWebmail" value="checkboxValue" checked="checked" /><label for="webmail_app"><xsl:value-of select="/cp/strings/user_add_mail_apps_webmail" /></label><br />
                            </xsl:otherwise>
                          </xsl:choose>
                         </xsl:if>
                       </xsl:when>
                       <xsl:otherwise>
                         <input type="hidden" name="checkboxWebmail"><xsl:if test="$opt_webmail='on'"><xsl:attribute name="value">on</xsl:attribute></xsl:if></input>
                       </xsl:otherwise>
                     </xsl:choose>
  
                     <xsl:choose>
                       <xsl:when test="$spamassassin_package='1'">
                         <xsl:if test="/cp/vsap/vsap[@type='auth']/server_admin or /cp/vsap/vsap[@type='auth']/capabilities/mail-spamassassin">
                          <xsl:choose>
                            <xsl:when test="$opt_spamassassin='off'">
                              <input type="checkbox" id="spamassassin_app" name="checkboxSpamassassin" value="checkboxValue" /><label for="spamassassin_app"><xsl:value-of select="/cp/strings/user_add_mail_apps_spamassassin" /></label><br />
                            </xsl:when>
                            <xsl:otherwise>
                              <input type="checkbox" id="spamassassin_app" name="checkboxSpamassassin" value="checkboxValue" checked="checked" /><label for="spamassassin_app"><xsl:value-of select="/cp/strings/user_add_mail_apps_spamassassin" /></label><br />
                            </xsl:otherwise>
                          </xsl:choose>
                         </xsl:if>
                       </xsl:when>
                       <xsl:otherwise>
                         <input type="hidden" name="checkboxSpamassassin"><xsl:if test="$opt_spamassassin='on'"><xsl:attribute name="value">on</xsl:attribute></xsl:if></input>
                       </xsl:otherwise>
                     </xsl:choose>
  
                     <xsl:choose>
                       <xsl:when test="$clamav_package='1'">
                         <xsl:if test="/cp/vsap/vsap[@type='auth']/server_admin or /cp/vsap/vsap[@type='auth']/capabilities/mail-clamav">
                          <xsl:choose>
                            <xsl:when test="/cp/vsap/vsap[@type='mail:clamav:milter_installed']/installed='yes'">
                              <input type="checkbox" id="clamav_app" name="checkboxClamav" value="checkboxValue" checked="checked" disabled="true" /><label for="clamav_app"><xsl:value-of select="/cp/strings/user_add_mail_apps_clamav" /></label> *<br />
                            </xsl:when>
                            <xsl:when test="$opt_clamav='off'">
                              <input type="checkbox" id="clamav_app" name="checkboxClamav" value="checkboxValue" /><label for="clamav_app"><xsl:value-of select="/cp/strings/user_add_mail_apps_clamav" /></label><br />
                            </xsl:when>
                            <xsl:otherwise>
                              <input type="checkbox" id="clamav_app" name="checkboxClamav" value="checkboxValue" checked="checked" /><label for="clamav_app"><xsl:value-of select="/cp/strings/user_add_mail_apps_clamav" /></label><br />
                            </xsl:otherwise>
                          </xsl:choose>
                         </xsl:if>
                       </xsl:when>
                       <xsl:otherwise>
                         <input type="hidden" name="checkboxClamav"><xsl:if test="$opt_clamav='on'"><xsl:attribute name="value">on</xsl:attribute></xsl:if></input>
                       </xsl:otherwise>
                     </xsl:choose>
                    </td>
                  </tr>

                </xsl:if>
  
                <tr class="controlrow">
                  <td colspan="2">
                    <input class="floatright" type="button" name="btnCancel" value="{/cp/strings/user_add_mail_btn_cancel}" 
                      onClick="document.forms[0].cancel.value='yes';document.forms[0].submit();" />
                    <input class="floatright" type="submit" name="btnSave" value="{/cp/strings/user_edit_mail_btn_save}" 
                      onClick="return validate_mail('{cp:js-escape(/cp/strings/user_mail_js_error_email_fmt)}')" />
                  </td>
                </tr>
              </table>

              <xsl:if test="/cp/vsap/vsap[@type='mail:clamav:milter_installed']/installed='yes'">
                <table class="formview" border="0" cellspacing="0" cellpadding="0">
                  <tr class="errorrow">
                    <td><xsl:copy-of select="/cp/strings/user_add_mail_apps_clamav_installed_as_milter" /></td>
                  </tr>
                </table>
              </xsl:if>

</xsl:template>
          
</xsl:stylesheet>
