<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../../global.meta.xsl" />
<xsl:import href="../cp_global.meta.xsl" />
<xsl:template match="/">
<meta>

<xsl:call-template name="auth">
  <xsl:with-param name="require_class">sa</xsl:with-param>
</xsl:call-template>

<xsl:call-template name="cp_global"/>

<xsl:choose>
  <xsl:when test="string(/cp/form/cancel)">
    <redirect>
      <path>cp/domains/index.xsl</path>
    </redirect>
  </xsl:when>
  <xsl:when test="/cp/form/next">
    <!-- nothing, just show the preview page -->
  </xsl:when>
  <xsl:when test="/cp/form/previous">
    <redirect>
      <path>cp/domains/domain_add_setup.xsl</path>
    </redirect>
  </xsl:when>
  <xsl:when test="/cp/form/save or /cp/form/save_another">
    <xsl:call-template name="dovsap">
      <xsl:with-param name="vsap">
        <vsap>
          <vsap type="domain:add">
            <admin><xsl:value-of select="/cp/form/admin" /></admin>
            <domain><xsl:value-of select="/cp/form/domain" /></domain>
            <xsl:if test="/cp/form/ip_address">
              <ip><xsl:value-of select="/cp/form/ip_address"/></ip>
            </xsl:if>
            <www_alias>
              <xsl:choose>
                <xsl:when test="/cp/form/www_alias = 1">1</xsl:when>
                <xsl:otherwise>0</xsl:otherwise>
              </xsl:choose>
            </www_alias>
            <other_aliases><xsl:value-of select="/cp/form/other_aliases" /></other_aliases>
            <cgi>
              <xsl:choose>
                <xsl:when test="/cp/form/cgi = 1">1</xsl:when>
                <xsl:otherwise>0</xsl:otherwise>
              </xsl:choose>
            </cgi>
            <ssl>
              <xsl:choose>
                <xsl:when test="/cp/form/ssl = 1">1</xsl:when>
                <xsl:otherwise>0</xsl:otherwise>
              </xsl:choose>
            </ssl>
            <xsl:choose>
              <xsl:when test="/cp/form/end_users = 'limit'">
                <end_users><xsl:value-of select="/cp/form/end_users_limit" /></end_users>
              </xsl:when>
              <xsl:otherwise>
                <end_users>unlimited</end_users>
              </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
             <xsl:when test="/cp/form/email_addr = 'limit'">
               <email_addrs><xsl:value-of select="/cp/form/email_addr_limit" /></email_addrs>
             </xsl:when>
              <xsl:otherwise>
                <email_addrs>unlimited</email_addrs>
              </xsl:otherwise>
            </xsl:choose>
            <website_logs><xsl:value-of select="/cp/form/website_logs" /></website_logs>
            <xsl:if test="/cp/form/log_rotate_select != 'no'"> 
              <log_rotate><xsl:value-of select="/cp/form/log_rotate" /></log_rotate>
              <log_save><xsl:value-of select="/cp/form/log_save" /></log_save>
            </xsl:if>
            <domain_contact><xsl:value-of select="/cp/form/domain_contact" /></domain_contact>
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
          </vsap>
        </vsap>

        <xsl:if test="/cp/vsap/vsap[@type='domain:add']/status='ok'">
          <!-- add a mail entry for the domain contact if domain:add was successful -->
          <vsap>
            <vsap type="mail:addresses:add">
              <source><xsl:value-of select="/cp/form/domain_contact" /></source>
              <dest><xsl:value-of select="/cp/form/admin" /></dest>
            </vsap>
          </vsap>
        </xsl:if>

      </xsl:with-param>
    </xsl:call-template>
  </xsl:when>
  <xsl:otherwise>
    <!-- this should only happen if someone tries to access this 
         page without going through domain_add_setup.xsl -->
    <redirect>
      <path>cp/domains/domain_add_setup.xsl</path>
    </redirect>
  </xsl:otherwise>
</xsl:choose>

<!--
  This page has the following events defined:

  domain_add_failure
  domain_add_successful

-->
<xsl:if test="/cp/form/save or /cp/form/save_another">
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
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='domain:add']/code = 115">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">vaddhost_failed</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
      </xsl:choose>  
      <redirect>
        <path>cp/domains/domain_add_setup.xsl</path>
      </redirect>
    </xsl:when>  
    <xsl:otherwise>
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">domain_add_successful</xsl:with-param>
      </xsl:call-template>
      <xsl:choose>
        <xsl:when test="/cp/form/save">
          <redirect>
            <path>cp/domains/index.xsl</path>
          </redirect>
        </xsl:when>
        <xsl:otherwise>
          <redirect>
            <path>cp/domains/domain_add_setup.xsl</path>
          </redirect>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:otherwise>
  </xsl:choose>
</xsl:if>

<showpage />

</meta>
</xsl:template>
</xsl:stylesheet>
