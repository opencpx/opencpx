<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
  xmlns:exslt="http://exslt.org/common"
  exclude-result-prefixes="exslt">

<xsl:import href="../cp_global.xsl" />

<xsl:variable name="message">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='user:prefs:save']/status = 'ok'">
      <xsl:call-template name="feedback_table">
        <xsl:with-param name="image">success</xsl:with-param>
        <xsl:with-param name="message"><xsl:copy-of select="/cp/strings/prefs_logout_success" /> </xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='user:prefs:save']/status = 'fail'">
      <xsl:call-template name="feedback_table">
        <xsl:with-param name="image">error</xsl:with-param>
        <xsl:with-param name="message"><xsl:copy-of select="/cp/strings/prefs_logout_failure" /> </xsl:with-param>
      </xsl:call-template>
    </xsl:when>
  </xsl:choose>
</xsl:variable>

<xsl:template match="/">
<xsl:call-template name="bodywrapper">

  <xsl:with-param name="title">
    <xsl:copy-of select="/cp/strings/cp_title" /> : <xsl:copy-of select="/cp/strings/bc_prefs_logout" />
  </xsl:with-param>

  <xsl:with-param name="formaction">autologout.xsl</xsl:with-param>
  <xsl:with-param name="feedback"><xsl:copy-of select="$message" /></xsl:with-param>

  <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_auto_logout" />
  <xsl:with-param name="help_short" select="/cp/strings/prefs_logout_hlp_short" />
  <xsl:with-param name="help_long" select="/cp/strings/prefs_logout_hlp_long" />
  <xsl:with-param name="breadcrumb">
    <breadcrumb>
      <section>
        <name><xsl:copy-of select="/cp/strings/bc_prefs_logout" /></name>
        <url>#</url>
        <image>Preferences</image>
      </section>
    </breadcrumb>
  </xsl:with-param>

</xsl:call-template>
</xsl:template>

<xsl:template name="content">

        <table class="formview" border="0" cellspacing="0" cellpadding="0">
          <tr class="title">
            <td colspan="2"><xsl:copy-of select="/cp/strings/prefs_logout_title" /></td>
          </tr>
          <tr class="instructionrow">
            <td colspan="2"><xsl:value-of select="/cp/strings/prefs_logout_instr"/></td>
          </tr>
          <tr class="rowodd">
            <td class="label"><xsl:value-of select="/cp/strings/prefs_logout_label"/></td>
            <td class="contentwidth"><xsl:value-of select="/cp/strings/prefs_logout_desc"/><br />

              <input type="radio" id="autologout_1hour" name="autologout" value="1">
                <xsl:if test="/cp/vsap/vsap/user_preferences/logout = 1">
                  <xsl:attribute name="checked" value="checked"/>
                </xsl:if>
              </input>
              <label for="autologout_1hour"><xsl:value-of select="/cp/strings/prefs_logout_1hr"/></label><br />

              <input type="radio" id="autologout_2hours" name="autologout" value="2">
                <xsl:if test="/cp/vsap/vsap/user_preferences/logout = 2">
                  <xsl:attribute name="checked" value="checked"/>
                </xsl:if>
              </input>
              <label for="autologout_2hours"><xsl:value-of select="/cp/strings/prefs_logout_2hr"/></label><br />

              <input type="radio" id="autologout_8hours" name="autologout" value="8">
                <xsl:if test="/cp/vsap/vsap/user_preferences/logout = 8">
                  <xsl:attribute name="checked" value="checked"/>
                </xsl:if>
              </input>
              <label for="autologout_8hours"><xsl:value-of select="/cp/strings/prefs_logout_8hr"/></label><br />

              <input type="radio" id="autologout_24hours" name="autologout" value="24">
                <xsl:if test="/cp/vsap/vsap/user_preferences/logout = 24">
                  <xsl:attribute name="checked" value="checked"/>
                </xsl:if>
              </input>
              <label for="autologout_24hours"><xsl:value-of select="/cp/strings/prefs_logout_24hr"/></label><br />

              </td>
            </tr>

          <tr class="controlrow">
            <td colspan="2"><span class="floatright"><input type="submit" name="save" value="{/cp/strings/prefs_logout_save_btn}" /><input type="submit" name="cancel" value="{/cp/strings/prefs_logout_cancel_btn}" /></span></td>
          </tr>
        </table>

</xsl:template>
</xsl:stylesheet>

