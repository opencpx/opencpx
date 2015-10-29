<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../../global.meta.xsl" />
<xsl:import href="../cp_global.meta.xsl" />
<xsl:import href="../cp_global.xsl" />

<xsl:template match="/">
<meta>

<xsl:call-template name="auth">
  <xsl:with-param name="require_class">sa</xsl:with-param>
</xsl:call-template>

<xsl:call-template name="cp_global" />

<xsl:choose>
  <xsl:when test="string(/cp/form/save)">

  <xsl:variable name="stateTranslate">
    <xsl:call-template name="transliterate">
      <xsl:with-param name="string" select="/cp/form/state"/>
      <xsl:with-param name="search">/</xsl:with-param>
      <xsl:with-param name="replace">\/</xsl:with-param>
    </xsl:call-template>
  </xsl:variable>
  
  <xsl:variable name="localityTranslate">
    <xsl:call-template name="transliterate">
      <xsl:with-param name="string" select="/cp/form/city"/>
      <xsl:with-param name="search">/</xsl:with-param>
      <xsl:with-param name="replace">\/</xsl:with-param>
    </xsl:call-template>
  </xsl:variable>
  
  <xsl:variable name="orgTranslate">
    <xsl:call-template name="transliterate">
      <xsl:with-param name="string" select="/cp/form/company"/>
      <xsl:with-param name="search">/</xsl:with-param>
      <xsl:with-param name="replace">\/</xsl:with-param>
    </xsl:call-template>
  </xsl:variable>
  
  <xsl:variable name="orgUnitTranslate">
    <xsl:call-template name="transliterate">
      <xsl:with-param name="string" select="/cp/form/company_division"/>
      <xsl:with-param name="search">/</xsl:with-param>
      <xsl:with-param name="replace">\/</xsl:with-param>
    </xsl:call-template>
  </xsl:variable>


    <xsl:call-template name="dovsap">
      <xsl:with-param name="vsap">
        <vsap>
          <vsap type="sys:ssl:csr_create">
            <domain><xsl:value-of select="/cp/form/domain" /></domain>
            <subject>/C=<xsl:value-of select="/cp/form/country" />/ST=<xsl:value-of select="$stateTranslate" />/L=<xsl:value-of select="$localityTranslate" />/O=<xsl:value-of select="$orgTranslate" /><xsl:if test="/cp/form/company_division != ''">/OU=<xsl:value-of select="$orgUnitTranslate" /></xsl:if><xsl:if test="/cp/form/email != ''">/emailAddress=<xsl:value-of select="/cp/form/email" /></xsl:if></subject>
          </vsap>
        </vsap>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:when>
  <xsl:when test="string(/cp/form/cancel)">
    <redirect>
      <path>cp/domains/index.xsl</path>
    </redirect>
  </xsl:when>
  <xsl:otherwise>
    <xsl:call-template name="dovsap">
      <xsl:with-param name="vsap">
        <vsap>
          <vsap type="domain:list"/>
        </vsap>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:otherwise>
</xsl:choose>


<xsl:if test="/cp/form/save">
  <xsl:if test="/cp/vsap/vsap[@type='sys:ssl:csr_create']/status != 'ok'">
    <xsl:call-template name="set_message">
      <xsl:with-param name="name">domain_csr_create_error</xsl:with-param>
    </xsl:call-template>
  </xsl:if>
</xsl:if>

<showpage />

</meta>
</xsl:template>
</xsl:stylesheet>
