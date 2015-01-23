<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../global.meta.xsl" />
<xsl:template match="/">
<meta>

<xsl:call-template name="auth">
  <xsl:with-param name="require_mail">1</xsl:with-param>
  <xsl:with-param name="require_webmail">1</xsl:with-param>
</xsl:call-template>

<xsl:if test="string(/cp/form/addfolder)">
  <redirect>
    <path>mail/wm_addfolder.xsl</path>
  </redirect>
</xsl:if>

<xsl:if test="string(/cp/form/subscribefolder)">
  <redirect>
    <path>mail/wm_subscribefolder.xsl</path>
  </redirect>
</xsl:if>

<xsl:call-template name="dovsap">
  <xsl:with-param name="vsap">
    <vsap>
      <xsl:choose>
        <xsl:when test="string(/cp/form/confirmdelete)">
          <vsap type="webmail:folders:delete">
            <xsl:for-each select="/cp/form/cbUserID">
              <folder><xsl:value-of select="." /></folder>
            </xsl:for-each>
          </vsap>
          <vsap type="webmail:folders:list"></vsap>
        </xsl:when>
        <xsl:when test="string(/cp/form/confirmunsubscribe)">
          <vsap type="webmail:folders:unsubscribe">
            <xsl:for-each select="/cp/form/cbUserID">
              <folder><xsl:value-of select="." /></folder>
            </xsl:for-each>
          </vsap>
          <vsap type="webmail:folders:list"></vsap>
        </xsl:when>
        <xsl:when test="/cp/form/clear">
          <vsap type="webmail:folders:clear">
            <folder><xsl:value-of select="/cp/form/clear" /></folder>
          </vsap> 
          <vsap type="webmail:folders:list"></vsap>
        </xsl:when>
        <xsl:otherwise>
          <vsap type="webmail:folders:list"></vsap>
        </xsl:otherwise>
      </xsl:choose>
    </vsap>
  </xsl:with-param>
</xsl:call-template>

<showpage />

</meta>
</xsl:template>
</xsl:stylesheet>
