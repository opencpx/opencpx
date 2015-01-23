<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
 <xsl:import href="../../global.meta.xsl"/>
 <xsl:import href="../cp_global.meta.xsl"/>

 <xsl:template match="/">
  <meta>

   <xsl:if test="/cp/form/action = 'cancel'">
    <redirect>
     <path>/cp/files/index.xsl</path>
    </redirect>
   </xsl:if>

   <!-- run auth code -->
   <xsl:call-template name="auth">
   <xsl:with-param name="require_fileman">1</xsl:with-param>
   </xsl:call-template>

   <xsl:call-template name="cp_global"/>

   <xsl:if test="/cp/form/action='doDelete'">
    <xsl:call-template name="dovsap">
     <xsl:with-param name="vsap">
      <vsap>
       <vsap type="files:delete">
        <xsl:copy-of select="/cp/form/path"/>
       </vsap>
       <xsl:if test="/cp/form/source_user">
        <user>
         <xsl:value-of select="/cp/form/source_user"/>
        </user>
       </xsl:if>
      </vsap>
     </xsl:with-param>
    </xsl:call-template>

    <redirect>
    <path>/cp/files/index.xsl</path>
    </redirect>
   </xsl:if>

   <showpage/>

  </meta>
 </xsl:template>
</xsl:stylesheet>
