<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../../global.meta.xsl" />
<xsl:template match="/">
<meta>

<xsl:call-template name="auth">
  <xsl:with-param name="require_mail">1</xsl:with-param>
</xsl:call-template>

<xsl:call-template name="dovsap">
  <xsl:with-param name="vsap">
    <vsap>
      <xsl:choose>
        <xsl:when test="string(/cp/form/save)">
          <xsl:choose>
            <xsl:when test="string(/cp/form/clamav_mail)">
              <xsl:choose>
                <xsl:when test="string(/cp/form/checkboxName)">
                  <vsap type="mail:clamav:enable" />
                </xsl:when>
                <xsl:otherwise>
                  <vsap type="mail:clamav:disable" />
                </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="not(/cp/vsap/vsap[@type='error'])">
          <vsap type="mail:clamav:status" />
        </xsl:when>
      </xsl:choose>
      <vsap type="mail:clamav:milter_installed" />
    </vsap>
  </xsl:with-param>
</xsl:call-template>

<showpage />

</meta>
</xsl:template>
</xsl:stylesheet>
