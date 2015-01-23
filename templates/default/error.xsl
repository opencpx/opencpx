<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="global.xsl" />
<xsl:output method="html" indent="yes" />

  <xsl:variable name="formaction">/ControlPanel/index.xsl</xsl:variable>

  <xsl:template match="/">
    <html>
    <title>VSAP Parse Error</title>
    <head>
      <link rel="stylesheet" type="text/css" href="{/cp/strings/stylesheet}" />
    </head>

    <body topmargin="0" leftmargin="0" marginheight="0" marginwidth="0">
      <form name="FormName" action="{$formaction}" method="post">
        <input name="back" type="button" value="Go Back" onClick="history.back(); return false;" />
        <br />
        An error occurred. Please contact support.
        <br />
        VSAP Parse error: [<xsl:value-of select="/cp/vsap_parse_error" />]
        <br />

        <xsl:for-each select="/cp/vsap[@type='error']">
          VSAP Error: [<xsl:copy-of select="." />]
          <br />
        </xsl:for-each>
      </form>
    </body>

    </html>

  </xsl:template>

</xsl:stylesheet>
