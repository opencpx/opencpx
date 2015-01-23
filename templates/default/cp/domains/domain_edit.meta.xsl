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

<xsl:variable name="user_type">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='auth']/server_admin">sa</xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='auth']/domain_admin">da</xsl:when>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="www_alias">
  <xsl:choose>
    <xsl:when test="/cp/form/www_alias">
      <xsl:value-of select="/cp/form/www_alias" />
    </xsl:when>
    <xsl:otherwise>0</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="cgi">
  <xsl:choose>
    <xsl:when test="/cp/form/cgi">
      <xsl:value-of select="/cp/form/cgi" />
    </xsl:when>
    <xsl:otherwise>0</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="ssl">
  <xsl:choose>
    <xsl:when test="/cp/form/ssl">
      <xsl:value-of select="/cp/form/ssl" />
    </xsl:when>
    <xsl:otherwise>0</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:choose>
  <xsl:when test="string(/cp/form/cancel)">
    <redirect>
      <path>cp/domains/domain_properties.xsl</path>
    </redirect>
  </xsl:when>
  <xsl:when test="/cp/form/save">
    <xsl:call-template name="dovsap">
      <xsl:with-param name="vsap">
        <vsap>
          <vsap type="domain:add">
            <edit>1</edit>
            <admin><xsl:value-of select="/cp/form/admin" /></admin>
            <domain><xsl:value-of select="/cp/form/domain" /></domain>
            <xsl:if test="/cp/form/ip_address">
              <ip><xsl:value-of select="/cp/form/ip_address"/></ip>
            </xsl:if>
            <xsl:if test="$user_type='sa'">
              <xsl:if test="$www_alias != /cp/form/orig_www_alias">
                <www_alias><xsl:value-of select="$www_alias"/></www_alias>
              </xsl:if>
              <xsl:if test="/cp/form/other_aliases != /cp/form/orig_other_aliases">
                <other_aliases><xsl:value-of select="/cp/form/other_aliases" /></other_aliases>
              </xsl:if>
              <xsl:if test="$cgi != /cp/form/orig_cgi">
                <cgi><xsl:value-of select="$cgi"/></cgi>
              </xsl:if>
              <xsl:if test="$ssl != /cp/form/orig_ssl">
                <ssl><xsl:value-of select="$ssl"/></ssl>
              </xsl:if>
              <xsl:if test="/cp/form/end_users != /cp/form/orig_end_users or /cp/form/end_users_limit != /cp/form/orig_end_users_limit">
                <end_users>
                  <xsl:choose>
                    <xsl:when test="/cp/form/end_users = 'limit'"><xsl:value-of select="/cp/form/end_users_limit" /></xsl:when>
                    <xsl:otherwise>unlimited</xsl:otherwise>
                  </xsl:choose>
                </end_users>
              </xsl:if>
              <xsl:if test="/cp/form/email_addr != /cp/form/orig_email_addr or /cp/form/email_addr_limit != /cp/form/orig_email_addr_limit">
                <email_addrs>
                  <xsl:choose>
                    <xsl:when test="/cp/form/email_addr = 'limit'"><xsl:value-of select="/cp/form/email_addr_limit" /></xsl:when>
                    <xsl:otherwise>unlimited</xsl:otherwise>
                  </xsl:choose>
                </email_addrs>
              </xsl:if>
              <xsl:if test="/cp/form/website_logs != /cp/form/orig_website_logs or /cp/form/log_rotate_select != /cp/form/orig_log_rotate_select or /cp/form/log_rotate != /cp/form/orig_log_rotate or /cp/form/log_save != /cp/form/orig_log_save">
                <website_logs><xsl:value-of select="/cp/form/website_logs" /></website_logs>
                <xsl:if test="/cp/form/log_rotate_select != 'no'"> 
                  <log_rotate><xsl:value-of select="/cp/form/log_rotate" /></log_rotate>
                  <log_save><xsl:value-of select="/cp/form/log_save" /></log_save>
                </xsl:if>
              </xsl:if>
            </xsl:if> 
            <xsl:if test="/cp/form/domain_contact != /cp/form/orig_domain_contact">
              <domain_contact><xsl:value-of select="/cp/form/domain_contact" /></domain_contact>
            </xsl:if> 
            <xsl:if test="/cp/form/mail_catchall != /cp/form/orig_mail_catchall or /cp/form/mail_catchall_custom != /cp/form/orig_mail_catchall_custom">
              <mail_catchall>
                <xsl:choose>
                  <xsl:when test="/cp/form/mail_catchall = 'custom'">
                    <xsl:value-of select="/cp/form/mail_catchall_custom" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="/cp/form/mail_catchall" />
                  </xsl:otherwise>
                </xsl:choose>
              </mail_catchall>
            </xsl:if> 
          </vsap>
        </vsap>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:when>
</xsl:choose>

<xsl:call-template name="dovsap">
  <xsl:with-param name="vsap">
    <vsap>
      <vsap type="domain:list">
        <domain><xsl:value-of select="/cp/form/domain" /></domain>
        <properties />
      </vsap>
      <xsl:if test="/cp/vsap/vsap[@type='auth']/platform='freebsd6' or /cp/vsap/vsap[@type='auth']/platform='linux'">
        <vsap type="domain:list_ips" />
      </xsl:if>
    </vsap>
  </xsl:with-param>
</xsl:call-template>

<!--
  This page has the following events defined:

  domain_add_failure
  domain_add_successful

-->
<xsl:if test="/cp/form/save">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='error']/@caller='domain:add'">
<!-- skipping 100,102-104,111 : these are redundant and already tested before calling vsap -->
<!-- skipping 109-110,113 : inapplicable to domain:add -->
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='domain:add']/code = 101">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">domain_permission</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='domain:add']/code = 105">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">domain_add_exists</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='domain:add']/code = 106">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">domain_admin_bad</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='domain:add']/code = 107">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">domain_log_rotate_bad</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='domain:add']/code = 108">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">domain_httpd_conf</xsl:with-param>
          </xsl:call-template>         
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='domain:add']/code = 112">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">domain_email_addrs_bad</xsl:with-param>
          </xsl:call-template>
        </xsl:when>                  
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='domain:add']/code = 113">
          <xsl:call-template name="set_message">  
            <xsl:with-param name="name">domain_email_addrs_bad</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
      </xsl:choose>                  
      <redirect>                  
        <path>cp/domains/domain_edit.xsl</path>
      </redirect>                 
    </xsl:when>
    <xsl:otherwise>
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">domain_edit_successful</xsl:with-param>
      </xsl:call-template>
      <redirect>
        <path>cp/domains/domain_properties.xsl</path>
      </redirect>       
    </xsl:otherwise>
  </xsl:choose>           
</xsl:if>

<showpage />

</meta>
</xsl:template>
</xsl:stylesheet>
