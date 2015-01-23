<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
 <xsl:import href="../../global.meta.xsl"/>
 <xsl:import href="../cp_global.meta.xsl"/>
 <xsl:template match="/">
  <meta>

    <xsl:call-template name="auth">
      <xsl:with-param name="require_class">da</xsl:with-param>
    </xsl:call-template>

   <xsl:call-template name="cp_global"/>

    <xsl:call-template name="dovsap">
      <xsl:with-param name="vsap">
        <vsap>
          <vsap type="domain:list"/>

          <xsl:if test="/cp/form/action='download'">
            <vsap type="sys:logs:download">
              <domain><xsl:value-of select="/cp/form/domain"/></domain>
              <path><xsl:value-of select="/cp/form/path"/></path>
            </vsap>
          </xsl:if>

          <xsl:if test="/cp/form/action='archive'">
            <vsap type="sys:logs:archive_now">
              <domain><xsl:value-of select="/cp/form/domain"/></domain>
              <path><xsl:value-of select="/cp/form/path"/></path>
            </vsap>
          </xsl:if>

          <xsl:if test="string(/cp/form/domain)">
            <vsap type="sys:logs:list">
              <domain><xsl:value-of select="/cp/form/domain"/></domain>
            </vsap>
          </xsl:if>
        </vsap>
      </xsl:with-param>
    </xsl:call-template>

    <xsl:choose>
      <xsl:when test="/cp/form/action='archive'">
        <xsl:choose>
          <xsl:when test="/cp/vsap/vsap[@type='sys:logs:archive_now']/status='ok'">
            <xsl:call-template name="set_message">
              <xsl:with-param name="name" select="'log_list_archive_success'"/>
              <xsl:with-param name="value" select="'ok'"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="set_message">
              <xsl:with-param name="name" select="'log_list_archive_failure'"/>
              <xsl:with-param name="value" select="'error'"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test="string(/cp/vsap/vsap[@type='error'])">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name" select="'log_list_failure'" />
            <xsl:with-param name="value" select="'error'" />
          </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>


    <showpage/>

  </meta>
 </xsl:template>
</xsl:stylesheet>
