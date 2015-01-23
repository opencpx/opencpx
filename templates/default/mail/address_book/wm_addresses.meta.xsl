<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
  xmlns:exslt="http://exslt.org/common"
  exclude-result-prefixes="exslt">
<xsl:import href="../../global.meta.xsl" />
<xsl:template match="/">
<meta>

<!-- run auth code -->
<xsl:call-template name="auth">
  <xsl:with-param name="require_mail">1</xsl:with-param>
  <xsl:with-param name="require_webmail">1</xsl:with-param>
</xsl:call-template>

<xsl:if test="string(/cp/form/impexp)">
  <redirect>
    <path>mail/address_book/wm_import_export.xsl</path>
  </redirect>
</xsl:if>

<xsl:if test="string(/cp/form/addcontact)">
  <redirect>
    <path>mail/address_book/wm_addcontact.xsl</path>
  </redirect>
</xsl:if>

<xsl:if test="string(/cp/form/addlist)">
  <redirect>
    <path>mail/address_book/wm_distlist.xsl</path>
  </redirect>
</xsl:if>

<xsl:call-template name="dovsap">
  <xsl:with-param name="vsap">
    <vsap>
      <xsl:choose>
        <xsl:when test="string(/cp/form/save_quickadd)">
          <vsap type="webmail:addressbook:add">
            <First_Name><xsl:value-of select="/cp/form/txtFirst" /></First_Name>
            <Last_Name><xsl:value-of select="/cp/form/txtLast" /></Last_Name>
            <Email_Address><xsl:value-of select="/cp/form/txtEmail" /></Email_Address>
          </vsap>
        </xsl:when>
        <xsl:when test="count(/cp/form/cbUserID)">
            <vsap type="webmail:addressbook:delete">
            <xsl:for-each select="/cp/form/cbUserID">
              <xsl:if test="starts-with(.,'ind')">
                <uid><xsl:value-of select="substring-after(.,'|')" /></uid>
              </xsl:if>
            </xsl:for-each>
            </vsap>
            <vsap type="webmail:distlist:delete">
            <xsl:for-each select="/cp/form/cbUserID">
              <xsl:if test="starts-with(.,'group')">
                <listid><xsl:value-of select="substring-after(.,'|')" /></listid>
              </xsl:if>
            </xsl:for-each>
           </vsap>
        </xsl:when>
      </xsl:choose>
      <xsl:if test="/cp/form/sort_by != '' or /cp/form/sort_type != ''">
        <vsap type="webmail:options:save">
          <addresses_order><xsl:value-of select="/cp/form/sort_type" /></addresses_order>
          <addresses_sortby><xsl:value-of select="/cp/form/sort_by" /></addresses_sortby>
        </vsap>
      </xsl:if>
      <vsap type="webmail:addressbook:load"/>
      <vsap type="webmail:distlist:list" />
      <vsap type='webmail:options:fetch'>
        <addresses_order/>
        <addresses_sortby/>
      </vsap>
    </vsap>
  </xsl:with-param>
</xsl:call-template>

<showpage />

</meta>
</xsl:template>
</xsl:stylesheet>
