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
        <xsl:with-param name="message"><xsl:copy-of select="/cp/strings/prefs_pm_success" /> </xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='user:prefs:save']/status = 'fail'">
      <xsl:call-template name="feedback_table">
        <xsl:with-param name="image">error</xsl:with-param>
        <xsl:with-param name="message"><xsl:copy-of select="/cp/strings/prefs_pm_failure" /> </xsl:with-param>
      </xsl:call-template>
    </xsl:when>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="packages_per_page">
  <xsl:choose>
    <xsl:when test="/cp/form/ppp">
      <xsl:value-of select="/cp/form/ppp"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="/cp/vsap/vsap/user_preferences/packages_per_page"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:template match="/">
<xsl:call-template name="bodywrapper">

  <xsl:with-param name="title">
    <xsl:copy-of select="/cp/strings/cp_title" /> : <xsl:copy-of select="/cp/strings/bc_prefs_pm" />
  </xsl:with-param>

  <xsl:with-param name="formaction">pm.xsl</xsl:with-param>
  <xsl:with-param name="feedback"><xsl:copy-of select="$message" /></xsl:with-param>

  <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_pm_prefs" />
  <xsl:with-param name="help_short" select="/cp/strings/prefs_pm_hlp_short" />
  <xsl:with-param name="help_long" select="/cp/strings/prefs_pm_hlp_long" />
  <xsl:with-param name="breadcrumb">
    <breadcrumb>
      <section>
        <name><xsl:copy-of select="/cp/strings/bc_prefs_pm" /></name>
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
            <td colspan="2"><xsl:copy-of select="/cp/strings/prefs_pm_title" /></td>
          </tr>
          <tr class="roweven">
            <td class="label"><xsl:value-of select="/cp/strings/prefs_pm_ppp_label"/></td>
            <td class="contentwidth">
              <input type="radio" id="upp10" name="ppp" value="10" border="0">
                <xsl:if test="$packages_per_page = '10'">
                  <xsl:attribute name="checked" value="checked"/>
                </xsl:if>
               </input><label for="upp10">10</label><br />

              <input type="radio" id="upp25" name="ppp" value="25" border="0">
                <xsl:if test="$packages_per_page = '25'">
                  <xsl:attribute name="checked" value="checked"/>
                </xsl:if>
               </input><label for="upp25">25</label><br />

              <input type="radio" id="upp50" name="ppp" value="50" border="0">
                <xsl:if test="$packages_per_page = '50'">
                  <xsl:attribute name="checked" value="checked"/>
                </xsl:if>
               </input><label for="upp50">50</label><br />

              <input type="radio" id="upp100" name="ppp" value="100" border="0">
                <xsl:if test="$packages_per_page = '100'">
                  <xsl:attribute name="checked" value="checked"/>
                </xsl:if>
               </input><label for="upp100">100</label><br />
            </td>
          </tr>
          <tr class="controlrow">
            <td colspan="2"><span class="floatright"><input type="submit" name="save" value="{/cp/strings/prefs_pm_save_btn}" /><input type="submit" name="cancel" value="{/cp/strings/prefs_pm_cancel_btn}" /></span></td>
          </tr>
        </table>

</xsl:template>
</xsl:stylesheet>

