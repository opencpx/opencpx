<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="cp_global.xsl" />

<xsl:template match="/">
  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title"><xsl:copy-of select="/cp/strings/cp_title" /> : <xsl:copy-of select="/cp/strings/nv_enhanced_webmail" /></xsl:with-param>
    <xsl:with-param name="formaction">shell.xsl</xsl:with-param>
    <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_enhanced_webmail" />
    <xsl:with-param name="breadcrumb">
      <breadcrumb>
      </breadcrumb>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

    <xsl:choose>
      <xsl:when test="/cp/vsap/vsap[@type='auth']/server_admin">
        <xsl:copy-of select="/cp/strings/cp_ewm_prompt_admin_message" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="/cp/strings/cp_ewm_prompt_message" />
      </xsl:otherwise>
    </xsl:choose>

</xsl:template>

</xsl:stylesheet>
