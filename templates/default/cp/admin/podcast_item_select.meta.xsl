<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
 <xsl:import href="../../global.meta.xsl"/>
 <xsl:import href="../cp_global.meta.xsl"/>
 <xsl:template match="/">
  <meta>

    <xsl:call-template name="auth">
      <xsl:with-param name="require_class">da</xsl:with-param>
      <xsl:with-param name="require_podcast">1</xsl:with-param>
    </xsl:call-template>

   <xsl:call-template name="cp_global"/>

    <xsl:call-template name="dovsap">
      <xsl:with-param name="vsap">
        <vsap>
          <xsl:if test="/cp/form/upload_file_save">
            <xsl:if test="/cp/form/fileupload != ''">
              <vsap type="files:upload:add">
                <sessionid><xsl:value-of select="/cp/form/sessionID"/></sessionid>
                <filename><xsl:value-of select="/cp/form/fileupload"/></filename>
              </vsap>
              <vsap type="files:upload:confirm">
                <sessionid><xsl:value-of select="/cp/form/sessionID"/> </sessionid>
                <path><xsl:value-of select="/cp/form/path" /></path>
                <overwrite/>
              </vsap>
            </xsl:if>
          </xsl:if>
          <vsap type="files:upload:list">
            <sessionid><xsl:value-of select="/cp/form/sessionID"/></sessionid>
          </vsap>
          <vsap type="files:list">
            <xsl:choose>
              <xsl:when test="string(/cp/form/view_path)">
                <path><xsl:value-of select="/cp/form/view_path" /></path>
              </xsl:when>
              <xsl:otherwise>
                <path><xsl:value-of select="/cp/form/path" /></path>
              </xsl:otherwise>
            </xsl:choose>
          </vsap>
        </vsap>
      </xsl:with-param>
    </xsl:call-template>

    <xsl:choose>
      <xsl:when test="string(/cp/form/upload_file_save)">
        <xsl:choose>
          <!-- upload file failure -->
          <xsl:when test="boolean(/cp/vsap/vsap[@type='error'])">
            <xsl:call-template name="set_message">
              <xsl:with-param name="name" select="'podcast_task_failure_upfile'"/>
              <xsl:with-param name="value" select="'error'"/>
            </xsl:call-template>
            <showpage/>
          </xsl:when>

          <!-- upload file success-->
          <xsl:otherwise>
            <xsl:call-template name="set_message">
              <xsl:with-param name="name" select="'podcast_task_success_upfile'"/>
              <xsl:with-param name="value" select="'ok'"/>
            </xsl:call-template>
            <showpage/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <showpage/>
      </xsl:otherwise>
    </xsl:choose>
  </meta>
 </xsl:template>
</xsl:stylesheet>
