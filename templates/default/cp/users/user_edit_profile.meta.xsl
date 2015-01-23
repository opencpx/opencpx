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

<xsl:variable name="user_type">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='auth']/server_admin">sa</xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='auth']/domain_admin">da</xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='auth']/mail_admin">ma</xsl:when>
    <xsl:otherwise>eu</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="user_name">
  <xsl:value-of select="/cp/vsap/vsap[@type='auth']/username" />
</xsl:variable>

<!-- if adding end-user, validate email addresses not maxed out -->
<xsl:variable name="domain_name">
  <xsl:value-of select="/cp/form/domain" />
</xsl:variable>

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

<xsl:variable name="validate_email_limit">
  <xsl:choose>
    <xsl:when test="/cp/form/cancel">1</xsl:when>
    <xsl:when test="/cp/form/mail_service_exists='1'">1</xsl:when>
    <xsl:when test="$user_type = 'sa'">1</xsl:when>
    <xsl:when test="/cp/form/type != 'eu' and /cp/form/type != 'ma'">1</xsl:when>
    <xsl:when test="/cp/form/checkboxUserMail and $email_add_ok &lt;= 0">0</xsl:when>
    <xsl:otherwise>1</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<!-- check for duplicate e-mail address (BUG22588) -->
<xsl:if test="/cp/form/save='1' and /cp/form/domain != /cp/form/old_domain">
  <xsl:call-template name="dovsap">
    <xsl:with-param name="vsap">
      <vsap>
        <vsap type="mail:addresses:exists">
          <source><xsl:value-of select="/cp/form/login_id" /></source>
          <domain><xsl:value-of select="/cp/form/domain" /></domain>
        </vsap>
      </vsap>
    </xsl:with-param>
  </xsl:call-template>
</xsl:if>

