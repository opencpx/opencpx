<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="global.xsl" />

<xsl:variable name="feedback">
 <xsl:if test="/cp/vsap/vsap[@type='error']/code = 100">
  <xsl:call-template name="feedback_table">
   <xsl:with-param name="image">error</xsl:with-param>
   <xsl:with-param name="message"><xsl:copy-of select="/cp/strings/restart_apache_permission_denied"/></xsl:with-param>
  </xsl:call-template>
 </xsl:if>
</xsl:variable>

<xsl:template match="/">
 <html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <meta http-equiv="content-type" content="text/html;charset=UTF-8" />
    <title><xsl:value-of select="/cp/strings/lg_title" /> : <xsl:value-of select="/cp/strings/restart_apache_title" /></title>
    <link href="{/cp/strings/stylesheet}" type="text/css" rel="stylesheet" media="screen" />
  </head>
  <body onload="document.forms[0].username.focus();">
    <table id="headerlogin" width="100%" border="0" cellspacing="0" cellpadding="0">
      <tr>
        <td><a href="{$base_url}/cp/" title="Home"><img src="/cpimages/61logo.gif" alt="Control Panel" id="logoImg"/></a></td>
      </tr>
    </table>
    <table id="globalnav" border="0" cellspacing="0" cellpadding="0">
      <tr>
        <td class="navmenuwidth"><br />
        </td>
        <td></td>
        <td></td>
      </tr>
    </table>
    <table id="navandcontent" border="0" cellspacing="0" cellpadding="0">
      <tr>
        <td id="navbglogon" class="navbgwidth"><br />
        </td>
        <td id="contentbglogon" class="contentbgwidth">
          <!-- feedback table gets inserted here -->
          <xsl:copy-of select="$feedback" />

          <div id="workarea">
            <table class="logon" border="0" cellspacing="0" cellpadding="0">
              <tr class="title">
                <td><xsl:value-of select="/cp/strings/restart_apache_title" /></td>
              </tr>
              <tr class="rowodd">
                <td class="contentwidth"><xsl:value-of select="/cp/strings/restart_apache_required" /></td>
              </tr>
            </table>
            <br />
            <br />
          </div>
        </td>
      </tr>
    </table>
    <table id="footers" border="0" cellspacing="0" cellpadding="0">
      <tr>
        <td><xsl:copy-of select="/cp/strings/global_footer" /></td>
      </tr>
    </table>
    <p />
  </body>
 </html>
</xsl:template>
</xsl:stylesheet>
