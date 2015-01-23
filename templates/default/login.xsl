<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="global.xsl" />

<xsl:variable name="message">
  <xsl:choose>
    <!-- NOTE: We need a cookie error message! -->
    <!-- NOTE: also add javascript form validation -->
    <!-- NOTE: the first three cases are copied from Signature and have not been tested/verified -->
    <xsl:when test="/cp/vsap/vsap[@type='error' and @caller='auth']/code = 100">
      <xsl:call-template name="feedback_table">
        <xsl:with-param name="image">error</xsl:with-param>
        <xsl:with-param name="message" select="/cp/strings/lg_msg_bad" />
      </xsl:call-template>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='error' and @caller='auth']/code = 101">
      <xsl:call-template name="feedback_table">
        <xsl:with-param name="image">error</xsl:with-param>
        <xsl:with-param name="message" select="/cp/strings/lg_msg_timeout" />
      </xsl:call-template>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='error' and @caller='auth']/code = 103">
      <xsl:call-template name="feedback_table">
        <xsl:with-param name="image">error</xsl:with-param>
        <xsl:with-param name="message" select="/cp/strings/lg_msg_nokeyfile" />
      </xsl:call-template>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='error' and @caller='auth']/code = 104">
      <xsl:call-template name="feedback_table">
        <xsl:with-param name="image">error</xsl:with-param>
        <xsl:with-param name="message" select="/cp/strings/lg_msg_homegone" />
      </xsl:call-template>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='error' and @caller='auth']/code = 105">
      <xsl:call-template name="feedback_table">
        <xsl:with-param name="image">error</xsl:with-param>
        <xsl:with-param name="message" select="/cp/strings/lg_msg_homeperm" />
      </xsl:call-template>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='error' and @caller='auth']/code = 200">
      <xsl:call-template name="feedback_table">
        <xsl:with-param name="image">error</xsl:with-param>
        <xsl:with-param name="message" select="/cp/strings/lg_msg_restart_1" />
        <xsl:with-param name="message2" select="/cp/strings/lg_msg_restart_2" />
      </xsl:call-template>
    </xsl:when>
    <xsl:when test="boolean(/cp/form/username)">
      <xsl:call-template name="feedback_table">
        <xsl:with-param name="image">error</xsl:with-param>
        <xsl:with-param name="message" select="/cp/strings/lg_msg_bad" />
      </xsl:call-template>
    </xsl:when>
    <xsl:when test="boolean(/cp/form/logout)">
      <xsl:call-template name="feedback_table">
        <xsl:with-param name="image">success</xsl:with-param>
        <xsl:with-param name="message" select="/cp/strings/lg_msg_logout" />
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <!-- no default case. For now the feedback table will not show up on the page unless there is feedback to display -->
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:template match="/">
  <html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <meta http-equiv="content-type" content="text/html;charset=UTF-8" />
    <title><xsl:value-of select="/cp/strings/lg_title" /> : <xsl:value-of select="/cp/strings/lg_login_header" /></title>
    <link href="{/cp/strings/stylesheet}" type="text/css" rel="stylesheet" media="screen" />
  </head>
  <body onload="document.forms[0].username.focus();">
    <!-- NOTE: check for browser compliance before loading css, etc. Also check for javascript and cookies. See Login UCS p 3-4 -->
    <script src="{concat($base_url, '/allfunctions.js')}" language="JavaScript"></script>
    <form action="/ControlPanel{/cp/request/filename}" method="post" name="globalnav">

      <!-- Attempt to recreate the original request; useful if a session has expired or a 
           bookmark contains get variables (e.g. /ControlPanel/mail/wm_messages.xsl?folder=Trash) -->
      <xsl:apply-templates select="/cp/form/*" />

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
            <xsl:copy-of select="$message" />

            <div id="workarea">
              <table class="logon" border="0" cellspacing="0" cellpadding="0">
                <tr class="title">
                  <td colspan="2"><xsl:value-of select="/cp/strings/lg_login_header" /></td>
                </tr>
                <tr class="rowodd">
                  <td class="label"><xsl:value-of select="/cp/strings/lg_login" /></td>
                  <td class="contentwidth"><input type="text" name="username" size="36" /></td>
                </tr>
                <tr class="roweven">
                  <td class="label"><xsl:value-of select="/cp/strings/lg_password" /></td>
                  <td class="contentwidth"><input type="password" name="password" size="36" /></td>
                </tr>
                <tr class="controlrow">
                  <td colspan="2"><span class="floatright"><input type="submit" name="login_submit" value="{/cp/strings/lg_bt_login}" class="button" /></span></td>
                </tr>
              </table>
              <br />
              <br />
              <!-- call help table template -->
              <xsl:call-template name="help_table">
                <xsl:with-param name="help_short"><xsl:value-of select="/cp/strings/lg_hlp_short" /></xsl:with-param>
                <xsl:with-param name="help_long"><xsl:value-of select="/cp/strings/lg_hlp_long" /></xsl:with-param>
              </xsl:call-template>
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
    </form>
  </body>
</html>
</xsl:template>

<xsl:template match="/cp/form/*">
<input type="hidden" name="{name()}" value="{.}" />
</xsl:template>

<!-- Ignore logout input -->
<xsl:template match="/cp/form/logout">
</xsl:template>

<!-- Ignore login page input -->
<xsl:template match="/cp/form/username">
</xsl:template>
<xsl:template match="/cp/form/password">
</xsl:template>
<xsl:template match="/cp/form/login_submit">
</xsl:template>

</xsl:stylesheet>
