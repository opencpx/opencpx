<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:import href="../../global.meta.xsl"/>
  <xsl:import href="../cp_global.meta.xsl"/>
  <xsl:template match="/">
  <meta>

    <xsl:call-template name="auth">
      <xsl:with-param name="require_class">sa</xsl:with-param>
      <xsl:with-param name="require_cloud">1</xsl:with-param>
    </xsl:call-template>

    <xsl:call-template name="cp_global"/>

    <xsl:if test="string(/cp/form/switch)">
      <xsl:call-template name="dovsap">
        <xsl:with-param name="vsap">
          <vsap>
            <vsap type="sys:account:self_manage:request">
              <admin_password><xsl:value-of select="/cp/form/old_password"/></admin_password>
              <root_password><xsl:value-of select="/cp/form/new_password"/></root_password>
              <confirm_password><xsl:value-of select="/cp/form/new_password2"/></confirm_password>
            </vsap>
          </vsap>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:if>

    <xsl:if test="string(/cp/form/switch) and (/cp/vsap/vsap[@type='sys:account:switch']/status = 'ok')">
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">server_selfmanaged_switch_success</xsl:with-param>
      </xsl:call-template>
      <redirect>
        <path>cp/admin/services.xsl</path>
      </redirect>
    </xsl:if>

    <xsl:if test="string(/cp/vsap/vsap[@type='error'])">
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='error']/code = 100">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">selfmanaged_permission_denied</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error']/code = 200">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">admin_password_js_error_password_blank</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error']/code = 201">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">admin_password_js_error_password_req</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error']/code = 202">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">admin_password_js_error_password_fmt</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error']/code = 203">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">admin_password_js_error_password_match</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error']/code = 204">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">server_selfmanaged_adminpassword_invalid</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error']/code = 205">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">selfmanaged_failed_provision_connection</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error']/code = ''">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">selfmanaged_generic_fail</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">selfmanaged_unknown_error</xsl:with-param>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>

    <showpage/>

  </meta>
 </xsl:template>
</xsl:stylesheet>
