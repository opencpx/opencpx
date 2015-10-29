<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../../global.meta.xsl" />
<xsl:import href="../cp_global.meta.xsl" />

<xsl:template match="/">
<meta>

<xsl:call-template name="auth">
  <xsl:with-param name="require_class">sa</xsl:with-param>
</xsl:call-template>

<xsl:call-template name="cp_global" />

<xsl:choose>
  <xsl:when test="string(/cp/form/save)">
    <!-- Save posted options to disk -->
    <xsl:call-template name="dovsap">
      <xsl:with-param name="vsap">
        <vsap>
          <vsap type="sys:ssl:cert_install">
            <domain><xsl:value-of select="/cp/form/domain" /></domain>
            <xsl:if test="/cp/form/applyto_apache"><applyto_apache>1</applyto_apache></xsl:if>
            <xsl:if test="/cp/form/applyto_dovecot"><applyto_dovecot>1</applyto_dovecot></xsl:if>
            <xsl:if test="/cp/form/applyto_postfix"><applyto_postfix>1</applyto_postfix></xsl:if>
            <xsl:if test="/cp/form/applyto_vsftpd"><applyto_vsftpd>1</applyto_vsftpd></xsl:if>
          </vsap>
        </vsap>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:when>
  <xsl:when test="string(/cp/form/cancel)">
    <redirect>
      <path>cp/domains/index.xsl</path>
    </redirect>
  </xsl:when>
  <xsl:otherwise>
    <xsl:call-template name="dovsap">
      <xsl:with-param name="vsap">
        <vsap>
          <vsap type="domain:list"/>
        </vsap>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:otherwise>
</xsl:choose>


<xsl:if test="/cp/form/save">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='sys:ssl:cert_install']/status = 'ok'">
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">domain_self_signed_cert_success</xsl:with-param>
      </xsl:call-template>
      <redirect>
        <path>cp/domains/index.xsl</path>
      </redirect>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='error']/code = 100">
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">domain_cert_error_permission_denied</xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='error']/code = 101">
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">domain_cert_error_domain_missing</xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='error']/code = 102">
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">domain_cert_error_openssl_failed</xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='error']/code = 103">
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">domain_cert_error_csr_file</xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='error']/code = 104">
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">domain_cert_error_cert_file</xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='error']/code = 105">
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">domain_cert_error_docroot_missing</xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='error']/code = 106">
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">domain_cert_error_validation_url</xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='error']/code = 110">
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">domain_cert_error_restart_service_failed</xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='error']/code = 111">
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">domain_cert_error_uninstall_inuse</xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">domain_cert_error_unknown_error</xsl:with-param>
      </xsl:call-template>
    </xsl:otherwise>
  </xsl:choose>
</xsl:if>

<showpage />

</meta>
</xsl:template>
</xsl:stylesheet>