<xsl:choose>
  <xsl:when test="$validate_email_limit='0'">
  </xsl:when>
  <xsl:when test="/cp/vsap/vsap[@type='mail:addresses:exists']/exists='1'">
  </xsl:when>
  <xsl:otherwise>
  <xsl:call-template name="dovsap">
   <xsl:with-param name="vsap">
    <vsap>
        <xsl:if test="/cp/form/save='1'">
          <vsap type="user:edit">
            <fullname><xsl:value-of select="/cp/form/txtFullName" /></fullname>
            <comments><xsl:value-of select="/cp/form/txtComments" /></comments>
            <eu_prefix><xsl:value-of select="/cp/form/eu_prefix" /></eu_prefix>
            <change_gecos/>
            <user><xsl:value-of select="/cp/form/login_id" /></user>
            <quota><xsl:value-of select="/cp/form/txtQuota" /></quota>
            <xsl:choose>
              <xsl:when test="/cp/form/type != 'eu' and /cp/form/type != 'ma'">
                <da>
                  <services>
                  <xsl:choose>
                    <xsl:when test="string(/cp/form/checkboxUserMail)">
                      <mail>1</mail>
                    </xsl:when>
                    <xsl:otherwise>
                      <mail>0</mail>
                      <!-- <webmail>0</webmail> -->
                    </xsl:otherwise>
                  </xsl:choose>
                  <xsl:choose>
                    <xsl:when test="string(/cp/form/checkboxUserFtp)">
                      <ftp>1</ftp>
                    </xsl:when>
                    <xsl:otherwise>
                      <ftp>0</ftp>
                    </xsl:otherwise>
                  </xsl:choose>
                  <xsl:choose>
                    <xsl:when test="string(/cp/form/checkboxUserFM)">
                      <fileman>1</fileman>
                    </xsl:when>
                    <xsl:otherwise>
                      <fileman>0</fileman>
                    </xsl:otherwise>
                  </xsl:choose>
                  <xsl:choose>
                    <xsl:when test="string(/cp/form/checkboxUserPC)">
                      <podcast>1</podcast>
                    </xsl:when>
                    <xsl:otherwise>
                      <podcast>0</podcast>
                    </xsl:otherwise>
                  </xsl:choose>
                  <xsl:choose>
                    <xsl:when test="string(/cp/form/checkboxUserShell)">
                      <shell>1</shell>
                    </xsl:when>
                    <xsl:otherwise>
                      <shell>0</shell>
                    </xsl:otherwise>
                  </xsl:choose>
                  </services>
                  <capabilities>
                    <xsl:choose>
                      <xsl:when test="string(/cp/form/checkboxUserMail)">
                        <mail>1</mail>
                      </xsl:when>
                      <xsl:otherwise>
                        <mail>0</mail>
                      </xsl:otherwise>
                    </xsl:choose>
                    <xsl:choose>
                      <xsl:when test="string(/cp/form/checkboxUserFtp)">
                        <ftp>1</ftp>
                      </xsl:when>
                      <xsl:otherwise>
                        <ftp>0</ftp>
                      </xsl:otherwise>
                    </xsl:choose>
                    <xsl:choose>
                      <xsl:when test="string(/cp/form/checkboxUserFM)">
                        <fileman>1</fileman>
                      </xsl:when>
                      <xsl:otherwise>
                        <fileman>0</fileman>
                      </xsl:otherwise>
                    </xsl:choose>
                    <xsl:choose>
                      <xsl:when test="string(/cp/form/checkboxUserShell)">
                        <shell>1</shell>
                      </xsl:when>
                      <xsl:otherwise>
                        <shell>0</shell>
                      </xsl:otherwise>
                    </xsl:choose>
                  </capabilities>
                  <xsl:if test="/cp/form/type='da'">
                    <eu_capabilities>
                      <xsl:choose>
                        <xsl:when test="string(/cp/form/checkboxEndUserMail)">
                          <mail>1</mail>
                        </xsl:when>
                        <xsl:otherwise>
                          <mail>0</mail>
                        </xsl:otherwise>
                      </xsl:choose>
                      <xsl:choose>
                        <xsl:when test="string(/cp/form/checkboxEndUserFtp)">
                          <ftp>1</ftp>
                        </xsl:when>
                        <xsl:otherwise>
                          <ftp>0</ftp>
                        </xsl:otherwise>
                      </xsl:choose>
                      <xsl:choose>
                        <xsl:when test="string(/cp/form/checkboxEndUserFM)">
                          <fileman>1</fileman>
                        </xsl:when>
                        <xsl:otherwise>
                          <fileman>0</fileman>
                        </xsl:otherwise>
                      </xsl:choose>
                      <xsl:choose>
                        <xsl:when test="string(/cp/form/checkboxEndUserShell)">
                          <shell>1</shell>
                        </xsl:when>
                        <xsl:otherwise>
                          <shell>0</shell>
                        </xsl:otherwise>
                      </xsl:choose>
                      <xsl:choose>
                        <xsl:when test="string(/cp/form/checkboxEndUserZeroQuota)">
                          <zeroquota>1</zeroquota>
                        </xsl:when>
                        <xsl:otherwise>
                          <zeroquota>0</zeroquota>
                        </xsl:otherwise>
                      </xsl:choose>
                    </eu_capabilities>
                  </xsl:if>
                </da>
              </xsl:when>

              <!-- changing an eu's (or an ma's) properties -->
              <xsl:otherwise>
                <eu>
                  <services>
                  <xsl:choose>
                    <xsl:when test="string(/cp/form/checkboxUserMail)">
                      <mail>1</mail>
                    </xsl:when>
                    <xsl:otherwise>
                      <mail>0</mail>
                    </xsl:otherwise>
                  </xsl:choose>
                  <xsl:choose>
                    <xsl:when test="string(/cp/form/checkboxUserFtp)">
                      <ftp>1</ftp>
                    </xsl:when>
                    <xsl:otherwise>
                      <ftp>0</ftp>
                    </xsl:otherwise>
                  </xsl:choose>
                  <xsl:choose>
                    <xsl:when test="string(/cp/form/checkboxUserFM)">
                      <fileman>1</fileman>
                    </xsl:when>
                    <xsl:otherwise>
                      <fileman>0</fileman>
                    </xsl:otherwise>
                  </xsl:choose>
                  <xsl:choose>
                    <xsl:when test="string(/cp/form/checkboxUserShell)">
                      <shell>1</shell>
                    </xsl:when>
                    <xsl:otherwise>
                      <shell>0</shell>
                    </xsl:otherwise>
                  </xsl:choose>
                  </services>
                  <domain><xsl:value-of select="/cp/form/domain" /></domain>
                  <old_domain><xsl:value-of select="/cp/form/old_domain" /></old_domain>
                </eu>
                <xsl:choose>
                  <xsl:when test="string(/cp/form/checkboxUserMailAdmin)">
                    <mail_admin>1</mail_admin>
                  </xsl:when>
                  <xsl:otherwise>
                    <mail_admin>0</mail_admin>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:otherwise>
            </xsl:choose>
          </vsap>
          <xsl:choose>
            <xsl:when test="string(/cp/form/checkboxUserMail) and /cp/form/mail_service_exists='0'">
              <xsl:choose>
                <xsl:when test="/cp/form/type='eu' or /cp/form/type='ma'">
                  <vsap type="user:mail:setup">
                    <user><xsl:value-of select="/cp/form/login_id" /></user>
                    <domain><xsl:value-of select="/cp/form/domain" /></domain>
                    <email_prefix><xsl:value-of select="/cp/form/login_id" /></email_prefix>
                  </vsap>
                  <vsap type="mail:addresses:add">
                    <source><xsl:value-of select="concat(/cp/form/login_id,'@',/cp/form/domain)" /></source>
                    <dest><xsl:value-of select="/cp/form/login_id" /></dest>
                  </vsap>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:variable name="admin">
                    <xsl:value-of select="/cp/form/login_id" />
                  </xsl:variable>
                  <xsl:for-each select="/cp/vsap/vsap[@type='domain:list']/domain[admin=/cp/form/login_id]">
                    <xsl:if test="admin=/cp/form/login_id">
                      <vsap type="user:mail:setup">
                        <user><xsl:value-of select="/cp/form/login_id" /></user>
                        <domain><xsl:value-of select="name" /></domain>
                        <email_prefix><xsl:value-of select="/cp/form/login_id" /></email_prefix>
                      </vsap>
                      <vsap type="mail:addresses:add">
                        <source><xsl:value-of select="concat(/cp/form/login_id,'@',name)" /></source>
                        <dest><xsl:value-of select="/cp/form/login_id" /></dest>
                      </vsap>
                    </xsl:if>
                  </xsl:for-each>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
            <xsl:when test="not(string(/cp/form/checkboxUserMail))">
              <xsl:choose>
                <xsl:when test="/cp/form/type = 'eu' or /cp/form/type = 'ma'">
                  <vsap type="mail:addresses:delete_user">
                    <user><xsl:value-of select="/cp/form/login_id" /></user>
                  </vsap>
                </xsl:when>
                <xsl:when test="/cp/form/type = 'da'">
                  <vsap type="mail:addresses:delete_user">
                    <admin><xsl:value-of select="/cp/form/login_id" /></admin>
                  </vsap>
                </xsl:when>
              </xsl:choose>
            </xsl:when>
          </xsl:choose>
          <xsl:if test="$user_type != 'ma'">
            <xsl:if test="not(/cp/vsap/vsap[@type='auth']/siteprefs/disable-shell)">
              <xsl:choose>
                <xsl:when test="string(/cp/form/checkboxUserShell)">
                  <vsap type="user:shell:change">
                    <user><xsl:value-of select="/cp/form/login_id" /></user>
                    <shell><xsl:value-of select="/cp/form/selectShell" /></shell>
                  </vsap>
                </xsl:when>  
                <xsl:otherwise>
                  <vsap type="user:shell:disable">
                    <user><xsl:value-of select="/cp/form/login_id" /></user>
                  </vsap>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:if>
          </xsl:if>
          <xsl:if test="string(/cp/form/txtPassword)">
            <vsap type="user:password:change">
              <user><xsl:value-of select="/cp/form/login_id" /></user>
              <xsl:if test="/cp/form/login_id = /cp/vsap/vsap[@type='auth']/username">
                <old_password><xsl:value-of select="/cp/form/old_password" /></old_password>
              </xsl:if>
              <new_password><xsl:value-of select="/cp/form/txtPassword" /></new_password>
              <new_password2><xsl:value-of select="/cp/form/txtConfirmPassword" /></new_password2>
            </vsap>
          </xsl:if>  
        </xsl:if>  
    </vsap>
   </xsl:with-param>
  </xsl:call-template>
  </xsl:otherwise>
