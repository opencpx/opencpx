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
        <path>cp/admin/services.xsl</path>
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

    <!-- set new password -->
    <xsl:if test="string(/cp/form/new_password)">
      <xsl:call-template name="dovsap">
        <xsl:with-param name="vsap">
          <vsap>
            <vsap type="mysql:config">
              <new_password><xsl:value-of select="/cp/form/new_password"/></new_password>
              <confirm_password><xsl:value-of select="/cp/form/new_password2"/></confirm_password>
              <!-- *** Functionality currently disabled per OCN request, but left for 
                   *** ease of re-implementation.
              -->
              <!--
              <xsl:choose>
                <xsl:when test="/cp/form/logrotate = '1' or /cp/form/logrotate = 'on'">
                  <logrotate_state>on</logrotate_state>
                </xsl:when>
                <xsl:otherwise>
                  <logrotate_state>off</logrotate_state>
                </xsl:otherwise>
              </xsl:choose>
              -->
            </vsap>
          </vsap>
        </xsl:with-param>
      </xsl:call-template>
      
      <!-- Pass to toggle 'on' with password changes if logrotate is off. -->
      <!-- *** Functionality currently disabled per OCN request, but left for 
           *** ease of re-implementation.
      -->
      <!--
      <xsl:if test="/cp/form/logrotate = '0' or /cp/form/logrotate = 'off'">
        <xsl:call-template name="dovsap">
          <xsl:with-param name="vsap">
            <vsap>
              <vsap type="mysql:logrotate_on" />
            </vsap>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:if>
    -->

    </xsl:if>

    <!-- save changes to config file -->
    <xsl:if test="string(/cp/form/save) and not(/cp/vsap/vsap[@type='error'])">
      <xsl:call-template name="dovsap">
        <xsl:with-param name="vsap">
          <vsap>
            <vsap type="sys:configfile:save">
              <application>mysqld</application>
              <contents><xsl:value-of select="/cp/form/contents"/></contents>
            </vsap>
          </vsap>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:if>
    
    <!-- Functionality may be re-enabled in the future. This is for use of 'toggle', not 'on', or 'off' -->
    <!-- Save logrotate changes -->
    <!-- 
    <xsl:if test="string(/cp/form/save) and string(/cp/form/logrotate_change) = 'true' and not(/cp/vsap/vsap[@type='error'])">
      <xsl:call-template name="dovsap">
        <xsl:with-param name="vsap">
          <vsap>
            <vsap type="mysql:logrotate_toggle">
              <xsl:choose>
                <xsl:when test="/cp/form/logrotate = '1' or /cp/form/logrotate = 'on'">
                  <logrotate_state>on</logrotate_state>
                </xsl:when>
                <xsl:otherwise>
                  <logrotate_state>off</logrotate_state>
                </xsl:otherwise>
              </xsl:choose>
            </vsap>
          </vsap>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:if>
    -->
    
    <xsl:choose>
      <xsl:when test="string(/cp/vsap/vsap[@type='error'])">
        <xsl:choose>
          <xsl:when test="/cp/vsap/vsap[@type='error']/code = 100">
            <xsl:call-template name="set_message">
              <xsl:with-param name="name">mysql_settings_error_password_missing</xsl:with-param>
            </xsl:call-template>
          </xsl:when>
          <xsl:when test="/cp/vsap/vsap[@type='error']/code = 101">
            <xsl:call-template name="set_message">
              <xsl:with-param name="name">mysql_settings_error_password_mismatch</xsl:with-param>
            </xsl:call-template>
          </xsl:when>
          <xsl:when test="/cp/vsap/vsap[@type='error']/code = 102">
            <xsl:call-template name="set_message">
              <xsl:with-param name="name">mysql_settings_password_change_error</xsl:with-param>
            </xsl:call-template>
          </xsl:when>
          <xsl:when test="/cp/vsap/vsap[@type='error']/code = 103">
            <xsl:call-template name="set_message">
              <xsl:with-param name="name">mysql_settings_logrotate_error</xsl:with-param>
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
              <xsl:with-param name="name">mysql_settings_failure</xsl:with-param>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="string(/cp/form/save) and string(/cp/form/new_password)">
            <xsl:call-template name="set_message">
              <xsl:with-param name="name">mysql_settings_success_both</xsl:with-param>
            </xsl:call-template>
          </xsl:when>
          <xsl:when test="string(/cp/form/save)">
            <xsl:call-template name="set_message">
              <xsl:with-param name="name">mysql_settings_success</xsl:with-param>
            </xsl:call-template>
          </xsl:when>
          <xsl:when test="string(/cp/form/new_password)">
            <!-- only changed the password -->
            <xsl:call-template name="set_message">
              <xsl:with-param name="name">mysql_settings_password_change_success</xsl:with-param>
            </xsl:call-template>
            <redirect>
              <path>cp/admin/services.xsl</path>
            </redirect>
          </xsl:when>
        </xsl:choose>
        <!-- load up config settings and backups -->
        <xsl:call-template name="dovsap">
          <xsl:with-param name="vsap">
            <vsap>
              <vsap type="sys:configfile:fetch">
                <application>mysqld</application>
              </vsap>
            </vsap>
          </xsl:with-param>
        </xsl:call-template>
        <xsl:call-template name="dovsap">
          <xsl:with-param name="vsap">
            <vsap>
              <vsap type="sys:configfile:list_backups">
                <application>mysqld</application>
                <brief/>
              </vsap>
            </vsap>
          </xsl:with-param>
        </xsl:call-template>
        
        <!-- Pass to toggle 'on' with password changes if logrotate is off. -->
        <!-- *** Functionality currently disabled per OCN request, but left for 
             *** ease of re-implementation.
        -->
        <!--
        <xsl:call-template name="dovsap">
          <xsl:with-param name="vsap">
            <vsap>
              <vsap type="mysql:logrotate_status" />
            </vsap>
          </xsl:with-param>
        </xsl:call-template>
        -->
      
      </xsl:otherwise>
    </xsl:choose>

   <showpage/>

  </meta>
 </xsl:template>
</xsl:stylesheet>
