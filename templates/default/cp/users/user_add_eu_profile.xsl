<?xml version="1.0" encoding="utf-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../cp_global.xsl" />

<xsl:variable name="message">
  <xsl:choose>
    <xsl:when test="/cp/msgs/msg[@name='user_add_successful']">
      '<xsl:copy-of select="/cp/form/txtLoginID_Prefix" /><xsl:copy-of select="/cp/form/txtLoginID" />'<xsl:copy-of select="/cp/strings/cp_msg_user_add" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='users_maxed_out']">
      <xsl:copy-of select="/cp/strings/user_profile_err_user_max" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='emails_maxed_out']">
      <xsl:copy-of select="/cp/strings/user_profile_err_user_email_max" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='user_permission']">
      <xsl:copy-of select="/cp/strings/user_profile_err_user_permission" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='user_eu_quota_exceeded']">
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
    <xsl:when test="/cp/msgs/msg[@name='user_home_exists']">
      <xsl:copy-of select="/cp/strings/user_profile_err_home_exists" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='user_login_bad_chars']">
      <xsl:copy-of select="/cp/strings/user_profile_err_login_bad_chars" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='user_login_first_char_invalid']">
      <xsl:copy-of select="/cp/strings/user_profile_err_login_first_char_invalid" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='user_domain_add_exists']">
      <xsl:copy-of select="/cp/strings/user_domain_err_add_exists" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='user_internal_error']">
      <xsl:copy-of select="/cp/strings/user_internal_error" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='email_bad_chars']">
      <xsl:copy-of select="/cp/strings/user_profile_err_email_bad_chars" />
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
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
<!--
  <xsl:if test="/cp/msgs/msg[@name='user_add_failure']">
    <xsl:value-of select="concat('Error - code:',/cp/vsap/vsap[@type='error']/code,' message:
',/cp/vsap/vsap[@type='error']/message)" />
  </xsl:if>
-->
</xsl:variable>

<xsl:variable name="error_set">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='error']">1</xsl:when>
    <xsl:when test="not(/cp/msgs/msg[@name='user_add_successful'])">1</xsl:when>
    <xsl:otherwise>0</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="feedback">
  <xsl:if test="$message != ''">
    <xsl:call-template name="feedback_table">
      <xsl:with-param name="image">
        <xsl:choose>
          <xsl:when test="$error_set = '1'">error</xsl:when>
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
  <xsl:choose>
    <xsl:when test="string(/cp/form/type)">
      <xsl:value-of select="/cp/form/type" />
    </xsl:when>
    <xsl:when test="string(/cp/form/add_da)">da</xsl:when>
    <xsl:when test="string(/cp/form/add_eu)">eu</xsl:when>
    <xsl:otherwise>eu</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="admin">
  <xsl:value-of select="/cp/vsap/vsap[@type='auth']/username" />
</xsl:variable>

<xsl:variable name="sel_navandcontent">
  <xsl:choose>
    <xsl:when test="$type='da'">
      <xsl:value-of select="/cp/strings/nv_add_da" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="/cp/strings/nv_add_eu" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="hlp_long">
  <xsl:choose>
    <xsl:when test="$type='da'">
      <xsl:copy-of select="/cp/strings/user_add_da_profile_hlp_long" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:copy-of select="/cp/strings/user_add_eu_profile_hlp_long" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="bc_name">
  <xsl:choose>
    <xsl:when test="$type='da'">
      <xsl:value-of select="/cp/strings/bc_user_add_da_profile" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="/cp/strings/bc_user_add_eu_profile" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="use_previous_value">
  <xsl:choose>
    <xsl:when test="string(/cp/form/previous) or string(/cp/form/btnPrevious) or string(/cp/form/btnPreviewPrevious) or $error_set='1'">1</xsl:when>
    <xsl:otherwise>0</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<!-- create a global to track the max space quota for the admin (bug 4701) -->
