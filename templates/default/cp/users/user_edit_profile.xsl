<?xml version="1.0" encoding="utf-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../cp_global.xsl" />

<xsl:variable name="message">
  <xsl:choose>
    <xsl:when test="/cp/msgs/msg[@name='add_enduser_successful']">
      '<xsl:copy-of select="/cp/form/domain" />'<xsl:copy-of select="/cp/strings/cp_msg_add_enduser" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='emails_maxed_out']">
      <xsl:copy-of select="/cp/strings/user_profile_err_user_email_max" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='email_address_exists']">
      '<xsl:value-of select="/cp/form/login_id" />@<xsl:value-of select="/cp/form/domain" />'<xsl:copy-of select="/cp/strings/user_profile_err_email_address_exists" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='user_permission']">
      <xsl:copy-of select="/cp/strings/user_profile_err_user_permission" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='user_eu_quota_out_of_bounds']">
      <xsl:copy-of select="/cp/strings/user_profile_err_eu_quota_exceeded" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='user_eu_quota_allocation_failure']">
      <xsl:copy-of select="/cp/strings/user_profile_err_quota_allocation_failure" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='user_unknown_domain']">
      <xsl:copy-of select="/cp/strings/user_profile_err_unknown_domain" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='user_service_verboten']">
      <xsl:copy-of select="/cp/strings/user_profile_err_service_verboten" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='user_vadduser_error']">
      <xsl:copy-of select="/cp/strings/user_profile_err_vadduser_error" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='user_login_exists']">
      <xsl:copy-of select="/cp/strings/user_profile_err_login_exists" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='user_domain_add_exists']">
      <xsl:copy-of select="/cp/strings/user_domain_err_add_exists" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='user_internal_error']">
      <xsl:copy-of select="/cp/strings/user_internal_error" />
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
    <xsl:when test="/cp/msgs/msg[@name='user_prefix_too_long']">
      <xsl:copy-of select="/cp/strings/user_profile_err_prefix_too_long" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='user_prefix_bad_chars']">
      <xsl:copy-of select="/cp/strings/user_profile_err_prefix_bad_chars" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='user_prefix_first_char_invalid']">
      <xsl:copy-of select="/cp/strings/user_profile_err_prefix_first_char_invalid" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='user_prefix_duplicate']">
      <xsl:copy-of select="/cp/strings/user_profile_err_prefix_duplicate" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='user_edit_password_new_missing']">
      <xsl:copy-of select="/cp/strings/user_edit_password_new_missing" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='user_edit_password_new_not_matching']">
      <xsl:copy-of select="/cp/strings/user_edit_password_new_not_matching" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='user_edit_password_change_error']">
      <xsl:copy-of select="/cp/strings/user_edit_password_change_error" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='user_edit_password_old_missing']">
      <xsl:copy-of select="/cp/strings/user_edit_password_old_missing" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='user_edit_password_old_not_matching']">
      <xsl:copy-of select="/cp/strings/user_edit_password_old_not_matching" />
    </xsl:when>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="feedback">
  <xsl:if test="$message != ''">
    <xsl:call-template name="feedback_table">
      <xsl:with-param name="image">
        <xsl:choose>
          <xsl:when test="/cp/vsap/vsap[@type='error']">error</xsl:when>
          <xsl:when test="/cp/msgs/msg[@name='emails_maxed_out']">error</xsl:when>
          <xsl:when test="/cp/msgs/msg[@name='email_address_exists']">error</xsl:when>
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

<xsl:variable name="admin">
  <xsl:value-of select="/cp/vsap/vsap[@type='auth']/username" />
</xsl:variable>

<xsl:variable name="sel_navandcontent">
  <xsl:value-of select="/cp/strings/nv_user_list" />
</xsl:variable>

<xsl:variable name="hlp_long">
  <xsl:choose>
    <xsl:when test="$type='da' or $type='sa'">
      <xsl:copy-of select="/cp/strings/user_add_da_profile_hlp_long" />
    </xsl:when>
    <xsl:when test="$type='ma'">
      <xsl:copy-of select="/cp/strings/user_add_ma_profile_hlp_long" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:copy-of select="/cp/strings/user_add_eu_profile_hlp_long" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="fullname">
  <xsl:choose>
    <xsl:when test="string(/cp/form/txtFullName)">
      <xsl:value-of select="/cp/form/txtFullName" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="/cp/vsap/vsap[@type='user:properties']/user/fullname" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="comments">
  <xsl:choose>
    <xsl:when test="string(/cp/form/txtComments)">
      <xsl:value-of select="/cp/form/txtComments" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="/cp/vsap/vsap[@type='user:properties']/user/comments" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="eu_prefix">
  <xsl:choose>
    <xsl:when test="string(/cp/form/eu_prefix)">
      <xsl:value-of select="/cp/form/eu_prefix" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="/cp/vsap/vsap[@type='user:properties']/user/eu_prefix" />
    </xsl:otherwise>
  </xsl:choose>
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

