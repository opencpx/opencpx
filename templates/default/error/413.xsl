<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="error_global.xsl" />

<xsl:template match="/">
  <xsl:call-template name="blankbodywrapper">
    <xsl:with-param name="title"><xsl:copy-of select="/cp/strings/error_413_title" /></xsl:with-param>
    <xsl:with-param name="formaction">error/413.xsl</xsl:with-param>
    <xsl:with-param name="feedback" />
    <xsl:with-param name="selected_navandcontent" />
    <xsl:with-param name="help_short" />
    <xsl:with-param name="help_long" />
    <xsl:with-param name="breadcrumb" />
    <xsl:with-param name="onload">UploadProgress.close();</xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

  <table class="uploadpopup" border="0" cellspacing="0" cellpadding="0" with="100%">
    <tr class="columnhead">
      <td><xsl:copy-of select="/cp/strings/error_413_title"/></td>
    </tr>
    <tr class="rowodd">
      <td><xsl:copy-of select="/cp/strings/error_413_desc"/></td>
    </tr>
    <tr class="controlrow">
     <td>
       <input class="floatright" type="button" onClick="history.go(-1)" name="back" value="{/cp/strings/error_413_btn_back}"/>
     </td>
    </tr>
  </table>
   
</xsl:template>
</xsl:stylesheet>
