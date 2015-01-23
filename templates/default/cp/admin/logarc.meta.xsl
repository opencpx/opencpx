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

          <xsl:if test="/cp/form/action='delete'">
            <vsap type="sys:logs:del_archive">
              <domain><xsl:value-of select="/cp/form/domain"/></domain>
              <xsl:if test="string(/cp/form/target)">
                <path><xsl:value-of select="/cp/form/target"/></path>
              </xsl:if>
              <xsl:for-each select="/cp/form/chk_log">
                <path><xsl:value-of select="."/></path>
              </xsl:for-each>
            </vsap>
          </xsl:if>

          <xsl:if test="/cp/form/action='download'">
            <vsap type="sys:logs:download">
              <domain><xsl:value-of select="/cp/form/domain"/></domain>
              <path><xsl:value-of select="/cp/form/target"/></path>
            </vsap>
          </xsl:if>

          <vsap type="sys:logs:list_archives">
            <domain><xsl:value-of select="/cp/form/domain"/></domain>
            <path><xsl:value-of select="/cp/form/logname"/></path>
          </vsap>
        </vsap>
      </xsl:with-param>
    </xsl:call-template>

    <xsl:choose>
      <xsl:when test="/cp/form/action='delete'">
        <xsl:choose>
          <xsl:when test="count(/cp/vsap/vsap[@type='sys:logs:del_archive'][status='ok']) = count(/cp/vsap/vsap[@type='sys:logs:del_archive']/path)">
            <xsl:call-template name="set_message">
              <xsl:with-param name="name" select="'log_archive_delete_success'"/>
              <xsl:with-param name="value" select="'ok'"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="set_message">
              <xsl:with-param name="name" select="'log_archive_delete_failure'"/>
              <xsl:with-param name="value" select="'error'"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test="string(/cp/vsap/vsap[@type='error'])">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name" select="'log_archive_list_failure'" />
            <xsl:with-param name="value" select="'error'" />
          </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>

    <showpage/>

  </meta>
 </xsl:template>
</xsl:stylesheet>