<xsl:variable name="password">
  <xsl:choose>
    <xsl:when test="string(/cp/form/txtPassword)">
      <xsl:value-of select="/cp/form/txtPassword" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="confirm_password">
  <xsl:choose>
    <xsl:when test="string(/cp/form/txtConfirmPassword)">
      <xsl:value-of select="/cp/form/txtConfirmPassword" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="quota">
  <xsl:choose>
    <xsl:when test="string(/cp/form/txtQuota)">
      <xsl:value-of select="/cp/form/txtQuota" />
    </xsl:when>
    <xsl:when test="$type='sa'">
      <xsl:value-of select="/cp/vsap/vsap[@type='user:properties']/user/user_quota/limit" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="/cp/vsap/vsap[@type='user:properties']/user/quota/limit" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="mail_service_exists">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='user:properties']/user[login_id=$loginid]/services/mail">1</xsl:when>
    <xsl:otherwise>0</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="opt_mail">
  <xsl:choose>
    <xsl:when test="string(/cp/form/checkboxUserMail)">
      <xsl:value-of select="/cp/form/checkboxUserMail" />
    </xsl:when>
    <xsl:when test="$type='sa'">1</xsl:when>
    <xsl:otherwise>
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='user:properties']/user/capability/mail">1</xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="opt_ftp">
  <xsl:choose>
    <xsl:when test="string(/cp/form/checkboxUserFtp)">
      <xsl:value-of select="/cp/form/checkboxUserFtp" />
    </xsl:when>
    <xsl:when test="$type='sa'">1</xsl:when>
    <xsl:otherwise>
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='user:properties']/user/capability/ftp">1</xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="opt_fm">
  <xsl:choose>
    <xsl:when test="string(/cp/form/checkboxUserFM)">
      <xsl:value-of select="/cp/form/checkboxUserFM" />
    </xsl:when>
    <xsl:when test="$type='sa'">1</xsl:when>
    <xsl:otherwise>
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='user:properties']/user/capability/fileman">1</xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="opt_shell">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='auth']/siteprefs/disable-shell">0</xsl:when>
    <xsl:when test="string(/cp/form/checkboxUserShell)">
      <xsl:value-of select="/cp/form/checkboxUserShell" />
    </xsl:when>
    <xsl:when test="$type='sa'">1</xsl:when>
    <xsl:otherwise>
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='user:properties']/user/capability/shell">1</xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="auth_mail_admin">
  <xsl:choose>
    <xsl:when test="string(/cp/form/checkboxUserMailAdmin)">1</xsl:when>
    <xsl:when test="$type='ma'">1</xsl:when>
    <xsl:otherwise>0</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="service_mail">
  <xsl:choose>
    <xsl:when test="string(/cp/form/checkboxUserMail)">1</xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='user:properties']/user/services/mail">1</xsl:when>
    <xsl:otherwise>0</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="service_ftp">
  <xsl:choose>
    <xsl:when test="string(/cp/form/checkboxUserFtp)">1</xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='user:properties']/user/services/ftp">1</xsl:when>
    <xsl:otherwise>0</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="service_fm">
  <xsl:choose>
    <xsl:when test="string(/cp/form/checkboxUserFM)">1</xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='user:properties']/user/services/fileman">1</xsl:when>
    <xsl:otherwise>0</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="service_shell">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='auth']/siteprefs/disable-shell">0</xsl:when>
    <xsl:when test="string(/cp/form/checkboxUserShell)">1</xsl:when>
    <xsl:when test="$type='sa'">1</xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='user:properties']/user/services/shell">1</xsl:when>
    <xsl:otherwise>0</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="service_pc">
  <xsl:choose>
    <xsl:when test="string(/cp/form/checkboxUserPC)">1</xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='user:properties']/user/services/podcast">1</xsl:when>
    <xsl:otherwise>0</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="selectShell">
  <xsl:choose>
    <xsl:when test="string(/cp/form/selectShell)">
      <xsl:value-of select="/cp/form/selectShell" />
    </xsl:when>
    <xsl:when test="$service_shell='1'">
      <xsl:for-each select="/cp/vsap/vsap[@type='user:shell:list']/shell">
        <xsl:if test="@current='1'">
          <xsl:value-of select="path" />
        </xsl:if>
      </xsl:for-each>
    </xsl:when>
    <xsl:otherwise>/bin/tcsh</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="opt_eup_mail">
  <xsl:choose>
    <xsl:when test="string(/cp/form/checkboxEndUserMail)">1</xsl:when>
    <xsl:otherwise>
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='user:properties']/user/eu_capability/mail">1</xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="opt_eup_ftp">
  <xsl:choose>
    <xsl:when test="string(/cp/form/checkboxEndUserFtp)">1</xsl:when>
    <xsl:otherwise>
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='user:properties']/user/eu_capability/ftp">1</xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="opt_eup_fm">
  <xsl:choose>
    <xsl:when test="string(/cp/form/checkboxEndUserFM)">1</xsl:when>
    <xsl:otherwise>
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='user:properties']/user/eu_capability/fileman">1</xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="opt_eup_shell">
  <xsl:choose>
    <xsl:when test="string(/cp/form/checkboxEndUserShell)">1</xsl:when>
    <xsl:otherwise>
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='user:properties']/user/eu_capability/shell">1</xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="opt_eup_zeroquota">
  <xsl:choose>
    <xsl:when test="string(/cp/form/checkboxEndUserZeroQuota)">1</xsl:when>
    <xsl:otherwise>
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='user:properties']/user/eu_capability/zeroquota">1</xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="eu_capa_mail">
  <xsl:choose>
    <xsl:when test="string(/cp/form/eu_capa_mail)">
      <xsl:value-of select="/cp/form/eu_capa_mail" />
    </xsl:when>
    <xsl:when test="$user_type='sa'">1</xsl:when>
    <xsl:otherwise>
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='user:list_eu_capa']/eu_capa/mail">1</xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="eu_capa_ftp">
  <xsl:choose>
    <xsl:when test="string(/cp/form/eu_capa_ftp)">
      <xsl:value-of select="/cp/form/eu_capa_ftp" />
    </xsl:when>
    <xsl:when test="$user_type='sa'">1</xsl:when>
    <xsl:otherwise>
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='user:list_eu_capa']/eu_capa/ftp">1</xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="eu_capa_fm">
  <xsl:choose>
    <xsl:when test="string(/cp/form/eu_capa_fm)">
      <xsl:value-of select="/cp/form/eu_capa_fm" />
    </xsl:when>
    <xsl:when test="$user_type='sa'">1</xsl:when>
    <xsl:otherwise>
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='user:list_eu_capa']/eu_capa/fileman">1</xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="eu_capa_shell">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='auth']/siteprefs/disable-shell">0</xsl:when>
    <xsl:when test="string(/cp/form/eu_capa_shell)">
      <xsl:value-of select="/cp/form/eu_capa_shell" />
    </xsl:when>
    <xsl:when test="$user_type='sa'">1</xsl:when>
    <xsl:otherwise>
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='user:list_eu_capa']/eu_capa/shell">1</xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="eu_capa_zeroquota">
  <xsl:choose>
    <xsl:when test="string(/cp/form/eu_capa_zeroquota)">
      <xsl:value-of select="/cp/form/eu_capa_zeroquota" />
    </xsl:when>
    <xsl:when test="$user_type='sa'">1</xsl:when>
    <xsl:otherwise>
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='user:list_eu_capa']/eu_capa/zeroquota">1</xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<!-- Saving the following variables as hidden to remedy bug 4802 -->
<xsl:variable name="webmail_capa">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='user:properties']/user/capability/webmail">1</xsl:when>
    <xsl:otherwise>0</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="spam_capa">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='user:properties']/user/capability/mail-spamassassin">1</xsl:when>
    <xsl:otherwise>0</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="clam_capa">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='user:properties']/user/capability/mail-clamav">1</xsl:when>
    <xsl:otherwise>0</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:template match="/">
 <xsl:call-template name="bodywrapper">
  <xsl:with-param name="title">
    <xsl:copy-of select="/cp/strings/cp_title" />
    v<xsl:value-of select="/cp/vsap/vsap[@type='auth']/version" /> : 
    <xsl:copy-of select="/cp/strings/bc_user_list" /> : 
    <xsl:copy-of select="/cp/strings/bc_user_edit_profile"/> <xsl:copy-of select="$loginid" />
  </xsl:with-param>
  <xsl:with-param name="formaction">user_edit_profile.xsl</xsl:with-param>
  <xsl:with-param name="feedback" select="$feedback" />
  <xsl:with-param name="help_short" select="/cp/strings/user_add_hlp_short" />
  <xsl:with-param name="selected_navandcontent" select="$sel_navandcontent" />
  <xsl:with-param name="help_long" select="$hlp_long" />
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
        <name><xsl:copy-of select="concat(/cp/strings/bc_user_edit_profile,$loginid)" /></name>
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
      <input type="hidden" name="mail_service_exists" value="{$mail_service_exists}" />
      <input type="hidden" name="eu_mail" value="{$opt_mail}" />
      <input type="hidden" name="eu_ftp" value="{$opt_ftp}" />
      <input type="hidden" name="eu_fm" value="{$opt_fm}" />
      <input type="hidden" name="eu_shell" value="{$opt_shell}" />
      <input type="hidden" name="eu_capa_mail" value="{$eu_capa_mail}" />
      <input type="hidden" name="eu_capa_ftp" value="{$eu_capa_ftp}" />
      <input type="hidden" name="eu_capa_fm" value="{$eu_capa_fm}" />
      <input type="hidden" name="eu_capa_shell" value="{$eu_capa_shell}" />
      <input type="hidden" name="eu_capa_zeroquota" value="{$eu_capa_zeroquota}" />

      <!-- saving these fields as hidden to pass to user_edit_profile.meta.xsl (bug 4802) -->
      <input type="hidden" name="webmail_capa" value="{$webmail_capa}" />
      <input type="hidden" name="spam_capa" value="{$spam_capa}" />
      <input type="hidden" name="clam_capa" value="{$clam_capa}" />

      <!-- saving this field - needed for bug 16990 -->
      <input type="hidden" name="old_domain" value="{/cp/vsap/vsap[@type='user:properties']/user/domain}" />


      <!-- some hidden field for sa privs -->
      <xsl:if test="$type='sa'">
        <input type="hidden" name="checkboxUserMail" value="true" />
        <input type="hidden" name="checkboxUserFtp" value="true" />
        <input type="hidden" name="checkboxUserFM" value="true" />
        <input type="hidden" name="checkboxUserPC" value="true" />
        <input type="hidden" name="checkboxUserShell" value="true" />
        <input type="hidden" name="checkboxEndUserMail" value="true" />
        <input type="hidden" name="checkboxEndUserFtp" value="true" />
        <input type="hidden" name="checkboxEndUserFM" value="true" />
        <input type="hidden" name="checkboxEndUserShell" value="true" />
        <input type="hidden" name="checkboxEndUserZeroQuota" value="true" />
      </xsl:if>

      <table class="formview" border="0" cellspacing="0" cellpadding="0">
        <tr class="title">
          <td colspan="2">
            <xsl:copy-of select="concat(/cp/strings/cp_title_user_edit_profile,$loginid)" />
          </td>
        </tr>
        <tr class="instructionrow">
          <xsl:choose>
            <xsl:when test="$type='sa'">
              <td colspan="2"><xsl:copy-of select="/cp/strings/cp_instr_user_edit_sa_profile" /></td>
            </xsl:when>
            <xsl:when test="$type='da'">
              <td colspan="2"><xsl:copy-of select="/cp/strings/cp_instr_user_edit_da_profile" /></td>
            </xsl:when>
            <xsl:when test="$type='ma'">
              <td colspan="2"><xsl:copy-of select="/cp/strings/cp_instr_user_edit_ma_profile" /></td>
            </xsl:when>
            <xsl:otherwise>
              <td colspan="2"><xsl:copy-of select="/cp/strings/cp_instr_user_edit_eu_profile" /></td>
            </xsl:otherwise>
          </xsl:choose>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:value-of select="/cp/strings/user_profile_full_name" /></td>
          <td class="contentwidth"><input type="text" name="txtFullName" size="42" maxlength="100" value="{$fullname}" />&#160;<span class="parenthetichelp"><xsl:value-of select="/cp/strings/user_profile_full_name_help" /></span></td>
        </tr>
        <tr class="roweven">
          <td class="label"><xsl:value-of select="/cp/strings/user_profile_login_id" /></td>
          <td class="contentwidth">
            <xsl:value-of select="$loginid" />
          </td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:value-of select="/cp/strings/user_profile_password" /></td>
          <td class="contentwidth"><input type="password" autocomplete="off" name="txtPassword" size="42" maxlength="32" value="{$password}" />&#160;<span class="parenthetichelp"><xsl:value-of select="/cp/strings/user_profile_password_help" /></span></td>
        </tr>
        <tr class="roweven">
          <td class="label"><xsl:value-of select="/cp/strings/user_profile_password_confirm" /></td>
          <td class="contentwidth"><input type="password" autocomplete="off" name="txtConfirmPassword" size="42" maxlength="32" value="{confirm_password}" /></td>
        </tr>
        <xsl:if test="$admin = $loginid">
          <tr class="roweven">
            <td class="label"><xsl:value-of select="/cp/strings/user_profile_password_old"/></td>
            <td class="contentwidth">
                <input type="password" name="old_password" size="42" value="" autocomplete="off" />
            </td>
          </tr>
        </xsl:if>
        <xsl:if test="$type='sa'">
          <tr class="rowodd">
            <td class="label"><xsl:value-of select="/cp/strings/cp_label_server_disk_space" /></td>
            <td class="contentwidth">&#160;<xsl:value-of select="/cp/vsap/vsap[@type='user:properties']/user/quota/limit" />&#160;<xsl:value-of select="/cp/strings/user_profile_user_disk_space_mb" /></td>
          </tr>
        </xsl:if>
        <tr class="rowodd">
          <td class="label"><xsl:value-of select="/cp/strings/user_profile_user_disk_space" /></td>
          <td class="contentwidth">&#160;<input type="text" name="txtQuota" size="5" value="{$quota}" />&#160;<xsl:value-of select="/cp/strings/user_profile_user_disk_space_mb" /></td>
        </tr>

        <xsl:choose>
          <xsl:when test="$type='da' or $type='sa'">
              <xsl:choose>
                <xsl:when test="$type = 'sa'">
                  <xsl:if test="not(/cp/vsap/vsap[@type='auth']/siteprefs/disable-shell)">
                    <tr class="rowodd">
                      <td class="label"><xsl:value-of select="/cp/strings/user_profile_sa_privileges" /></td>
                      <td class="contentwidth">
                        <xsl:variable name="selectShellClass">
                          <xsl:choose>
                            <xsl:when test="$type='da'">indent</xsl:when>
                            <xsl:otherwise></xsl:otherwise>
                          </xsl:choose>
                        </xsl:variable>
                        <select class="$selectShellClass" name="selectShell" size="1">
                          <xsl:if test="$opt_shell='0' or $service_shell='0'">
                            <xsl:attribute name="disabled">disabled</xsl:attribute>
                          </xsl:if>
                          <xsl:for-each select="/cp/vsap/vsap[@type='user:shell:list']/shell">
                            <option value="{path}">
                              <xsl:if test="path = $selectShell">
                                <xsl:attribute name="selected">true</xsl:attribute>
                              </xsl:if><xsl:value-of select="path" /></option>
                          </xsl:for-each>
                        </select>
                        <br />
                      </td>
                    </tr>
                  </xsl:if>
                </xsl:when>
                <xsl:otherwise>
                  <tr class="rowodd">
                    <td class="label"><xsl:value-of select="/cp/strings/user_profile_da_privileges" /></td>
                    <td class="contentwidth">
                      <xsl:value-of select="/cp/strings/cp_instr_user_da_edit_profile_privileges" /><br />

                      <input type="checkbox" id="usermail" name="checkboxUserMail" onClick="setEUCheckbox(this);" value="true">
                        <xsl:if test="$service_mail='1'">
                          <xsl:attribute name="checked">checked</xsl:attribute>
                        </xsl:if>
                      </input>
                      <label for="usermail"><xsl:value-of select="/cp/strings/user_profile_privileges_mail" /></label><br />

                      <input type="checkbox" id="userftp" name="checkboxUserFtp" onClick="setEUCheckbox(this);" value="true">
                        <xsl:if test="$service_ftp='1'">
                          <xsl:attribute name="checked">checked</xsl:attribute>
                        </xsl:if>
                      </input>
                      <label for="userftp"><xsl:value-of select="/cp/strings/user_profile_privileges_ftp" /></label><br />

                      <input type="checkbox" id="userfm" name="checkboxUserFM" onClick="setEUCheckbox(this);" value="true">
                        <xsl:if test="$service_fm='1'">
                          <xsl:attribute name="checked">checked</xsl:attribute>
                        </xsl:if>
                      </input>
                      <label for="userfm"><xsl:value-of select="/cp/strings/user_profile_privileges_fm" /></label><br />

                      <xsl:if test="not(/cp/vsap/vsap[@type='auth']/siteprefs/disable-podcast)">
                        <input type="checkbox" id="userpodcast" name="checkboxUserPC" value="true">
                          <xsl:if test="$service_pc='1'">
                            <xsl:attribute name="checked">checked</xsl:attribute>
                          </xsl:if>
                        </input>
                        <label for="userpodcast"><xsl:value-of select="/cp/strings/user_profile_privileges_pc" /></label><br />
                      </xsl:if>

                      <xsl:if test="not(/cp/vsap/vsap[@type='auth']/siteprefs/disable-shell)">
                        <input type="checkbox" id="usershell" name="checkboxUserShell" onClick="setEUCheckbox(this);" value="true">
                          <xsl:if test="$service_shell='1' and $opt_shell='1'">
                            <xsl:attribute name="checked">checked</xsl:attribute>
                          </xsl:if>
                        </input>
                        <label for="usershell"><xsl:value-of select="/cp/strings/user_profile_privileges_shell" /></label>

                        <xsl:variable name="selectShellClass">
                          <xsl:choose>
                            <xsl:when test="$type='da'">indent</xsl:when>
                            <xsl:otherwise></xsl:otherwise>
                          </xsl:choose>
                        </xsl:variable>
                        <select class="$selectShellClass" name="selectShell" size="1">
                          <xsl:if test="$opt_shell='0' or $service_shell='0'">
                            <xsl:attribute name="disabled">disabled</xsl:attribute>
                          </xsl:if>
                          <xsl:for-each select="/cp/vsap/vsap[@type='user:shell:list']/shell">
                            <option value="{path}">
                              <xsl:if test="path = $selectShell">
                                <xsl:attribute name="selected">true</xsl:attribute>
                              </xsl:if><xsl:value-of select="path" /></option>
                          </xsl:for-each>
                        </select>
                      </xsl:if>
                      <br />
                    </td>
                  </tr>
                </xsl:otherwise>
              </xsl:choose>


            <xsl:if test="$type='da'">
              <tr class="rowodd">
                <td class="label"><xsl:value-of select="/cp/strings/user_profile_da_privileges_eu" /></td>
                <td><xsl:value-of select="/cp/strings/cp_instr_user_profile_da_privileges_eu" /><br />

                  <input type="checkbox" id="endusermail" name="checkboxEndUserMail" value="true">
                    <xsl:if test="$type='sa' or ($opt_mail='0' or $service_mail='0')">
                      <xsl:attribute name="disabled">disabled</xsl:attribute>
                    </xsl:if>
                    <xsl:if test="$type='sa' or $opt_eup_mail='1'">
                      <xsl:attribute name="checked">checked</xsl:attribute>
                    </xsl:if>
                  </input>
                  <label for="endusermail"><xsl:value-of select="/cp/strings/user_profile_privileges_mail" /></label><br />

                  <input type="checkbox" id="enduserftp" name="checkboxEndUserFtp" value="true">
                    <xsl:if test="$type='sa' or ($opt_ftp='0' or $service_ftp='0')">
                      <xsl:attribute name="disabled">disabled</xsl:attribute>
                    </xsl:if>
                    <xsl:if test="$type='sa' or $opt_eup_ftp='1'">
                      <xsl:attribute name="checked">checked</xsl:attribute>
                    </xsl:if>
                  </input>
                  <label for="enduserftp"><xsl:value-of select="/cp/strings/user_profile_privileges_ftp" /></label><br />

                  <input type="checkbox" id="enduserfm" name="checkboxEndUserFM" value="true">
                    <xsl:if test="$type='sa' or ($opt_fm='0' or $service_fm='0')">
                      <xsl:attribute name="disabled">disabled</xsl:attribute>
                    </xsl:if>
                    <xsl:if test="$type='sa' or $opt_eup_fm='1'">
                      <xsl:attribute name="checked">checked</xsl:attribute>
                    </xsl:if>
                  </input>
                  <label for="enduserfm"><xsl:value-of select="/cp/strings/user_profile_privileges_fm" /></label><br />

                  <xsl:if test="not(/cp/vsap/vsap[@type='auth']/siteprefs/disable-shell)">
                    <input type="checkbox" id="endusershell" name="checkboxEndUserShell" value="true">
                      <xsl:if test="$type='sa' or ($opt_shell='0' or $service_shell='0')">
                        <xsl:attribute name="disabled">disabled</xsl:attribute>
                      </xsl:if>
                      <xsl:if test="$type='sa' or $opt_eup_shell='1'">
                        <xsl:attribute name="checked">checked</xsl:attribute>
                      </xsl:if>
                    </input>
                    <label for="endusershell"><xsl:value-of select="/cp/strings/user_profile_privileges_shell" /></label><br />
                  </xsl:if>

                  <input type="checkbox" id="enduserzeroquota" name="checkboxEndUserZeroQuota" value="true">
                    <xsl:if test="$opt_eup_zeroquota='1'"><xsl:attribute name="checked">checked</xsl:attribute></xsl:if>
                  </input>
                  <label for="enduserzeroquota"><xsl:value-of select="/cp/strings/user_profile_privileges_zeroquota" /></label><br />

                </td>
              </tr>
            </xsl:if>

            <tr class="rowodd">
              <td class="label"><xsl:value-of select="/cp/strings/user_profile_eu_prefix" /></td>
              <td class="contentwidth">
                <xsl:copy-of select="/cp/strings/user_profile_eu_prefix_hlp_1" /><br />
                <input type="text" name="eu_prefix" size="42" maxlength="10" value="{$eu_prefix}" /><br />
                <xsl:copy-of select="/cp/strings/user_profile_eu_prefix_hlp_2" /><br />
              </td>
            </tr>

            <tr class="roweven">
              <td class="label"><xsl:value-of select="/cp/strings/user_profile_edit_da_domain" /></td>
              <td class="contentwidth">
                <xsl:for-each select="/cp/vsap/vsap[@type='user:properties']/user/domains/domain">
                  <xsl:if test="$type='sa' or admin = $loginid">
                    <a href="http://{name}" target="_blank"><xsl:value-of select="name" /></a>&#160;
                  </xsl:if>
                </xsl:for-each>
              </td>
            </tr>
          </xsl:when>

          <xsl:otherwise>

            <xsl:if test="not(/cp/vsap/vsap[@type='auth']/siteprefs/disable-mail-admin)">
              <xsl:if test="$user_type!='ma'">
                <tr class="roweven">
                  <td class="label"><xsl:value-of select="/cp/strings/cp_label_auth_rights" /></td>
                  <td class="contentwidth">
                    <input type="checkbox" id="userauth" name="checkboxUserMailAdmin" value="true">
                    <xsl:if test="$auth_mail_admin='1'"><xsl:attribute name="checked">checked</xsl:attribute></xsl:if>
                    <xsl:attribute name="onClick">if (this.checked) document.forms[0].checkboxUserMail.checked = true;</xsl:attribute>
                    </input>
                    <xsl:choose>
                      <xsl:when test="$type='ma'">
                        <label for="userauth"><xsl:value-of select="/cp/strings/user_profile_auth_rights_mail_admin_demote" /></label>
                      </xsl:when>
                      <xsl:otherwise>
                        <label for="userauth"><xsl:value-of select="/cp/strings/user_profile_auth_rights_mail_admin_promote" /></label>
                      </xsl:otherwise>
                    </xsl:choose>
                  </td>
                </tr>
              </xsl:if>
            </xsl:if>

            <tr class="rowodd">

              <xsl:choose>
                <xsl:when test="$type='ma'">
                  <td class="label"><xsl:value-of select="/cp/strings/user_profile_ma_privileges" /></td>
                </xsl:when>
                <xsl:otherwise>
                  <td class="label"><xsl:value-of select="/cp/strings/user_profile_eu_privileges" /></td>
                </xsl:otherwise>
              </xsl:choose>

              <td class="contentwidth">
                <xsl:choose>
                  <xsl:when test="$type='ma'">
                    <xsl:value-of select="/cp/strings/cp_instr_user_ma_edit_profile_privileges" /><br />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="/cp/strings/cp_instr_user_eu_edit_profile_privileges" /><br />
                  </xsl:otherwise>
                </xsl:choose>

                <xsl:choose>
                  <xsl:when test="$eu_capa_mail='1'">
                    <input type="checkbox" id="usermail" name="checkboxUserMail" value="true">
                      <xsl:if test="$service_mail='1'"><xsl:attribute name="checked">checked</xsl:attribute></xsl:if>
                      <xsl:attribute name="onClick">if ( document.forms[0].checkboxUserMailAdmin &amp;&amp; document.forms[0].checkboxUserMailAdmin.checked ) this.checked = true;</xsl:attribute>
                    </input>
                    <label for="usermail"><xsl:value-of select="/cp/strings/user_profile_privileges_mail" /></label><br />
                  </xsl:when>
                  <xsl:when test="$service_mail='1'">
                    <input type="hidden" name="checkboxUserMail" value="true" />
                    <input type="checkbox" id="usermail" name="checkboxUserMail" value="true" checked="checked" disabled="disabled" />
                    <label for="usermail"><xsl:value-of select="/cp/strings/user_profile_privileges_mail" /></label><br />
                  </xsl:when>
                </xsl:choose>

                <xsl:choose>
                  <xsl:when test="$eu_capa_ftp='1'">
                    <input type="checkbox" id="userftp" name="checkboxUserFtp" value="true">
                      <xsl:if test="$service_ftp='1'"><xsl:attribute name="checked">checked</xsl:attribute></xsl:if>
                    </input>
                    <label for="userftp"><xsl:value-of select="/cp/strings/user_profile_privileges_ftp" /></label><br />
                  </xsl:when>
                  <xsl:when test="$service_ftp='1'">
                    <input type="hidden" id="userftp" name="checkboxUserFtp" value="true" />
                    <input type="checkbox" name="checkboxUserFtp" value="true" checked="checked" disabled="disabled" />
                    <label for="userftp"><xsl:value-of select="/cp/strings/user_profile_privileges_ftp" /></label><br />
                  </xsl:when>
                </xsl:choose>

                <xsl:choose>
                  <xsl:when test="$eu_capa_fm='1'">
                    <input type="checkbox" id="userfm" name="checkboxUserFM" value="true">
                      <xsl:if test="$service_fm='1'"><xsl:attribute name="checked">checked</xsl:attribute></xsl:if>
                    </input>
                    <label for="userfm"><xsl:value-of select="/cp/strings/user_profile_privileges_fm" /></label><br />
                  </xsl:when>
                  <xsl:when test="$service_fm='1'">
                    <input type="hidden" name="checkboxUserFM" value="true" />
                    <input type="checkbox" id="userfm" name="checkboxUserFM" value="true" checked="checked" disabled="disabled" />
                    <label for="userfm"><xsl:value-of select="/cp/strings/user_profile_privileges_fm" /></label><br />
                  </xsl:when>
                </xsl:choose>

                <xsl:if test="not(/cp/vsap/vsap[@type='auth']/siteprefs/disable-shell)">
                  <xsl:choose>
                    <xsl:when test="$eu_capa_shell='1'">
                      <input type="checkbox" id="usershell" name="checkboxUserShell" value="true" onClick="setShellCheckbox(this);">
                        <xsl:if test="$service_shell='1'"><xsl:attribute name="checked">checked</xsl:attribute></xsl:if>
                      </input>
                      <label for="usershell"><xsl:value-of select="/cp/strings/user_profile_privileges_shell" /></label>

                      <select class="indent" name="selectShell" size="1">
                        <xsl:if test="$service_shell='0'"><xsl:attribute name="disabled">disabled</xsl:attribute></xsl:if>
                        <xsl:for-each select="/cp/vsap/vsap[@type='user:shell:list']/shell">
                          <option value="{path}">
                            <xsl:if test="path = $selectShell">
                              <xsl:attribute name="selected">true</xsl:attribute>
                            </xsl:if><xsl:value-of select="path" /></option>
                        </xsl:for-each>
                      </select><br />
                    </xsl:when>
                    <xsl:when test="$service_shell='1'">
                      <input type="hidden" name="checkboxUserShell" value="true" />
                      <input type="hidden" name="selectShell" value="{$selectShell}" />
                      <input type="checkbox" id="usershell" name="checkboxUserShell" value="true" checked="checked" disabled="disabled" /><label for="usershell"><xsl:value-of select="/cp/strings/user_profile_privileges_shell" /></label>
                      <select class="indent" name="selectShell" size="1" disabled="disabled">
                        <option value="{$selectShell}" selected="true"><xsl:value-of select="$selectShell" /></option>
                      </select>
                    </xsl:when>
                  </xsl:choose>
                </xsl:if>

              </td>
            </tr>
            <xsl:choose>
              <xsl:when test="$user_type='ma'">
                <xsl:variable name="mail_admin_domain">
                  <xsl:value-of select="/cp/vsap/vsap[@type='domain:list']/domain/name" />
                </xsl:variable>
                <input type="hidden" name="domain" value="{$mail_admin_domain}" />
              </xsl:when>
              <xsl:otherwise>
                <tr class="roweven">
                  <td class="label"><xsl:value-of select="/cp/strings/user_profile_domain" /></td>
                  <td class="contentwidth">
                    <select name="domain">
                      <xsl:for-each select="/cp/vsap/vsap[@type='domain:list']/domain">
                        <xsl:sort select="translate(name, 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')" />
                        <option value="{name}">
                          <xsl:if test="name = /cp/vsap/vsap[@type='user:properties']/user/domain">
                            <xsl:attribute name="selected">true</xsl:attribute>
                          </xsl:if><xsl:value-of select="name" />
                        </option>
                      </xsl:for-each>
                    </select>
                  </td>
                </tr>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>

        <tr class="rowodd">
          <td class="label"><xsl:value-of select="/cp/strings/user_profile_comments" /></td>
          <td class="contentwidth"><input type="text" name="txtComments" size="60" maxlength="100" value="{$comments}" /></td>
        </tr>

        <tr class="controlrow">
          <td colspan="2">
            <input class="floatright" type="button" name="btnCancel" value="{/cp/strings/user_profile_btn_cancel}"
              onClick="document.forms[0].cancel.value='yes';document.forms[0].submit();" />
            <input class="floatright" type="submit" name="btnSave" value="{/cp/strings/user_profile_btn_save}"
              onClick="return validate_profile
              (
                '{cp:js-escape(/cp/strings/user_profile_js_error_fullname_req)}',
                '{cp:js-escape(/cp/strings/user_profile_js_error_fullname_fmt_chars)}',
                '{cp:js-escape(/cp/strings/user_profile_js_error_loginid_req)}',
                '{cp:js-escape(/cp/strings/user_profile_js_error_loginid_fmt_chars)}',
                '{cp:js-escape(/cp/strings/user_profile_js_error_loginid_fmt_start)}',
                '{cp:js-escape(/cp/strings/user_profile_js_error_password_req)}',
                '{cp:js-escape(/cp/strings/user_profile_js_error_password_fmt)}',
                '{cp:js-escape(/cp/strings/user_profile_js_error_password_login_match)}',
                '{cp:js-escape(/cp/strings/user_profile_js_error_password_match)}',
                '{cp:js-escape(/cp/strings/user_profile_js_error_quota_req)}',
                '{cp:js-escape(/cp/strings/user_profile_js_error_quota_fmt)}',
                '{cp:js-escape(/cp/strings/user_profile_js_warning_quota_zero)}',
                '{cp:js-escape(/cp/strings/user_profile_js_error_quota_exceeded)}',
                '{cp:js-escape(/cp/strings/user_profile_js_error_daps)}',
                '{cp:js-escape(/cp/strings/user_profile_js_error_eups)}',
                '{cp:js-escape(/cp/strings/user_profile_js_error_domain_req)}',
                '{cp:js-escape(/cp/strings/user_profile_js_error_domain_fmt)}',
                '{cp:js-escape(/cp/strings/user_profile_js_error_euprefix_fmt_chars)}',
                '{cp:js-escape(/cp/strings/user_profile_js_error_euprefix_fmt_start)}',
                '{cp:js-escape(/cp/strings/user_mail_err_prefix_invalid)}'
              );"
            />
          </td>
        </tr>
      </table>

</xsl:template>

</xsl:stylesheet>
