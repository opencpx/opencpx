<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../global.meta.xsl" />
<xsl:template match="/">
<meta>

<xsl:call-template name="auth">
  <xsl:with-param name="require_mail">1</xsl:with-param>
  <xsl:with-param name="require_webmail">1</xsl:with-param>
</xsl:call-template>

<xsl:call-template name="dovsap">
  <xsl:with-param name="vsap">
    <vsap>
      <xsl:choose>
        <xsl:when test="string(/cp/form/subscribe) or string(/cp/form/another)">
            <vsap type="webmail:folders:subscribe">
              <folder><xsl:value-of select="/cp/form/newfolder" /></folder>
            </vsap>
        </xsl:when>
      </xsl:choose>
    </vsap>
  </xsl:with-param>
</xsl:call-template>

<xsl:choose>
  <xsl:when test="boolean(/cp/vsap/vsap[@type='error'])">
    <showpage />
  </xsl:when>
  <xsl:when test="string(/cp/form/cancel) or string(/cp/form/subscribe_folder)">
    <redirect>
      <path>mail/wm_folders.xsl</path>
     </redirect>
   </xsl:when>
  <xsl:otherwise>
    <showpage />
  </xsl:otherwise>
</xsl:choose>

</meta>
</xsl:template>
</xsl:stylesheet>
          
