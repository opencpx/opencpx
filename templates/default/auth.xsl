<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

<xsl:output method="html" indent="yes" />

<!-- THIS PAGE SHOULD NEVER GET SHOWN!!
This page is only included for completeness. The auth.meta.xsl file
is used by the ControlPanel::FileTransfer module to authenticate the
user. This transformation should never result in a page shown to the
user (for uploads another transformation will happen later with the
real file) -->

<xsl:template match="/">

<html><head><title>Error!</title></head><body>Error!</body></html>

</xsl:template>

<!-- THIS PAGE SHOULD NEVER GET SHOWN!! -->

</xsl:stylesheet>
