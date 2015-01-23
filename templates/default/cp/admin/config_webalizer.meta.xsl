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
        <path>cp/admin/applications.xsl</path>
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

    <!-- set new ACL settings? -->
    <xsl:variable name="saveACL">
      <xsl:choose>
        <xsl:when test="string(/cp/form/add) and string(/cp/form/allow_from)">1</xsl:when>
        <xsl:when test="string(/cp/form/remove)">1</xsl:when>
        <xsl:when test="string(/cp/form/afa)">1</xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- save changes to access control list file -->
    <xsl:if test="$saveACL = '1'">
      <xsl:call-template name="dovsap">
        <xsl:with-param name="vsap">
          <vsap>
            <vsap type="app:webalizer:config">
              <xsl:choose>
                <xsl:when test="string(/cp/form/afa)">
                  <allow_from_all><xsl:value-of select="/cp/form/afa"/></allow_from_all>
                </xsl:when>
                <xsl:when test="string(/cp/form/add)">
                  <allow_from><xsl:value-of select="/cp/form/allow_from"/></allow_from>
                </xsl:when>
                <xsl:when test="string(/cp/form/remove)">
                  <xsl:for-each select="/cp/form/allow_list">
                    <remove_from><xsl:value-of select="."/></remove_from>
                  </xsl:for-each>
                </xsl:when>
              </xsl:choose>
            </vsap>
          </vsap>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:if>

    <!-- save changes to config file -->
    <xsl:if test="string(/cp/form/save)">
      <xsl:call-template name="dovsap">
        <xsl:with-param name="vsap">
          <vsap>
            <vsap type="sys:configfile:save">
              <application>webalizer</application>
              <contents><xsl:value-of select="/cp/form/contents"/></contents>
            </vsap>
          </vsap>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:if>

    <!-- check save status -->
    <xsl:if test="($saveACL = '1') or string(/cp/form/save)">
      <xsl:choose>
        <xsl:when test="string(/cp/vsap/vsap[@type='error'])">
          <xsl:choose>
            <xsl:when test="string(/cp/form/save)">
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
                <xsl:otherwise>
                  <xsl:call-template name="set_message">
                    <xsl:with-param name="name">config_file_edit_failure</xsl:with-param>
                  </xsl:call-template>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
            <xsl:when test="($saveACL = '1')">
              <xsl:choose> 
                <xsl:when test="/cp/vsap/vsap[@type='error']/code = 306">
                  <xsl:call-template name="set_message">
                    <xsl:with-param name="name">admin_access_list_duplicate_IP</xsl:with-param>
                  </xsl:call-template>
                </xsl:when>
                <xsl:when test="/cp/vsap/vsap[@type='error']/code = 307">
                  <xsl:call-template name="set_message">
                    <xsl:with-param name="name">admin_access_list_failure</xsl:with-param>
                  </xsl:call-template>
                </xsl:when>
              </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="set_message">
                <xsl:with-param name="name">webalizer_settings_failure</xsl:with-param>
              </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="($saveACL = '1') and /cp/vsap/vsap[@type='app:webalizer:config']/status = 'ok'">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">admin_access_control_updated</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:if test="string(/cp/form/save)">
            <xsl:call-template name="set_message">
              <xsl:with-param name="name">config_file_edit_success</xsl:with-param>
            </xsl:call-template>
            <redirect>
              <path>cp/admin/applications.xsl</path>
            </redirect>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>

    <!-- load up config settings and backups -->
    <xsl:call-template name="dovsap">
      <xsl:with-param name="vsap">
        <vsap>
          <vsap type="sys:configfile:fetch">
            <application>webalizer</application>
          </vsap>
          <vsap type="sys:configfile:list_backups">
            <application>webalizer</application>
            <brief/>
          </vsap>
          <vsap type="app:webalizer:status" />
        </vsap>
      </xsl:with-param>
    </xsl:call-template>

    <showpage/>

  </meta>
 </xsl:template>
</xsl:stylesheet>
