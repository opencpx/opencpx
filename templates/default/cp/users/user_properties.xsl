<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../cp_global.xsl" />

<xsl:variable name="message">
  <xsl:choose>
    <xsl:when test="/cp/msgs/msg[@name='user_edit_successful']">
        '<xsl:copy-of select="/cp/form/login_id" />'<xsl:copy-of select="/cp/strings/cp_msg_user_edit" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="feedback">
  <xsl:if test="$message != ''">
    <xsl:call-template name="feedback_table">
      <xsl:with-param name="image">
        <xsl:choose>
          <xsl:when test="/cp/vsap/vsap[@type='error']">error</xsl:when>
          <xsl:otherwise>success</xsl:otherwise>
        </xsl:choose>
      </xsl:with-param>
      <xsl:with-param name="message">
        <xsl:copy-of select="$message" />
      </xsl:with-param>
    </xsl:call-template>
  </xsl:if>
</xsl:variable>

<xsl:variable name="have_mail_applications">
  <xsl:choose>
    <xsl:when test="($webmail_package='1' and /cp/vsap/vsap[@type='user:properties']/user/capability/webmail)">1</xsl:when>
    <xsl:when test="($clamav_package='1' and /cp/vsap/vsap[@type='user:properties']/user/capability/mail-clamav)">1</xsl:when>
    <xsl:when test="($spamassassin_package='1' and /cp/vsap/vsap[@type='user:properties']/user/capability/mail-spamassassin)">1</xsl:when>
    <xsl:otherwise>0</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="loginid">
  <xsl:value-of select="/cp/vsap/vsap[@type='user:properties']/user/login_id" />
</xsl:variable>

<xsl:variable name="eu_prefix">
  <xsl:value-of select="/cp/vsap/vsap[@type='user:properties']/user/eu_prefix" />
</xsl:variable>

<xsl:variable name="comments">
  <xsl:value-of select="/cp/vsap/vsap[@type='user:properties']/user/eu_prefix" />
</xsl:variable>

<xsl:variable name="type">
  <xsl:value-of select="/cp/vsap/vsap[@type='user:properties']/user/usertype" />
</xsl:variable>

