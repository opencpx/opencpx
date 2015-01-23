<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
  xmlns:exslt="http://exslt.org/common"
  exclude-result-prefixes="exslt">
<xsl:import href="../../global.meta.xsl" />

  <xsl:template name="extract_csv_list">
    <xsl:param name="list" />

    <xsl:variable name="nlist" select="$list" />
    <xsl:variable name="first" select="substring-before($nlist, ',')" />
    <xsl:variable name="rest" select="substring-after($nlist, ',')" />
    <xsl:if test="string($first)">
      <address><xsl:value-of select="$first" /></address>
    </xsl:if>
    <xsl:if test="string($rest)">
      <xsl:call-template name="extract_csv_list">
        <xsl:with-param name="list" select="$rest" />
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

<xsl:template match="/">
<meta>

<!-- run auth code -->
<xsl:call-template name="auth">
  <xsl:with-param name="require_mail">1</xsl:with-param>
  <xsl:with-param name="require_webmail">1</xsl:with-param>
</xsl:call-template>

<xsl:call-template name="dovsap">
  <xsl:with-param name="vsap">
    <vsap>
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='error']">
          <vsap type="webmail:addressbook:load">
          </vsap>
        </xsl:when>
        <xsl:when test="string(/cp/form/save_group) or string(/cp/form/save_another)"> 
          <vsap type="webmail:distlist:add">
            <xsl:if test="string(/cp/form/edit)">
              <edit />
              <listid><xsl:value-of select="/cp/form/listid" /></listid>
            </xsl:if>
            <name><xsl:value-of select="/cp/form/txtListName" /></name>
            <nickname><xsl:value-of select="/cp/form/txtNickname" /></nickname>
            <description><xsl:value-of select="/cp/form/comment" /></description>
            <xsl:variable name="id_list">
              <xsl:choose>
                <xsl:when test="string(/cp/form/ids)">
                  <xsl:call-template name="extract_csv_list">
                    <xsl:with-param name="list" select="/cp/form/ids" />
                  </xsl:call-template>
                </xsl:when> 
                <xsl:otherwise></xsl:otherwise> 
              </xsl:choose>
            </xsl:variable>
            <xsl:variable name="allAddresses" select="exslt:node-set($id_list)" />
            <xsl:for-each select="$allAddresses/address">
              <xsl:variable name="email">
                <xsl:value-of select="substring-before(.,'|')" />
              </xsl:variable>
              <xsl:variable name="rest">
                <xsl:value-of select="substring-after(.,'|')" />
              </xsl:variable>
              <xsl:variable name="first">
                <xsl:value-of select="substring-before($rest,'|')" />
              </xsl:variable>
              <xsl:variable name="last">
                <xsl:value-of select="substring-after($rest,'|')" />
              </xsl:variable>
              <entry>
                <first><xsl:value-of select="$first" /></first>
                <last><xsl:value-of select="$last" /></last>
                <address><xsl:value-of select="$email" /></address>
              </entry>
            </xsl:for-each>
          </vsap>
          <xsl:if test="string(/cp/form/save_another)">
            <vsap type="webmail:addressbook:load">
            </vsap>
          </xsl:if>
        </xsl:when>
        <xsl:when test="string(cp/form/listid) and not(string(/cp/form/cancel))">
          <vsap type="webmail:distlist:list">
            <listid><xsl:value-of select="/cp/form/listid" /></listid>
          </vsap>
          <vsap type="webmail:addressbook:load">
          </vsap>
        </xsl:when>
        <xsl:when test="not(string(/cp/form/cancel))">
          <vsap type="webmail:addressbook:load">
          </vsap>
        </xsl:when>
      </xsl:choose>
    </vsap>
  </xsl:with-param>
</xsl:call-template>

<xsl:choose>
  <xsl:when test="boolean(/cp/vsap/vsap[@type='error'])">
    <showpage />
  </xsl:when>
  <xsl:when test="string(/cp/form/save_group) or string(/cp/form/cancel)">
    <redirect>
      <path>mail/address_book/wm_addresses.xsl</path>
    </redirect>
  </xsl:when>
  <xsl:otherwise>
    <showpage />
  </xsl:otherwise>
</xsl:choose>

</meta>
</xsl:template>
</xsl:stylesheet>
