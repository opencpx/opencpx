<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../../global.meta.xsl"/>
<xsl:import href="../cp_global.meta.xsl"/>
<xsl:template match="/">
  <meta>

    <xsl:call-template name="auth" />

    <xsl:call-template name="cp_global"/>

    <xsl:call-template name="dovsap">
      <xsl:with-param name="vsap">
        <vsap>
          <vsap type="extensions:oneclick_install">
            <app_key><xsl:value-of select="/cp/form/app_key"/></app_key>
            <domain><xsl:value-of select="/cp/form/domain" /></domain>
          </vsap>
        </vsap>
      </xsl:with-param>
    </xsl:call-template>

    <showpage/>

  </meta>
 </xsl:template>
</xsl:stylesheet>
