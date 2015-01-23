<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="error_global.xsl" />

<xsl:template match="/">
  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title"><xsl:copy-of select="/cp/strings/error_503_title" /></xsl:with-param>
    <xsl:with-param name="formaction">error/503.xsl</xsl:with-param>
    <xsl:with-param name="feedback" />
    <xsl:with-param name="selected_navandcontent" />
    <xsl:with-param name="help_short" />
    <xsl:with-param name="help_long" />
    <xsl:with-param name="breadcrumb" />
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

<table class="formview" border="0" cellspacing="0" cellpadding="0">
<tr class="title">
<td><xsl:copy-of select="/cp/strings/error_503_title"/></td>
</tr>
<tr class="rowodd">
<td>
  <xsl:copy-of select="/cp/strings/error_503_desc"/><br/>
  <br/>
  <input class="floatright" type="button" onClick="location.reload" name="back" value="{/cp/strings/error_503_btn_reload}"/>
</td>
</tr>
</table>
   
</xsl:template>
</xsl:stylesheet>
