<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../../global.meta.xsl" />
<xsl:import href="../cp_global.meta.xsl" />
<xsl:template match="/">
<meta>

<xsl:call-template name="auth">
  <xsl:with-param name="require_class">da</xsl:with-param>
</xsl:call-template>

<xsl:call-template name="cp_global"/>

<xsl:choose>
  <xsl:when test="/cp/form/add_domain">
    <redirect>
      <path>cp/domains/domain_add_setup.xsl</path>
    </redirect>
  </xsl:when>
  <xsl:otherwise>
    <xsl:call-template name="dovsap">
      <xsl:with-param name="vsap">
        <vsap>
          <xsl:if test="/cp/form/action='disable'">
            <vsap type="domain:disable">
              <domain><xsl:value-of select="/cp/form/domain" /></domain>
            </vsap>
          </xsl:if>
          <xsl:if test="/cp/form/action='enable'">
            <vsap type="domain:enable">
              <domain><xsl:value-of select="/cp/form/domain" /></domain>
            </vsap>
          </xsl:if>
          <xsl:if test="/cp/form/action = 'delete'"> 
            <vsap type="domain:delete">
              <domain><xsl:value-of select="/cp/form/domain" /></domain>
            </vsap>
          </xsl:if>


          <xsl:if test="/cp/form/delete = 'yes' and (count (/cp/form/domain) > 0)">
            <vsap type="domain:delete">
              <xsl:for-each select="/cp/form/domain">
                <domain><xsl:value-of select="." /></domain>
              </xsl:for-each>
            </vsap>
          </xsl:if>

          <vsap type="domain:paged_list">
            <xsl:if test="/cp/form/select_admin != ''">
              <admin><xsl:value-of select="/cp/form/select_admin" /></admin>
            </xsl:if>
            <properties />
            <xsl:if test="/cp/form/show_usage = '1'">
              <diskspace />
            </xsl:if>
            <page>
              <xsl:choose>
                <xsl:when test="number(/cp/form/page) > 0"><xsl:value-of select="/cp/form/page" /></xsl:when>
                <xsl:otherwise>1</xsl:otherwise>
              </xsl:choose>
            </page>
            <sortby><xsl:value-of select="/cp/form/sort_by" /></sortby>
            <order><xsl:value-of select="/cp/form/sort_type" /></order>
          </vsap>

          <xsl:if test="/cp/vsap/vsap[@type='auth']/server_admin">
            <vsap type="user:list_da" />
          </xsl:if>

          <vsap type="user:properties">
            <brief/>
            <!-- this call is for the quota display at the top of the domains table -->
            <xsl:choose>
              <xsl:when test="/cp/form/select_admin != ''">
                <user><xsl:value-of select="/cp/form/select_admin" /></user>
              </xsl:when>
              <xsl:otherwise>
                <user><xsl:value-of select="/cp/vsap/vsap[@type='auth']/username" /></user>
              </xsl:otherwise>
            </xsl:choose>
          </vsap>

        </vsap>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:otherwise>
</xsl:choose>

<!--
  This page has the following events defined:

  domain_delete_failure
  domain_delete_successful

  domain_add_failure
  domain_add_successful

  domain_edit_failure
  domain_edit_successful
-->
<xsl:if test="(/cp/form/delete != '' or /cp/form/action='delete') and (count (/cp/form/domain) > 0)"> 
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='error']/@caller = 'domain:delete'">
      <xsl:variable name="msg_error_val">
        <xsl:choose>
          <xsl:when test="count(/cp/form/domain)=1">domain_delete_failure</xsl:when>
          <xsl:otherwise>domain_multi_delete_failure</xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:call-template name="set_message">
        <xsl:with-param name="name"><xsl:value-of select="$msg_error_val" /></xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <xsl:variable name="msg_success_val">
        <xsl:choose>
          <xsl:when test="count(/cp/form/domain)=1">domain_delete_successful</xsl:when>
          <xsl:otherwise>domain_multi_delete_successful</xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:call-template name="set_message">
        <xsl:with-param name="name"><xsl:value-of select="$msg_success_val" /></xsl:with-param>
      </xsl:call-template>
    </xsl:otherwise>
  </xsl:choose>
</xsl:if>

<xsl:if test="/cp/vsap/vsap[@type='domain:enable']">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='error']/@caller='domain:enable'">
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">domain_enable_failure</xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">domain_enable_successful</xsl:with-param>
      </xsl:call-template>
    </xsl:otherwise>
  </xsl:choose>
</xsl:if>

<xsl:if test="/cp/vsap/vsap[@type='domain:disable']">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='error']/@caller='domain:disable'">
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">domain_disable_failure</xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">domain_disable_successful</xsl:with-param>
      </xsl:call-template>
    </xsl:otherwise>
  </xsl:choose>
</xsl:if>

<showpage />

</meta>
</xsl:template>
</xsl:stylesheet>
