<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../global.meta.xsl" />
<xsl:template match="/">
<meta>

<!-- run auth code -->
<xsl:call-template name="auth">
  <xsl:with-param name="require_mail">1</xsl:with-param>
  <xsl:with-param name="require_webmail">1</xsl:with-param>
</xsl:call-template>

<!-- run vsap code -->
<xsl:call-template name="dovsap">
  <xsl:with-param name="vsap">
    <vsap>
      <xsl:if test="string(/cp/form/attach_file)">
        <xsl:if test="/cp/form/fileupload != ''">
          <vsap type='webmail:send:attachment:add'>
            <messageid><xsl:value-of select="/cp/form/messageid" /></messageid>
            <filename><xsl:value-of select="/cp/form/fileupload" /></filename>
          </vsap>
        </xsl:if>
      </xsl:if>  
      <xsl:if test="string(/cp/form/remove)">
        <xsl:for-each select="/cp/form/remove">
          <vsap type='webmail:send:attachment:delete'>
            <messageid><xsl:value-of select="/cp/form/messageid" /></messageid>
            <filename><xsl:value-of select="." /></filename>
          </vsap>
        </xsl:for-each>
      </xsl:if>
      <xsl:if test="string(/cp/form/remove_all)">
        <vsap type='webmail:send:attachment:delete_all'>
          <messageid><xsl:value-of select="/cp/form/messageid" /></messageid>
        </vsap>
      </xsl:if>
    </vsap>
  </xsl:with-param>
</xsl:call-template>

<xsl:call-template name="dovsap">
  <xsl:with-param name="vsap">
    <vsap>
      <vsap type='webmail:send:attachment:list'>
        <messageid><xsl:value-of select="/cp/form/messageid" /></messageid>
      </vsap>
    </vsap>
  </xsl:with-param>
</xsl:call-template>

<!-- if that's all done, we just show the page -->
<showpage />

</meta>
</xsl:template>
</xsl:stylesheet>
