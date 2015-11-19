<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../cp_global.xsl" />

<xsl:variable name="message">
  <xsl:choose>
    <xsl:when test="/cp/msgs/msg[@name='profile_password_change_success']">
      <xsl:copy-of select="/cp/strings/profile_password_change_success" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='profile_shell_change_success']">
      <xsl:copy-of select="/cp/strings/profile_shell_change_success" />
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

<xsl:template match="/">
  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title">
      <xsl:copy-of select="/cp/strings/cp_title" />
      v<xsl:value-of select="/cp/vsap/vsap[@type='auth']/version" /> :
      <xsl:copy-of select="/cp/strings/bc_profile" />
    </xsl:with-param>
    <xsl:with-param name="formaction">index.xsl</xsl:with-param>
    <xsl:with-param name="feedback" select='$feedback' />
    <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_view_profile" />
    <xsl:with-param name="help_short" select="/cp/strings/profile_index_hlp_short" />
    <xsl:with-param name="help_long" select="/cp/strings/profile_index_hlp_long" />
    <xsl:with-param name="breadcrumb">
      <breadcrumb>
        <section>
          <name><xsl:copy-of select="/cp/strings/bc_profile" /></name>
          <url>#</url>
          <image>Profile</image>
        </section>
      </breadcrumb>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

      <table class="formview" border="0" cellspacing="0" cellpadding="0">
        <tr class="title">
          <td colspan="2"><xsl:copy-of select="/cp/strings/profile_title" /></td>
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
          <td class="contentwidth"><xsl:copy-of select="/cp/strings/cp_pw_stars" /> <a 
            class="indent" href="{$base_url}/cp/profile/password.xsl"><xsl:copy-of select="/cp/strings/profile_change_password" /></a></td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:copy-of select="/cp/strings/cp_label_home_directory" /></td>
          <td class="contentwidth"><xsl:value-of select="/cp/vsap/vsap[@type='user:properties']/user/home_dir" /></td>
        </tr>

        <xsl:choose>
          <xsl:when test="$user_type='sa'">
            <tr class="roweven">
              <td class="label">
                <xsl:copy-of select="/cp/strings/cp_label_server_disk_space" />
              </td>
              <td class="contentwidth">
                <xsl:call-template name="print_quota">
                  <xsl:with-param name="quota" select="/cp/vsap/vsap[@type='user:properties']/user/quota" />
                </xsl:call-template>
              </td>
            </tr>
            <tr class="roweven">
              <td class="label">
                <xsl:copy-of select="/cp/strings/cp_label_user_disk_space" />
              </td>
              <td class="contentwidth">
                <xsl:call-template name="print_quota">
                  <xsl:with-param name="quota" select="/cp/vsap/vsap[@type='user:properties']/user/user_quota" />
                </xsl:call-template>
              </td>
            </tr>
          </xsl:when>
          <xsl:otherwise>
            <tr class="roweven">
              <td class="label">
                <xsl:copy-of select="/cp/strings/cp_label_user_disk_space" />
              </td>
              <td class="contentwidth">
                <xsl:call-template name="print_quota">
                  <xsl:with-param name="quota" select="/cp/vsap/vsap[@type='user:properties']/user/quota" />
                </xsl:call-template>
              </td>
            </tr>
          </xsl:otherwise>
        </xsl:choose>

        <xsl:if test="$user_type = 'da'">
          <tr class="roweven">
            <td class="label"><xsl:copy-of select="/cp/strings/cp_label_end_user_quota" /></td>
            <td class="contentwidth">
              <xsl:call-template name="print_quota">
                <xsl:with-param name="quota" select="/cp/vsap/vsap[@type='user:properties']/user/end_user_quota" />
              </xsl:call-template>
            </td>
          </tr>
          <tr class="rowodd">
            <td class="label"><xsl:copy-of select="/cp/strings/cp_label_group_quota" /></td>
            <td class="contentwidth">
              <xsl:call-template name="print_quota">
                <xsl:with-param name="quota" select="/cp/vsap/vsap[@type='user:properties']/user/group_quota" />
              </xsl:call-template>
            </td>
          </tr>
        </xsl:if>

        <xsl:if test="$user_type='ma'">
          <tr class="rowodd">
            <td class="label"><xsl:value-of select="/cp/strings/cp_label_auth_rights" /></td>
            <td class="contentwidth"><xsl:value-of select="/cp/strings/cp_label_auth_rights_mail_admin" /></td>
          </tr>
        </xsl:if>

        <tr class="roweven">
          <td class="label">
            <xsl:choose>
              <xsl:when test="$user_type = 'sa'">
                <xsl:copy-of select="/cp/strings/cp_label_sa_privs" />
              </xsl:when>
              <xsl:when test="$user_type = 'da'">
                <xsl:copy-of select="/cp/strings/cp_label_da_privs" />
              </xsl:when>
              <xsl:when test="$user_type = 'ma'">
                <xsl:copy-of select="/cp/strings/cp_label_ma_privs" />
              </xsl:when>
              <xsl:otherwise>
                <xsl:copy-of select="/cp/strings/cp_label_user_privileges" />
              </xsl:otherwise>
            </xsl:choose>
          </td>
          <td class="contentwidth">
            
            <xsl:call-template name="list_services">
              <xsl:with-param name="services" select="/cp/vsap/vsap[@type='user:properties']/user/services" />
            </xsl:call-template>

            <xsl:if test="/cp/vsap/vsap[@type='user:properties']/user/services/shell">
              - <xsl:value-of select="/cp/vsap/vsap[@type='user:shell:list']/shell[@current = '1']/path" /> <a 
                class="indent" href="{$base_url}/cp/profile/shell.xsl"><xsl:copy-of select="/cp/strings/profile_change_shell" /></a>
            </xsl:if>
          </td>
        </tr>
        <xsl:choose>
          <xsl:when test="$user_type = 'sa'">
            <tr class="rowodd">
              <td class="label"><xsl:copy-of select="/cp/strings/cp_label_eu_privs" /></td>
              <td class="contentwidth">
                <xsl:choose>
                  <xsl:when test="/cp/vsap/vsap[@type='auth']/siteprefs/disable-shell">
                    <xsl:copy-of select="concat(/cp/strings/cp_service_mail,', ',/cp/strings/cp_service_ftp,', ',/cp/strings/cp_service_fm)" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:copy-of select="concat(/cp/strings/cp_service_mail,', ',/cp/strings/cp_service_ftp,', ',/cp/strings/cp_service_fm,', ',/cp/strings/cp_service_shell)" />
                  </xsl:otherwise>
                </xsl:choose>
              </td>
            </tr>
            <tr class="rowodd">
              <td class="label"><xsl:copy-of select="/cp/strings/cp_label_domains" /></td>
              <td class="contentwidth">
                <xsl:for-each select="/cp/vsap/vsap[@type='user:properties']/user/domains/domain">
                  <a href="http://{name}"><xsl:value-of select="name" /></a>
                  <xsl:if test="position() != last()">, </xsl:if>
                </xsl:for-each>
              </td>
            </tr>
          </xsl:when>
          <xsl:when test="$user_type = 'da'">
            <tr class="rowodd">
              <td class="label"><xsl:copy-of select="/cp/strings/cp_label_eu_privs" /></td>
              <td class="contentwidth">
                <xsl:call-template name="list_services">
                  <xsl:with-param name="services" select="/cp/vsap/vsap[@type='user:properties']/user/eu_capability" />
                </xsl:call-template>
              </td>
            </tr>
            <tr class="roweven">
              <td class="label"><xsl:copy-of select="/cp/strings/cp_label_domains" /></td>
              <td class="contentwidth">
                <xsl:for-each select="/cp/vsap/vsap[@type='user:properties']/user/domains/domain">
                  <a href="http://{name}"><xsl:value-of select="name" /></a>
                  <xsl:if test="position() != last()">, </xsl:if>
                </xsl:for-each>
              </td>
            </tr>
          </xsl:when>
          <xsl:otherwise>
            <tr class="rowodd">
              <td class="label"><xsl:copy-of select="/cp/strings/cp_label_domain" /></td>
              <td class="contentwidth"><a href="http://{/cp/vsap/vsap[@type='user:properties']/user/domain}"><xsl:value-of select="/cp/vsap/vsap[@type='user:properties']/user/domain" /></a></td>
            </tr>
          </xsl:otherwise>
        </xsl:choose>
      </table>

</xsl:template>

</xsl:stylesheet>
