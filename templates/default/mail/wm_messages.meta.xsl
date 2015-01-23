<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../global.meta.xsl" />
<xsl:template match="/">
<meta>

<xsl:call-template name="auth">
  <xsl:with-param name="require_mail">1</xsl:with-param>
  <xsl:with-param name="require_webmail">1</xsl:with-param>
</xsl:call-template>

<xsl:choose>
  <xsl:when test="/cp/form/compose">
    <redirect>
      <path>mail/wm_compose.xsl</path>
    </redirect>
  </xsl:when>
  <xsl:otherwise>
    <xsl:call-template name="dovsap">
      <xsl:with-param name="vsap">
        <vsap>
          <xsl:choose>
            <xsl:when test="(string(/cp/form/delete) != '') and (count (/cp/form/uid) > 0) and string(/cp/form/folder) = 'Trash'">
              <vsap type="webmail:messages:delete">
                <folder><xsl:value-of select="/cp/form/folder" /></folder>
                <xsl:for-each select="/cp/form/uid"><uid><xsl:value-of select="." /></uid></xsl:for-each>
                <sortby><xsl:value-of select="/cp/form/sort_by" /></sortby>
                <order><xsl:value-of select="/cp/form/sort_type" /></order>
                <num_messages><xsl:value-of select="/cp/form/num_messages" /></num_messages>
              </vsap>
            </xsl:when>

            <xsl:when test="(string(/cp/form/delete) != '') and (count(/cp/form/uid) > 0)">
              <vsap type="webmail:messages:move">
                <folder><xsl:value-of select="/cp/form/folder" /></folder>
                <xsl:for-each select="/cp/form/uid"><uid><xsl:value-of select="." /></uid></xsl:for-each>
                <num_messages><xsl:value-of select="/cp/form/num_messages" /></num_messages>
                <dest_folder>Trash</dest_folder>
                <sortby><xsl:value-of select="/cp/form/sort_by" /></sortby>
                <order><xsl:value-of select="/cp/form/sort_type" /></order>
              </vsap>
            </xsl:when>
          </xsl:choose>

          <xsl:if test="(string(/cp/form/move) != '') and (count(/cp/form/uid) > 0)">
            <vsap type="webmail:messages:move">
              <folder><xsl:value-of select="/cp/form/folder" /></folder>
                <xsl:for-each select="/cp/form/uid"><uid><xsl:value-of select="." /></uid></xsl:for-each>
              <dest_folder><xsl:value-of select="/cp/form/dest_folder" /></dest_folder>
              <num_messages><xsl:value-of select="/cp/form/num_messages" /></num_messages>
              <sortby><xsl:value-of select="/cp/form/sort_by" /></sortby>
              <order><xsl:value-of select="/cp/form/sort_type" /></order>
            </vsap>
          </xsl:if>

          <xsl:if test="/cp/form/emptytrash">
            <vsap type="webmail:folders:clear">
              <folder>Trash</folder>
            </vsap>
          </xsl:if>

<!-- upon sending a message from compose, the values for webmail_options are lost,
     though the vsap hash entry '_wm_options_loaded' still report them as loaded (see bug 4868)
     (the following line forces the option values to be set - redundant for all but sending an email)
-->
          <vsap type="webmail:options:load"></vsap>
          <vsap type='webmail:options:fetch'><inbox_checkmail/><attachment_view/></vsap>

          <vsap type="webmail:folders:list"><fast/></vsap>
          <vsap type="webmail:messages:list">
            <reload_prefs/>
            <page>
              <xsl:choose>
                <xsl:when test="number(/cp/form/page) > 0"><xsl:value-of select="/cp/form/page" /></xsl:when>
                <xsl:otherwise>1</xsl:otherwise>
              </xsl:choose>
            </page>
            <folder>
              <xsl:choose>
                <xsl:when test="string(/cp/form/save_draft)">Drafts</xsl:when>
                <xsl:when test="string(/cp/form/save_send)">INBOX</xsl:when>
                <xsl:when test="string(/cp/form/folder)"><xsl:value-of select="/cp/form/folder" /></xsl:when>
                <xsl:otherwise>INBOX</xsl:otherwise>
              </xsl:choose>
            </folder>
            <sortby><xsl:value-of select="/cp/form/sort_by" /></sortby>
            <order><xsl:value-of select="/cp/form/sort_type" /></order>
          </vsap>
          <vsap type="user:prefs:load"></vsap>
        </vsap>
      </xsl:with-param>
    </xsl:call-template>
    <xsl:choose>
      <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='webmail:messages:move']">
        <xsl:if test="/cp/vsap/vsap[@type='error'][@caller='webmail:messages:move']/code = '112'">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">move_src_read_failure</xsl:with-param>
          </xsl:call-template>
        </xsl:if>
        <xsl:if test="/cp/vsap/vsap[@type='error'][@caller='webmail:messages:move']/code = '113'">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">move_src_write_failure</xsl:with-param>
          </xsl:call-template>
        </xsl:if>
        <xsl:if test="/cp/vsap/vsap[@type='error'][@caller='webmail:messages:move']/code = '114'">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">move_dest_write_failure</xsl:with-param>
          </xsl:call-template>
        </xsl:if>
        <xsl:if test="/cp/vsap/vsap[@type='error'][@caller='webmail:messages:move']/code = '115'">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">move_failure</xsl:with-param>
          </xsl:call-template>
        </xsl:if>
        <xsl:if test="/cp/vsap/vsap[@type='error'][@caller='webmail:messages:move']/code = '117'">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">move_dest_over_quota</xsl:with-param>
          </xsl:call-template>
        </xsl:if>
      </xsl:when>
    </xsl:choose>
 
    <showpage />

  </xsl:otherwise>
</xsl:choose>

</meta>
</xsl:template>
</xsl:stylesheet>
