<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../cp_global.xsl" />

<xsl:template match="/">
  <xsl:call-template name="blankbodywrapper">
    <xsl:with-param name="title">
      <xsl:copy-of select="/cp/strings/cp_title"/>
      v<xsl:value-of select="/cp/vsap/vsap[@type='auth']/version" /> :
      <xsl:copy-of select="/cp/strings/bc_system_admin_log" /> : 
      <xsl:value-of select="/cp/form/domain"/>
    </xsl:with-param>
    <xsl:with-param name="formaction">logview.xsl</xsl:with-param>
    <xsl:with-param name="formname">specialwindow</xsl:with-param>
    <xsl:with-param name="onload">
      <xsl:if test="string(/cp/form/archive_now)">window.opener.location='<xsl:value-of select="$base_url"/>/cp/admin/loglist.xsl?domain=<xsl:value-of select="/cp/form/domain"/>&amp;sort=<xsl:value-of select="/cp/form/sort"/>&amp;order=<xsl:value-of select="/cp/form/order"/>';window.close()</xsl:if>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

      <input type="hidden" name="path" value="{/cp/form/path}"/>
      <input type="hidden" name="domain" value="{/cp/form/domain}"/>
      <input type="hidden" name="sort" value="{/cp/form/sort}"/>
      <input type="hidden" name="order" value="{/cp/form/order}"/>
      <table class="controlbar" border="0" cellspacing="0" cellpadding="0">
        <tr>
          <td>
            <span class="floatright">
              <input type="button" name="download_file" value="{cp/strings/log_btn_download}" onClick="window.location='{$base_url}/cp/admin/loglist.xsl/VSAPDOWNLOAD/?path={/cp/form/path}&amp;currentUser={/cp/vsap/vsap[@type='auth']/username}&amp;action=download&amp;domain={/cp/form/domain}'"/>
              <input type="button" name="close_window" value="{cp/strings/log_btn_close}" onClick="window.close()"/>
            </span>
          </td>
        </tr>
      </table>
      <table class="printableview" border="0" cellspacing="0" cellpadding="0">
        <tr>
          <td><xsl:value-of select="/cp/strings/log_view_tail_of"/>&#160;<strong><xsl:value-of select="/cp/form/path"/></strong><br/>
              <xsl:value-of select="/cp/strings/log_full_size"/>&#160;
              <xsl:call-template name="format_bytes">
                <xsl:with-param name="bytes" select="/cp/form/size"/>
              </xsl:call-template>
          </td>
        </tr>
        <tr>
          <td>
            <pre>
              <xsl:call-template name="remove_2lf">
                <xsl:with-param name="content" select="/cp/vsap/vsap[@type='sys:logs:show']/content"/>
              </xsl:call-template>
            </pre>
          </td>
        </tr>
      </table>

</xsl:template>

<xsl:template name="remove_2lf">
  <xsl:param name="content"/>
  <xsl:choose>
    <xsl:when test="starts-with($content, '&#xA;')">
      <xsl:call-template name="remove_2lf">
        <xsl:with-param name="content" select="substring($content,2)"/>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$content"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

</xsl:stylesheet>
