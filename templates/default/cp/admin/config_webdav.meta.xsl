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

    <xsl:call-template name="dovsap">
      <xsl:with-param name="vsap">
        <vsap>
          <xsl:choose>
            <xsl:when test="string(/cp/form/addUser)">
              <vsap type="app:webdav:user_add">
                <user><xsl:value-of select="/cp/form/add_user"/></user>
                <password><xsl:value-of select="/cp/form/add_password"/></password>
                <confirm_password><xsl:value-of select="/cp/form/add_confirm_password"/></confirm_password>
                <edit>0</edit>
              </vsap>
            </xsl:when>
            <xsl:when test="string(/cp/form/editUser)">
              <vsap type="app:webdav:user_add">
                <user><xsl:value-of select="/cp/form/edit_user"/></user>
                <password><xsl:value-of select="/cp/form/edit_password"/></password>
                <confirm_password><xsl:value-of select="/cp/form/edit_confirm_password"/></confirm_password>
                <edit>1</edit>
              </vsap>
            </xsl:when>
            <xsl:when test="string(/cp/form/removeUser)">
              <vsap type="app:webdav:user_remove">
                <xsl:for-each select="/cp/form/user_list">
                 <user><xsl:value-of select="."/></user>
                </xsl:for-each>
              </vsap>
            </xsl:when>
          </xsl:choose>
          <vsap type="app:webdav:user_list" />
        </vsap>
      </xsl:with-param>
    </xsl:call-template>

    <xsl:choose>
      <xsl:when test="string(/cp/form/addUser)">
        <xsl:if test="/cp/vsap/vsap[@type='app:webdav:user_add']/status = 'ok'">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">webdav_user_add_success</xsl:with-param>
          </xsl:call-template>
        </xsl:if>
      </xsl:when>
      <xsl:when test="string(/cp/form/editUser)">
        <xsl:if test="/cp/vsap/vsap[@type='app:webdav:user_add']/status = 'ok'">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">webdav_user_edit_success</xsl:with-param>
          </xsl:call-template>
        </xsl:if>
      </xsl:when>
      <xsl:when test="string(/cp/form/removeUser)">
        <xsl:if test="/cp/vsap/vsap[@type='app:webdav:user_remove']/status = 'ok'">
          <xsl:choose>
            <xsl:when test="count(/cp/form/user_list) = '1'">
              <xsl:call-template name="set_message">
                <xsl:with-param name="name">webdav_user_remove_success_single</xsl:with-param>
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="set_message">
                <xsl:with-param name="name">webdav_user_remove_success_plural</xsl:with-param>
              </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:if>
      </xsl:when>
    </xsl:choose>

    <xsl:if test="string(/cp/vsap/vsap[@type='error'])">
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='error']/code = 201">
          <xsl:choose>
            <xsl:when test="string(/cp/form/addUser)">
              <xsl:call-template name="set_message">
                <xsl:with-param name="name">webdav_user_add_failure</xsl:with-param>
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="set_message">
                <xsl:with-param name="name">webdav_user_edit_failure</xsl:with-param>
              </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error']/code = 202">
          <xsl:choose>
            <xsl:when test="count(/cp/form/user_list) = '1'">
              <xsl:call-template name="set_message">
                <xsl:with-param name="name">webdav_user_remove_failure_single</xsl:with-param>
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="set_message">
                <xsl:with-param name="name">webdav_user_remove_failure_plural</xsl:with-param>
              </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error']/code = 300">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">webdav_js_error_login_req</xsl:with-param>
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
            <xsl:with-param name="name">admin_password_js_error_password_fmt</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error']/code = 306">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">admin_password_js_error_password_match</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error']/code = 307">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">webdav_user_add_exists</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error']/code = 308">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">webdav_js_error_login_fmt_chars</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error']/code = 309">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">webdav_js_error_login_fmt_start</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
      </xsl:choose>
    </xsl:if>

    
    <showpage />

  </meta>
 </xsl:template>
</xsl:stylesheet>
