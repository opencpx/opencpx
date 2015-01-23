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
            <xsl:when test="string(/cp/form/spamassassin_mail)">
              <xsl:choose>
                <xsl:when test="string(/cp/form/checkboxName)">
                  <vsap type="mail:spamassassin:enable" />
                </xsl:when>
                <xsl:otherwise>
                  <vsap type="mail:spamassassin:disable" />
                </xsl:otherwise>
              </xsl:choose>
              <vsap type="mail:spamassassin:set_user_prefs">
                <xsl:choose>
                  <xsl:when test="/cp/form/level='CUSTOM'">
                    <required_score><xsl:value-of select="/cp/form/custom_score" /></required_score>
                  </xsl:when>
                  <xsl:otherwise>
                    <required_score><xsl:value-of select="/cp/form/level" /></required_score>
                  </xsl:otherwise>
                </xsl:choose>
              </vsap>
            </xsl:when>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="not(/cp/vsap/vsap[@type='error'])">
          <vsap type="mail:spamassassin:status" />
        </xsl:when>
      </xsl:choose>
      <vsap type="mail:spamassassin:globally_installed" />
    </vsap>
  </xsl:with-param>
</xsl:call-template>

<showpage />

</meta>
</xsl:template>
</xsl:stylesheet>
