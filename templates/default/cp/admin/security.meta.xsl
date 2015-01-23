<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
 <xsl:import href="../../global.meta.xsl"/>
 <xsl:import href="../cp_global.meta.xsl"/>
 <xsl:template match="/">
  <meta>

    <xsl:if test="string(/cp/form/btnCancel)">
      <redirect>
        <path>cp/admin/services.xsl</path>
      </redirect>
    </xsl:if>

    <xsl:call-template name="auth">
      <xsl:with-param name="require_class">sa</xsl:with-param>
    </xsl:call-template>

   <xsl:call-template name="cp_global"/>

    <xsl:call-template name="dovsap">
      <xsl:with-param name="vsap">
        <vsap>
         <xsl:choose>
          <xsl:when test="string(/cp/form/btnSave)">
            <vsap type="sys:security:controlpanel">
              <ssl_redirect><xsl:value-of select="/cp/form/ssl_redirect"/></ssl_redirect>
            </vsap>
          </xsl:when>
          <xsl:otherwise>
            <vsap type="sys:security:controlpanel"/>
          </xsl:otherwise>
         </xsl:choose>
	</vsap>
      </xsl:with-param>
    </xsl:call-template>

   <showpage/>

  </meta>
 </xsl:template>
</xsl:stylesheet>
