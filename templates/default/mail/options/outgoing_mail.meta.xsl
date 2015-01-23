<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:import href="../../global.meta.xsl" />
  <xsl:template match="/">
  <meta>

    <xsl:call-template name="auth">
      <xsl:with-param name="require_mail">1</xsl:with-param>
      <xsl:with-param name="require_webmail">1</xsl:with-param>
    </xsl:call-template>

    <xsl:call-template name="dovsap">
      <xsl:with-param name="vsap">
        <vsap>
          <xsl:choose>
            <xsl:when test="string(/cp/form/save)">
              <!-- Save posted options to disk -->
              <vsap type="webmail:options:save">
                <from_name><xsl:value-of select="/cp/form/from_name" /></from_name>
                <preferred_from><xsl:value-of select="/cp/form/preferred_from" /></preferred_from>
                <xsl:if test="/cp/form/reply_to_toggle = 'select'">
                  <reply_to><xsl:value-of select="/cp/form/reply_to_select" /></reply_to>
                </xsl:if>
                <xsl:if test="/cp/form/reply_to_toggle = 'input'">
                  <reply_to><xsl:value-of select="/cp/form/reply_to_input" /></reply_to>
                </xsl:if>
                <reply_to_toggle><xsl:value-of select="/cp/form/reply_to_toggle" /></reply_to_toggle>
                <signature_toggle><xsl:value-of select="/cp/form/signature_toggle" /></signature_toggle>
                <signature><xsl:value-of select="/cp/form/signature" /></signature>
                <outbound_encoding><xsl:value-of select="/cp/form/outbound_encoding" /></outbound_encoding>
                <fcc><xsl:value-of select="/cp/form/fcc" /></fcc>
              </vsap>
              <!-- Load options to DOM -->
              <vsap type="webmail:options:load"/>
            </xsl:when>
            <xsl:when test="not(/cp/vsap/vsap[@type='error'])">
              <!-- Load options to DOM -->
              <vsap type="webmail:options:load"/>
            </xsl:when>
          </xsl:choose>
          <vsap type="user:properties">
            <user><xsl:value-of select="/cp/vsap/vsap[@type='auth']/username" /></user>
          </vsap>
          <vsap type="mail:addresses:list">
            <rhs><xsl:value-of select="/cp/vsap/vsap[@type='auth']/username" /></rhs>
          </vsap>
        </vsap>
      </xsl:with-param>
    </xsl:call-template>


    <xsl:choose>
      <xsl:when test="string(/cp/form/save)">
        <xsl:choose>
          <!-- save options error -->
          <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='webmail:options:save']/code = '102'">
            <xsl:call-template name="set_message">
              <xsl:with-param name="name" select="'wm_opt_outgoing_saved_error_reply-to'"/>
              <xsl:with-param name="value" select="'error'"/>
            </xsl:call-template>
            <showpage/>
          </xsl:when>

          <!-- quota exceeded error -->
          <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='webmail:options:save']/code = '106'">
            <xsl:call-template name="set_message">
              <xsl:with-param name="name" select="'wm_opt_outgoing_saved_failure'"/>
              <xsl:with-param name="value" select="'error'"/>
            </xsl:call-template>
            <showpage/>
          </xsl:when>

          <!-- save options success -->
          <xsl:when test="/cp/vsap/vsap[@type='webmail:options:save']/status = 'ok'">
            <xsl:call-template name="set_message">
              <xsl:with-param name="name" select="'wm_opt_outgoing_saved_success'"/>
              <xsl:with-param name="value" select="'ok'"/>
            </xsl:call-template>
            <showpage/>
          </xsl:when>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <showpage/>
      </xsl:otherwise>
    </xsl:choose>
  </meta>
  </xsl:template>
</xsl:stylesheet>
