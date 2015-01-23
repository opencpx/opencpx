<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
 <xsl:import href="../../global.meta.xsl"/>
 <xsl:import href="../cp_global.meta.xsl"/>
 <xsl:template match="/">
  <meta>

    <xsl:if test="string(/cp/form/cancel)">
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">feedback_cancel</xsl:with-param>
      </xsl:call-template>
      <redirect>
        <xsl:choose>
          <xsl:when test="(/cp/form/application = 'dovecot') or
                          (/cp/form/application = 'ftp') or
                          (/cp/form/application = 'httpd') or
                          (/cp/form/application = 'postfix')">
            <path>cp/admin/services.xsl</path>
          </xsl:when>
          <xsl:otherwise>
            <path>cp/admin/applications.xsl</path>
          </xsl:otherwise>
        </xsl:choose>
      </redirect>
    </xsl:if>

    <xsl:if test="string(/cp/form/recover)">
      <redirect>
        <path>cp/admin/config_file_restore.xsl</path>
      </redirect>
    </xsl:if>

    <xsl:call-template name="auth">
      <xsl:with-param name="require_class">sa</xsl:with-param>
      <xsl:with-param name="require_cloud">1</xsl:with-param>
    </xsl:call-template>

    <xsl:call-template name="cp_global"/>

    <xsl:if test="string(/cp/form/save)">
      <xsl:call-template name="dovsap">
        <xsl:with-param name="vsap">
          <vsap>
            <vsap type="sys:configfile:save">
              <application><xsl:value-of select="/cp/form/application"/></application>
              <config_path><xsl:value-of select="/cp/form/config_path"/></config_path>
              <contents><xsl:value-of select="/cp/form/contents"/></contents>
            </vsap>
          </vsap>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:if>

    <xsl:if test="not(/cp/form/save)">
      <xsl:call-template name="dovsap">
        <xsl:with-param name="vsap">
          <vsap>
            <vsap type="sys:configfile:fetch">
              <application><xsl:value-of select="/cp/form/application"/></application>
            </vsap>
          </vsap>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:if>

    <xsl:call-template name="dovsap">
      <xsl:with-param name="vsap">
        <vsap>
          <vsap type="sys:configfile:list_backups">
            <application><xsl:value-of select="/cp/form/application"/></application>
            <xsl:choose>
              <xsl:when test="string(/cp/form/config_path)">
                <config_path><xsl:value-of select="/cp/form/config_path"/></config_path>
              </xsl:when>
              <xsl:when test="count(/cp/vsap/vsap[@type='sys:configfile:fetch']/file) &gt; 1">
                <config_path><xsl:value-of select="/cp/vsap/vsap[@type='sys:configfile:fetch']/file[1]/path"/></config_path>
              </xsl:when>
            </xsl:choose>
            <brief/>
          </vsap>
        </vsap>
      </xsl:with-param>
    </xsl:call-template>

    <xsl:if test="string(/cp/form/save)">

      <xsl:variable name="success_msg">
        <xsl:if test="/cp/vsap/vsap[@type='sys:configfile:save']/status = 'ok'">
          <xsl:choose>
            <xsl:when test="/cp/vsap/vsap[@type='sys:configfile:save']/service_warning != ''">config_file_edit_success_warning</xsl:when>
            <xsl:otherwise>config_file_edit_success</xsl:otherwise>
          </xsl:choose>
        </xsl:if>
      </xsl:variable>

      <xsl:if test="/cp/vsap/vsap[@type='sys:configfile:save']/status = 'ok'">
        <xsl:call-template name="set_message">
          <xsl:with-param name="name"><xsl:copy-of select="$success_msg"/></xsl:with-param>
        </xsl:call-template>
        <redirect>
          <xsl:choose>
            <xsl:when test="(/cp/form/application = 'dovecot') or
                            (/cp/form/application = 'ftp') or
                            (/cp/form/application = 'httpd') or
                            (/cp/form/application = 'postfix')">
              <path>cp/admin/services.xsl</path>
            </xsl:when>
            <xsl:otherwise>
              <path>cp/admin/applications.xsl</path>
            </xsl:otherwise>
          </xsl:choose>
        </redirect>
      </xsl:if>
    </xsl:if>

    <xsl:if test="string(/cp/vsap/vsap[@type='error'])">
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='error']/code = 101">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">config_file_application_missing</xsl:with-param>
          </xsl:call-template>
          <redirect>
            <path>cp/admin/applications.xsl</path>
          </redirect>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error']/code = 102">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">application_not_supported</xsl:with-param>
          </xsl:call-template>
          <redirect>
            <path>cp/admin/applications.xsl</path>
          </redirect>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error']/code = 103">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">config_file_path_missing</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error']/code = 104">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">config_file_contents_missing</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error']/code = 105">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">config_file_write_failed</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error']/code = 110">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">config_file_contents_invalid</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">config_file_edit_failure</xsl:with-param>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>

   <showpage/>

  </meta>
 </xsl:template>
</xsl:stylesheet>
