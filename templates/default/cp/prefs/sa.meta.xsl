<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../../global.meta.xsl" />
<xsl:import href="../cp_global.meta.xsl" />
<xsl:template match="/">
<meta>

<xsl:call-template name="auth" />
<xsl:call-template name="cp_global" />

<xsl:call-template name="dovsap">
  <xsl:with-param name="vsap">
    <vsap>
      <xsl:choose>

        <xsl:when test="string(/cp/form/save)">
        <!-- Save posted options to disk -->
          <vsap type="user:prefs:save">
            <user_preferences>
              <sa_packages_per_page><xsl:value-of select="/cp/form/ppp" /></sa_packages_per_page>
            </user_preferences>
          </vsap>
          <!-- Load options to DOM -->
          <vsap type="user:prefs:load"/>
        </xsl:when>

        <xsl:otherwise>
          <!-- Load options to DOM -->
          <vsap type="user:prefs:load"/>
        </xsl:otherwise>

      </xsl:choose>
    </vsap>
  </xsl:with-param>
</xsl:call-template>

<showpage />

</meta>
</xsl:template>
</xsl:stylesheet>
