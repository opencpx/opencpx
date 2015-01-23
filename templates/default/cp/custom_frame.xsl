<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:exslt="http://exslt.org/common"
                exclude-result-prefixes="exslt">
<xsl:import href="cp_global.xsl" />

<xsl:variable name="message">
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

<xsl:variable name="selectedCustomNav">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='auth']/siteprefs/custom-sidenav"><xsl:value-of select="/cp/strings/nv_custom_side_nav" /></xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='auth']/siteprefs/custom-topnav"></xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:template match="/">
  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title"><xsl:copy-of select="/cp/strings/cp_title" /> : <xsl:copy-of select="/cp/strings/bc_user_list" /></xsl:with-param>
    <xsl:with-param name="formaction"><xsl:value-of select="$base_url" />/cp/users/index.xsl</xsl:with-param>
    <xsl:with-param name="feedback" select="$feedback" />
    <xsl:with-param name="selected_navandcontent" select="$selectedCustomNav" />
    <xsl:with-param name="help_short" select="/cp/strings/user_list_hlp_short" />
    <xsl:with-param name="help_long">
      <xsl:choose>
        <xsl:when test="$user_type='sa'">
          <xsl:copy-of select="/cp/strings/user_list_hlp_long_sa" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:copy-of select="/cp/strings/user_list_hlp_long_da" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:with-param>
    <!-- ########### Set onload for the iframe ############## -->
    <xsl:with-param name="onload">loadCustomFrame();</xsl:with-param>
    <!-- #################################################### -->
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

  <script language="JavaScript" type="text/javascript" src="custom_frame.js" />

  <iframe id="custom_content_frame" src="" width="740" height="600" frameborder="0"></iframe>


</xsl:template>

</xsl:stylesheet>
