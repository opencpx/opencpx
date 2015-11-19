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
        <xsl:with-param name="message"><xsl:copy-of select="/cp/strings/prefs_fm_success" /> </xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='user:prefs:save']/status = 'fail'">
      <xsl:variable name="errmsg">
        <xsl:choose>
          <xsl:when test="/cp/vsap/vsap[@type='user:prefs:save']/failure_code = '109'">
            <xsl:copy-of select="/cp/strings/prefs_fm_startpath_does_not_exist" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:copy-of select="/cp/strings/prefs_fm_failure" />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:call-template name="feedback_table">
        <xsl:with-param name="image">error</xsl:with-param>
        <xsl:with-param name="message"><xsl:copy-of select="$errmsg" /></xsl:with-param>
      </xsl:call-template>
    </xsl:when>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="startpath">
  <xsl:choose>
    <xsl:when test="/cp/form/target">
      <xsl:value-of select="/cp/form/target"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="/cp/vsap/vsap/user_preferences/fm_startpath"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:template match="/">
<xsl:call-template name="bodywrapper">

  <xsl:with-param name="title">
    <xsl:copy-of select="/cp/strings/cp_title" />
    v<xsl:value-of select="/cp/vsap/vsap[@type='auth']/version" /> :
    <xsl:copy-of select="/cp/strings/bc_prefs_fm" />
  </xsl:with-param>

  <xsl:with-param name="formaction">fm.xsl</xsl:with-param>
  <xsl:with-param name="feedback"><xsl:copy-of select="$message" /></xsl:with-param>

  <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_fm_prefs" />
  <xsl:with-param name="help_short" select="/cp/strings/prefs_fm_hlp_short" />
  <xsl:with-param name="help_long" select="/cp/strings/prefs_fm_hlp_long" />
  <xsl:with-param name="breadcrumb">
    <breadcrumb>
      <section>
        <name><xsl:copy-of select="/cp/strings/bc_prefs_fm" /></name>
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
            <td colspan="2"><xsl:copy-of select="/cp/strings/prefs_fm_title" /></td>
          </tr>
          <tr class="rowodd">
            <td class="label"><xsl:value-of select="/cp/strings/prefs_fm_startpath_label"/></td>
            <td class="contentwidth">
              <input name="target" value="{$startpath}" size="60"/>&#160;<a href="OpenDirectoryDialog" target="_blank" onClick="showDirectoryDialog(); return false;"><img src="{/cp/strings/prefs_fm_img_folder}" border="0" align="middle" /></a>
            </td>
          </tr>
          <tr class="roweven">
            <td class="label"><xsl:value-of select="/cp/strings/prefs_fm_hfd_label"/></td>
            <td class="contentwidth">

              <input type="radio" id="hfd_yes" name="hfd" value="show">
                <xsl:if test="/cp/vsap/vsap/user_preferences/fm_hidden_file_default = 'show'">
                  <xsl:attribute name="checked" value="checked"/>
                </xsl:if>
              </input>
              <label for="hfd_yes"><xsl:value-of select="/cp/strings/prefs_fm_hfd_yes"/></label><br />

              <input type="radio" id="hfd_no" name="hfd" value="hide">
                <xsl:if test="/cp/vsap/vsap/user_preferences/fm_hidden_file_default = 'hide'">
                  <xsl:attribute name="checked" value="checked"/>
                </xsl:if>
              </input>
              <label for="hfd_no"><xsl:value-of select="/cp/strings/prefs_fm_hfd_no"/></label><br />

            </td>
          </tr>
          <tr class="controlrow">
            <td colspan="2"><span class="floatright"><input type="submit" name="save" value="{/cp/strings/prefs_fm_save_btn}" /><input type="submit" name="cancel" value="{/cp/strings/prefs_fm_cancel_btn}" /></span></td>
          </tr>
        </table>

</xsl:template>
</xsl:stylesheet>

