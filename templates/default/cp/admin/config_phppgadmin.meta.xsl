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

    <xsl:call-template name="auth">
      <xsl:with-param name="require_class">sa</xsl:with-param>
      <xsl:with-param name="require_cloud">1</xsl:with-param>
    </xsl:call-template>

    <xsl:call-template name="cp_global"/>

    <xsl:variable name="saveConfig">
      <xsl:choose>
        <xsl:when test="string(/cp/form/save)">1</xsl:when>
        <xsl:when test="string(/cp/form/add) and string(/cp/form/allow_from)">1</xsl:when>
        <xsl:when test="string(/cp/form/remove)">1</xsl:when>
        <xsl:when test="string(/cp/form/afa)">1</xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

     <!-- ACL settings -->
    <xsl:variable name="saveACL">
      <xsl:choose>
        <xsl:when test="string(/cp/form/add) and string(/cp/form/allow_from)">1</xsl:when>
        <xsl:when test="string(/cp/form/remove)">1</xsl:when>
        <xsl:when test="string(/cp/form/afa)">1</xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:call-template name="dovsap">
      <xsl:with-param name="vsap">
        <vsap>
          <xsl:if test="$saveConfig='1'">
            <vsap type="app:phppgadmin:config">
              <xsl:choose>
                <xsl:when test="string(/cp/form/afa)">
                  <allow_from_all><xsl:value-of select="/cp/form/afa"/></allow_from_all>
                </xsl:when>
                <xsl:when test="string(/cp/form/save)">
                  <password><xsl:value-of select="/cp/form/new_password"/></password>
                  <confirm_password><xsl:value-of select="/cp/form/new_password2"/></confirm_password>
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
          </xsl:if>
          <vsap type="app:phppgadmin:status" />
        </vsap>
      </xsl:with-param>
    </xsl:call-template>

    <xsl:choose>
      <xsl:when test="string(/cp/form/save)">
        <xsl:if test="/cp/vsap/vsap[@type='app:phppgadmin:config']/status = 'ok'">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">phppgadmin_postgresql_password_change_success</xsl:with-param>
          </xsl:call-template>
        </xsl:if>
      </xsl:when>
      <xsl:when test="$saveACL = '1'">
        <xsl:if test="/cp/vsap/vsap[@type='app:phppgadmin:config']/status = 'ok'">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">admin_access_control_updated</xsl:with-param>
          </xsl:call-template>
        </xsl:if>
      </xsl:when>
    </xsl:choose>

    <xsl:if test="string(/cp/vsap/vsap[@type='error'])">
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='error']/code = 200">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">postgresql_settings_password_change_error</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error']/code = 301">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">admin_password_js_error_password_req</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error']/code = 302">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">admin_password_js_error_password_fmt</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error']/code = 303">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">admin_password_js_error_password_fmt</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error']/code = 304">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">admin_password_js_error_password_fmt</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error']/code = 305">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">admin_password_js_error_password_match</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
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
    </xsl:if>

    <showpage />

  </meta>
 </xsl:template>
</xsl:stylesheet>

