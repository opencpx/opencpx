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
            <vsap type="sys:package:install">
              <package><xsl:value-of select="/cp/form/package"/></package>
            </vsap>
          </xsl:if>

          <xsl:if test="/cp/form/action='uninstall'">
            <vsap type="sys:package:uninstall">
              <package><xsl:value-of select="/cp/form/package"/></package>
            </vsap>
          </xsl:if>

          <xsl:if test="/cp/form/action='update'">
            <vsap type="sys:package:update">
              <package><xsl:value-of select="/cp/form/package"/></package>
            </vsap>
          </xsl:if>

          <xsl:if test="/cp/form/action='reinstall'">
            <vsap type="sys:package:reinstall">
              <package><xsl:value-of select="/cp/form/package"/></package>
            </vsap>
          </xsl:if>

          <xsl:variable name="only_installed">
            <xsl:choose>
              <xsl:when test="/cp/form/group != ''">1</xsl:when>
              <xsl:when test="/cp/form/pattern != ''">
                <xsl:choose>
                  <xsl:when test="/cp/form/search_all='yes'">0</xsl:when>
                  <xsl:otherwise>1</xsl:otherwise>
                </xsl:choose>
              </xsl:when>
              <xsl:otherwise>1</xsl:otherwise>
            </xsl:choose>
          </xsl:variable>

          <vsap type="sys:package:list">
            <page>
              <xsl:choose>
                <xsl:when test="number(/cp/form/page) > 0"><xsl:value-of select="/cp/form/page" /></xsl:when>
                <xsl:otherwise>1</xsl:otherwise>
              </xsl:choose>
            </page>
            <sortby><xsl:value-of select="/cp/form/sort_by" /></sortby>
            <order><xsl:value-of select="/cp/form/sort_type" /></order>
            <xsl:if test="/cp/form/group != ''">
              <group><xsl:value-of select="/cp/form/group" /></group>
            </xsl:if>
            <xsl:if test="/cp/form/pattern != ''">
              <pattern><xsl:value-of select="/cp/form/pattern" /></pattern>
            </xsl:if>
            <installed><xsl:value-of select="$only_installed" /></installed>
	  </vsap>

        </vsap>
      </xsl:with-param>
    </xsl:call-template>

    <xsl:choose>

      <xsl:when test="/cp/form/action='install'">
        <xsl:choose>
          <xsl:when test="/cp/vsap/vsap[@type='sys:package:install']/status='ok'">
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
          <xsl:when test="/cp/vsap/vsap[@type='sys:package:uninstall']/status='ok'">
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
          <xsl:when test="/cp/vsap/vsap[@type='sys:package:update']/status='ok'">
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
          <xsl:when test="/cp/vsap/vsap[@type='sys:package:reinstall']/status='ok'">
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
