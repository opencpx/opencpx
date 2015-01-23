<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
 <xsl:import href="../../global.meta.xsl"/>
 <xsl:import href="../cp_global.meta.xsl"/>
 <xsl:template match="/">
  <meta>

    <xsl:if test="string(/cp/form/back)">
      <redirect>
        <path>cp/admin/config_file_restore.xsl</path>
      </redirect>
    </xsl:if>

    <xsl:call-template name="auth">
      <xsl:with-param name="require_class">sa</xsl:with-param>
      <xsl:with-param name="require_cloud">1</xsl:with-param>
    </xsl:call-template>

    <xsl:call-template name="cp_global"/>

    <xsl:call-template name="dovsap">
      <xsl:with-param name="vsap">
        <vsap>
          <vsap type="sys:configfile:view_backup">
            <application><xsl:value-of select="/cp/form/application"/></application>
            <config_path><xsl:value-of select="/cp/form/config_path"/></config_path>
            <backup_version><xsl:value-of select="/cp/form/version"/></backup_version>
            <xsl:if test="/cp/form/action = 'diff'">
              <show_diffs/>
            </xsl:if>
          </vsap>
        </vsap>
      </xsl:with-param>
    </xsl:call-template>

    <showpage/>

  </meta>
 </xsl:template>
</xsl:stylesheet>
