<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../../global.meta.xsl" />
<xsl:import href="../cp_global.meta.xsl" />
<xsl:template match="/">
<meta>

<xsl:call-template name="auth">
  <xsl:with-param name="require_class">da</xsl:with-param>
</xsl:call-template>

<xsl:call-template name="cp_global"/>

<xsl:choose>
  <xsl:when test="/cp/form/ok">
    <redirect>
      <path>cp/domains/index.xsl</path>
    </redirect>
  </xsl:when>
  <xsl:when test="/cp/form/edit">
    <redirect>
      <path>cp/domains/index.xsl</path>
    </redirect>
  </xsl:when>
  <xsl:otherwise>
  </xsl:otherwise>
</xsl:choose>

<xsl:call-template name="dovsap">
  <xsl:with-param name="vsap">
    <vsap>
      <vsap type="domain:list">
        <domain><xsl:value-of select="/cp/form/domain" /></domain>
        <properties />
      </vsap>
    </vsap>
  </xsl:with-param>
</xsl:call-template>

<showpage />

</meta>
</xsl:template>
</xsl:stylesheet>
