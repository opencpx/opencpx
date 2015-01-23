<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../cp_global.xsl" />

<xsl:template match="/">
  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title"><xsl:copy-of select="/cp/strings/cp_title" /> : <xsl:copy-of select="/cp/strings/bc_system_shell" /></xsl:with-param>
    <xsl:with-param name="formaction">shell.xsl</xsl:with-param>
    <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_global_tools_shell" />
    <xsl:with-param name="help_short" select="/cp/strings/system_admin_hlp_short" />
    <xsl:with-param name="help_long"><xsl:copy-of select="/cp/strings/system_admin_hlp_long" /></xsl:with-param>
    <xsl:with-param name="breadcrumb">
      <breadcrumb>
        <section>
          <name><xsl:copy-of select="/cp/strings/bc_system_shell" /></name>
          <url>#</url>
          <image>GlobalTools</image>
        </section>
      </breadcrumb>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

      <table class="formview" border="0" cellspacing="0" cellpadding="0">
        <tr class="title">
          <td colspan="2"><xsl:value-of select="/cp/strings/admin_access_shell" /></td>
        </tr>
        <xsl:choose>
         <xsl:when test="/cp/vsap/vsap[@type='sys:ssh:status']/ssh1_status='enabled'">
          <tr class="rowodd">
           <td class="label"><xsl:value-of select="/cp/strings/admin_shell_window" /></td>
           <td class="contentwidth">
            <applet ARCHIVE="jta25.jar" CODE="de.mud.jta.Applet" WIDTH="{/cp/strings/shell_applet_width}" HEIGHT="{/cp/strings/shell_applet_height}"><PARAM NAME="config" VALUE="applet.conf"/>
              <br/><xsl:copy-of select="/cp/strings/missing_java_support/*" /><br/>
            </applet>
           </td>
          </tr>
          <tr class="controlrow">
           <td colspan="2"><span class="floatright">
            <input type="button" name="refresh" value="{/cp/strings/admin_shell_btn_restart}" onClick="history.go()"/>&#160;
            <input type="button" name="done" value="{/cp/strings/admin_shell_btn_done}" onClick="history.back()"/>
           </span></td>
          </tr>
         </xsl:when>
         <xsl:otherwise>
          <tr class="rowodd">
           <td class="label"><xsl:value-of select="/cp/strings/admin_shell_ssh1_disabled" /></td>
          </tr>
         </xsl:otherwise>
        </xsl:choose>
      </table> 

</xsl:template>

</xsl:stylesheet>