<xsl:variable name="max_space">
  <xsl:choose>
    <xsl:when test="$user_type != 'eu'">
      <xsl:variable name="max_limit">
        <xsl:value-of select="/cp/vsap/vsap[@type='user:properties']/user[login_id=$admin]/quota/limit" />
      </xsl:variable>
      <xsl:variable name="allocated">
        <xsl:value-of select="/cp/vsap/vsap[@type='user:properties']/user[login_id=$admin]/quota/usage" />
      </xsl:variable>
      <xsl:value-of select="$max_limit - $allocated" />
    </xsl:when>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="max_space_unit">
  <xsl:if test="$user_type != 'eu'">
    <xsl:choose>
      <xsl:when test="string(/cp/vsap/vsap[@type='user:properties']/user[login_id=$admin]/quota/units)">
        <xsl:value-of select="/cp/vsap/vsap[@type='user:properties']/user[login_id=$admin]/quota/units" />
      </xsl:when>
      <xsl:otherwise>MB</xsl:otherwise>
    </xsl:choose>
  </xsl:if>
</xsl:variable>
 
<xsl:variable name="fullname">
  <xsl:choose>
    <xsl:when test="$use_previous_value='1'">
      <xsl:value-of select="/cp/form/txtFullName" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="comments">
  <xsl:choose>
    <xsl:when test="$use_previous_value='1'">
      <xsl:value-of select="/cp/form/txtComments" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="eu_prefix">
  <xsl:choose>
    <xsl:when test="$type='eu'">
      <xsl:value-of select="/cp/vsap/vsap[@type='user:properties']/user[login_id=$admin]/eu_prefix" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="/cp/form/eu_prefix" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="login_prefix">
  <xsl:if test="$type='eu'">
    <xsl:variable name="admin">
      <xsl:value-of select="/cp/vsap/vsap[@type='auth']/username" />
    </xsl:variable>
    <xsl:value-of select="/cp/vsap/vsap[@type='user:properties']/user[login_id=$admin]/eu_prefix" />
  </xsl:if>
</xsl:variable>

