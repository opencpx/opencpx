<?xml version="1.0" encoding="UTF-8"?>
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
      <vsap type="webmail:messages:read">
        <uid><xsl:value-of select="/cp/form/uid" /></uid>
        <folder><xsl:value-of select="/cp/form/folder" /></folder>
        <userencoding><xsl:value-of select="/cp/form/try_encoding" /></userencoding>
      </vsap>
      <vsap type="user:prefs:load"></vsap>
    </vsap>
  </xsl:with-param>
</xsl:call-template>

<showpage />

</meta>
</xsl:template>
</xsl:stylesheet>
