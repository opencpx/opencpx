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
            <url_highlight>no</url_highlight><!-- hard coded for now (BUG04867) -->
            <messages_per_page><xsl:value-of select="/cp/form/messages_per_page" /></messages_per_page>
<!-- set tz_display to my until this has been fully implemented in webmail - see bug 4886 -->
            <tz_display>my</tz_display>
            <display_encoding><xsl:value-of select="/cp/form/display_encoding" /></display_encoding>
            <multipart_view><xsl:value-of select="/cp/form/multipart_view" /></multipart_view>
            <fetch_images_remote><xsl:value-of select="/cp/form/fetch_images_remote" /></fetch_images_remote>
            <fetch_images_local><xsl:value-of select="/cp/form/fetch_images_local" /></fetch_images_local>
            <attachment_view><xsl:value-of select="/cp/form/attachment_view" /></attachment_view>
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
