<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../../global.meta.xsl" />
<xsl:import href="../cp_global.meta.xsl" />

<xsl:template match="/">
<meta>

<xsl:call-template name="auth" />

<xsl:call-template name="cp_global" />

<xsl:call-template name="dovsap">
  <xsl:with-param name="vsap">
    <vsap>
      <vsap type="extensions:oneclick_apps" />
      <vsap type="domain:list" />
      <xsl:if test="not(/cp/vsap/vsap[@type='auth']/server_admin) and not(/cp/vsap/vsap[@type='auth']/domain_admin)">
        <vsap type="user:list">
          <page>1</page>
          <sortby />
          <order />
        </vsap>
      </xsl:if>
    </vsap>
  </xsl:with-param>
</xsl:call-template>

<showpage />

</meta>
</xsl:template>
</xsl:stylesheet>
