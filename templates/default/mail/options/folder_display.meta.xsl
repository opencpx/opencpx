<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../../global.meta.xsl" />
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

        <xsl:when test="string(/cp/form/save)">
        <!-- Save posted options to disk -->
          <vsap type="webmail:options:save">
            <use_mailboxlist><xsl:value-of select="/cp/form/use_mailboxlist" /></use_mailboxlist>
            <inbox_checkmail><xsl:value-of select="/cp/form/inbox_checkmail" /></inbox_checkmail>
          </vsap>
          <!-- Load options to DOM -->
          <vsap type="webmail:options:load"/>
        </xsl:when>

        <xsl:when test="not(/cp/vsap/vsap[@type='error'])">
          <!-- Load options to DOM -->
          <vsap type="webmail:options:load"/>
        </xsl:when>

      </xsl:choose>
    </vsap>
  </xsl:with-param>
</xsl:call-template>

<showpage />

</meta>
</xsl:template>
</xsl:stylesheet>
