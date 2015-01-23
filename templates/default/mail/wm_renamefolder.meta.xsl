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
        <xsl:when test="/cp/form/save_rename!=''">
          <vsap type="webmail:folders:rename">
            <folder><xsl:value-of select="/cp/form/oldfolder" /></folder>
            <new_folder><xsl:value-of select="/cp/form/newfolder" /></new_folder>
          </vsap>
        </xsl:when>
      </xsl:choose>
    </vsap>
  </xsl:with-param>
</xsl:call-template>

<xsl:if test="/cp/form/cancel!=''">
  <redirect>
    <path>mail/wm_folders.xsl</path>
  </redirect>
</xsl:if>

<xsl:if test="/cp/form/save_rename and not(string(/cp/vsap/vsap[@type='error']))">
  <redirect>
    <path>mail/wm_folders.xsl</path>
  </redirect>
</xsl:if>

<showpage />

</meta>
</xsl:template>
</xsl:stylesheet>
          