</xsl:choose>

<xsl:call-template name="dovsap">
  <xsl:with-param name="vsap">
    <vsap>
      <vsap type="user:properties">
        <user><xsl:value-of select="/cp/form/login_id" /></user>
      </vsap>
      <xsl:if test="$user_type != 'ma'">
        <vsap type="user:shell:list">
          <user><xsl:value-of select="/cp/form/login_id" /></user>
        </vsap>
      </xsl:if>
      <vsap type="user:list_eu_capa">
        <admin><xsl:value-of select="/cp/vsap/vsap[@type='auth']/username" /></admin>
      </vsap>
    </vsap>
  </xsl:with-param>
</xsl:call-template>

<xsl:if test="$validate_email_limit = '0'">
  <xsl:call-template name="set_message">
    <xsl:with-param name="name">emails_maxed_out</xsl:with-param>
  </xsl:call-template>
  <showpage />
</xsl:if>

<xsl:if test="/cp/vsap/vsap[@type='mail:addresses:exists']/exists='1'">
  <xsl:call-template name="set_message">
    <xsl:with-param name="name">email_address_exists</xsl:with-param>
  </xsl:call-template>
  <showpage />
</xsl:if>

<!--
  This page has the following events defined:

  user_edit_failure
  user_edit_successful

-->
<xsl:if test="/cp/form/save != ''">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='error']">
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">user_edit_failure</xsl:with-param>
      </xsl:call-template>
      <xsl:choose>
