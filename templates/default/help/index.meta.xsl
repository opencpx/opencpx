<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../global.meta.xsl" />

<xsl:template match="/">
<meta>

<xsl:call-template name="auth" />

<xsl:variable name='topic' select="/cp/form/topic" />
<xsl:variable name="view" select="/cp/form/view" />
<xsl:variable name="base_dir">../../../help/</xsl:variable>
<xsl:variable name='help_toc_file' select='concat($base_dir, "en_US/", "help_toc.xml")'/>
<xsl:variable name='help_toc' select="document( $help_toc_file )" />


<xsl:choose>
  <xsl:when test="string(/cp/form/query)">
    <!-- Search article -->
    <xsl:call-template name="dovsap">
      <xsl:with-param name="vsap">
        <vsap>
          <vsap type="help:search">
            <query><xsl:value-of select="/cp/form/query" /></query>
            <category><xsl:value-of select="/cp/form/category"/></category>
            <case_sensitive><xsl:value-of select="/cp/form/case_sensitive"/></case_sensitive>
            <language><xsl:value-of select='/cp/form/language'/></language>
          </vsap>
        </vsap>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:when>
  <xsl:when test="string(/cp/form/debug)">
    <!-- Debug checking -->
    <xsl:call-template name="dovsap">
      <xsl:with-param name="vsap">
        <vsap>
          <vsap type="help:debug">
            <debug><xsl:value-of select="/cp/form/debug" /></debug>
            <query><xsl:value-of select="/cp/form/query" /></query>
            <topic><xsl:value-of select="/cp/form/topic" /></topic>
            <category>
              <xsl:choose>
						    <xsl:when test='string(/cp/form/category)'>
						      <xsl:value-of select='/cp/form/category'/>
						    </xsl:when>
						    <xsl:when test='string($topic)'>
						      <xsl:value-of select='$help_toc/toc/*/category/topic[@id=$topic]/../@id' />
						    </xsl:when>
						  </xsl:choose>
            </category>
            <case_sensitive><xsl:value-of select="/cp/form/case_sensitive"/></case_sensitive>
            <language>en_US</language>
          </vsap>
        </vsap>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:when>
  <xsl:when test="string(/cp/form/cancel)">
    <redirect>
      <path>help/index.xsl</path>
    </redirect>
  </xsl:when>
</xsl:choose>

<xsl:if test="/cp/vsap/vsap[@type='error']/code">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='error']/code = 100">
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">help_search_query_too_short</xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='error']/code = 101">
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">help_invalid_language</xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='error']/code = 102">
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">help_no_search_results</xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='error']/code = 103">
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">help_invalid_category</xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='error']/code = 104">
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">help_invalid_toc_file</xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='error']/code = 105">
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">help_invalid_toc_xml</xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='error']/code = 106">
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">help_invalid_got_file</xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='error']/code = 107">
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">help_invalid_got_xml</xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='error']/code = 108">
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">help_invalid_faq_file</xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='error']/code = 109">
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">help_invalid_faq_xml</xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='error']/code = 110">
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">help_invalid_topic_file</xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='error']/code = 111">
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">help_invalid_topic_xml</xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='error']/code = 112">
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">help_invalid_language</xsl:with-param>
      </xsl:call-template>
    </xsl:when>
  </xsl:choose>
</xsl:if>

<showpage />

</meta>
</xsl:template>

</xsl:stylesheet>
