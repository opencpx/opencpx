<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../cp_global.xsl" />

<xsl:variable name="message">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='error']/code='100'">
      <xsl:copy-of select="/cp/strings/oneclick_permission_denied" />
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='error']/code='102'">
      <xsl:copy-of select="/cp/strings/oneclick_invalid_installer_path" />
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='error']/code='103'">
      <xsl:copy-of select="/cp/strings/oneclick_installer_failed" />
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='error']/code='104'">
      <xsl:copy-of select="/cp/strings/oneclick_not_authorized" />
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='error']/code='105'">
      <xsl:copy-of select="/cp/strings/oneclick_unknown" />
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

<xsl:variable name="user_custom_error">
  <xsl:for-each select="/cp/vsap/vsap[@type='error']">
    <xsl:if test="./code = 'USER_CUSTOM'">
      <xsl:value-of select="./message" />
    </xsl:if>
  </xsl:for-each>
</xsl:variable>

<xsl:template name="success_display">
  <xsl:variable name="succeed_img">
    <xsl:value-of select="/cp/strings/img_success" />
  </xsl:variable>

  <xsl:if test="/cp/vsap/vsap[@type='oneclick_install']/status='ok'">
    <table class="formview" border="0" cellspacing="0" cellpadding="0">
      <tr class="title">
        <td colspan="2"><xsl:value-of select="/cp/strings/oneclick_title" /></td>
      </tr>
      <tr class="instructionrow">
        <td colspan="2">
          <img src="{$succeed_img}" /><xsl:value-of select="/cp/strings/oneclick_success" />
        </td>
      </tr>
      <xsl:if test="/cp/vsap/vsap[@type='oneclick_install']/stdoutNode != ''">
      <tr class="roweven">
        <td colspan="2" class="contentwidth">
          <xsl:value-of select="/cp/vsap/vsap[@type='oneclick_install']/stdoutNode" disable-output-escaping="yes" />
        </td>
      </tr>
      </xsl:if>
    </table>
  </xsl:if>
</xsl:template>

<xsl:template name="failure_display">
  <xsl:if test="$user_custom_error != ''">
    <table class="formview" border="0" cellspacing="0" cellpadding="0">
      <tr class="title">
        <td colspan="2"><xsl:copy-of select="/cp/strings/oneclick_title" /></td>
      </tr>
      <tr class="instructionrow">
        <td colspan="2">
            <xsl:value-of select="$user_custom_error" />
        </td>
      </tr>
    </table>
  </xsl:if>
</xsl:template>

<xsl:template match="/">

<xsl:call-template name="bodywrapper">

  <xsl:with-param name="title">
    <xsl:copy-of select="/cp/strings/cp_title" /> : <xsl:copy-of select="/cp/strings/oneclick_title" />
  </xsl:with-param>

  <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_one_click" />
  <xsl:with-param name="feedback" select="$feedback" />
  <xsl:with-param name="breadcrumb">
    <breadcrumb>
      <section>
        <name><xsl:copy-of select="/cp/strings/bc_oneclick" /></name>
        <url>#</url>
        <image>Preferences</image>
      </section>
    </breadcrumb>
  </xsl:with-param>

</xsl:call-template>
</xsl:template>


<xsl:template name="content">

  <xsl:if test="/cp/vsap/vsap[@type='oneclick_install']/status='ok'">
    <xsl:call-template name="success_display" />
  </xsl:if>
  <xsl:if test="$user_custom_error != ''">
    <xsl:call-template name="failure_display" />
  </xsl:if>

</xsl:template>

</xsl:stylesheet>
