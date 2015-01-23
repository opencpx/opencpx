<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
 <xsl:import href="../../global.meta.xsl"/>
 <xsl:import href="../cp_global.meta.xsl"/>
 <xsl:template match="/">
  <meta>

    <xsl:if test="string(/cp/form/done)">
      <redirect>
        <xsl:choose>
          <xsl:when test="/cp/form/application = 'mailman'">
            <path>cp/admin/config_mailman.xsl</path>
          </xsl:when>
          <xsl:when test="/cp/form/application = 'mysqld'">
            <path>cp/admin/config_mysql.xsl</path>
          </xsl:when>
          <xsl:when test="/cp/form/application = 'postgresql'">
            <path>cp/admin/config_postgresql.xsl</path>
          </xsl:when>
          <xsl:when test="/cp/form/application = 'webalizer'">
            <path>cp/admin/config_webalizer.xsl</path>
          </xsl:when>
          <xsl:otherwise>
            <path>cp/admin/config_file.xsl</path>
          </xsl:otherwise>
        </xsl:choose>
      </redirect>
    </xsl:if>

    <xsl:call-template name="auth">
      <xsl:with-param name="require_class">sa</xsl:with-param>
      <xsl:with-param name="require_cloud">1</xsl:with-param>
    </xsl:call-template>

    <xsl:call-template name="cp_global"/>

    <xsl:if test="/cp/form/action = 'restore'">
      <xsl:call-template name="dovsap">
        <xsl:with-param name="vsap">
          <vsap>
            <vsap type="sys:configfile:restore">
              <application><xsl:value-of select="/cp/form/application"/></application>
              <config_path><xsl:value-of select="/cp/form/config_path"/></config_path>
              <backup_version><xsl:value-of select="/cp/form/version"/></backup_version>
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
            <config_path><xsl:value-of select="/cp/form/config_path"/></config_path>
          </vsap>
        </vsap>
      </xsl:with-param>
    </xsl:call-template>

    <xsl:if test="/cp/form/action = 'restore'">
      <xsl:if test="/cp/vsap/vsap[@type='sys:configfile:restore']/status = 'ok'">
        <xsl:call-template name="set_message">
          <xsl:with-param name="name">config_file_restore_success</xsl:with-param>
        </xsl:call-template>
        <redirect>
          <xsl:choose>
            <xsl:when test="/cp/form/application = 'webalizer'">
              <path>cp/admin/config_webalizer.xsl</path>
            </xsl:when>
            <xsl:otherwise>
              <path>cp/admin/config_file.xsl</path>
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
          <redirect>
            <path>cp/admin/applications.xsl</path>
          </redirect>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error']/code = 106">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">config_file_version_missing</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error']/code = 107">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">config_file_version_invalid</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error']/code = 108">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">config_file_restore_failed</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error']/code = 109">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">config_file_path_invalid</xsl:with-param>
          </xsl:call-template>
          <redirect>
            <path>cp/admin/applications.xsl</path>
          </redirect>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">config_file_restore_failed</xsl:with-param>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>

   <showpage/>

  </meta>
 </xsl:template>
</xsl:stylesheet>
