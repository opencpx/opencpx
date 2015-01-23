<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../../global.meta.xsl" />
<xsl:import href="../cp_global.meta.xsl" />
<xsl:template match="/">
<meta>

<xsl:call-template name="auth">
  <xsl:with-param name="require_class">ma</xsl:with-param>
</xsl:call-template>

<xsl:call-template name="cp_global"/>

<xsl:call-template name="dovsap">
  <xsl:with-param name="vsap">
    <vsap>
      <vsap type="domain:list">
        <properties />
      </vsap>
    </vsap>
  </xsl:with-param>
</xsl:call-template>

<xsl:if test="/cp/form/type='da'">
  <xsl:call-template name="dovsap">
    <xsl:with-param name="vsap">
      <vsap>
        <vsap type="user:list:eu">
          <user><xsl:value-of select="/cp/form/login_id" /></user>
        </vsap>
      </vsap>
    </xsl:with-param>
  </xsl:call-template>
</xsl:if>

<xsl:call-template name="dovsap">
  <xsl:with-param name="vsap">
    <vsap>
      <xsl:if test="/cp/form/save='1'">
        <!-- if removing service for user, disable capability for user -->
        <xsl:if test="not(string(/cp/form/checkboxSpamassassin))">
          <vsap type="mail:spamassassin:disable">
            <user><xsl:value-of select="/cp/form/login_id" /></user>
          </vsap>
        </xsl:if>
        <xsl:if test="not(string(/cp/form/checkboxClamav))">
          <vsap type="mail:clamav:disable">
            <user><xsl:value-of select="/cp/form/login_id" /></user>
          </vsap>
        </xsl:if>
        <!-- if removing service for domain admin, disable capability for end users -->
        <xsl:if test="/cp/form/type='da'">
          <xsl:for-each select="/cp/vsap/vsap[@type='user:list:eu']/user">
            <xsl:if test=". != /cp/form/login_id">
              <xsl:if test="not(string(/cp/form/checkboxSpamassassin))">
                <vsap type="mail:spamassassin:disable">
                  <user><xsl:value-of select="." /></user>
                </vsap>
              </xsl:if>
              <xsl:if test="not(string(/cp/form/checkboxClamav))">
                <vsap type="mail:clamav:disable">
                  <user><xsl:value-of select="." /></user>
                </vsap>
              </xsl:if>
            </xsl:if>
          </xsl:for-each>
        </xsl:if>
        <!-- formulate edit user request -->
        <vsap type="user:edit">
          <user><xsl:value-of select="/cp/form/login_id" /></user>
          <xsl:choose>
            <xsl:when test="/cp/form/type!='eu'">
              <da>
                <services>
                  <xsl:choose>
                    <xsl:when test="string(/cp/form/checkboxWebmail)">
                      <webmail>1</webmail>
                    </xsl:when>
                    <xsl:otherwise>
                      <webmail>0</webmail>
                    </xsl:otherwise>
                  </xsl:choose>
                </services>
                <capabilities>
                  <xsl:choose>
                    <xsl:when test="string(/cp/form/checkboxWebmail)">
                      <webmail>1</webmail>
                    </xsl:when>
                    <xsl:otherwise>
                      <webmail>0</webmail>
                    </xsl:otherwise>
                  </xsl:choose>
                  <xsl:choose>
                    <xsl:when test="string(/cp/form/checkboxSpamassassin)">
                      <mail-spamassassin>1</mail-spamassassin>
                    </xsl:when>
                    <xsl:otherwise>
                      <mail-spamassassin>0</mail-spamassassin>
                    </xsl:otherwise>
                  </xsl:choose>
                  <xsl:choose>
                    <xsl:when test="string(/cp/form/checkboxClamav)">
                      <mail-clamav>1</mail-clamav>
                    </xsl:when>
                    <xsl:otherwise>
                      <mail-clamav>0</mail-clamav>
                    </xsl:otherwise>
                  </xsl:choose>
                </capabilities>
              </da>
            </xsl:when>
            <xsl:otherwise>
              <eu>
                <services>
                  <xsl:choose>
                    <xsl:when test="string(/cp/form/checkboxWebmail)">
                      <webmail>1</webmail>
                    </xsl:when>
                    <xsl:otherwise>
                      <webmail>0</webmail>
                    </xsl:otherwise>
                  </xsl:choose>
                </services>
                <capabilities>
                  <xsl:choose>
                    <xsl:when test="string(/cp/form/checkboxWebmail)">
                      <webmail>1</webmail>
                    </xsl:when>
                    <xsl:otherwise>
                      <webmail>0</webmail>
                    </xsl:otherwise>
                  </xsl:choose>
                  <xsl:choose>
                    <xsl:when test="string(/cp/form/checkboxSpamassassin)">
                      <mail-spamassassin>1</mail-spamassassin>
                    </xsl:when>
                    <xsl:otherwise>
                      <mail-spamassassin>0</mail-spamassassin>
                    </xsl:otherwise>
                  </xsl:choose>
                  <xsl:choose>
                    <xsl:when test="string(/cp/form/checkboxClamav)">
                      <mail-clamav>1</mail-clamav>
                    </xsl:when>
                    <xsl:otherwise>
                      <mail-clamav>0</mail-clamav>
                    </xsl:otherwise>
                  </xsl:choose>
                </capabilities>
              </eu>
            </xsl:otherwise>
          </xsl:choose>
        </vsap> 
          
      </xsl:if>  

      <vsap type="user:properties">
        <user><xsl:value-of select="/cp/form/login_id" /></user>
      </vsap>
      <vsap type="mail:addresses:list">
        <rhs><xsl:value-of select="/cp/form/login_id" /></rhs>
      </vsap>
      <vsap type="mail:clamav:milter_installed" />
    </vsap>
  </xsl:with-param>
</xsl:call-template>

<!--
  This page has the following events defined:

  user_add_failure
  user_add_successful

-->
<xsl:if test="/cp/form/save != ''">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='error']/@caller = 'user:mail:setup'">
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">user_edit_failure</xsl:with-param>
      </xsl:call-template>
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:mail:setup']/code = 100">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_mail_permission</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:mail:setup']/code = 200">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_mail_user_missing</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:mail:setup']/code = 201">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_mail_user_unknown</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:mail:setup']/code = 202">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_mail_domain_missing</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:mail:setup']/code = 203">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_mail_domain_unknown</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:mail:setup']/code = 204">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_mail_prefix_invalid</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
      </xsl:choose>
      <showpage />
    </xsl:when>
    <xsl:otherwise>
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">user_edit_successful</xsl:with-param>
      </xsl:call-template>
    </xsl:otherwise>
  </xsl:choose>
</xsl:if>

<xsl:if test="/cp/form/save or /cp/form/cancel">
  <!-- redirect to the appropriate  page -->
  <redirect>
    <path>cp/users/user_properties.xsl</path>
  </redirect>
</xsl:if>

<!-- this can happen if a user is just trying to access users directly -->
<xsl:if test="/cp/vsap/vsap[@type='error'][@caller='user:properties']/code = 105">
  <xsl:call-template name="set_message">
    <xsl:with-param name="name">user_permission</xsl:with-param>
  </xsl:call-template>
  <redirect>
    <path>cp/users/index.xsl</path>
  </redirect>
</xsl:if>

<showpage />

</meta>
</xsl:template>
</xsl:stylesheet>
