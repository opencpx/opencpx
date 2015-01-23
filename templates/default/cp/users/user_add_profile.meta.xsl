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

<xsl:variable name="admin_type">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='auth']/server_admin">sa</xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='auth']/domain_admin">da</xsl:when>
    <xsl:otherwise>ma</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<!-- FIXME: if the default in VSAP ever changes, this will have to be
     changed also or pre-existing home directories will not be detected -->
<xsl:variable name="home_dir">
  <xsl:value-of select="concat('/home/', /cp/form/txtLoginID_Prefix, /cp/form/txtLoginID)" />
</xsl:variable>

<xsl:call-template name="dovsap">
  <xsl:with-param name="vsap">
    <vsap>
      <vsap type="user:properties">
        <user><xsl:value-of select="/cp/vsap/vsap[@type='auth']/username"/></user>
      </vsap>
      <vsap type="domain:list">
        <properties />
      </vsap>
      <vsap type="domain:list_ips" />  <!-- do this on all platforms (ENH18508) -->
      <vsap type="user:shell:list" />
      <xsl:if test="cp/form/mail_next">
        <vsap type="user:exists">
          <login_id><xsl:value-of select="/cp/form/txtLoginID_Prefix" /><xsl:value-of select="/cp/form/txtLoginID" /></login_id>
        </vsap>
        <vsap type="user:home_exists">
          <home_dir><xsl:value-of select="$home_dir" /></home_dir>
        </vsap>
        <xsl:if test="string(/cp/form/txtDomain)">
          <vsap type="domain:exists">
            <domain><xsl:value-of select="/cp/form/txtDomain" /></domain>
          </vsap>
        </xsl:if>
      </xsl:if>
    </vsap>
  </xsl:with-param>
</xsl:call-template>

<xsl:choose>
  <xsl:when test="string(/cp/form/cancel)">
    <redirect>
      <path>cp/users/index.xsl</path>
    </redirect>
  </xsl:when>

  <xsl:when test="/cp/form/mail_next">
    <xsl:if test="/cp/vsap/vsap[@type='user:exists']/exists='1'">
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">user_login_exists</xsl:with-param>
      </xsl:call-template>
      <showpage />
    </xsl:if>

    <xsl:if test="/cp/vsap/vsap[@type='user:home_exists']/exists='1'">
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">user_home_exists</xsl:with-param>
      </xsl:call-template>
      <showpage />
    </xsl:if>

    <xsl:if test="string(/cp/vsap/vsap[@type='domain:exists'])">
      <xsl:if test="/cp/vsap/vsap[@type='domain:exists']/exists='1'">
        <xsl:call-template name="set_message">
          <xsl:with-param name="name">user_domain_add_exists</xsl:with-param>
        </xsl:call-template>
        <showpage />
      </xsl:if>
    </xsl:if>

<!-- if adding end-user, validate users/email addresses not maxed out -->
<!-- note: server admin is now subject to these limits (see BUG25437) -->
    <xsl:if test="(/cp/form/type='eu' or /cp/form/type='ma')">
      <xsl:variable name="domain_name">
        <xsl:value-of select="/cp/form/selectName" />
      </xsl:variable>
      <xsl:variable name="user_count">
        <xsl:value-of select="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain_name]/users/usage" />
      </xsl:variable>
      <xsl:variable name="user_limit">
        <xsl:value-of select="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain_name]/users/limit" />
      </xsl:variable>
      <xsl:variable name="user_add_ok">
        <xsl:choose>
          <xsl:when test="$user_limit='unlimited'">1</xsl:when>
          <xsl:otherwise><xsl:value-of select="$user_limit - $user_count" /></xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <xsl:if test="$user_add_ok &lt;= 0">
        <xsl:call-template name="set_message">
          <xsl:with-param name="name">users_maxed_out</xsl:with-param>
        </xsl:call-template>
        <showpage />
      </xsl:if>

      <xsl:variable name="email_count">
        <xsl:value-of select="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain_name]/mail_aliases/usage" />
      </xsl:variable>
      <xsl:variable name="email_limit">
        <xsl:value-of select="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain_name]/mail_aliases/limit" />
      </xsl:variable>
      <xsl:variable name="email_add_ok">
        <xsl:choose>
          <xsl:when test="$email_limit='unlimited'">1</xsl:when>
          <xsl:otherwise><xsl:value-of select="$email_limit - $email_count" /></xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <xsl:if test="/cp/form/checkboxUserMail and $email_add_ok &lt;= 0">
        <xsl:call-template name="set_message">
          <xsl:with-param name="name">emails_maxed_out</xsl:with-param>
        </xsl:call-template>
        <showpage />
      </xsl:if>
    </xsl:if>

    <xsl:if test="not(string(/cp/form/btnSave)) and not(string(/cp/form/btnSaveAnother)) and not(string(/cp/form/btnPreviewPrevious))">
      <xsl:choose>
        <xsl:when test="string(/cp/form/checkboxUserMail)">
          <redirect>
            <path>cp/users/user_add_mail.xsl</path>
          </redirect>
        </xsl:when>
        <xsl:otherwise>
          <xsl:choose>
            <xsl:when test="/cp/form/type='da' and /cp/form/previous">
              <!-- Nothing...supposed to be here -->
            </xsl:when>
            <xsl:when test="/cp/form/type='da'">
              <redirect>
                <path>cp/users/user_add_domain.xsl</path>
              </redirect>
            </xsl:when>
            <xsl:otherwise>
              <redirect>
                <path>cp/users/user_add_preview.xsl</path>
              </redirect>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:when>
</xsl:choose>

<showpage />

</meta>
</xsl:template>
</xsl:stylesheet>