<xsl:template match="/">
  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title"><xsl:copy-of select="/cp/strings/cp_title" /> : <xsl:copy-of select="/cp/strings/bc_user_list" /> : <xsl:copy-of select="/cp/strings/bc_user_properties" /><xsl:value-of select="/cp/vsap/vsap[@type='user:properties']/user/login_id" /></xsl:with-param>
    <!-- The only form action on this page is the "Ok" button which just redirects back to the user list -->
    <xsl:with-param name="formaction">index.xsl</xsl:with-param>
    <xsl:with-param name="feedback" select="$feedback" />
    <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_user_list" />
    <xsl:with-param name="help_short" select="/cp/strings/user_properties_hlp_short" />
    <xsl:with-param name="help_long">
      <xsl:choose>
        <xsl:when test="$type = 'da' or $type = 'sa'">
          <xsl:copy-of select="/cp/strings/user_properties_da_hlp_long" />
        </xsl:when>
        <xsl:when test="$type = 'ma'">
          <xsl:copy-of select="/cp/strings/user_properties_ma_hlp_long" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:copy-of select="/cp/strings/user_properties_eu_hlp_long" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:with-param>
    <xsl:with-param name="breadcrumb">
      <breadcrumb>
        <section>
          <name><xsl:copy-of select="/cp/strings/bc_user_list" /></name>
          <url><xsl:value-of select="$base_url" />/cp/users/index.xsl</url>
        </section>
        <section>
          <name><xsl:copy-of select="/cp/strings/bc_user_properties" /><xsl:value-of select="/cp/vsap/vsap[@type='user:properties']/user/login_id" /></name>
          <url>#</url>
          <image>UserManagement</image>
        </section>
      </breadcrumb>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

      <table class="formview" border="0" cellspacing="0" cellpadding="0">
        <tr class="title">
          <td colspan="2"><xsl:copy-of select="/cp/strings/cp_title_properties" /><xsl:value-of select="/cp/vsap/vsap[@type='user:properties']/user/login_id" /></td>
        </tr>
        <tr class="instructionrow">
          <td colspan="2">
            <xsl:copy-of select="/cp/strings/user_properties_instr1" />
              <!-- determine user type here -->
              <xsl:choose>
                <xsl:when test="$type = 'sa'">
                  <xsl:copy-of select="/cp/strings/cp_sa" />
                </xsl:when>
                <xsl:when test="$type = 'da'">
                  <xsl:copy-of select="/cp/strings/cp_da" />
                </xsl:when>
                <xsl:when test="$type = 'ma'">
                  <xsl:copy-of select="/cp/strings/cp_ma" />
                </xsl:when>
                <xsl:otherwise>
                  <xsl:copy-of select="/cp/strings/cp_eu" />
                </xsl:otherwise>
              </xsl:choose>
            <xsl:copy-of select="/cp/strings/user_properties_instr2" />
          </td>
        </tr>
        <tr class="title">
          <td colspan="2">
            <xsl:copy-of select="/cp/strings/cp_title_profile" />
              <a href="{$base_url}/cp/users/user_edit_profile.xsl?login_id={$loginid}"><xsl:copy-of select="/cp/strings/user_properties_edit" /></a>
          </td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:copy-of select="/cp/strings/cp_label_full_name" /></td>
          <td class="contentwidth"><xsl:value-of select="/cp/vsap/vsap[@type='user:properties']/user/fullname" /></td>
        </tr>
        <tr class="roweven">
          <td class="label"><xsl:copy-of select="/cp/strings/cp_label_login_id" /></td>
          <td class="contentwidth"><xsl:value-of select="/cp/vsap/vsap[@type='user:properties']/user/login_id" /></td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:copy-of select="/cp/strings/cp_label_password" /></td>
          <td class="contentwidth"><xsl:copy-of select="/cp/strings/cp_pw_stars" /></td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:copy-of select="/cp/strings/cp_label_home_directory" /></td>
          <td class="contentwidth"><xsl:value-of select="/cp/vsap/vsap[@type='user:properties']/user/home_dir" /></td>
        </tr>

        <xsl:choose>
          <xsl:when test="$type = 'sa'">
            <tr class="roweven">
              <td class="label"><xsl:copy-of select="/cp/strings/cp_label_server_disk_space" /></td>
              <td class="contentwidth">
                <xsl:call-template name="print_quota">
                  <xsl:with-param name="quota" select="/cp/vsap/vsap[@type='user:properties']/user/quota" />
                </xsl:call-template>
              </td>
            </tr>
            <tr class="roweven">
              <td class="label"><xsl:copy-of select="/cp/strings/cp_label_user_disk_space" /></td>
              <td class="contentwidth">
                <xsl:call-template name="print_quota">
                  <xsl:with-param name="quota" select="/cp/vsap/vsap[@type='user:properties']/user/user_quota" />
                </xsl:call-template>
              </td>
            </tr>
          </xsl:when>
          <xsl:otherwise>
            <tr class="roweven">
              <td class="label"><xsl:copy-of select="/cp/strings/cp_label_user_disk_space" /></td>
              <td class="contentwidth">
                <xsl:call-template name="print_quota">
                  <xsl:with-param name="quota" select="/cp/vsap/vsap[@type='user:properties']/user/quota" />
                </xsl:call-template>
              </td>
            </tr>
          </xsl:otherwise>
        </xsl:choose>

        <xsl:if test="$type = 'da'">
          <tr class="rowodd">
            <td class="label"><xsl:copy-of select="/cp/strings/cp_label_end_user_quota" /></td>
            <td class="contentwidth">
              <xsl:call-template name="print_quota">
                <xsl:with-param name="quota" select="/cp/vsap/vsap[@type='user:properties']/user/end_user_quota" />
              </xsl:call-template>
            </td>
          </tr>
          <tr class="roweven">
            <td class="label"><xsl:copy-of select="/cp/strings/cp_label_group_quota" /></td>
            <td class="contentwidth">
              <xsl:call-template name="print_quota">
                <xsl:with-param name="quota" select="/cp/vsap/vsap[@type='user:properties']/user/group_quota" />
              </xsl:call-template>
            </td>
          </tr>
        </xsl:if>
        <xsl:choose>
          <xsl:when test="$type = 'da' or $type = 'sa'">
            <tr class="roweven">
              <xsl:choose>
                <xsl:when test="$type = 'sa'">
                  <td class="label"><xsl:copy-of select="/cp/strings/cp_label_sa_privs" /></td>
                </xsl:when>
                <xsl:otherwise>
                  <td class="label"><xsl:copy-of select="/cp/strings/cp_label_da_privs" /></td>
                </xsl:otherwise>
              </xsl:choose>
              <td class="contentwidth">
                <xsl:call-template name="list_services">
                  <xsl:with-param name="services" select="/cp/vsap/vsap[@type='user:properties']/user/services" />
                </xsl:call-template>
              </td>
            </tr>
            <tr class="rowodd">
              <td class="label"><xsl:copy-of select="/cp/strings/cp_label_eu_privs" /></td>
              <td class="contentwidth">
                <xsl:choose>
                  <xsl:when test="$type='sa'">
                    <xsl:copy-of select="concat(/cp/strings/cp_service_mail,', ',/cp/strings/cp_service_ftp,', ',/cp/strings/cp_service_fm)" />
                    <xsl:if test="not(/cp/vsap/vsap[@type='auth']/siteprefs/disable-shell)">
                      <xsl:copy-of select="concat(',  ',/cp/strings/cp_service_shell)" />
                    </xsl:if>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:call-template name="list_eu_capabilities">
                      <xsl:with-param name="eu_capability" select="/cp/vsap/vsap[@type='user:properties']/user/eu_capability" />
                    </xsl:call-template>
                  </xsl:otherwise>
                </xsl:choose>
              </td>
            </tr>
            <tr class="rowodd">
              <td class="label"><xsl:copy-of select="/cp/strings/user_profile_eu_prefix" /></td>
              <td class="contentwidth"><xsl:value-of select="/cp/vsap/vsap[@type='user:properties']/user/eu_prefix" /></td>
            </tr>
            <tr class="roweven">
              <td class="label"><xsl:copy-of select="/cp/strings/cp_label_domains" /></td>
              <td class="contentwidth">
                <xsl:for-each select="/cp/vsap/vsap[@type='user:properties']/user/domains/domain">
                  <xsl:choose>
                    <xsl:when test="$type='sa'">
                      <a href="http://{name}"><xsl:value-of select="name" /></a>&#160;
                    </xsl:when>
                    <xsl:when test="admin = $loginid">
                      <a href="http://{name}"><xsl:value-of select="name" /></a>&#160;
                    </xsl:when>
                  </xsl:choose>
                </xsl:for-each>
              </td>
            </tr>
          </xsl:when>
          <xsl:otherwise>
            <xsl:if test="not(/cp/vsap/vsap[@type='auth']/siteprefs/disable-mail-admin)">
              <xsl:if test="$user_type='sa' or $user_type='da' or ($user_type='ma' and $type='ma')">
                <tr class="rowodd">
                  <td class="label"><xsl:value-of select="/cp/strings/cp_label_auth_rights" /></td>
                  <td class="contentwidth">
                    <xsl:choose>
                      <xsl:when test="$type='ma'">
                        <xsl:value-of select="/cp/strings/cp_label_auth_rights_mail_admin" />
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="/cp/strings/user_profile_auth_rights_none" />
                      </xsl:otherwise>
                    </xsl:choose>
                  </td>
                </tr>
              </xsl:if>
            </xsl:if>

            <tr class="roweven">
              <xsl:choose>
                <xsl:when test="$type='ma'">
                  <td class="label"><xsl:copy-of select="/cp/strings/cp_label_ma_privs" /></td>
                </xsl:when>
                <xsl:otherwise>
                  <td class="label"><xsl:copy-of select="/cp/strings/cp_label_eu_privs" /></td>
                </xsl:otherwise>
              </xsl:choose>
              <td class="contentwidth">
                <xsl:call-template name="list_services">
                  <xsl:with-param name="services" select="/cp/vsap/vsap[@type='user:properties']/user/services" />
                </xsl:call-template>
              </td>
            </tr>
            <tr class="rowodd">
              <td class="label"><xsl:copy-of select="/cp/strings/cp_label_domain" /></td>
              <td class="contentwidth">
                <a href="http://{/cp/vsap/vsap[@type='user:properties']/user/domain}">
                  <xsl:value-of select="/cp/vsap/vsap[@type='user:properties']/user/domain" />
                </a>
              </td>
            </tr>
          </xsl:otherwise>
        </xsl:choose>
        <tr class="rowodd">
          <td class="label"><xsl:copy-of select="/cp/strings/user_profile_comments" /></td>
          <td class="contentwidth"><xsl:value-of select="/cp/vsap/vsap[@type='user:properties']/user/comments" /></td>
        </tr>

        <xsl:if test="/cp/vsap/vsap[@type='user:properties']/user/services/mail">
          <tr class="title">
            <td colspan="2"><xsl:copy-of select="/cp/strings/cp_title_mail_setup" /><xsl:if test="$have_mail_applications='1'"><a href="{$base_url}/cp/users/user_edit_mail.xsl?login_id={$loginid}"><xsl:copy-of select="/cp/strings/user_properties_edit" /></a></xsl:if></td>
          </tr>
          <tr class="rowodd">
            <td class="label"><xsl:copy-of select="/cp/strings/cp_label_mailbox_name" /></td>
            <td class="contentwidth">
              <xsl:value-of select="$loginid" /></td>
          </tr>
          <tr class="roweven">
            <td class="label"><xsl:copy-of select="/cp/strings/cp_label_email_addresses" /></td>
            <td class="contentwidth">
              <xsl:for-each select="/cp/vsap/vsap[@type='mail:addresses:list']/address">
                <xsl:value-of select="source" /><br />
              </xsl:for-each>
              <xsl:if test="count(/cp/vsap/vsap[@type='mail:addresses:list']/address) = '0'">
                <br />
              </xsl:if>
            </td>
          </tr>
          <xsl:if test="$have_mail_applications='1'">
            <tr class="rowodd">
              <td class="label"><xsl:copy-of select="/cp/strings/cp_label_mail_applications" /></td>
              <td class="contentwidth"><xsl:value-of select="/cp/vsap/mail_apps" />
                <xsl:call-template name="list_mail_capabilities">
                  <xsl:with-param name="capabilities" select="/cp/vsap/vsap[@type='user:properties']/user/capability" />
                </xsl:call-template>
              </td>
            </tr>
          </xsl:if>
        </xsl:if>

        <tr class="controlrow">
          <td colspan="2">
            <input class="floatright" type="submit" name="ok" value="{/cp/strings/user_properties_btn_ok}" />
            <input type="button" name="profile" value="{/cp/strings/user_properties_btn_edit_profile}" onClick="window.location='{$base_url}/cp/users/user_edit_profile.xsl?login_id={$loginid}'"/>
            <xsl:if test="$have_mail_applications='1' and /cp/vsap/vsap[@type='user:properties']/user/services/mail">
             <input type="button" name="mail" value="{/cp/strings/user_properties_btn_edit_mail_setup}" onClick="window.location='{$base_url}/cp/users/user_edit_mail.xsl?login_id={$loginid}'"/>
            </xsl:if>
          </td>
        </tr>
      </table>

</xsl:template>

</xsl:stylesheet>