<!-- skipping 100, 200-220 : these are redundant and already tested before calling vsap -->
<!-- skipping 101-104 : inapplicable error conditions to user:edit -->
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:edit']/code = 105">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_permission</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:edit']/code = 222">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_unknown_domain</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:edit']/code = 223">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_service_verboten</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:edit']/code = 224">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_vadduser_error</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:edit']/code = 225">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_login_exists</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:edit']/code = 226">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_eu_quota_out_of_bounds</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:edit']/code = 227">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_eu_quota_allocation_failure</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:edit']/code = 230">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_prefix_too_long</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:edit']/code = 231">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_prefix_bad_chars</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:edit']/code = 232">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_prefix_first_char_invalid</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:edit']/code = 233">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_prefix_duplicate</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
<!-- mail:setup and mail:add errors -->
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
<!-- user:password:change errors -->
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:password:change']/code = 100">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_edit_password_new_missing</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:password:change']/code = 101">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_edit_password_new_not_matching</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:password:change']/code = 102">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_edit_password_change_error</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:password:change']/code = 103">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_edit_password_old_missing</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:password:change']/code = 104">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_edit_password_old_not_matching</xsl:with-param>
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
<xsl:if test="/cp/vsap/vsap[@type='error'][@caller='user:edit']/code = 105">
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
