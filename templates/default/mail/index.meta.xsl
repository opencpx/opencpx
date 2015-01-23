<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../global.meta.xsl" />
<xsl:template match="/">
<meta>

<!-- run auth code -->
<xsl:call-template name="auth">
  <xsl:with-param name="require_mail">1</xsl:with-param>
</xsl:call-template>

<xsl:choose>
  <xsl:when test="(/cp/vsap/vsap[@type='auth']/services/webmail) and not(/cp/vsap/vsap[@type='auth']/siteprefs/disable-webmail)">
    <!-- peach changes; redirect users with webmail privs to inbox -->
    <redirect>
      <path>mail/wm_messages.xsl</path>
    </redirect>
  </xsl:when>
  <xsl:otherwise>
    <!-- non-webmail (mail-only) user -->
    <xsl:call-template name="dovsap">
      <xsl:with-param name="vsap">
        <vsap>
          <vsap type='user:prefs:load' />
          <vsap type='user:properties'>
            <user><xsl:value-of select="/cp/vsap/vsap[@type='auth']/username" /></user>
          </vsap>
          <vsap type='mail:forward:status' />
          <vsap type='mail:autoreply:status' />
        </vsap>
      </xsl:with-param>
    </xsl:call-template>

    <xsl:variable name="clamav_package">
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='auth']/siteprefs/disable-clamav">0</xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='auth']/packages/mail-clamav">1</xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:if test="($clamav_package='1')">
      <xsl:call-template name="dovsap">
        <xsl:with-param name="vsap">
          <vsap>
            <vsap type='mail:clamav:status' />
          </vsap>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:if>

    <xsl:variable name="spamassassin_package">
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='auth']/siteprefs/disable-spamassassin">0</xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='auth']/packages/mail-spamassassin">1</xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:if test="($spamassassin_package='1')">
      <xsl:call-template name="dovsap">
        <xsl:with-param name="vsap">
          <vsap>
            <vsap type='mail:spamassassin:status' />
          </vsap>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:if>

    <showpage/>
  </xsl:otherwise>
</xsl:choose>

</meta>
</xsl:template>
</xsl:stylesheet>