<xsl:variable name="loginid">
  <xsl:choose>
    <xsl:when test="$use_previous_value='1'">
      <xsl:value-of select="/cp/form/txtLoginID" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="password">
  <xsl:choose>
    <xsl:when test="$use_previous_value='1'">
      <xsl:value-of select="/cp/form/txtPassword" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="confirm_password">
  <xsl:choose>
    <xsl:when test="$use_previous_value='1'">
      <xsl:value-of select="/cp/form/txtConfirmPassword" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="quota">
  <xsl:choose>
    <xsl:when test="$use_previous_value='1' and /cp/form/txtQuota">
      <xsl:value-of select="/cp/form/txtQuota" />
    </xsl:when>
    <!-- changing this is not a good idea in spite of what Scott F. thinks -->
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="opt_mail">
  <xsl:choose>
    <xsl:when test="$use_previous_value='1'">
      <xsl:choose>
        <xsl:when test="string(/cp/form/checkboxUserMail)">1</xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:otherwise>1</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="opt_ftp">
  <xsl:choose>
    <xsl:when test="$use_previous_value='1'">
      <xsl:choose>
        <xsl:when test="string(/cp/form/checkboxUserFtp)">1</xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:otherwise>1</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="opt_fm">
  <xsl:choose>
    <xsl:when test="$use_previous_value='1'">
      <xsl:choose>
        <xsl:when test="string(/cp/form/checkboxUserFM)">1</xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:otherwise>1</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="opt_pc">
  <xsl:choose>
    <xsl:when test="$use_previous_value='1'">
      <xsl:choose>
        <xsl:when test="string(/cp/form/checkboxUserPC)">1</xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:otherwise>1</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="opt_shell">
  <xsl:choose>
    <xsl:when test="$use_previous_value='1'">
      <xsl:choose>
        <xsl:when test="string(/cp/form/checkboxUserShell)">1</xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:otherwise>
      <xsl:choose>
        <xsl:when test="$type!='sa'">0</xsl:when>
        <xsl:otherwise>"1</xsl:otherwise>
      </xsl:choose>
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="selectShell">
  <xsl:choose>
    <xsl:when test="$use_previous_value='1'">
      <xsl:choose>
        <xsl:when test="string(/cp/form/selectShell)">
          <xsl:value-of select="/cp/form/selectShell" />
        </xsl:when>
        <xsl:otherwise>/bin/tcsh</xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:otherwise>/bin/tcsh</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="eu_mail_ok">
  <xsl:choose>
    <xsl:when test="$user_type='sa'">1</xsl:when>
    <xsl:otherwise>
      <xsl:if test="/cp/vsap/vsap[@type='user:properties']/user[login_id=$admin]/eu_capability/mail">1</xsl:if>
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="eu_ftp_ok">
  <xsl:choose>
    <xsl:when test="$user_type='sa'">1</xsl:when>
    <xsl:otherwise>
      <xsl:if test="/cp/vsap/vsap[@type='user:properties']/user[login_id=$admin]/eu_capability/ftp">1</xsl:if>
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="eu_fm_ok">
  <xsl:choose>
    <xsl:when test="$user_type='sa'">1</xsl:when>
    <xsl:otherwise>
      <xsl:if test="/cp/vsap/vsap[@type='user:properties']/user[login_id=$admin]/eu_capability/fileman">1</xsl:if>
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="eu_shell_ok">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='auth']/siteprefs/disable-shell">0</xsl:when>
    <xsl:when test="$user_type='sa'">1</xsl:when>
    <xsl:otherwise>
      <xsl:if test="/cp/vsap/vsap[@type='user:properties']/user[login_id=$admin]/eu_capability/shell">1</xsl:if>
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="eu_zeroquota_ok">
  <xsl:choose>
    <xsl:when test="$user_type='sa'">1</xsl:when>
    <xsl:otherwise>
      <xsl:if test="/cp/vsap/vsap[@type='user:properties']/user[login_id=$admin]/eu_capability/zeroquota">1</xsl:if>
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="opt_eup_mail">
  <xsl:choose>
    <xsl:when test="$use_previous_value='1'">
      <xsl:choose>
        <xsl:when test="string(/cp/form/checkboxEndUserMail)">1</xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:otherwise>1</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="opt_eup_ftp">
  <xsl:choose>
    <xsl:when test="$use_previous_value='1'">
      <xsl:choose>
        <xsl:when test="string(/cp/form/checkboxEndUserFtp)">1</xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:otherwise>1</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="opt_eup_fm">
  <xsl:choose>
    <xsl:when test="$use_previous_value='1'">
      <xsl:choose>
        <xsl:when test="string(/cp/form/checkboxEndUserFM)">1</xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:otherwise>1</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="opt_eup_shell">
  <xsl:choose>
    <xsl:when test="$use_previous_value='1'">
      <xsl:choose>
        <xsl:when test="string(/cp/form/checkboxEndUserShell)">1</xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:otherwise>
      <xsl:choose>
        <xsl:when test="$type='da'">0</xsl:when>
        <xsl:otherwise>"1</xsl:otherwise>
      </xsl:choose>
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="opt_eup_zeroquota">
  <xsl:choose>
    <xsl:when test="$use_previous_value='1'">
      <xsl:choose>
        <xsl:when test="string(/cp/form/checkboxEndUserZeroQuota)">1</xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:otherwise>1</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="domain">
  <xsl:choose>
    <xsl:when test="$type != 'eu'">
      <xsl:choose>
        <xsl:when test="$use_previous_value='1'">
          <xsl:value-of select="/cp/form/txtDomain" />
        </xsl:when>
        <xsl:otherwise></xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:otherwise>
      <xsl:choose>
        <xsl:when test="$use_previous_value='1'">
          <xsl:value-of select="/cp/form/selectName" />
        </xsl:when>
        <xsl:otherwise></xsl:otherwise>
      </xsl:choose>
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="old_domain">
  <xsl:choose>
    <xsl:when test="$use_previous_value!='1'"></xsl:when>
    <xsl:when test="string(/cp/form/txtDomain)">
      <xsl:value-of select="/cp/form/txtDomain" />
    </xsl:when>
    <xsl:when test="string(/cp/form/selectName)">
      <xsl:value-of select="/cp/form/selectName" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="old_login">
  <xsl:choose>
    <xsl:when test="$use_previous_value!='1'"></xsl:when>
    <xsl:when test="string(/cp/form/txtLoginID)">
      <xsl:value-of select="/cp/form/txtLoginID" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="end_users_limit">
  <xsl:choose>
    <xsl:when test="/cp/form/end_users_limit">
      <xsl:value-of select="/cp/form/end_users_limit" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="/cp/strings/user_add_domain_eu_limit" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="email_limit">
  <xsl:choose>
    <xsl:when test="/cp/form/email_addr_limit">
      <xsl:value-of select="/cp/form/email_addr_limit" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="/cp/strings/user_add_domain_email_limit" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<!-- this will be the "selected" ip address value in the form -->
