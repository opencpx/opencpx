<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
 <xsl:import href="../../global.meta.xsl"/>
 <xsl:import href="../cp_global.meta.xsl"/>
 <xsl:template match="/">
  <meta>

    <xsl:call-template name="auth">
      <xsl:with-param name="require_class">sa</xsl:with-param>
    </xsl:call-template>

   <xsl:call-template name="cp_global"/>

    <xsl:call-template name="dovsap">
      <xsl:with-param name="vsap">
        <vsap>
          <xsl:choose>
            <xsl:when test="/cp/form/service_type='2'">  <!-- Sub Service - inetd -->
              <xsl:if test="/cp/form/action = 'stop'">
                <vsap type="sys:inetd:disable">
                  <xsl:element name="{/cp/form/service}"/>
                </vsap>
              </xsl:if>
              <xsl:if test="/cp/form/action = 'start'">
                <vsap type="sys:inetd:enable">
                  <xsl:element name="{/cp/form/service}"/>
                </vsap>
              </xsl:if>
            </xsl:when>

            <xsl:when test="/cp/form/service_type='1'">  <!-- Core Service -->
              <xsl:if test="/cp/form/action = 'stop' and /cp/form/service != 'httpd'">
                <!-- stop first, then disable: BUG21629 -->
                <vsap type="sys:service:stop">
                  <xsl:element name="{/cp/form/service}"/>
                </vsap>
                <vsap type="sys:service:disable">
                  <xsl:element name="{/cp/form/service}"/>
                </vsap>
                <xsl:if test="/cp/form/service = 'mailman'">
                  <vsap type="app:mailman:disable"/>
                </xsl:if>
              </xsl:if>
              <xsl:if test="/cp/form/action = 'start'">
                <vsap type="sys:service:enable">
                  <xsl:element name="{/cp/form/service}"/>
                </vsap>
                <vsap type="sys:service:start">
                  <xsl:element name="{/cp/form/service}"/>
                </vsap>
                <xsl:if test="/cp/form/service = 'mailman'">
                  <vsap type="app:mailman:enable"/>
                </xsl:if>
              </xsl:if>
              <xsl:if test="/cp/form/action = 'restart'">
                <vsap type="sys:service:restart">
                  <xsl:element name="{/cp/form/service}"/>
                </vsap>
              </xsl:if>
            </xsl:when>
            <xsl:when test="/cp/form/service_type='0'">  <!-- Server reboot -->
              <vsap type="sys:reboot"/>
            </xsl:when>
          </xsl:choose>

          <vsap type='user:prefs:load' />
          <vsap type="sys:service:status"/>
          <vsap type="sys:inetd:status"/>
          <vsap type="sys:info:uptime"/>
	 </vsap>
      </xsl:with-param>
    </xsl:call-template>

    <xsl:choose>
      <xsl:when test="string(/cp/form/action)">
        <xsl:choose>
          <xsl:when test="/cp/form/action='reboot'">
	    <xsl:choose>
              <xsl:when test="/cp/vsap/vsap[@type='error']">
                <xsl:call-template name="set_message">
                  <xsl:with-param name="name">service_reboot_failure</xsl:with-param>
                  <xsl:with-param name="value" select="'error'"/>
                </xsl:call-template>
              </xsl:when>
              <xsl:otherwise>
                <xsl:call-template name="set_message">
                  <xsl:with-param name="name">service_reboot_successful</xsl:with-param>
                  <xsl:with-param name="value" select="'ok'"/>
                </xsl:call-template>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>

          <xsl:when test="string(/cp/vsap/vsap[@type='error']) or string(/cp/vsap/vsap[concat('sys:service:', /cp/form/action)]/*[local-name()=/cp/form/service]/@error)">
            <xsl:call-template name="set_message">
              <xsl:with-param name="name" select="concat('service_action_', /cp/form/action, '_failure')"/>
              <xsl:with-param name="value" select="'error'"/>
            </xsl:call-template>
          </xsl:when>

          <xsl:otherwise>
            <xsl:call-template name="set_message">
              <xsl:with-param name="name" select="concat('service_action_', /cp/form/action, '_successful')"/>
              <xsl:with-param name="value" select="'ok'"/>
            </xsl:call-template>
          </xsl:otherwise>

        </xsl:choose>
      </xsl:when>

      <xsl:otherwise>
        <xsl:if test="string(/cp/vsap/vsap[@type='error'])">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">list_services_failure</xsl:with-param>
            <xsl:with-param name="value" select="'error'"/>
          </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>

    <showpage/>

  </meta>
 </xsl:template>
</xsl:stylesheet>
