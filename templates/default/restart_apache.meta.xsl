<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
 <xsl:import href="global.meta.xsl"/>

 <xsl:template match="/">
  <meta>

   <!-- run auth code -->
   <xsl:call-template name="auth">
     <xsl:with-param name="require_class">da</xsl:with-param>
   </xsl:call-template>

   <!-- submit restart apache request -->
   <xsl:call-template name="dovsap">
     <xsl:with-param name="vsap">
       <vsap>
         <vsap type="apache:restart"/>
       </vsap>
     </xsl:with-param>
   </xsl:call-template>

   <showpage/>

  </meta>
 </xsl:template>
</xsl:stylesheet>
