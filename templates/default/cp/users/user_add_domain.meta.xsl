<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../../global.meta.xsl" />
<xsl:import href="../cp_global.meta.xsl" />
<xsl:template match="/">
<meta>

<xsl:call-template name="auth">
  <xsl:with-param name="require_class">sa</xsl:with-param>
</xsl:call-template>

<xsl:call-template name="cp_global"/>

<xsl:choose>
  <xsl:when test="string(/cp/form/cancel)">
    <redirect>
      <path>cp/users/index.xsl</path>
    </redirect>
  </xsl:when>
  <xsl:when test="string(/cp/form/save)">
    <redirect>
      <path>cp/users/user_add_preview.xsl</path>
    </redirect>
  </xsl:when>
  <xsl:when test="/cp/form/previous">
    <xsl:choose>
      <xsl:when test="string(/cp/form/checkboxUserMail)">
        <redirect>
          <path>cp/users/user_add_mail.xsl</path>
        </redirect>
      </xsl:when>
      <xsl:otherwise>
        <redirect>
          <path>cp/users/user_add_profile.xsl</path>
        </redirect>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:when>
</xsl:choose>

<showpage />

</meta>
</xsl:template>
</xsl:stylesheet>
