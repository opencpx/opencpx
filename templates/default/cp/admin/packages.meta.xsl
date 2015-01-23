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
          <xsl:if test="/cp/form/action='install'">
            <vsap type="sys:packages:install">
              <package><xsl:value-of select="/cp/form/package"/></package>
            </vsap>
          </xsl:if>

          <xsl:if test="/cp/form/action='uninstall'">
            <vsap type="sys:packages:uninstall">
              <package><xsl:value-of select="/cp/form/package"/></package>
            </vsap>
          </xsl:if>

          <xsl:if test="/cp/form/action='update'">
            <vsap type="sys:packages:update">
              <package><xsl:value-of select="/cp/form/package"/></package>
            </vsap>
          </xsl:if>

          <xsl:if test="/cp/form/action='reinstall'">
            <vsap type="sys:packages:reinstall">
              <package><xsl:value-of select="/cp/form/package"/></package>
            </vsap>
          </xsl:if>

          <vsap type='user:prefs:load' />

          <xsl:variable name="range">
            <xsl:choose>
              <xsl:when test="string(/cp/form/range)"><xsl:value-of select="/cp/form/range" /></xsl:when>
              <xsl:otherwise></xsl:otherwise>
            </xsl:choose>
          </xsl:variable>

          <vsap type="sys:packages:list">
            <xsl:if test="string(/cp/form/sort) and string(/cp/form/order)">
              <sort><xsl:value-of select="concat(/cp/form/sort, '_', /cp/form/order)"/></sort>
            </xsl:if>
            <start>
              <xsl:choose>
                <xsl:when test="string(/cp/form/start)"><xsl:value-of select="/cp/form/start"/></xsl:when>
                <xsl:otherwise>1</xsl:otherwise>
              </xsl:choose>
            </start>
            <range><xsl:value-of select="$range"/></range>
            <xsl:if test="string(/cp/form/pattern)">
              <search_pattern><xsl:value-of select="/cp/form/pattern"/></search_pattern>
            </xsl:if>
            <xsl:if test="string(/cp/form/chk_pkg_desc)">
              <search_type>name_and_description</search_type>
            </xsl:if>
            <xsl:if test="string(/cp/form/chk_show_maintained)">
              <show_maintained/>
            </xsl:if>
          </vsap>
	 </vsap>
      </xsl:with-param>
    </xsl:call-template>

    <xsl:choose>

      <xsl:when test="/cp/form/action='install'">
        <xsl:choose>
          <xsl:when test="/cp/vsap/vsap[@type='sys:packages:install']/status='ok'">
            <xsl:call-template name="set_message">
              <xsl:with-param name="name">package_install_successful</xsl:with-param>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="set_message">
              <xsl:with-param name="name">package_install_failure</xsl:with-param>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>

      <xsl:when test="/cp/form/action='uninstall'">
        <xsl:choose>
          <xsl:when test="/cp/vsap/vsap[@type='sys:packages:uninstall']/status='ok'">
            <xsl:call-template name="set_message">
              <xsl:with-param name="name">package_uninstall_successful</xsl:with-param>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="set_message">
              <xsl:with-param name="name">package_uninstall_failure</xsl:with-param>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>

      <xsl:when test="/cp/form/action='update'">
        <xsl:choose>
          <xsl:when test="/cp/vsap/vsap[@type='sys:packages:update']/status='ok'">
            <xsl:call-template name="set_message">
              <xsl:with-param name="name">package_update_successful</xsl:with-param>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="set_message">
              <xsl:with-param name="name">package_update_failure</xsl:with-param>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>

      <xsl:when test="/cp/form/action='reinstall'">
        <xsl:choose>
          <xsl:when test="/cp/vsap/vsap[@type='sys:packages:reinstall']/status='ok'">
            <xsl:call-template name="set_message">
              <xsl:with-param name="name">package_reinstall_successful</xsl:with-param>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="set_message">
              <xsl:with-param name="name">package_reinstall_failure</xsl:with-param>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>

    </xsl:choose>

   <showpage/>

  </meta>
 </xsl:template>
</xsl:stylesheet>