<xsl:variable name="ip_address">
  <xsl:choose>
    <xsl:when test="$use_previous_value='1' and string(/cp/form/ip_address)">
        <xsl:value-of select="/cp/form/ip_address" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<!-- this appears to just be checking whether it's been selected before, say on a click forward, then click back thru the steps...? -->
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

<!-- domain crap -->

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
<!--
<xsl:variable name="end_users_limit">
  <xsl:choose>
    <xsl:when test="/cp/form/end_users_limit">
      <xsl:value-of select="/cp/form/end_users_limit" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>
-->
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
<!--
<xsl:variable name="eu_prefix">
  <xsl:choose>
    <xsl:when test="$type='eu'">
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
-->
<xsl:template match="/">
<xsl:call-template name="bodywrapper">
<xsl:with-param name="title"><xsl:copy-of select="/cp/strings/cp_title" /> : <xsl:copy-of select="$bc_name" /></xsl:with-param>
<xsl:with-param name="formaction">user_add_eu_profile.xsl</xsl:with-param>
<xsl:with-param name="feedback" select="$feedback" />
<xsl:with-param name="help_short" select="/cp/strings/user_add_hlp_short" />
<xsl:with-param name="selected_navandcontent" select="$sel_navandcontent" />
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

      <script src="{concat($base_url, '/cp/cp.js')}" language="JavaScript"></script>

      <input type="hidden" name="cancel" value="" />
      <input type="hidden" name="mail_next" value="" />
      <input type="hidden" name="type" value="{$type}" />
      <input type="hidden" name="source" value="add" />
      <input type="hidden" name="old_domain" value="{$old_domain}" />
      <input type="hidden" name="old_login" value="{$old_login}" />
      <input type="hidden" name="eu_mail" value="{$eu_mail_ok}" />
      <input type="hidden" name="eu_ftp" value="{$eu_ftp_ok}" />
      <input type="hidden" name="eu_shell" value="{$eu_shell_ok}" />
      <input type="hidden" name="eu_capa_mail" value="{$eu_mail_ok}" />
      <input type="hidden" name="eu_capa_ftp" value="{$eu_ftp_ok}" />
      <input type="hidden" name="eu_capa_fm" value="{$eu_fm_ok}" />
      <input type="hidden" name="eu_capa_shell" value="{$eu_shell_ok}" />
      <input type="hidden" name="eu_capa_zeroquota" value="{$eu_zeroquota_ok}" />
