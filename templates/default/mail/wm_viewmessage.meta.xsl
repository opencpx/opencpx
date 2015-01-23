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

  <xsl:when test="/cp/form/delete and string-length(/cp/form/next_uid) = 0">
    <redirect>
      <path>mail/wm_messages.xsl</path>
    </redirect>
  </xsl:when>

  <xsl:when test="/cp/form/move = 'yes'">
    <redirect>
      <path>mail/wm_messages.xsl</path>
    </redirect>
  </xsl:when>

  <xsl:otherwise>
    <!-- only call vsap if we aren't deleting or moving -->
    <xsl:call-template name="dovsap">
      <xsl:with-param name="vsap">
        <vsap>

          <xsl:if test="/cp/form/delete">
            <xsl:choose>
              <xsl:when test="/cp/form/uid > 0 and string(/cp/form/folder) = 'Trash'">
                <vsap type="webmail:messages:delete">
                  <folder><xsl:value-of select="/cp/form/folder" /></folder>
                  <xsl:for-each select="/cp/form/uid"><uid><xsl:value-of select="." /></uid></xsl:for-each>
                  <sortby><xsl:value-of select="/cp/form/sort_by" /></sortby>
                  <order><xsl:value-of select="/cp/form/sort_type" /></order>
                  <num_messages><xsl:value-of select="/cp/form/num_messages" /></num_messages>
                </vsap>
              </xsl:when>

              <xsl:when test="/cp/form/uid > 0">
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
          </xsl:if>

          <xsl:choose>
            <xsl:when test="string(/cp/form/download) = 'true'">
              <vsap type="webmail:messages:attachment">
                <uid><xsl:value-of select="/cp/form/uid" /></uid>
                <attach_id><xsl:value-of select="/cp/form/attach_id" /></attach_id>
                <folder><xsl:value-of select="/cp/form/folder" /></folder>
              </vsap>
            </xsl:when>

            <xsl:otherwise>
              <vsap type="webmail:messages:read">
                <uid><xsl:choose>
                  <xsl:when test="/cp/form/delete and string-length(/cp/form/next_uid) > 0">
                    <xsl:value-of select="/cp/form/next_uid" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="/cp/form/uid" />
                  </xsl:otherwise>
                </xsl:choose></uid>
                <folder><xsl:value-of select="/cp/form/folder" /></folder>
                <encoding><xsl:value-of select="/cp/form/try_encoding" /></encoding>
                <sortby><xsl:value-of select="/cp/form/sort_by" /></sortby>
                <order><xsl:value-of select="/cp/form/sort_type" /></order>
                <viewpref><xsl:value-of select="/cp/form/viewpref" /></viewpref>
                <localimages><xsl:value-of select="/cp/form/localimages" /></localimages>
                <remoteimages><xsl:value-of select="/cp/form/remoteimages" /></remoteimages>
                <xsl:if test="string(/cp/form/reply) or string(/cp/form/reply_all) or string(/cp/form/forward)">
                  <quote><xsl:value-of select="/cp/form/quote" /></quote>
                  <beautify>no</beautify>
                  <strip_html>1</strip_html>
                </xsl:if>
              </vsap>
              <vsap type="webmail:messages:flag">
                <uid><xsl:value-of select="/cp/form/uid" /></uid>
                <folder><xsl:value-of select="/cp/form/folder" /></folder>
                <flag>\Seen</flag>
              </vsap>

              <vsap type="webmail:folders:list"><fast/></vsap>
            </xsl:otherwise>
          </xsl:choose>

          <!-- for clientencoding -->
          <vsap type="user:prefs:load" />
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
            <xsl:with-param name="name">move_dest_write_failure</xsl:with-param>
          </xsl:call-template>
        </xsl:if>
        <xsl:if test="/cp/vsap/vsap[@type='error'][@caller='webmail:messages:move']/code = '117'">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">move_dest_over_quota</xsl:with-param>
          </xsl:call-template>
        </xsl:if>
      </xsl:when>
    </xsl:choose>
  </xsl:otherwise>
</xsl:choose>

<xsl:if test="/cp/form/reply or /cp/form/reply_all or /cp/form/forward">
  <redirect>
    <path>mail/wm_compose.xsl</path>
  </redirect>
</xsl:if>

<showpage />

</meta>
</xsl:template>
</xsl:stylesheet>
