<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../../global.meta.xsl" />
<xsl:import href="../cp_global.meta.xsl" />

<xsl:template match="/">
<meta>

<xsl:call-template name="auth" />
<xsl:call-template name="cp_global" />

<xsl:choose>
  <xsl:when test="string(/cp/form/save)">
    <!-- Save posted options to disk -->
    <xsl:call-template name="dovsap">
      <xsl:with-param name="vsap">
        <vsap>
          <vsap type="user:password:change">
            <old_password><xsl:value-of select="/cp/form/old_password" /></old_password>
            <new_password><xsl:value-of select="/cp/form/new_password" /></new_password>
            <new_password2><xsl:value-of select="/cp/form/new_password2" /></new_password2>
          </vsap>
        </vsap>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:when>
  <xsl:when test="string(/cp/form/cancel)">
    <redirect>
      <path>cp/profile/index.xsl</path>
    </redirect>
  </xsl:when>
</xsl:choose>


<xsl:if test="/cp/form/save">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='user:password:change']/status = 'ok'">
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">profile_password_change_success</xsl:with-param>
      </xsl:call-template>
      <redirect>
        <path>cp/profile/index.xsl</path>
      </redirect>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='error']/code = 100">
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">profile_password_new_missing</xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='error']/code = 101">
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">profile_password_new_not_matching</xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='error']/code = 102">
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">profile_password_change_error</xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='error']/code = 103">
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">profile_password_old_missing</xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='error']/code = 104">
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">profile_password_old_not_matching</xsl:with-param>
      </xsl:call-template>
    </xsl:when>
  </xsl:choose>
</xsl:if>

<showpage />

</meta>
</xsl:template>
</xsl:stylesheet>