<!--  these hiddens are for verifying the quota in javascript -->
      <xsl:if test="/cp/vsap/vsap[@type='user:properties']/user[login_id=$admin]/quota/limit != 0">
        <input type="hidden" name="max_space" value="{$max_space}" />
        <input type="hidden" name="max_space_unit" value="{$max_space_unit}" />
      </xsl:if>

      <!-- preserve previous values from other pages of form if at this page
           from the 'previous' button or an error occurred when trying to save
      -->
      <xsl:choose>
        <xsl:when test="$use_previous_value='1'">
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
           <input type="hidden" name="cgi" value="{/cp/form/cgi}" />
           <input type="hidden" name="ssl" value="{/cp/form/ssl}" />
           <input type="hidden" name="end_users" value="{/cp/form/end_users}" />
           <input type="hidden" name="end_users_limit" value="{$end_users_limit}" />
           <input type="hidden" name="email_addr" value="{/cp/form/email_addr}" />
           <input type="hidden" name="email_addr_limit" value="{$email_limit}" />
           <input type="hidden" name="website_logs" value="{/cp/form/website_logs}" />
           <input type="hidden" name="log_rotate_select" value="{/cp/form/log_rotate_select}" />
           <input type="hidden" name="log_rotate" value="{/cp/form/log_rotate}" />
           <input type="hidden" name="log_save" value="{/cp/form/log_save}" />
           <input type="hidden" name="domain_contact" value="{/cp/form/domain_contact}" />
           <input type="hidden" name="mail_catchall" value="{/cp/form/mail_catchall}" />
           <input type="hidden" name="mail_catchall_custom" value="{/cp/form/mail_catchall_custom}" />
         </xsl:if>
        </xsl:when>
        <xsl:otherwise>
          <!--  need to initialize form fields for add_user_domain page here -->
          <xsl:if test="$type != 'eu'">
            <input type="hidden" name="end_users_limit" value="{$end_users_limit}" />
            <input type="hidden" name="email_addr_limit" value="{$email_limit}" />
            <input type="hidden" name="www_alias" value="1" />
            <input type="hidden" name="cgi" value="1" />
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>

      <xsl:if test="$type = 'eu'">
        <input type="hidden" name="txtLoginID_Prefix" value="{$login_prefix}" />
      </xsl:if>

      <table class="formview" border="0" cellspacing="0" cellpadding="0">
	<tr class="title">
              <td colspan="2"><xsl:copy-of select="/cp/strings/cp_title_user_add_eu_profile" /></td>
	</tr>
	<tr class="instructionrow">
	      <td colspan="2"><xsl:copy-of select="/cp/strings/cp_instr_user_add_eu_profile" /></td>
	</tr>

	<tr class="rowodd">
	  <td class="label"><xsl:value-of select="/cp/strings/user_profile_full_name" /></td>
	  <td class="contentwidth"><input type="text" name="txtFullName" size="42" maxlength="100" value="{$fullname}" />&#160;<span class="parenthetichelp"><xsl:value-of select="/cp/strings/user_profile_full_name_help" /></span></td>
	</tr>
        <xsl:choose>
          <xsl:when test="$type='eu' and $eu_prefix != ''">
            <xsl:variable name="login_length">
              <xsl:value-of select="16 - string-length($eu_prefix)"/>
            </xsl:variable>
            <xsl:variable name="eu_prefix_help">
              <xsl:call-template name="transliterate">
                <xsl:with-param name="string"><xsl:value-of select="/cp/strings/user_profile_login_id_prefix_help"/></xsl:with-param>
                <xsl:with-param name="search">__PREFIX__</xsl:with-param>
                <xsl:with-param name="replace" select="$eu_prefix"/>
              </xsl:call-template>
            </xsl:variable>
            <xsl:variable name="login_help">
              <xsl:call-template name="transliterate">
                <xsl:with-param name="string"><xsl:value-of select="/cp/strings/user_profile_login_id_help"/></xsl:with-param>
                <xsl:with-param name="search">16</xsl:with-param>
                <xsl:with-param name="replace" select="$login_length"/>
              </xsl:call-template>
            </xsl:variable>
            <tr class="roweven">
              <td class="label"><xsl:value-of select="/cp/strings/user_profile_login_id" /></td>
              <td class="contentwidth"><xsl:value-of select="$eu_prefix_help"/><br/><input type="text" name="txtLoginID" size="42" maxlength="{$login_length}" value="{$loginid}" />&#160;<span class="parenthetichelp"><xsl:value-of select="$login_help" /></span></td>
            </tr>
          </xsl:when>
          <xsl:otherwise>
            <tr class="roweven">
              <td class="label"><xsl:value-of select="/cp/strings/user_profile_login_id" /></td>
              <td class="contentwidth"><input type="text" autocomplete="off" name="txtLoginID" size="42" maxlength="16" value="{$loginid}" />&#160;<span class="parenthetichelp"><xsl:value-of select="/cp/strings/user_profile_login_id_help" /></span></td>
            </tr>
          </xsl:otherwise>
        </xsl:choose>
	<tr class="rowodd">
	  <td class="label"><xsl:value-of select="/cp/strings/user_profile_password" /></td>
	  <td class="contentwidth"><input type="password" autocomplete="off" name="txtPassword" size="42" maxlength="32" value="{$password}" />&#160;<span class="parenthetichelp"><xsl:value-of select="/cp/strings/user_profile_password_help" /></span></td>
	</tr>
	<tr class="roweven">
	  <td class="label"><xsl:value-of select="/cp/strings/user_profile_password_confirm" /></td>
	  <td class="contentwidth"><input type="password" autocomplete="off" name="txtConfirmPassword" size="42" maxlength="32" value="{$confirm_password}" /></td>
	</tr>
	<tr class="rowodd">
	  <td class="label"><xsl:value-of select="/cp/strings/user_profile_user_disk_space" /></td>
	  <td class="contentwidth">&#160;<input type="text" name="txtQuota" size="5" value="{$quota}" />&#160;<xsl:value-of select="/cp/strings/user_profile_user_disk_space_mb" /></td>
	</tr>

            <tr class="roweven">
              <td class="label"><xsl:value-of select="/cp/strings/user_profile_eu_privileges" /></td>
              <td class="contentwidth"><xsl:value-of select="/cp/strings/cp_instr_user_eu_profile_privileges" /><br />

                <xsl:if test="$eu_mail_ok='1'">
