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
        <user><xsl:value-of select="/cp/form/login_id" /></user>
      </vsap>
      <vsap type="mail:addresses:list">
        <rhs><xsl:value-of select="/cp/form/login_id" /></rhs>
      </vsap>
    </vsap>
  </xsl:with-param>
</xsl:call-template>

<!-- this can happen if a user is just trying to access users directly -->
<xsl:if test="/cp/vsap/vsap[@type='error'][@caller='user:properties']/code = 105">
  <xsl:call-template name="set_message">
    <xsl:with-param name="name">user_permission</xsl:with-param>
  </xsl:call-template>
  <redirect>
    <path>cp/users/index.xsl</path>
  </redirect>
</xsl:if>

<showpage />

</meta>
</xsl:template>
</xsl:stylesheet>
