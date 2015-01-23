<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
 <xsl:import href="../../global.meta.xsl"/>
 <xsl:import href="../cp_global.meta.xsl"/>
 <xsl:template match="/">
  <meta>

    <xsl:call-template name="auth">
      <xsl:with-param name="require_shell">1</xsl:with-param>
    </xsl:call-template>

    <xsl:call-template name="cp_global"/>

    <!-- get ssh protocol 1 status (BUG27930)
    <xsl:call-template name="dovsap">
     <xsl:with-param name="vsap">
        <vsap>
          <vsap type="sys:ssh:status"/>
        </vsap>
      </vsap>
    </xsl:with-param>
    -->

   <showpage/>

  </meta>
 </xsl:template>
</xsl:stylesheet>
