<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
 <xsl:import href="../../global.meta.xsl"/>
 <xsl:import href="../cp_global.meta.xsl"/>
 <xsl:template match="/">
  <meta>

    <xsl:if test="string(/cp/form/create_feed)">
      <redirect>
        <path>cp/admin/podcast_feed_add.xsl</path>
      </redirect>
    </xsl:if>

    <xsl:call-template name="auth">
      <xsl:with-param name="require_class">da</xsl:with-param>
      <xsl:with-param name="require_podcast">1</xsl:with-param>
    </xsl:call-template>

   <xsl:call-template name="cp_global"/>

    <xsl:call-template name="dovsap">
      <xsl:with-param name="vsap">
        <vsap>
          <xsl:if test="/cp/form/delete = 'feed'">
            <vsap type="web:rss:delete:feed">
              <ruid><xsl:value-of select="/cp/form/ruid" /></ruid>
            </vsap>
          </xsl:if>
          <xsl:if test="/cp/form/delete = 'item'">
            <vsap type="web:rss:delete:item">
              <iuid><xsl:value-of select="/cp/form/iuid" /></iuid>
            </vsap>
          </xsl:if>
          <xsl:if test="/cp/form/publish = 'feed'">
            <vsap type="web:rss:post:feed">
              <ruid><xsl:value-of select="/cp/form/ruid" /></ruid>
            </vsap>
          </xsl:if>
          <vsap type="web:rss:load:feed" />
        </vsap>
      </xsl:with-param>
    </xsl:call-template>


    <xsl:choose>
      <xsl:when test="/cp/form/delete = 'feed'">
        <xsl:choose>
          <!-- delete feed failure -->
          <xsl:when test="boolean(/cp/vsap/vsap[@type='error'])">
            <xsl:call-template name="set_message">
              <xsl:with-param name="name" select="'podcast_task_failure_delfeed'"/>
              <xsl:with-param name="value" select="'error'"/>
            </xsl:call-template>
            <showpage/>
          </xsl:when>

          <!-- delete feed success-->
          <xsl:otherwise>
            <xsl:call-template name="set_message">
              <xsl:with-param name="name" select="'podcast_task_success_delfeed'"/>
              <xsl:with-param name="value" select="'ok'"/>
            </xsl:call-template>
            <showpage/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="/cp/form/delete = 'item'">
        <xsl:choose>
          <!-- delete item failure -->
          <xsl:when test="boolean(/cp/vsap/vsap[@type='error'])">
            <xsl:call-template name="set_message">
              <xsl:with-param name="name" select="'podcast_task_failure_delitem'"/>
              <xsl:with-param name="value" select="'error'"/>
            </xsl:call-template>
            <showpage/>
          </xsl:when>

          <!-- delete item success-->
          <xsl:otherwise>
            <xsl:call-template name="set_message">
              <xsl:with-param name="name" select="'podcast_task_success_delitem'"/>
              <xsl:with-param name="value" select="'ok'"/>
            </xsl:call-template>
            <showpage/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="/cp/form/publish = 'feed'">
        <xsl:choose>
          <!-- publish feed failure -->
          <xsl:when test="boolean(/cp/vsap/vsap[@type='error'])">
            <xsl:call-template name="set_message">
              <xsl:with-param name="name" select="'podcast_task_failure_pubfeed'"/>
              <xsl:with-param name="value" select="'error'"/>
            </xsl:call-template>
            <showpage/>
          </xsl:when>

          <!-- publish feed success-->
          <xsl:otherwise>
            <xsl:call-template name="set_message">
              <xsl:with-param name="name" select="'podcast_task_success_pubfeed'"/>
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
