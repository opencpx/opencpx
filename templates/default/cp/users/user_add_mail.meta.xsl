<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../../global.meta.xsl" />
<xsl:import href="../cp_global.meta.xsl" />
<xsl:template match="/">
<meta>

<xsl:call-template name="auth">
  <xsl:with-param name="require_class">ma</xsl:with-param>
</xsl:call-template>

<xsl:call-template name="cp_global"/>

<xsl:call-template name="dovsap">
  <xsl:with-param name="vsap">
    <vsap>
      <vsap type="user:properties">
        <user><xsl:value-of select="/cp/vsap/vsap[@type='auth']/username"/></user>
      </vsap>
      <vsap type="mail:clamav:milter_installed" />
    </vsap>
  </xsl:with-param>
</xsl:call-template>

<xsl:choose>
  <xsl:when test="string(/cp/form/cancel)">
    <redirect>
      <path>cp/users/index.xsl</path>
    </redirect>
  </xsl:when>
  <xsl:when test="string(/cp/form/preview_next)">
    <xsl:choose>
      <xsl:when test="/cp/form/type='da'">
        <redirect>
          <path>cp/users/user_add_domain.xsl</path>
        </redirect>
      </xsl:when>
      <xsl:otherwise>
        <redirect>
          <path>cp/users/user_add_preview.xsl</path>
        </redirect>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:when>
  <xsl:when test="string(/cp/form/btnPrevious)">
    <redirect>
      <path>cp/users/user_add_profile.xsl</path>
    </redirect>
  </xsl:when>
</xsl:choose>

<showpage />

</meta>
</xsl:template>
</xsl:stylesheet>
