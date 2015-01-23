<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
  xmlns:exslt="http://exslt.org/common"
  exclude-result-prefixes="exslt">

<xsl:import href="../cp_global.xsl" />

<xsl:variable name="message">
  <xsl:choose>
    <xsl:when test="/cp/msgs/msg[@name='profile_shell_change_success']">
      <xsl:copy-of select="/cp/strings/profile_shell_change_success" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='profile_shell_change_error']">
      <xsl:copy-of select="/cp/strings/profile_shell_change_error" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='profile_shell_invalid']">
      <xsl:copy-of select="/cp/strings/profile_shell_invalid" />
    </xsl:when>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="feedback">
  <xsl:if test="$message != ''">
    <xsl:call-template name="feedback_table">
      <xsl:with-param name="image">
        <xsl:choose>
          <xsl:when test="/cp/vsap/vsap[@type='error']">error</xsl:when>
          <xsl:otherwise>success</xsl:otherwise>
        </xsl:choose>
      </xsl:with-param>
      <xsl:with-param name="message">
        <xsl:copy-of select="$message" />
      </xsl:with-param>
    </xsl:call-template>
  </xsl:if>
</xsl:variable>

<xsl:template match="/">
<xsl:call-template name="bodywrapper">

  <xsl:with-param name="title">
    <xsl:copy-of select="/cp/strings/cp_title" /> : <xsl:copy-of select="/cp/strings/bc_profile" /> : <xsl:copy-of select="/cp/strings/bc_profile_shell" />
  </xsl:with-param>

  <xsl:with-param name="formaction">shell.xsl</xsl:with-param>
  <xsl:with-param name="feedback"><xsl:copy-of select="$message" /></xsl:with-param>
  <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_view_profile" />
  <xsl:with-param name="help_short" select="/cp/strings/profile_shell_help_short" />
  <xsl:with-param name="help_long" select="/cp/strings/profile_shell_help_long" />
  <xsl:with-param name="breadcrumb">
    <breadcrumb>
      <section>
        <name><xsl:copy-of select="/cp/strings/bc_profile" /></name>
        <url><xsl:value-of select="$base_url" />/cp/profile/</url>
        <image>Profile</image>
      </section>
      <section>
        <name><xsl:copy-of select="/cp/strings/bc_profile_shell" /></name>
        <url>#</url>
        <image>Profile</image>
      </section>
    </breadcrumb>
  </xsl:with-param>

</xsl:call-template>
</xsl:template>

<xsl:template name="content">

        <table class="formview" border="0" cellspacing="0" cellpadding="0">
          <tr class="title">
            <td colspan="2"><xsl:copy-of select="/cp/strings/profile_shell_title" /></td>
          </tr>
          <tr class="instructionrow">
            <td colspan="2"><xsl:value-of select="/cp/strings/profile_shell_instr"/></td>
          </tr>
          <tr class="rowodd">
            <td class="label"><xsl:value-of select="/cp/strings/profile_shell_select_shell"/></td>
            <td class="contentwidth">
                <select name='shell' >
                <xsl:for-each select="/cp/vsap/vsap[@type='user:shell:list']/shell" >
                    <xsl:choose>
                        <xsl:when test='@current = 1'>
                            <option value='{path}' SELECTED='1'><xsl:value-of select='path'/></option>
                        </xsl:when>
                        <xsl:otherwise>
                            <option value='{path}'><xsl:value-of select='path'/></option>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
                </select>
            </td>
          </tr>
          <tr class="controlrow">
            <td colspan="2">
                <span class="floatright">
                <input type="submit" name="save" value="{/cp/strings/profile_shell_save_btn}" />
                <input type="submit" name="cancel" value="{/cp/strings/profile_shell_cancel_btn}" />
                </span>
            </td>
          </tr>
        </table>

</xsl:template>

</xsl:stylesheet>