<!--
                  <input onchange="fix({$opt_webmail}, {$opt_spamassassin}, {$opt_clamav});" type="checkbox" id="usermail" name="checkboxUserMail" value="true">
-->
                  <input type="checkbox" id="usermail" name="checkboxUserMail" value="true">
                    <xsl:if test="$opt_mail='1'"><xsl:attribute name="checked">checked</xsl:attribute></xsl:if>
                  </input><label for="usermail"><xsl:value-of select="/cp/strings/user_profile_privileges_mail" /></label><br />
                </xsl:if>

                <xsl:if test="$eu_ftp_ok='1'">
                  <input type="checkbox" id="userftp" name="checkboxUserFtp" value="true">
                    <xsl:if test="$opt_ftp='1'"><xsl:attribute name="checked">checked</xsl:attribute></xsl:if>
                  </input><label for="userftp"><xsl:value-of select="/cp/strings/user_profile_privileges_ftp" /></label><br />
                </xsl:if>

                <xsl:if test="$eu_fm_ok='1'">
                  <input type="checkbox" id="userfm" name="checkboxUserFM" value="true">
                    <xsl:if test="$opt_fm='1'"><xsl:attribute name="checked">checked</xsl:attribute></xsl:if>
                  </input><label for="userfm"><xsl:value-of select="/cp/strings/user_profile_privileges_fm" /></label><br />
                </xsl:if>

                <xsl:if test="$eu_shell_ok='1'">
                  <input type="checkbox" id="usershell" name="checkboxUserShell" value="true" onClick="setShellCheckbox(this);">
                    <xsl:if test="$opt_shell='1'"><xsl:attribute name="checked">checked</xsl:attribute></xsl:if>
                  </input>
                  <label for="usershell"><xsl:value-of select="/cp/strings/user_profile_privileges_shell" /></label>

                  <select class="indent" name="selectShell" size="1"> 
                    <xsl:if test="$opt_shell='0'"><xsl:attribute name="disabled">disabled</xsl:attribute></xsl:if>
                    <xsl:for-each select="/cp/vsap/vsap[@type='user:shell:list']/shell">
                      <option value="{path}">
                        <xsl:if test="path = $selectShell">
                          <xsl:attribute name="selected">true</xsl:attribute>
                        </xsl:if><xsl:value-of select="path" /></option>
                    </xsl:for-each>
                  </select><br />
                </xsl:if>

              </td>
            </tr>

            <tr class="rowodd">
              <td class="label"><xsl:value-of select="/cp/strings/user_profile_domain" /></td>
              <td class="contentwidth"><xsl:value-of select="/cp/strings/cp_instr_user_add_eu_profile_domain" /><br />
                <select name="selectName" size="1">
                  <xsl:for-each select="/cp/vsap/vsap[@type='user:properties']/user[login_id=$admin]/domains/domain">
                    <xsl:sort select="translate(name, 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')" />

                    <xsl:variable name="domain_name">
                      <xsl:value-of select="name" />
                    </xsl:variable>
                    <xsl:variable name="user_count">
                      <xsl:value-of select="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain_name]/users/usage" />
                    </xsl:variable>
                    <xsl:variable name="user_limit">
                      <xsl:value-of select="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain_name]/users/limit" />
                    </xsl:variable>
                    <xsl:variable name="user_add_ok">
                      <xsl:choose>
                        <xsl:when test="$user_limit='unlimited'">1</xsl:when>
                        <xsl:otherwise><xsl:value-of select="$user_limit - $user_count" /></xsl:otherwise>
                      </xsl:choose>
                    </xsl:variable>

                    <xsl:variable name="email_count">
                      <xsl:value-of select="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain_name]/mail_aliases/usage" />
                    </xsl:variable>
                    <xsl:variable name="email_limit">
                      <xsl:value-of select="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain_name]/mail_aliases/limit" />
                    </xsl:variable>
                    <xsl:variable name="email_add_ok">
                      <xsl:choose>
                        <xsl:when test="$email_limit='unlimited'">1</xsl:when>
                        <xsl:otherwise><xsl:value-of select="$email_limit - $email_count" /></xsl:otherwise>
                      </xsl:choose>
                    </xsl:variable>

                    <xsl:choose>
                      <xsl:when test="name = $domain">
                        <option value="{name}" selected="true"><xsl:value-of select="name" /></option>
                      </xsl:when>
                      <xsl:otherwise>
                        <option value="{name}"><xsl:value-of select="name" /></option>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:for-each>
                </select>
              </td>
            </tr>

	<tr class="rowodd">
	  <td class="label"><xsl:value-of select="/cp/strings/user_profile_comments" /></td>
	  <td class="contentwidth"><input type="text" name="txtComments" size="60" maxlength="100" value="{$comments}" /></td>
	</tr>

