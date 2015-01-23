<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../../global.meta.xsl" />
<xsl:import href="../cp_global.meta.xsl" />
<xsl:template match="/">
<meta>

<xsl:call-template name="auth">
  <xsl:with-param name="require_class">ma</xsl:with-param>
  <xsl:with-param name="check_diskspace">0</xsl:with-param>
</xsl:call-template>

<xsl:call-template name="cp_global"/>

<xsl:variable name="user_type">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='auth']/server_admin">sa</xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='auth']/domain_admin">da</xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='auth']/mail_admin">ma</xsl:when>
    <xsl:otherwise>eu</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="user_name">
  <xsl:value-of select="/cp/vsap/vsap[@type='auth']/username" />
</xsl:variable>

<xsl:choose>
  <xsl:when test="/cp/form/add_eu or /cp/form/add_ma or /cp/form/add_da">
    <redirect>
      <path>cp/users/user_add_profile.xsl</path>
    </redirect>
  </xsl:when>
  <xsl:otherwise>
    <xsl:if test="(string(/cp/form/delete) != '') and (count (/cp/form/login_id) > 0)">
      <xsl:call-template name="dovsap">
        <xsl:with-param name="vsap">
          <vsap>
            <vsap type="user:remove">
              <xsl:for-each select="/cp/form/login_id"><user><xsl:value-of select="." /></user></xsl:for-each>
            </vsap>
          </vsap>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:if>

    <xsl:call-template name="dovsap">
      <xsl:with-param name="vsap">
        <vsap>
          <xsl:if test="string(/cp/form/set_status)">
            <vsap type="user:edit">
              <user><xsl:value-of select="/cp/form/login_id" /></user>
              <status><xsl:value-of select="/cp/form/set_status" /></status>
            </vsap>
          </xsl:if>

          <xsl:if test="/cp/vsap/vsap[@type='auth']/server_admin">
            <vsap type="user:list_da" />
          </xsl:if>

          <vsap type="domain:list">
            <properties />
          </vsap>

          <vsap type="user:list">
            <xsl:if test="/cp/form/select_domain != ''">
              <domain><xsl:value-of select="/cp/form/select_domain" /></domain>
            </xsl:if>
            <xsl:if test="/cp/form/select_admin != ''">
              <admin><xsl:value-of select="/cp/form/select_admin" /></admin>
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

        </vsap>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:otherwise>
</xsl:choose>

<!-- this needs to be done after user:remove -->
<xsl:call-template name="dovsap">
  <xsl:with-param name="vsap">
    <vsap>
      <vsap type="diskspace" />
    </vsap>
  </xsl:with-param>
</xsl:call-template>

<!--
  This page has the following events defined:

  user_delete_failure
  user_delete_successful

  user_set_status_failure
  user_set_status_successful
-->
<xsl:if test="(string(/cp/form/delete) != '') and (count (/cp/form/login_id) > 0)">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='error']/@caller = 'user:remove'">
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:remove']/code = 250">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_delete_threshold_exceeded</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <!-- FIXME: what happens when you can delete some but not others? -->
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_delete_failure</xsl:with-param>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:otherwise>
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">user_delete_successful</xsl:with-param>
      </xsl:call-template>
    </xsl:otherwise>
  </xsl:choose>
</xsl:if>
<xsl:if test="/cp/form/set_status">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:edit']/code = 105">
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">user_set_status_failure_user_permission</xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='error']/@caller = 'user:edit'">
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">user_set_status_failure_other</xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">user_set_status_successful</xsl:with-param>
      </xsl:call-template>
    </xsl:otherwise>
  </xsl:choose>
</xsl:if>

<showpage />

</meta>
</xsl:template>
</xsl:stylesheet>
