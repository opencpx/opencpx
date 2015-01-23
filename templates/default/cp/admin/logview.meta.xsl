<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
 <xsl:import href="../../global.meta.xsl"/>
 <xsl:import href="../cp_global.meta.xsl"/>
 <xsl:template match="/">
  <meta>

    <xsl:call-template name="auth">
      <xsl:with-param name="require_class">da</xsl:with-param>
    </xsl:call-template>

   <xsl:call-template name="cp_global"/>

    <xsl:call-template name="dovsap">
      <xsl:with-param name="vsap">
        <vsap>

          <xsl:if test="string(/cp/form/archive_now)">
            <vsap type="sys:logs:archive_now">
              <path><xsl:value-of select="/cp/form/path"/></path>
            </vsap>
          </xsl:if>

          <xsl:if test="string(/cp/form/path)">
            <vsap type="sys:logs:show">
              <path><xsl:value-of select="/cp/form/path"/></path>
              <range>200</range>
              <page>1</page>
              <domain><xsl:value-of select="/cp/form/domain"/></domain>
            </vsap>
          </xsl:if>


        </vsap>
      </xsl:with-param>
    </xsl:call-template>
   <showpage/>

  </meta>
 </xsl:template>
</xsl:stylesheet>
