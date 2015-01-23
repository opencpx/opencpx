<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

 <xsl:import href="../../global.meta.xsl"/>
 <xsl:import href="../cp_global.meta.xsl"/>

 <xsl:template match="/">
  <meta>

   <!-- run auth code -->
   <xsl:call-template name="auth"/>

   <xsl:call-template name="cp_global"/>

   <xsl:call-template name="dovsap">
    <xsl:with-param name="vsap">
     <vsap>
      <vsap type="diskspace:list">
       <sz>4</sz>
       <xsl:if test="/cp/form/dir">
        <dir><xsl:value-of select="/cp/form/dir"/></dir>
       </xsl:if>
       <xsl:if test="/cp/form/units">
        <units><xsl:value-of select="/cp/form/units"/></units>
       </xsl:if>
      </vsap>
     </vsap>
    </xsl:with-param>
   </xsl:call-template>

   <showpage/>

  </meta>
 </xsl:template>
</xsl:stylesheet>
