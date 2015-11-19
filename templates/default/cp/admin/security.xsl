<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../cp_global.xsl" />

<xsl:variable name="message">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='error'] and string(/cp/form/btnSave)">
      <xsl:value-of select="/cp/strings/security_update_failure"/>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='error']">
      <xsl:value-of select="/cp/strings/security_get_failure"/>
    </xsl:when>
    <xsl:when test="string(/cp/form/btnSave)">
      <xsl:value-of select="/cp/strings/security_update_successful"/>
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

<xsl:variable name="ssl_redirect" select="/cp/vsap/vsap[@type='sys:security:controlpanel']/ssl_redirect"/>

<xsl:template match="/">
  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title">
      <xsl:copy-of select="/cp/strings/cp_title" />
      v<xsl:value-of select="/cp/vsap/vsap[@type='auth']/version" /> :
      <xsl:copy-of select="/cp/strings/bc_system_admin_security" />
    </xsl:with-param>
    <xsl:with-param name="formaction">security.xsl</xsl:with-param>
    <xsl:with-param name="feedback" select="$feedback" />
    <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_admin_set_security" />
    <xsl:with-param name="help_short" select="/cp/strings/system_admin_hlp_short" />
    <xsl:with-param name="help_long"><xsl:copy-of select="/cp/strings/system_admin_hlp_long" /></xsl:with-param>
    <xsl:with-param name="breadcrumb">
      <breadcrumb>
        <section>
          <name><xsl:copy-of select="/cp/strings/bc_system_admin_security" /></name>
          <url>#</url>
          <image>SystemAdministration</image>
        </section>
      </breadcrumb>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

  <script src="{concat($base_url, '/cp/cp.js')}" language="JavaScript"></script>

  <table class="formview" border="0" cellspacing="0" cellpadding="0">
    <tr class="title">
      <td colspan="2"><xsl:copy-of select="/cp/strings/server_security_preferences" /></td>
    </tr>
    <tr class="instructionrow">
      <td colspan="2"><xsl:copy-of select="/cp/strings/server_security_info" /></td>
    </tr>
    <tr class="rowodd">
      <td class="label"><xsl:copy-of select="/cp/strings/server_security_https" /></td>
      <td class="contentwidth">

        <input type="radio" id="security_https_off" name="ssl_redirect" value="disable" border="0">
          <xsl:if test="$ssl_redirect = 'disabled'">
            <xsl:attribute name="checked" value="checked"/>
          </xsl:if>
        </input><label for="security_https_off"><xsl:value-of select="/cp/strings/server_security_https_off"/></label><br />

        <input type="radio" id="security_https_on" name="ssl_redirect" value="enable" border="0">
          <xsl:if test="$ssl_redirect = 'enabled'">
            <xsl:attribute name="checked" value="checked"/>
          </xsl:if>
        </input><label for="security_https_on"><xsl:value-of select="/cp/strings/server_security_https_on"/></label><br />

      </td>
    </tr>

    <tr class="controlrow">
      <td colspan="2"><input class="floatright" type="submit" name="btnCancel" value="{/cp/strings/server_security_btn_cancel}"/><input class="floatright" type="submit" name="btnSave" value="{/cp/strings/server_security_btn_save}" /></td>
    </tr>
  </table>

</xsl:template>

</xsl:stylesheet>
