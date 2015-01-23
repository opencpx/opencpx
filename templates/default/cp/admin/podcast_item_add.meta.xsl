<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
 <xsl:import href="../../global.meta.xsl"/>
 <xsl:import href="../cp_global.meta.xsl"/>
 <xsl:template match="/">
  <meta>

    <xsl:if test="string(/cp/form/cancel)">
      <redirect>
        <path>cp/admin/podcast_list.xsl</path>
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

          <xsl:if test="string(/cp/form/save) or string(/cp/form/save_and_add)">
            <vsap type="web:rss:add:item">
              <xsl:if test="string(/cp/form/edit)">
                <edit><xsl:value-of select="/cp/form/edit" /></edit>
                <iuid><xsl:value-of select="/cp/form/iuid" /></iuid>
              </xsl:if>
              <ruid><xsl:value-of select="/cp/form/ruid" /></ruid>
              <title><xsl:value-of select="/cp/form/title" /></title>
              <fileurl><xsl:value-of select="/cp/form/fileurl" /></fileurl>
              <description><xsl:value-of select="/cp/form/description" /></description>
              <author><xsl:value-of select="/cp/form/author" /></author>
              <pubdate_day><xsl:value-of select="/cp/form/pubdate_day" /></pubdate_day>
              <pubdate_date><xsl:value-of select="/cp/form/pubdate_date" /></pubdate_date>
              <pubdate_month><xsl:value-of select="/cp/form/pubdate_month" /></pubdate_month>
              <pubdate_year><xsl:value-of select="/cp/form/pubdate_year" /></pubdate_year>
              <pubdate_hour><xsl:value-of select="/cp/form/pubdate_hour" /></pubdate_hour>
              <pubdate_minute><xsl:value-of select="/cp/form/pubdate_minute" /></pubdate_minute>
              <pubdate_second><xsl:value-of select="/cp/form/pubdate_second" /></pubdate_second>
              <pubdate_zone><xsl:value-of select="/cp/form/pubdate_zone" /></pubdate_zone>
              <guid><xsl:value-of select="/cp/form/fileurl" /></guid>
              <itunes_subtitle><xsl:value-of select="/cp/form/itunes_subtitle" /></itunes_subtitle>
              <itunes_author><xsl:value-of select="/cp/form/itunes_author" /></itunes_author>
              <itunes_summary><xsl:value-of select="/cp/form/itunes_summary" /></itunes_summary>
              <itunes_duration_hour><xsl:value-of select="/cp/form/itunes_duration_hour" /></itunes_duration_hour>
              <itunes_duration_minute><xsl:value-of select="/cp/form/itunes_duration_minute" /></itunes_duration_minute>
              <itunes_duration_second><xsl:value-of select="/cp/form/itunes_duration_second" /></itunes_duration_second>
              <itunes_keywords><xsl:value-of select="/cp/form/itunes_keywords" /></itunes_keywords>
              <itunes_explicit><xsl:value-of select="/cp/form/itunes_explicit" /></itunes_explicit>
              <itunes_block><xsl:value-of select="/cp/form/itunes_block" /></itunes_block>
            </vsap>
          </xsl:if>

          <vsap type="web:rss:load:feed" />

          <vsap type="domain:list">
            <properties>1</properties>
          </vsap>

        </vsap>
      </xsl:with-param>
    </xsl:call-template>


    <xsl:choose>
      <xsl:when test="string(/cp/form/save)">
        <xsl:choose>
          <!-- if edit -->
          <xsl:when test="string(/cp/form/edit)">
            <xsl:choose>
              <!-- edit item error -->
              <xsl:when test="boolean(/cp/vsap/vsap[@type='error'])">
                <xsl:call-template name="set_message">
                  <xsl:with-param name="name" select="'podcast_task_failure_edititem'"/>
                  <xsl:with-param name="value" select="'error'"/>
                </xsl:call-template>
                <showpage/>
              </xsl:when>

              <!-- edit item success -->
              <xsl:otherwise>
                <xsl:call-template name="set_message">
                  <xsl:with-param name="name" select="'podcast_task_success_edititem'"/>
                  <xsl:with-param name="value" select="'ok'"/>
                </xsl:call-template>
                <redirect>
                  <path>cp/admin/podcast_list.xsl</path>
                </redirect>
              </xsl:otherwise>
            </xsl:choose>
            <showpage/>
          </xsl:when>

          <!-- if add -->
          <xsl:otherwise>
            <xsl:choose>
              <!-- add item failure -->
              <xsl:when test="boolean(/cp/vsap/vsap[@type='error'])">
                <xsl:call-template name="set_message">
                  <xsl:with-param name="name" select="'podcast_task_failure_additem'"/>
                  <xsl:with-param name="value" select="'error'"/>
                </xsl:call-template>
                <showpage/>
              </xsl:when>

              <!-- add item success-->
              <xsl:otherwise>
                <xsl:call-template name="set_message">
                  <xsl:with-param name="name" select="'podcast_task_success_additem'"/>
                  <xsl:with-param name="value" select="'ok'"/>
                </xsl:call-template>
                <redirect>
                  <path>cp/admin/podcast_list.xsl</path>
                </redirect>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="string(/cp/form/save_and_add)">
        <xsl:choose>
          <!-- add item failure -->
          <xsl:when test="boolean(/cp/vsap/vsap[@type='error'])">
            <xsl:call-template name="set_message">
              <xsl:with-param name="name" select="'podcast_task_failure_additem'"/>
              <xsl:with-param name="value" select="'error'"/>
            </xsl:call-template>
            <showpage/>
          </xsl:when>

          <!-- add item success-->
          <xsl:otherwise>
            <xsl:call-template name="set_message">
              <xsl:with-param name="name" select="'podcast_task_success_additem'"/>
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
