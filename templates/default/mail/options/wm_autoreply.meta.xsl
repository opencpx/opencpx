<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
 <xsl:import href="../../global.meta.xsl" />
 <xsl:template match="/">
  <meta>

    <xsl:call-template name="auth">
      <xsl:with-param name="require_mail">1</xsl:with-param>
    </xsl:call-template>

    <xsl:if test="string(/cp/form/btnCancel)">
      <redirect>
        <path>mail/index.xsl</path>
      </redirect>
    </xsl:if>

    <xsl:if test="string(/cp/form/save_autoreply)">
      <xsl:call-template name="dovsap">
        <xsl:with-param name="vsap">
          <vsap>
            <xsl:choose>
              <xsl:when test="/cp/form/groupAutoreply='on'">
                <vsap type="mail:autoreply:enable">
                  <replyto><xsl:value-of select="/cp/form/replyto" /></replyto>
                  <subject><xsl:value-of select="/cp/form/subject" /></subject>
                  <message><xsl:value-of select="/cp/form/textareaName" /></message>
                  <interval><xsl:value-of select="/cp/form/interval" /></interval>
                  <encoding><xsl:value-of select="/cp/form/encoding" /></encoding>
                </vsap>
              </xsl:when>
              <xsl:otherwise>
                <vsap type="mail:autoreply:disable">
                  <replyto><xsl:value-of select="/cp/form/autoreply_replyto" /></replyto>
                  <subject><xsl:value-of select="/cp/form/autoreply_subject" /></subject>
                  <message><xsl:value-of select="/cp/form/autoreply_message" /></message>
                  <interval><xsl:value-of select="/cp/form/autoreply_interval" /></interval>
                  <encoding><xsl:value-of select="/cp/form/autoreply_encoding" /></encoding>
                </vsap>
              </xsl:otherwise>
            </xsl:choose>
          </vsap>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:if>

    <xsl:if test="not(/cp/vsap/vsap[@type='error'])">
      <xsl:call-template name="dovsap">
        <xsl:with-param name="vsap">
          <vsap>
            <vsap type="mail:autoreply:status" />
          </vsap>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:if>

    <showpage />

  </meta>
 </xsl:template>
</xsl:stylesheet>
