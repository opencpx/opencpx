<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:variable name="dir">
	<xsl:value-of select="/cp/vsap/vsap[@type='diskspace:list']/dir"/>
</xsl:variable>
<xsl:variable name="sz">
	<xsl:value-of select="/cp/vsap/vsap[@type='diskspace:list']/sz"/>
</xsl:variable>
<xsl:variable name="hdr">
        <xsl:value-of select="/cp/vsap/vsap[@type='diskspace:list']/hdr"/>
</xsl:variable>

<xsl:template match="/">

<html>
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
	<title>Control Panel</title>
	<style>
		TD.dir { width: 1.5em; font-family: helvetica, arial, sans-serif;
			 text-align: center; text-decoration: none; }
		INPUT.subDir { background-color: #FFF; border: none; cursor: pointer; padding: 0; }
	</style>
</head>

<body>
	<xsl:choose>
	<xsl:when test="$hdr != ''">
		<img src="/cpimages/file_dirspace.gif" title="{$hdr}"/>
	</xsl:when>
	<xsl:otherwise>
		<form name="dirForm" action="dirspace.xsl" method="post" enctype="multipart/form-data">
			<table border="1" cellspacing="0" cellpadding="0">
			<input name="sz" type="hidden" value="{$sz}"/>
			<input name="dir" type="hidden" value="{$dir}"/>
			<xsl:for-each select="/cp/vsap/vsap[@type='diskspace:list']/nodes/node[position() mod $sz=1]">
				<tr valign="top">
				<xsl:for-each select=".|following-sibling::node[position() &lt; $sz]">
					<td class="dir">
						<xsl:choose>
						<xsl:when test="text() = 0"></xsl:when>
						<xsl:otherwise>
						<input type="submit" class="subDir" name="units" value="{.}"/>
						</xsl:otherwise>
						</xsl:choose>
					</td>
				</xsl:for-each>
				</tr>
			</xsl:for-each>
			</table>
		</form>
	</xsl:otherwise>
	</xsl:choose>
</body>
</html>

</xsl:template>
</xsl:stylesheet>
