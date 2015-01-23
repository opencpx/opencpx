<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
  xmlns:exslt="http://exslt.org/common"
  exclude-result-prefixes="exslt">

<xsl:import href="../cp_global.xsl" />

<xsl:variable name="message">
  <xsl:choose>
    <xsl:when test="/cp/msgs/msg[@name='profile_password_change_success']">
      <xsl:copy-of select="/cp/strings/profile_password_change_success" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='profile_password_new_missing']">
      <xsl:copy-of select="/cp/strings/profile_password_new_missing" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='profile_password_new_not_matching']">
      <xsl:copy-of select="/cp/strings/profile_password_new_not_matching" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='profile_password_change_error']">
      <xsl:copy-of select="/cp/strings/profile_password_change_error" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='profile_password_old_missing']">
      <xsl:copy-of select="/cp/strings/profile_password_old_missing" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='profile_password_old_not_matching']">
      <xsl:copy-of select="/cp/strings/profile_password_old_not_matching" />
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

<xsl:variable name="username">
  <xsl:value-of select="/cp/vsap/vsap[@type='auth']/username" />
</xsl:variable>

<xsl:template match="/">
<xsl:call-template name="bodywrapper">

  <xsl:with-param name="title">
    <xsl:copy-of select="/cp/strings/cp_title" /> : <xsl:copy-of select="/cp/strings/bc_profile" /> : <xsl:copy-of select="/cp/strings/bc_profile_password" />
  </xsl:with-param>

  <xsl:with-param name="formaction">password.xsl</xsl:with-param>
  <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_change_password" />
  <xsl:with-param name="help_short" select="/cp/strings/profile_password_help_short" />
  <xsl:with-param name="help_long" select="/cp/strings/profile_password_help_long" />
  <xsl:with-param name="feedback" select="$feedback" />
  <xsl:with-param name="breadcrumb">
    <breadcrumb>
      <section>
        <name><xsl:copy-of select="/cp/strings/bc_profile" /></name>
        <url><xsl:value-of select="$base_url" />/cp/profile/</url>
        <image>Profile</image>
      </section>
      <section>
        <name><xsl:copy-of select="/cp/strings/bc_profile_password" /></name>
        <url>#</url>
        <image>Profile</image>
      </section>
    </breadcrumb>
  </xsl:with-param>

</xsl:call-template>
</xsl:template>

<xsl:template name="content">

        <script src="{concat($base_url, '/cp/cp.js')}" language="JavaScript"></script>

        <input type="hidden" name="save" value="" />
        <input type="hidden" name="cancel" value="" />

        <table class="formview" border="0" cellspacing="0" cellpadding="0">
          <tr class="title">
            <td colspan="2"><xsl:copy-of select="/cp/strings/profile_password_title" /></td>
          </tr>
          <tr class="instructionrow">
            <td colspan="2"><xsl:value-of select="/cp/strings/profile_password_instr"/></td>
          </tr>
          <tr class="roweven">
            <td class="label"><xsl:value-of select="/cp/strings/profile_password_old_password"/></td>
            <td class="contentwidth">
                <input type="password" name="old_password" size="42" value="" autocomplete="off" />
            </td>
          </tr>
          <tr class="rowodd">
            <td class="label"><xsl:value-of select="/cp/strings/profile_password_new_password"/></td>
            <td class="contentwidth">
                <input type="password" name="new_password" size="42" value="" autocomplete="off" />&#160;<span class="parenthetichelp"><xsl:value-of select="/cp/strings/profile_password_new_password_instr"/></span>
            </td>
          </tr>
          <tr class="roweven">
            <td class="label"><xsl:value-of select="/cp/strings/profile_password_confirm_password"/></td>
            <td class="contentwidth"><input type="password" name="new_password2" size="42" value="" autocomplete="off" /></td>
          </tr>
          <tr class="controlrow">
            <td colspan="2">
              <span class="floatright">
                <input type="submit" name="btn_save" value="{/cp/strings/profile_password_save_btn}" 
                  onClick="return validatePassword(
                    '{cp:js-escape(/cp/strings/profile_password_js_error_password_req)}',
                    '{cp:js-escape(/cp/strings/profile_password_js_error_password_fmt)}',
                    '{cp:js-escape(/cp/strings/profile_password_js_error_password_match)}',
                    '{cp:js-escape(/cp/strings/profile_password_js_error_old_password_req)}',
                    '{cp:js-escape(/cp/strings/profile_password_js_error_password_login_match)}',
                    '{$username}'
                );"/>
                <input type="button" name="btn_cancel" value="{/cp/strings/profile_password_cancel_btn}" 
                  onClick="document.forms[0].cancel.value='yes';document.forms[0].submit();" /></span></td>
          </tr>
        </table>

</xsl:template>
</xsl:stylesheet>

