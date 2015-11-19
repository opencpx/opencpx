<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../cp_global.xsl" />

<!--desc_ascending and desc_descending-->

<xsl:variable name="message"/>

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
      <xsl:copy-of select="/cp/strings/cp_title" />
      v<xsl:value-of select="/cp/vsap/vsap[@type='auth']/version" /> :
      <xsl:copy-of select="cp/strings/bc_system_admin_view_package" /> : 
      <xsl:value-of select="/cp/vsap/vsap[@type='sys:package:info']/name"/>
    </xsl:with-param>
    <xsl:with-param name="formaction">packages.xsl</xsl:with-param>
    <xsl:with-param name="feedback" select="$feedback" />
    <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_admin_manage_packages" />
    <xsl:with-param name="help_short" select="/cp/strings/system_admin_hlp_short" />
    <xsl:with-param name="help_long"><xsl:copy-of select="/cp/strings/system_admin_hlp_long" /></xsl:with-param>
    <xsl:with-param name="breadcrumb">
      <breadcrumb>
        <section>
          <name><xsl:copy-of select="/cp/strings/bc_system_admin_packages" /></name>
          <url>packages.xsl</url>
        </section>
        <section>
          <name><xsl:copy-of select="cp/strings/bc_system_admin_view_package" /></name>
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
          <td colspan="2"><xsl:value-of select="/cp/strings/view_software_package"/>&#160;<xsl:value-of select="/cp/vsap/vsap[@type='sys:package:info']/name"/></td>
        </tr>

        <tr class="rowodd">
          <td class="label"><xsl:value-of select="/cp/strings/package_summary"/></td>
          <td class="contentwidth"><xsl:value-of select="/cp/vsap/vsap[@type='sys:package:info']/summary"/></td>
        </tr>

        <tr class="roweven">
          <td class="label"><xsl:value-of select="/cp/strings/package_description"/></td>
          <td class="contentwidth"><xsl:value-of select="/cp/vsap/vsap[@type='sys:package:info']/description"/></td>
        </tr>

        <tr class="rowodd">
          <td class="label"><xsl:value-of select="/cp/strings/package_version"/></td>
          <td class="contentwidth"><xsl:value-of select="/cp/vsap/vsap[@type='sys:package:info']/version"/></td>
        </tr>

        <xsl:if test="string(/cp/vsap/vsap[@type='sys:package:info']/installdate)">
         <tr class="roweven">
          <td class="label"><xsl:value-of select="/cp/strings/package_install_date"/></td>
          <td class="contentwidth">
            <xsl:call-template name="display_date">
             <xsl:with-param name="date" select="/cp/vsap/vsap[@type='sys:package:info']/installdate"/>
            </xsl:call-template>
          </td>
         </tr>
        </xsl:if>

        <xsl:if test="string(/cp/vsap/vsap[@type='sys:package:info']/builddate)">
         <tr class="rowodd">
          <td class="label"><xsl:value-of select="/cp/strings/package_build_date"/></td>
          <td class="contentwidth">
            <xsl:call-template name="display_date">
             <xsl:with-param name="date" select="/cp/vsap/vsap[@type='sys:package:info']/builddate"/>
            </xsl:call-template>
          </td>
         </tr>
        </xsl:if>

        <xsl:if test="string(/cp/vsap/vsap[@type='sys:package:info']/size)">
         <tr class="roweven">
          <td class="label"><xsl:value-of select="/cp/strings/package_size"/></td>
          <td class="contentwidth">
            <xsl:call-template name="format_bytes">
             <xsl:with-param name="bytes" select="/cp/vsap/vsap[@type='sys:package:info']/size"/>
            </xsl:call-template>
          </td>
         </tr>
        </xsl:if>

        <xsl:if test="string(/cp/vsap/vsap[@type='sys:package:info']/group)">
         <tr class="rowodd">
          <td class="label"><xsl:value-of select="/cp/strings/package_group"/></td>
          <td class="contentwidth"><xsl:value-of select="/cp/vsap/vsap[@type='sys:package:info']/group"/></td>
         </tr>
        </xsl:if>

        <tr class="roweven">          
          <td class="label"><xsl:value-of select="/cp/strings/package_dependencies"/></td>
          <td class="contentwidth">
            <xsl:if test="count(/cp/vsap/vsap[@type='sys:package:info']/dependencies/package) = 0"><xsl:value-of select="/cp/strings/package_none"/></xsl:if>
            <xsl:for-each select="/cp/vsap/vsap[@type='sys:package:info']/dependencies/package">
              <xsl:value-of select="."/><br/>
            </xsl:for-each>
          </td>
        </tr>
        <tr class="rowodd">          
          <td class="label"><xsl:value-of select="/cp/strings/package_required_by"/></td>
          <td class="contentwidth">
            <xsl:if test="count(/cp/vsap/vsap[@type='sys:package:info']/required_by/package) = 0"><xsl:value-of select="/cp/strings/package_none"/></xsl:if>
            <xsl:for-each select="/cp/vsap/vsap[@type='sys:package:info']/required_by/package">
              <xsl:value-of select="."/><br/>
            </xsl:for-each>
          </td>
        </tr>
        <tr class="controlrow">
          <td colspan="2"><span class="floatright"><input type="button" name="back" value="{/cp/strings/btn_back}" onClick="history.back()" /></span></td>
        </tr>
      </table>

</xsl:template>

</xsl:stylesheet>
