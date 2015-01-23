<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../../global.meta.xsl" />
<xsl:import href="../cp_global.meta.xsl" />
<xsl:template match="/">
<meta>

<xsl:call-template name="auth">
  <xsl:with-param name="require_class">ma</xsl:with-param>
  <xsl:with-param name="require_mail">1</xsl:with-param>
</xsl:call-template>

<xsl:call-template name="cp_global"/>

<xsl:variable name="admin_type">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='auth']/server_admin">sa</xsl:when>
    <xsl:otherwise>da</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:call-template name="dovsap">
  <xsl:with-param name="vsap">
    <vsap>
      <vsap type="domain:list" />
      <vsap type="user:list_brief" />
    </vsap>
  </xsl:with-param>
</xsl:call-template>

<xsl:choose>
 <xsl:when test="/cp/form/Save='1'">

  <xsl:call-template name="dovsap">
    <xsl:with-param name="vsap">
      <vsap>
        <vsap type="mail:addresses:exists">
          <source><xsl:value-of select="/cp/form/lhs"/></source>
          <domain><xsl:value-of select="/cp/form/domain"/></domain>
        </vsap>
      </vsap>
    </xsl:with-param>
  </xsl:call-template>

  <xsl:variable name="domain_name">
    <xsl:value-of select="/cp/form/domain" />
  </xsl:variable>
  <xsl:variable name="email_count">
    <xsl:value-of select="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain_name]/mail_aliases/usage" />
  </xsl:variable>
  <xsl:variable name="email_limit">
    <xsl:value-of select="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain_name]/mail_aliases/limit" />
  </xsl:variable>
  <xsl:variable name="remaining_email">
    <xsl:choose>
      <xsl:when test="$email_limit='unlimited'">1</xsl:when>
      <xsl:otherwise><xsl:value-of select="$email_limit - $email_count" /></xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="action" select="/cp/form/function" />

  <xsl:variable name="email_add_ok">
    <xsl:choose>
      <xsl:when test="$action = 'update'">1</xsl:when>
      <xsl:when test="/cp/form/Save='1'"> 
        <xsl:choose>
          <xsl:when test="$remaining_email &lt;= 0">0</xsl:when>
          <xsl:otherwise>1</xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>1</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:choose>
    <xsl:when test="$action = 'add' and /cp/vsap/vsap[@type='mail:addresses:exists']/exists='1'">
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">email_address_exists</xsl:with-param>
      </xsl:call-template>
      <redirect>
        <path>cp/email/index.xsl</path>
      </redirect>
      <showpage />
    </xsl:when>
    <xsl:when test="$email_add_ok='0'">
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">emails_maxed_out</xsl:with-param>
      </xsl:call-template>
      <redirect>
        <path>cp/email/index.xsl</path>
      </redirect>
      <showpage />
    </xsl:when>
    <xsl:when test="$email_add_ok='1'">
      <xsl:call-template name="dovsap">
        <xsl:with-param name="vsap">
          <vsap>
            <vsap type="mail:addresses:{$action}">
              <source><xsl:value-of select="/cp/form/lhs"/>@<xsl:value-of select="/cp/form/domain"/></source>
              <xsl:choose>
                <xsl:when test="/cp/form/delivery = 'reject'">
                  <dest type="reject"/>
                </xsl:when>
                <xsl:when test="/cp/form/delivery = 'delete'">
                  <dest type="delete"/>
                </xsl:when>
                <xsl:when test="/cp/form/delivery = 'local'">
                  <dest><xsl:value-of select="/cp/form/local_mailbox"/></dest>
                </xsl:when>
                <xsl:when test="/cp/form/delivery = 'list'">
                  <dest><xsl:value-of select="/cp/form/address_list"/></dest>
                </xsl:when>
              </xsl:choose>
            </vsap>
          </vsap>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:when>
  </xsl:choose>

  <xsl:if test="$action='add'">
    <xsl:choose>
      <xsl:when test="/cp/vsap/vsap[@type='error']/@caller='mail:addresses:add'">
        <xsl:choose>
          <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='mail:addresses:add']/code = 100">
            <xsl:call-template name="set_message">
              <xsl:with-param name="name">add_email_permission</xsl:with-param>
            </xsl:call-template>
          </xsl:when>
          <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='mail:addresses:add']/code = 101">
            <xsl:call-template name="set_message">
              <xsl:with-param name="name">add_email_invalid</xsl:with-param>
            </xsl:call-template>
          </xsl:when>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="/cp/vsap/vsap[@type='mail:addresses:add']/status='ok'">
        <xsl:call-template name="set_message">
          <xsl:with-param name="name">email_add_successful</xsl:with-param>
        </xsl:call-template>
      </xsl:when>
    </xsl:choose>
  </xsl:if>

  <xsl:if test="$action='update'">
    <xsl:choose>
      <xsl:when test="/cp/vsap/vsap[@type='error']/@caller='mail:addresses:update'">
        <xsl:choose>
          <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='mail:addresses:update']/code = 100">
            <xsl:call-template name="set_message">
              <xsl:with-param name="name">update_email_permission</xsl:with-param>
            </xsl:call-template>
          </xsl:when>
          <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='mail:addresses:update']/code = 101">
            <xsl:call-template name="set_message">
              <xsl:with-param name="name">update_email_invalid</xsl:with-param>
            </xsl:call-template>
          </xsl:when>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="set_message">
          <xsl:with-param name="name">email_edit_successful</xsl:with-param>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:if>

  <xsl:choose>
    <xsl:when test="$action = 'add' and /cp/vsap/vsap[@type='mail:addresses:exists']/exists='0' and $email_add_ok='1' and not(/cp/vsap/vsap[@type='error'])">
      <redirect>
        <path>cp/email/index.xsl</path>
      </redirect>
    </xsl:when>
    <xsl:when test="$action = 'update' and not(/cp/vsap/vsap[@type='error'])">
      <redirect>
        <path>cp/email/index.xsl</path>
      </redirect>
    </xsl:when>
  </xsl:choose>

 </xsl:when>

 <xsl:when test="string(/cp/form/Cancel)">
  <redirect>
    <path>cp/email/index.xsl</path>
  </redirect>
 </xsl:when>

 <xsl:otherwise>
  <xsl:call-template name="dovsap">
    <xsl:with-param name="vsap">
      <vsap>
        <vsap type="mail:addresses:list" >
          <domain><xsl:value-of select="/cp/form/domain" /></domain>
        </vsap>
        <vsap type="user:list_brief" />
      </vsap>
    </xsl:with-param>
  </xsl:call-template>
 </xsl:otherwise>

</xsl:choose>

<showpage />

</meta>
</xsl:template>
</xsl:stylesheet>
