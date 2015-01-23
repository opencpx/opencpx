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
      <xsl:if test="/cp/form/sort_by != '' or /cp/form/sort_type != ''">
        <vsap type="webmail:options:save">
          <sel_addressee_order><xsl:value-of select="/cp/form/sort_by" /></sel_addressee_order>
          <sel_addressee_sortby><xsl:value-of select="/cp/form/sort_type" /></sel_addressee_sortby>
        </vsap>
      </xsl:if>
      <vsap type='user:prefs:load' />
      <vsap type='webmail:addressbook:load' />
      <vsap type='webmail:distlist:list' />
      <vsap type='webmail:options:fetch'>
        <sel_addressee_order/>
        <sel_addressee_sortby/>
      </vsap>
    </vsap>
  </xsl:with-param>
</xsl:call-template>

<!-- if that's all done, we just show the page -->
<showpage />

</meta>
</xsl:template>
</xsl:stylesheet>
