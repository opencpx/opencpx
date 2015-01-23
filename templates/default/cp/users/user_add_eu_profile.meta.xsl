<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../../global.meta.xsl" />
<xsl:import href="../cp_global.meta.xsl" />
<xsl:template match="/">
<meta>

<xsl:if test="string(/cp/form/btnCancel)">
  <redirect>
    <path>cp/users/index.xsl</path>
  </redirect>
</xsl:if>

<xsl:call-template name="auth">
  <xsl:with-param name="require_class">da</xsl:with-param>
  <xsl:with-param name="check_diskspace">0</xsl:with-param>
</xsl:call-template>

<xsl:call-template name="cp_global"/>

<xsl:call-template name="dovsap">
  <xsl:with-param name="vsap">
    <vsap>
<!--
    <xsl:if test="string(/cp/form/btnSave) or string(/cp/form/btnSaveAnother)">
-->

<xsl:choose>
  <xsl:when test="string(/cp/form/btnSave) or string(/cp/form/btnSaveAnother)">

      <vsap type="user:add">
        <fullname><xsl:value-of select="/cp/form/txtFullName" /></fullname>
        <comments><xsl:value-of select="/cp/form/txtComments" /></comments>
        <login_id><xsl:value-of select="/cp/form/txtLoginID_Prefix" /><xsl:value-of select="/cp/form/txtLoginID" /></login_id>
        <password><xsl:value-of select="/cp/form/txtPassword" /></password>
        <confirm_password><xsl:value-of select="/cp/form/txtConfirmPassword" /></confirm_password>
        <email_prefix><xsl:value-of select="/cp/form/txtAlias" /></email_prefix>
        <quota><xsl:value-of select="/cp/form/txtQuota" /></quota>
            <eu>
              <domain><xsl:value-of select="/cp/form/selectName" /></domain>
              <xsl:if test="string(/cp/form/checkboxUserMail)">
                <mail_privs/>
              </xsl:if>
              <xsl:if test="string(/cp/form/checkboxUserMail) and string(/cp/form/checkboxWebmail)">
                <webmail_privs/>
              </xsl:if>
              <xsl:if test="string(/cp/form/checkboxUserFtp)">
                <ftp_privs/>
              </xsl:if>
              <xsl:if test="string(/cp/form/checkboxUserFM)">
                <fileman_privs/>
              </xsl:if>
              <xsl:if test="string(/cp/form/checkboxUserShell)">
                <shell_privs/>
                <shell><xsl:value-of select="/cp/form/selectShell" /></shell>
              </xsl:if>
            </eu>
      </vsap>
  
      <xsl:if test="string(/cp/form/checkboxUserMail)">
        <vsap type="user:mail:setup">
          <user><xsl:value-of select="/cp/form/txtLoginID_Prefix" /><xsl:value-of select="/cp/form/txtLoginID" /></user>
          <xsl:choose>
            <xsl:when test="/cp/form/type='da'">
              <domain><xsl:value-of select="/cp/form/txtDomain" /></domain>
            </xsl:when>
            <xsl:otherwise>
              <domain><xsl:value-of select="/cp/form/selectName" /></domain>
            </xsl:otherwise>
          </xsl:choose>
          <email_prefix><xsl:value-of select="/cp/form/txtAlias" /></email_prefix>
          <xsl:if test="string(/cp/form/checkboxWebmail)">
            <capa_webmail/>
          </xsl:if>
          <xsl:if test="string(/cp/form/checkboxSpamassassin)">
            <capa_spamassassin/>
          </xsl:if>
          <xsl:if test="string(/cp/form/checkboxClamav)">
            <capa_clamav/>
          </xsl:if>
        </vsap>
        <!-- enable SpamAssassin for user by default when capa is granted (per USE08994) -->
        <xsl:if test="string(/cp/form/checkboxSpamassassin)">
          <vsap type="mail:spamassassin:enable">
            <user><xsl:value-of select="/cp/form/txtLoginID_Prefix" /><xsl:value-of select="/cp/form/txtLoginID" /></user>
          </vsap>
        </xsl:if>
        <!-- enable ClamAV for user by default when capa is granted (per USE08994) -->
        <xsl:if test="string(/cp/form/checkboxClamav)">
          <vsap type="mail:clamav:enable">
            <user><xsl:value-of select="/cp/form/txtLoginID_Prefix" /><xsl:value-of select="/cp/form/txtLoginID" /></user>
          </vsap>
        </xsl:if>
      </xsl:if>
<!--
    </xsl:if>
-->
    </xsl:when>
<!-- btnSave, btnSaveAnother -->
    <xsl:otherwise>