<!-- mail crap -->

                <tr class="roweven">
                  <td class="label"><xsl:value-of select="/cp/strings/user_add_mail_email_addr" /></td>
                  <td class="contentwidth">
                  <xsl:choose>
                    <xsl:when test="$type='da'">
<!--
                      <input type="text" name="txtAlias" value="{$alias}" size="16"><xsl:attribute name="disabled">disabled</xsl:attribute></input>&#160;@ <xsl:value-of select="/cp/form/txtDomain" /> <br />
-->
                      <input type="text" name="txtAlias" value="{$alias}" size="16" />&#160;@ <xsl:value-of select="/cp/form/txtDomain" /> <br />
                    </xsl:when>
                    <xsl:otherwise>
                      <input type="text" name="txtAlias" value="{/cp/form/txtLoginID}" size="16"/>&#160;@ <xsl:value-of select="/cp/form/selectName" /> <br />
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
                      <xsl:otherwise>
                        <xsl:value-of select="/cp/strings/cp_instr_user_add_eu_mail_apps" /><br />
                      </xsl:otherwise>
                     </xsl:choose>
                     <xsl:choose>
                       <xsl:when test="$webmail_package='1'">
                         <xsl:if test="/cp/vsap/vsap[@type='auth']/server_admin or /cp/vsap/vsap[@type='auth']/capabilities/webmail">
                          <xsl:choose>
                            <xsl:when test="$opt_webmail='0'">
<!--
                              <input type="checkbox" id="webmail_app" name="checkboxWebmail" value="checkboxValue"><xsl:attribute name="disabled">disabled</xsl:attribute></input><label for="webmail_app"><xsl:value-of select="/cp/strings/user_add_mail_apps_webmail" /></label><br />
-->
                              <input type="checkbox" id="webmail_app" name="checkboxWebmail" value="checkboxValue"/><label for="webmail_app"><xsl:value-of select="/cp/strings/user_add_mail_apps_webmail" /></label><br />
                            </xsl:when>
                            <xsl:otherwise>
