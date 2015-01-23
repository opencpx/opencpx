<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="mail_global.xsl" />

<xsl:template match="/">

<!-- subject isn't set in messages:raw, but it would be nice if it were
  <xsl:variable name="subtitle">
    <xsl:choose>
      <xsl:when test="string-length(/cp/vsap/vsap[@type='webmail:messages:raw']/subject) > 0">
        <xsl:value-of select="/cp/vsap/vsap[@type='webmail:messages:raw']/subject" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="/cp/strings/wm_viewmessage_nosubject" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
-->

  <xsl:call-template name="printbodywrapper">
<!--
    <xsl:with-param name="title"><xsl:copy-of select="/cp/strings/wm_title" /> : <xsl:copy-of select="$subtitle" /></xsl:with-param>
-->
    <xsl:with-param name="title"><xsl:copy-of select="/cp/strings/wm_title" /></xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

      <table class="printableview" border="0" cellspacing="0" cellpadding="0">
        <tr>
          <td class="message" colspan="2">
            <cp-unescape><pre><xsl:value-of select="/cp/vsap/vsap[@type='webmail:messages:raw']/body" /></pre></cp-unescape>
          </td>
        </tr>
      </table>

</xsl:template>
</xsl:stylesheet>
