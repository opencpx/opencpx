<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../../global.meta.xsl" />
<xsl:import href="../cp_global.meta.xsl" />

<xsl:template match="/">
<meta>

<xsl:call-template name="auth">
  <xsl:with-param name="require_shell">1</xsl:with-param>
</xsl:call-template>

<xsl:call-template name="cp_global" />

<xsl:choose>
  <xsl:when test="/cp/form/save">
    <!-- Save posted options to disk -->
    <xsl:call-template name="dovsap">
      <xsl:with-param name="vsap">
        <vsap>
          <vsap type="user:shell:change">
            <shell><xsl:value-of select="/cp/form/shell" /></shell>
          </vsap>
          <vsap type="user:shell:list"/>
        </vsap>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:when> 
  <xsl:when test="/cp/form/cancel">
    <redirect>
      <path>/cp/profile/index.xsl</path>
    </redirect>
  </xsl:when>
  <xsl:otherwise>
    <xsl:call-template name="dovsap">
      <xsl:with-param name="vsap">
        <vsap>
          <vsap type="user:shell:list"/>
        </vsap>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:otherwise>
</xsl:choose>

<xsl:if test="/cp/form/save">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='user:shell:change']/status = 'ok'">
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">profile_shell_change_success</xsl:with-param>
      </xsl:call-template>
      <redirect>
	      <path>cp/profile/index.xsl</path>
	    </redirect>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='error']/code = 200">
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">profile_shell_invalid</xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='error']/code = 201">
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">profile_shell_change_error</xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='error']/code = 501">
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">profile_shell_permission_denied</xsl:with-param>
      </xsl:call-template>
    </xsl:when>
  </xsl:choose>
</xsl:if>

<showpage />

</meta>
</xsl:template>
</xsl:stylesheet>
