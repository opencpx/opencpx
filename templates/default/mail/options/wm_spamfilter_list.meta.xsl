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
        <xsl:when test="string(/cp/form/add)">
          <vsap type="mail:spamassassin:add_patterns">
            <xsl:choose> 
              <xsl:when test="/cp/form/listType='black'">
                <blacklist_from><xsl:value-of select="/cp/form/pattern"/></blacklist_from>
              </xsl:when>
              <xsl:otherwise>
                <whitelist_from><xsl:value-of select="/cp/form/pattern"/></whitelist_from>
              </xsl:otherwise>
            </xsl:choose> 
          </vsap>
        </xsl:when>
        <xsl:when test="string(/cp/form/remove)">
          <vsap type="mail:spamassassin:remove_patterns">
            <xsl:choose> 
              <xsl:when test="/cp/form/listType='black'">
                <xsl:for-each select="/cp/form/blacklist_from">
                 <blacklist_from><xsl:value-of select="."/></blacklist_from>
                </xsl:for-each>
              </xsl:when>
              <xsl:otherwise>
                <xsl:for-each select="/cp/form/whitelist_from">
                 <whitelist_from><xsl:value-of select="."/></whitelist_from>
                </xsl:for-each>
              </xsl:otherwise>
            </xsl:choose> 
          </vsap>
        </xsl:when>
      </xsl:choose>
      <xsl:if test="not(/cp/vsap/vsap[@type='error'])">
        <vsap type="mail:spamassassin:status" />
      </xsl:if>
    </vsap>
  </xsl:with-param>
</xsl:call-template>

<showpage />

</meta>
</xsl:template>
</xsl:stylesheet>
