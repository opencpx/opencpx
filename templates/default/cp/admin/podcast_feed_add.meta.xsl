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
            <vsap type="web:rss:add:feed">
              <xsl:if test="string(/cp/form/ruid)">
                <ruid><xsl:value-of select="/cp/form/ruid" /></ruid>
              </xsl:if>
              <xsl:if test="string(/cp/form/edit)">
                <edit><xsl:value-of select="/cp/form/edit" /></edit>
              </xsl:if>
              <title><xsl:value-of select="/cp/form/title" /></title>
              <domain><xsl:value-of select="/cp/form/domain" /></domain>
              <directory><xsl:value-of select="/cp/form/directory" /></directory>
              <filename><xsl:value-of select="/cp/form/filename" /></filename>
              <link><xsl:value-of select="/cp/form/link" /></link>
              <description><xsl:value-of select="/cp/form/description" /></description>
              <language><xsl:value-of select="/cp/form/language" /></language>
              <copyright><xsl:value-of select="/cp/form/copyright" /></copyright>
              <pubdate_day><xsl:value-of select="/cp/form/pubdate_day" /></pubdate_day>
              <pubdate_date><xsl:value-of select="/cp/form/pubdate_date" /></pubdate_date>
              <pubdate_month><xsl:value-of select="/cp/form/pubdate_month" /></pubdate_month>
              <pubdate_year><xsl:value-of select="/cp/form/pubdate_year" /></pubdate_year>
              <pubdate_hour><xsl:value-of select="/cp/form/pubdate_hour" /></pubdate_hour>
              <pubdate_minute><xsl:value-of select="/cp/form/pubdate_minute" /></pubdate_minute>
              <pubdate_second><xsl:value-of select="/cp/form/pubdate_second" /></pubdate_second>
              <pubdate_zone><xsl:value-of select="/cp/form/pubdate_zone" /></pubdate_zone>
              <image_url><xsl:value-of select="/cp/form/image_url" /></image_url>
              <image_title><xsl:value-of select="/cp/form/image_title" /></image_title>
              <image_link><xsl:value-of select="/cp/form/image_link" /></image_link>
              <itunes_subtitle><xsl:value-of select="/cp/form/itunes_subtitle" /></itunes_subtitle>
              <itunes_author><xsl:value-of select="/cp/form/itunes_author" /></itunes_author>
              <itunes_summary><xsl:value-of select="/cp/form/itunes_summary" /></itunes_summary>
              <xsl:for-each select="/cp/form/itunes_category">
                <itunes_category><xsl:value-of select="." /></itunes_category>
              </xsl:for-each>
              <itunes_owner_name><xsl:value-of select="/cp/form/itunes_owner_name" /></itunes_owner_name>
              <itunes_owner_email><xsl:value-of select="/cp/form/itunes_owner_email" /></itunes_owner_email>
              <itunes_image><xsl:value-of select="/cp/form/itunes_image" /></itunes_image>
              <itunes_explicit><xsl:value-of select="/cp/form/itunes_explicit" /></itunes_explicit>
              <itunes_block><xsl:value-of select="/cp/form/itunes_block" /></itunes_block>
            </vsap>
          </xsl:if>

          <xsl:if test="string(/cp/form/edit)">
            <vsap type="web:rss:load:feed" />
          </xsl:if>

          <vsap type="web:rss:get:parameters" />

          <vsap type="domain:list" />

        </vsap>
      </xsl:with-param>
    </xsl:call-template>


    <xsl:choose>
      <xsl:when test="string(/cp/form/save)">
        <xsl:choose>
          <!-- if edit -->
          <xsl:when test="string(/cp/form/edit)">
            <xsl:choose>
              <!-- edit feed error -->
              <xsl:when test="boolean(/cp/vsap/vsap[@type='error'])">
                <xsl:call-template name="set_message">
                  <xsl:with-param name="name" select="'podcast_task_failure_editfeed'"/>
                  <xsl:with-param name="value" select="'error'"/>
                </xsl:call-template>
                <showpage/>
              </xsl:when>

              <!-- edit feed success -->
              <xsl:otherwise>
                <xsl:call-template name="set_message">
                  <xsl:with-param name="name" select="'podcast_task_success_editfeed'"/>
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
              <!-- add feed failure -->
              <xsl:when test="boolean(/cp/vsap/vsap[@type='error'])">
                <xsl:call-template name="set_message">
                  <xsl:with-param name="name" select="'podcast_task_failure_addfeed'"/>
                  <xsl:with-param name="value" select="'error'"/>
                </xsl:call-template>
                <showpage/>
              </xsl:when>

              <!-- add feed success-->
              <xsl:otherwise>
                <xsl:call-template name="set_message">
                  <xsl:with-param name="name" select="'podcast_task_success_addfeed'"/>
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
          <!-- add feed failure -->
          <xsl:when test="boolean(/cp/vsap/vsap[@type='error'])">
            <xsl:call-template name="set_message">
              <xsl:with-param name="name" select="'podcast_task_failure_addfeed'"/>
              <xsl:with-param name="value" select="'error'"/>
            </xsl:call-template>
            <showpage/>
          </xsl:when>

          <!-- add feed success-->
          <xsl:otherwise>
            <xsl:call-template name="set_message">
              <xsl:with-param name="name" select="'podcast_task_success_addfeed'"/>
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
