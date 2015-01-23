<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="global.meta.xsl" />

<!-- This .meta file is only used by the FileTransfer.pm module to make sure someone is authenticated -->

<xsl:template match="/">
<meta>

<xsl:call-template name="auth" />

<showpage />

</meta>
</xsl:template>
</xsl:stylesheet>
