<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../global.meta.xsl" />
<xsl:template match="/">
<meta>

<!-- run auth code -->
<xsl:call-template name="auth" />

<xsl:variable name="type">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='auth']/server_admin">sa</xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='auth']/domain_admin">da</xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='auth']/mail_admin">ma</xsl:when>
    <xsl:otherwise>eu</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<redirect>
<xsl:choose>
  <xsl:when test="$type = 'sa'">
    <path>cp/admin/services.xsl</path>
  </xsl:when>
  <xsl:when test="$type = 'da'">
    <path>cp/users/index.xsl</path>
  </xsl:when>
  <xsl:when test="$type = 'ma'">
    <path>cp/email/index.xsl</path>
  </xsl:when>
  <xsl:otherwise>
    <path>cp/profile/index.xsl</path>
  </xsl:otherwise>
</xsl:choose>
</redirect>

<!-- run vsap code
<xsl:call-template name="dovsap">
  <xsl:with-param name="vsap">
    <vsap>
      <vsap type="user:list"><brief/></vsap>
      <xsl:if test="$type != 'eu'">
        <vsap type="domain:list" />
      </xsl:if>
    </vsap>
  </xsl:with-param>
</xsl:call-template>

<showpage />
-->

</meta>
</xsl:template>
</xsl:stylesheet>
