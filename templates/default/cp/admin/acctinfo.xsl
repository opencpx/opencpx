<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../cp_global.xsl" />

<xsl:variable name="feedback">
  <xsl:if test="string(/cp/vsap/vsap[@type='error'])">
    <xsl:call-template name="feedback_table">
      <xsl:with-param name="image">error</xsl:with-param>
      <xsl:with-param name="message">
        <xsl:copy-of select="/cp/strings/acctinfo_get_error" />
      </xsl:with-param>
    </xsl:call-template>
  </xsl:if>
</xsl:variable>

<xsl:template match="/">
  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title">
      <xsl:copy-of select="/cp/strings/cp_title" />
      v<xsl:value-of select="/cp/vsap/vsap[@type='auth']/version" /> :
      <xsl:copy-of select="/cp/strings/bc_system_acctinfo" />
    </xsl:with-param>
    <xsl:with-param name="formaction">acctinfo.xsl</xsl:with-param>
    <xsl:with-param name="feedback" select="$feedback" />
    <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_admin_acctinfo" />
    <xsl:with-param name="help_short" select="/cp/strings/system_admin_hlp_short" />
    <xsl:with-param name="help_long"><xsl:copy-of select="/cp/strings/system_admin_hlp_long" /></xsl:with-param>
    <xsl:with-param name="breadcrumb">
      <breadcrumb>
        <section>
          <name><xsl:copy-of select="/cp/strings/bc_system_acctinfo" /></name>
          <url>#</url>
          <image>SystemAdministration</image>
        </section>
      </breadcrumb>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

      <table class="formview" border="0" cellspacing="0" cellpadding="0">
        <tr class="title">
          <td colspan="2"><xsl:value-of select="/cp/strings/acctinfo_header" />&#160;<xsl:value-of select="/cp/vsap/vsap[@type='auth']/username"/></td>
        </tr>
        <tr class="roweven">
          <td class="label"><xsl:value-of select="/cp/strings/acctinfo_server_name" /></td>
        <td class="contentwidth"><xsl:value-of select="/cp/vsap/vsap[@type='sys:info:get']/hostname"/></td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:value-of select="/cp/strings/acctinfo_ip" /></td>
          <td class="contentwidth">
            <xsl:for-each select="/cp/vsap/vsap[@type='domain:list_ips']/ip">
              <xsl:value-of select="."/><br/>
            </xsl:for-each>
          </td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:value-of select="/cp/strings/acctinfo_disk_usage" /></td>
          <td class="contentwidth">
            <xsl:value-of select="/cp/vsap/vsap[@type='diskspace']/used"/>&#160;<xsl:value-of select="/cp/vsap/vsap[@type='diskspace']/units"/>
            &#160;<xsl:value-of select="/cp/strings/acctinfo_of"/>&#160;
            <xsl:value-of select="/cp/vsap/vsap[@type='diskspace']/allocated"/>&#160;<xsl:value-of select="/cp/vsap/vsap[@type='diskspace']/units"/>
            &#160;(<xsl:value-of select="/cp/vsap/vsap[@type='diskspace']/percent"/>%)
          </td>
        </tr>
        <tr class="roweven">
          <td class="label"><xsl:value-of select="/cp/strings/acctinfo_open_files" /></td>
          <td class="contentwidth"><xsl:value-of select="/cp/vsap/vsap[@type='sys:info:get']/nofile"/>&#160;<xsl:value-of select="/cp/strings/acctinfo_of"/>&#160;<xsl:value-of select="/cp/vsap/vsap[@type='sys:info:get']/nofilelimit"/></td>
        </tr>
        <tr class="roweven">
          <td class="label"><xsl:value-of select="/cp/strings/acctinfo_max_proc" /></td>
          <td class="contentwidth"><xsl:value-of select="/cp/vsap/vsap[@type='sys:info:get']/noproc"/>&#160;<xsl:value-of select="/cp/strings/acctinfo_of"/>&#160;<xsl:value-of select="/cp/vsap/vsap[@type='sys:info:get']/noproclimit"/></td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:value-of select="/cp/strings/acctinfo_hosts" /></td>
          <td class="contentwidth"><xsl:value-of select="count(/cp/vsap/vsap[@type='domain:list']/domain)"/></td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:value-of select="/cp/strings/acctinfo_users" /></td>
          <td class="contentwidth"><xsl:value-of select="count(/cp/vsap/vsap[@type='user:list_brief']/user)"/></td>
        </tr>
      </table>

</xsl:template>

</xsl:stylesheet>