<!--
i don't see where mail_next ever gets set to a value...
it does show up as a hidden on a few pages...

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
-->

    </xsl:otherwise>
  </xsl:choose>

<!--
apparently this crap is to be run regardless of where we're going...
however, seems like the first 2 (at least) only need to be run if no btnSave or (yes btnSave and no error)
-->
      <vsap type="domain:list_ips" />  <!-- do this on all platforms (ENH18508) -->
      <vsap type="user:shell:list" />

      <vsap type="user:properties">
        <user><xsl:value-of select="/cp/vsap/vsap[@type='auth']/username"/></user>
      </vsap>
<!-- fix for bug 4811 - need domain:list to determine whether to display 'add end user' and 'add email address' -->
      <vsap type="domain:list">
        <properties />
      </vsap>
    </vsap>
  </xsl:with-param>
</xsl:call-template>

<!-- this needs to be done after user:add -->
<xsl:call-template name="dovsap">
  <xsl:with-param name="vsap">
    <vsap>
      <vsap type="diskspace" />
    </vsap>
  </xsl:with-param>
</xsl:call-template>

<!--
this is the previous button on the Preview page...
i don't have this page anymore...
<xsl:choose>
  <xsl:when test="/cp/form/btnPreviewPrevious">
    <xsl:choose>
      <xsl:when test="/cp/form/type='da'">
        <redirect>
          <path>cp/users/user_add_domain.xsl</path>
        </redirect>
      </xsl:when>
      <xsl:when test="string(/cp/form/checkboxUserMail)">
        <redirect>
          <path>cp/users/user_add_mail.xsl</path>
        </redirect>
      </xsl:when>
      <xsl:otherwise>
        <redirect>
          <path>cp/users/user_add_profile.xsl</path>
        </redirect>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:when>
</xsl:choose>
-->

<!--
  This page has the following events defined:

  miscellaneious failure conditions defined 
  user_add_successful

  TODO: If user:add ok, but mail:setup failed - have to do something about rm'ing the user
        likewise if user:add,mail:setup successful, but add:domain failed

-->
<xsl:if test="/cp/form/btnSave or /cp/form/btnSaveAnother">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='error']/@caller='user:add'">
      <!-- set a generic error to notify xsl file that error did occur -->
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">user_add_failure</xsl:with-param>
      </xsl:call-template>
      <xsl:choose>

<!--
i bet these are the ones that i'll have to move over from add_eu_profile.meta...
-->
<!-- skipping 100, 200-220 : these are redundant and already tested before calling vsap -->

<!-- skipping 101-104 : inapplicable error conditions to user:add -->

<!--
maybe these overwrite the above generic error?
-->

        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:add']/code = 105">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_permission</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:add']/code = 205">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_login_bad_chars</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:add']/code = 206">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_login_first_char_invalid</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:add']/code = 221">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_eu_quota_exceeded</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:add']/code = 222">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_unknown_domain</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:add']/code = 223">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_service_verboten</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:add']/code = 224">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_vadduser_error</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:add']/code = 225">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_login_exists</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:add']/code = 227">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_eu_quota_allocation_failure</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:add']/code = 228">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_home_exists</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:add']/code = 229">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">email_bad_chars</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:add']/code = 230">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_prefix_too_long</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:add']/code = 231">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_prefix_bad_chars</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:add']/code = 232">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_prefix_first_char_invalid</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='user:add']/code = 233">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">user_prefix_duplicate</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
      </xsl:choose>
<!--
      <redirect>
        <path>cp/users/user_add_profile.xsl</path>
      </redirect>
-->
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='error']/@caller='user:mail:setup'">
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

<!--
probably showpage, or something here...
-->
      <redirect>
        <path>cp/users/user_add_mail.xsl</path>
      </redirect>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='error']">
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">user_internal_error</xsl:with-param>
      </xsl:call-template>
<!-- for now redirecting to first page - may need to change domain name -->
      <redirect>
<!--        <path>cp/users/user_add_profile.xsl</path> -->
        <path>cp/users/user_add_eu_profile.xsl</path>
      </redirect>
    </xsl:when>

<!--
here is the else, which will redirect to index.xsl, or wherever...
-->
    <xsl:otherwise>
      <xsl:call-template name="set_message">
        <xsl:with-param name="name">user_add_successful</xsl:with-param>
      </xsl:call-template>
      <xsl:choose>
        <xsl:when test="string(/cp/form/btnSaveAnother)">
          <redirect>
            <path>cp/users/user_add_profile.xsl</path>
          </redirect>
        </xsl:when>
        <xsl:otherwise>
          <redirect>
            <path>cp/users/index.xsl</path>
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
