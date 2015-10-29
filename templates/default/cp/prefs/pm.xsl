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
        <xsl:with-param name="message"><xsl:copy-of select="/cp/strings/prefs_sa_success" /> </xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='user:prefs:save']/status = 'fail'">
      <xsl:call-template name="feedback_table">
        <xsl:with-param name="image">error</xsl:with-param>
        <xsl:with-param name="message"><xsl:copy-of select="/cp/strings/prefs_sa_failure" /> </xsl:with-param>
      </xsl:call-template>
    </xsl:when>
  </xsl:choose>
</xsl:variable>

<xsl:template match="/">
<xsl:call-template name="bodywrapper">

  <xsl:with-param name="title">
    <xsl:copy-of select="/cp/strings/cp_title" /> : <xsl:copy-of select="/cp/strings/bc_prefs_sa" />
  </xsl:with-param>

  <xsl:with-param name="formaction">sa.xsl</xsl:with-param>
  <xsl:with-param name="feedback"><xsl:copy-of select="$message" /></xsl:with-param>

  <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_sa_prefs" />
  <xsl:with-param name="help_short" select="/cp/strings/prefs_sa_hlp_short" />
  <xsl:with-param name="help_long" select="/cp/strings/prefs_sa_hlp_long" />
  <xsl:with-param name="breadcrumb">
    <breadcrumb>
      <section>
        <name><xsl:copy-of select="/cp/strings/bc_prefs_sa" /></name>
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
            <td colspan="2"><xsl:copy-of select="/cp/strings/prefs_sa_title" /></td>
          </tr>
          <tr class="roweven">
            <td class="label"><xsl:value-of select="/cp/strings/prefs_sa_ppp_label"/></td>
            <td class="contentwidth">
		<xsl:value-of select="/cp/strings/prefs_sa_packages_display"/> &#160;     	
              <select name="ppp">
                <option value="10">
                  <xsl:if test="/cp/vsap/vsap/user_preferences/sa_packages_per_page = '10'">
                    <xsl:attribute name="selected" value="1"/>
                  </xsl:if>
                  10
                </option>
                <option value="25">
                  <xsl:if test="/cp/vsap/vsap/user_preferences/sa_packages_per_page = '25'">
                    <xsl:attribute name="selected" value="1"/>
                  </xsl:if>
                  25
                </option>
                <option value="50">
                  <xsl:if test="/cp/vsap/vsap/user_preferences/sa_packages_per_page = '50'">
                    <xsl:attribute name="selected" value="1"/>
                  </xsl:if>
                  50
                </option>
                <option value="100">
                  <xsl:if test="/cp/vsap/vsap/user_preferences/sa_packages_per_page = '100'">
                    <xsl:attribute name="selected" value="1"/>
                  </xsl:if>
                  100
                </option>
              </select>
		&#160;
		<xsl:value-of select="/cp/strings/prefs_sa_packages_per_page"/>	
            </td>
          </tr>
          <tr class="controlrow">
            <td colspan="2"><span class="floatright"><input type="submit" name="save" value="{/cp/strings/prefs_sa_save_btn}" /><input type="submit" name="cancel" value="{/cp/strings/prefs_sa_cancel_btn}" /></span></td>
          </tr>
        </table>

</xsl:template>
</xsl:stylesheet>