<!--
                              <input type="checkbox" id="webmail_app" name="checkboxWebmail" value="checkboxValue"><xsl:attribute name="disabled">disabled</xsl:attribute></input><label for="webmail_app"><xsl:value-of select="/cp/strings/user_add_mail_apps_webmail" /></label><br />
-->
                              <input type="checkbox" id="webmail_app" name="checkboxWebmail" value="checkboxValue"/><label for="webmail_app"><xsl:value-of select="/cp/strings/user_add_mail_apps_webmail" /></label><br />
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
<!--
                              <input type="checkbox" id="spamassassin_app" name="checkboxSpamassassin" value="checkboxValue"><xsl:attribute name="disabled">disabled</xsl:attribute></input><label for="spamassassin_app"><xsl:value-of select="/cp/strings/user_add_mail_apps_spamassassin" /></label><br />
-->
                              <input type="checkbox" id="spamassassin_app" name="checkboxSpamassassin" value="checkboxValue"/><label for="spamassassin_app"><xsl:value-of select="/cp/strings/user_add_mail_apps_spamassassin" /></label><br />
                            </xsl:when>
                            <xsl:otherwise>
<!--
                              <input type="checkbox" id="spamassassin_app" name="checkboxSpamassassin" value="checkboxValue"><xsl:attribute name="disabled">disabled</xsl:attribute></input><label for="spamassassin_app"><xsl:value-of select="/cp/strings/user_add_mail_apps_spamassassin" /></label><br />
-->
                              <input type="checkbox" id="spamassassin_app" name="checkboxSpamassassin" value="checkboxValue"/><label for="spamassassin_app"><xsl:value-of select="/cp/strings/user_add_mail_apps_spamassassin" /></label><br />
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
                            <xsl:when test="$opt_clamav='0'">
<!--
                              <input type="checkbox" id="clamav_app" name="checkboxClamav" value="checkboxValue"><xsl:attribute name="disabled">disabled</xsl:attribute></input><label for="clamav_app"><xsl:value-of select="/cp/strings/user_add_mail_apps_clamav" /></label><br />
-->
                              <input type="checkbox" id="clamav_app" name="checkboxClamav" value="checkboxValue"/><label for="clamav_app"><xsl:value-of select="/cp/strings/user_add_mail_apps_clamav" /></label><br />
                            </xsl:when>
                            <xsl:otherwise>
<!--
                              <input type="checkbox" id="clamav_app" name="checkboxClamav" value="checkboxValue"><xsl:attribute name="disabled">disabled</xsl:attribute></input><label for="clamav_app"><xsl:value-of select="/cp/strings/user_add_mail_apps_clamav" /></label><br />
-->
                              <input type="checkbox" id="clamav_app" name="checkboxClamav" value="checkboxValue"/><label for="clamav_app"><xsl:value-of select="/cp/strings/user_add_mail_apps_clamav" /></label><br />
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

<!-- end mail crap -->

                <tr class="controlrow">
                  <td colspan="2"><input class="floatright" type="submit" name="btnCancel" value="{/cp/strings/user_add_preview_btn_cancel}" /><input class="floatright" type="submit" name="btnSaveAnother" value="{/cp/strings/user_add_preview_btn_saveanother}" /><input class="floatright" type="submit" name="btnSave" value="{/cp/strings/user_add_preview_btn_save}" /></td>
                </tr>
<!--
	<tr class="controlrow">
	  <td colspan="2">
            <input class="floatright" type="button" name="btnCancel" value="{/cp/strings/user_profile_btn_cancel}" 
              onClick="document.forms[0].cancel.value='yes';document.forms[0].submit();" />
            <input class="floatright" type="submit" name="btnNext" value="{/cp/strings/user_profile_btn_next}" 
              onClick="return validate_profile
              (
                '{cp:js-escape(/cp/strings/user_profile_js_error_fullname_req)}',
                '{cp:js-escape(/cp/strings/user_profile_js_error_fullname_no_colon)}',
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
                '{cp:js-escape(/cp/strings/user_profile_js_error_euprefix_fmt_start)}'
              );" 
            />
          </td>
	</tr>
-->
      </table>

</xsl:template>
            
</xsl:stylesheet>
