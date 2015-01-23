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

    <xsl:if test="string(/cp/form/action)">
      <xsl:call-template name="dovsap">
        <xsl:with-param name="vsap">
          <vsap>
            <vsap type="sys:application:valid">
              <application><xsl:value-of select="/cp/form/application"/></application>
            </vsap>
          </vsap>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:if>

    <xsl:if test="string(/cp/vsap/vsap[@type='error'][@caller='sys:application:valid'])">
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">application_not_supported</xsl:with-param>
        <xsl:with-param name="value" select="'error'"/>
      </xsl:call-template>
    </xsl:if>

    <xsl:call-template name="dovsap">
      <xsl:with-param name="vsap">
        <vsap>
          <xsl:if test="string(/cp/form/action) and not(/cp/vsap/vsap[@type='error'][@caller='sys:application:valid'])">
            <!-- time to make the doughnuts -->
            <xsl:variable name="command">
              <xsl:value-of select="concat('app:', /cp/form/application, ':', /cp/form/action)"/>
            </xsl:variable>
            <vsap type="{$command}"/>
          </xsl:if>
          <vsap type="sys:application:status"/>
        </vsap>
      </xsl:with-param>
    </xsl:call-template>

    <xsl:choose>

      <xsl:when test="string(/cp/form/action) and not(/cp/vsap/vsap[@type='error'][@caller='sys:application:valid'])">
        <!-- action was requested... check status -->
        <xsl:choose>
          <xsl:when test="string(/cp/vsap/vsap[@type='error']) or string(/cp/vsap/vsap[concat('app:', /cp/form/application, ':', /cp/form/action)]/*[local-name()=/cp/form/application]/@error)">
            <xsl:call-template name="set_message">
              <xsl:with-param name="name" select="concat('application_action_', /cp/form/action, '_failure')"/>
              <xsl:with-param name="value" select="'error'"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="set_message">
              <xsl:with-param name="name" select="concat('application_action_', /cp/form/action, '_successful')"/>
              <xsl:with-param name="value" select="'ok'"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>

      <xsl:otherwise>
        <!-- check status of list application call -->
        <xsl:if test="string(/cp/vsap/vsap[@type='error'])">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">list_applications_failure</xsl:with-param>
            <xsl:with-param name="value" select="'error'"/>
          </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>

    </xsl:choose>

    <showpage/>

  </meta>
 </xsl:template>
</xsl:stylesheet>
