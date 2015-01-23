<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../global.meta.xsl" />
<xsl:import href="cp_global.meta.xsl" />
<xsl:template match="/">
<meta>

<xsl:call-template name="auth" />
<xsl:call-template name="cp_global"/>

<xsl:variable name="user_name">
  <xsl:value-of select="/cp/vsap/vsap[@type='auth']/username" />
</xsl:variable>

<showpage />

</meta>
</xsl:template>
</xsl:stylesheet>
