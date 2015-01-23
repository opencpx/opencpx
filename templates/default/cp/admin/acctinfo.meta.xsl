<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
 <xsl:import href="../../global.meta.xsl"/>
 <xsl:import href="../cp_global.meta.xsl"/>
 <xsl:template match="/">
  <meta>

    <xsl:call-template name="auth">
      <xsl:with-param name="require_class">sa</xsl:with-param>
    </xsl:call-template>

   <xsl:call-template name="cp_global"/>

    <xsl:call-template name="dovsap">
      <xsl:with-param name="vsap">
        <vsap>
          <vsap type="sys:info:get" />
          <vsap type="user:list_brief" />
          <vsap type="domain:list" />
          <vsap type="domain:list_ips" />
        </vsap>
      </xsl:with-param>
    </xsl:call-template>

   <showpage/>

  </meta>
 </xsl:template>
</xsl:stylesheet>
