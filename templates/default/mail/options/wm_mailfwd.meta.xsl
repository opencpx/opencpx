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

    <xsl:variable name="saveCopy">
      <xsl:choose>
        <xsl:when test="/cp/form/save_copy = 'on'">on</xsl:when>
        <xsl:otherwise></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:if test="string(/cp/form/save_forward)">
      <xsl:call-template name="dovsap">
        <xsl:with-param name="vsap">
          <vsap>
            <xsl:choose>
              <xsl:when test="/cp/form/groupForward='on'">
                <vsap type="mail:forward:enable">
                  <email><xsl:value-of select="/cp/form/textareaName" /></email>
                  <savecopy><xsl:value-of select="$saveCopy" /></savecopy>
                </vsap>
              </xsl:when>
              <xsl:otherwise>
                <vsap type="mail:forward:disable">
                  <email><xsl:value-of select="/cp/form/forward_address" /></email>
                  <savecopy><xsl:value-of select="$saveCopy" /></savecopy>
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
            <vsap type="mail:forward:status" />
          </vsap>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:if>

    <showpage />

  </meta>
 </xsl:template>
</xsl:stylesheet>
