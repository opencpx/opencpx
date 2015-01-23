<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="mail_global.xsl" />

<xsl:template match="/">

  <xsl:variable name="subject_subtitle">
    <xsl:choose>
      <xsl:when test="string-length(/cp/vsap/vsap[@type='webmail:messages:read']/subject) > 0">
        <xsl:value-of select="/cp/vsap/vsap[@type='webmail:messages:read']/subject" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="/cp/strings/wm_viewmessage_nosubject" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:call-template name="printbodywrapper">
    <xsl:with-param name="title"><xsl:copy-of select="/cp/strings/wm_title" /> : <xsl:copy-of select="$subject_subtitle" /></xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

      <table class="printableview" border="0" cellspacing="0" cellpadding="0">
        <!-- From -->
        <tr>
          <td class="label" width="0">
            <xsl:value-of select="/cp/strings/wm_viewmessage_from" /> <br />
          </td>
          <td class="contentwidth">
            <xsl:value-of select="/cp/vsap/vsap[@type='webmail:messages:read']/from/address/personal" />
            &lt;<xsl:value-of select="/cp/vsap/vsap[@type='webmail:messages:read']/from/address/full" />&gt;
          </td>

        </tr>

        <!-- To -->
        <tr class="messagerow">
          <td class="label" width="0">
            <xsl:value-of select="/cp/strings/wm_viewmessage_to" /> <br />
          </td>
          <td class="contentwidth">
            <xsl:for-each select="/cp/vsap/vsap[@type='webmail:messages:read']/to/address">
              <xsl:value-of select="personal" />
              &lt;<xsl:value-of select="full" />&gt;
              <br />
            </xsl:for-each>
            <span />
          </td>
        </tr>
        <!-- Cc -->
        <tr class="messagerow">
          <td class="label" width="0">
            <xsl:value-of select="/cp/strings/wm_viewmessage_cc" /> <br />
          </td>
          <td class="contentwidth">
            <xsl:for-each select="/cp/vsap/vsap[@type='webmail:messages:read']/cc/address">
              <xsl:value-of select="personal" />
              &lt;<xsl:value-of select="full" />&gt;
              <br />
            </xsl:for-each>
            <span />
          </td>
        </tr>
        <!-- Subject -->
        <tr class="messagerow">
          <td class="label" width="0">
            <xsl:value-of select="/cp/strings/wm_viewmessage_subject" /> <br />
          </td>
          <td class="contentwidth">
            <xsl:choose>
              <xsl:when test="string-length(/cp/vsap/vsap[@type='webmail:messages:read']/subject) > 0">
                <xsl:value-of select="/cp/vsap/vsap[@type='webmail:messages:read']/subject" />
              </xsl:when>
              <xsl:otherwise>
                <xsl:copy-of select="/cp/strings/wm_viewmessage_nosubject" />
              </xsl:otherwise>
            </xsl:choose>
            <br />
          </td>
        </tr>
        <!-- Date -->
        <tr class="messagerow">
          <td class="label" width="0">
            <xsl:value-of select="/cp/strings/wm_viewmessage_date" /> <br />
          </td>
          <td class="contentwidth">
            <xsl:call-template name="format-date">
              <xsl:with-param name="date" select="/cp/vsap/vsap[@type='webmail:messages:read']/date" />
            </xsl:call-template>
            <br />
          </td>
        </tr>
        <!-- Time -->
        <tr class="messagerow">
          <td class="label" width="0">
            <xsl:value-of select="/cp/strings/wm_viewmessage_time" /> <br />
          </td>
          <td class="contentwidth">
            <xsl:call-template name="format-time">
              <xsl:with-param name="date" select="/cp/vsap/vsap[@type='webmail:messages:read']/date" />
            </xsl:call-template>
            <br />
          </td>
        </tr>
        <!-- Attachments -->
        <tr class="messagerow">
          <td class="label" width="0">
            <xsl:value-of select="/cp/strings/wm_viewmessage_attachments" />
          </td>
          <td class="contentwidth">
            <xsl:choose>
              <xsl:when test="count(/cp/vsap/vsap[@type='webmail:messages:read']/attachments/attachment) > 0">
                <xsl:for-each select="/cp/vsap/vsap[@type='webmail:messages:read']/attachments/attachment">
                  <img src="{/cp/strings/wm_img_attachment}" alt="" border="0" />
                  <xsl:value-of select="name" />
                  <xsl:if test="position() != last()"><xsl:value-of select="/cp/strings/wm_viewmessage_comma" /></xsl:if>
                </xsl:for-each>
              </xsl:when>
            </xsl:choose>
          </td>
        </tr>
        <!-- Message Body -->
        <tr>
          <td class="message" colspan="2">
            <cp-unescape><xsl:value-of select="/cp/vsap/vsap[@type='webmail:messages:read']/body" /></cp-unescape>
          </td>
        </tr>
      </table>

</xsl:template>
</xsl:stylesheet>
