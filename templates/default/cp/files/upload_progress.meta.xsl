<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
 <xsl:import href="../../global.meta.xsl"/>
 <xsl:import href="../cp_global.meta.xsl"/>

 <xsl:template match="/">
  <meta>

   <!-- run auth code -->
   <xsl:call-template name="auth">
    <xsl:with-param name="require_fileman">1</xsl:with-param>
   </xsl:call-template>

   <xsl:call-template name="cp_global"/>

   <xsl:if test="string(/cp/form/action)='ok'">
    <xsl:call-template name="dovsap">
     <xsl:with-param name="vsap">
      <vsap>
       <vsap type="files:upload:sweep">
        <sessionid><xsl:value-of select="/cp/form/sessionID"/></sessionid>
       </vsap>       
      </vsap>
     </xsl:with-param>
    </xsl:call-template>
   </xsl:if>

   <!-- run vsap code -->
   <xsl:call-template name="dovsap">
    <xsl:with-param name="vsap">
     <vsap>
      <vsap type="files:upload:status">
       <sessionid><xsl:value-of select="/cp/form/sessionID"/></sessionid>
      </vsap>
     </vsap>
    </xsl:with-param>
   </xsl:call-template>

   <!-- if that's all done, we just show the page -->
   <showpage/>

  </meta>
 </xsl:template>
</xsl:stylesheet>
