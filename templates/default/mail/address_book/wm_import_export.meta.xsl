<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../../global.meta.xsl" />
<xsl:template match="/">
<meta>

<!-- run auth code -->
<xsl:call-template name="auth">
  <xsl:with-param name="require_mail">1</xsl:with-param>
  <xsl:with-param name="require_webmail">1</xsl:with-param>
</xsl:call-template>

<xsl:call-template name="dovsap">
  <xsl:with-param name="vsap">
    <vsap>
      <xsl:choose>
        <xsl:when test="string(/cp/form/import)">
          <vsap type="webmail:addressbook:import">
            <file_name><xsl:value-of select="/cp/request/uploaded_file" /></file_name>
            <file_type><xsl:value-of select="/cp/form/import_format"/></file_type>
            <encoding><xsl:value-of select="/cp/form/import_encoding"/></encoding>
          </vsap>
        </xsl:when>
        <xsl:when test="string(/cp/form/export)">
          <vsap type="webmail:addressbook:export">
            <file_type><xsl:value-of select="/cp/form/export_format"/></file_type>
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
  <xsl:when test="string(/cp/form/import) or string(/cp/form/export) or string(/cp/form/cancel)">
    <redirect>
      <path>mail/address_book/wm_addresses.xsl</path>
    </redirect>
  </xsl:when>
  <xsl:otherwise>
    <showpage />
  </xsl:otherwise>
</xsl:choose>

</meta>
</xsl:template>
</xsl:stylesheet>
