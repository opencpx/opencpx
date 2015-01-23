<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../cp_global.xsl" />

<xsl:variable name="message">
  <xsl:choose>
    <xsl:when test="/cp/msgs/msg[@name='selfmanaged_permission_denied']">
      <xsl:copy-of select="/cp/strings/selfmanaged_permission_denied" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='admin_password_js_error_password_blank']">
      <xsl:copy-of select="/cp/strings/admin_password_js_error_password_blank" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='admin_password_js_error_password_req']">
      <xsl:copy-of select="/cp/strings/admin_password_js_error_password_req" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='admin_password_js_error_password_fmt']">
      <xsl:copy-of select="/cp/strings/admin_password_js_error_password_fmt" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='admin_password_js_error_password_match']">
      <xsl:copy-of select="/cp/strings/admin_password_js_error_password_match" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='server_selfmanaged_adminpassword_invalid']">
      <xsl:copy-of select="/cp/strings/server_selfmanaged_adminpassword_invalid" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='selfmanaged_failed_provision_connection']">
      <xsl:copy-of select="/cp/strings/selfmanaged_failed_provision_connection" />
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='error']/code = ''">
      <xsl:copy-of select="/cp/strings/selfmanaged_generic_fail" />  <xsl:copy-of select="/cp/vsap/vsap[@type='error']/message" />
    </xsl:when>
    <xsl:when test="string(/cp/vsap/vsap[@type='error'])">
      <xsl:copy-of select="/cp/strings/selfmanaged_unknown_error" /> <xsl:copy-of select="/cp/vsap/vsap[@type='error']/code" />
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

<xsl:template match="/">
  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title"><xsl:copy-of select="/cp/strings/cp_title" /> : <xsl:copy-of select="/cp/strings/bc_system_admin_selfmanaged" /></xsl:with-param>
    <xsl:with-param name="formaction">selfmanaged.xsl</xsl:with-param>
    <xsl:with-param name="feedback" select="$feedback" />
    <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_admin_set_selfmanaged" />
    <xsl:with-param name="help_short" select="/cp/strings/system_admin_hlp_short" />
    <xsl:with-param name="help_long"><xsl:copy-of select="/cp/strings/system_admin_hlp_long" /></xsl:with-param>
    <xsl:with-param name="breadcrumb">
      <breadcrumb>
        <section>
          <name><xsl:copy-of select="/cp/strings/bc_system_admin_selfmanaged" /></name>
          <url>#</url>
          <image>SystemAdministration</image>
        </section>
      </breadcrumb>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

      <script src="{concat($base_url, '/cp/admin/selfmanaged.js')}" language="JavaScript"></script>

      <input type="hidden" name="switch" value="" />

      <table class="formview" border="0" cellspacing="0" cellpadding="0">
        <tr class="title">
          <td colspan="2"><xsl:value-of select="/cp/strings/server_selfmanaged_set" /></td>
        </tr>

        <tr class="instructionrow">
          <td colspan="2">
            <p><xsl:value-of select="/cp/strings/server_selfmanaged_info" /></p>
            <p><xsl:copy-of select="/cp/strings/server_selfmanaged_warningtext" /></p>
            <p><xsl:value-of select="/cp/strings/server_selfmanaged_adminpassword_help" /></p>
          </td>
        </tr>

        <tr class="roweven">
          <td class="label"><xsl:value-of select="/cp/strings/server_selfmanaged_adminpassword" /></td>
          <td class="contentwidth">
            <input type="password" name="old_password" size="42" value="" autocomplete="off" />
          </td>
        </tr>

        <tr class="rowodd">
          <td colspan="2">
            <p><xsl:value-of select="/cp/strings/server_selfmanaged_newrootpasswd_help" /></p>
          </td>
        </tr>

        <tr class="roweven">
          <td class="label"><xsl:value-of select="/cp/strings/server_selfmanaged_newrootpasswd" /></td>
          <td class="contentwidth">
            <input type="password" name="new_password" size="42" value="" autocomplete="off" />&#160;<span class="parenthetichelp"><xsl:value-of select="/cp/strings/mailman_password_new_password_instr"/></span>
          </td>
        </tr>

        <tr class="roweven">
          <td class="label"><xsl:value-of select="/cp/strings/server_selfmanaged_newrootpasswd_confirm" /></td>
          <td class="contentwidth">
            <input type="password" name="new_password2" size="42" value="" autocomplete="off" />
          </td>
        </tr>

        <tr class="controlrow">
          <td colspan="2">
            <span class="floatright">
              <input type="submit" name="btn_save" value="{/cp/strings/server_selfmanaged_btn_save}"
                onClick="
                  return validateSwitchToSelfManaged('{cp:js-escape(/cp/strings/admin_password_js_error_password_blank)}',
                                                     '{cp:js-escape(/cp/strings/admin_password_js_error_password_req)}',
                                                     '{cp:js-escape(/cp/strings/admin_password_js_error_password_fmt)}',
                                                     '{cp:js-escape(/cp/strings/admin_password_js_error_password_match)}',
                                                     '{cp:js-escape(/cp/strings/server_selfmanaged_confirm)}')"/>
            </span>
          </td>
        </tr>
      </table>

</xsl:template>

</xsl:stylesheet>
