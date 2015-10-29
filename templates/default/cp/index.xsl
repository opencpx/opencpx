<?xml version="1.0" encoding="UTF-8"?>

<!--                                                                    -->
<!-- this code is deprecated due to redirect (see index.meta.xsl)       -->
<!-- this code is not compliant with new pre-openCPX 0.12 features      -->
<!--                                                                    -->
<!--      !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!           -->
<!--      !!!!! MOVE ALONG THERE IS NOTHING TO SEE HERE !!!!!           -->
<!--      !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!           -->
<!--                                                                    -->

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="cp_global.xsl" />

<xsl:template match="/">
  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title"><xsl:copy-of select="/cp/strings/cp_title" /></xsl:with-param>
    <xsl:with-param name="formaction">cp/index.xsl</xsl:with-param>
    <xsl:with-param name="feedback" />
    <xsl:with-param name="selected_navandcontent" />
    <xsl:with-param name="help_short" select="/cp/strings/cp_index_hlp_short" />
    <xsl:with-param name="help_long" select="/cp/strings/cp_index_hlp_long" />
    <xsl:with-param name="breadcrumb">
      <breadcrumb>
      </breadcrumb>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

      <table id="homepage" border="0" cellspacing="0" cellpadding="0">
        <xsl:if test="$user_type = 'sa' or $user_type = 'da'">
          <tr>
            <td>
              <table id="homepageusermanagement" border="0" cellspacing="0" cellpadding="0">
                <tr class="title">
                  <td colspan="2" ><xsl:copy-of select="/cp/strings/cp_index_usermanagement" /></td>
                </tr>
                <tr>
                  <td class="icon"><br /></td>
                  <td><xsl:copy-of select="/cp/strings/cp_index_add_manage_users" /><br />
                    <hr />
                    <a href="{$base_url}/cp/users/"><xsl:copy-of select="/cp/strings/cp_index_user_list" /></a><br />
                    <xsl:if test="$user_type = 'sa'">
                      <a href="{$base_url}/cp/users/user_add_profile.xsl?type=da"><xsl:copy-of select="/cp/strings/cp_index_add_da" /></a><br />
                    </xsl:if>
                    <xsl:if test="$eu_add != '0'">
                      <xsl:if test="$mail_ok = '1'">
                        <a href="{$base_url}/cp/users/user_add_profile.xsl?type=ma"><xsl:copy-of select="/cp/strings/cp_index_add_ma" /></a><br />
                      </xsl:if>
                      <a href="{$base_url}/cp/users/user_add_profile.xsl?type=eu"><xsl:copy-of select="/cp/strings/cp_index_add_eu" /></a><br />
                    </xsl:if>
                  </td>
                </tr>
                <tr class="statusrow">
                  <td colspan="2">
                    <xsl:copy-of select="/cp/strings/cp_index_total_users" />
                    <xsl:value-of select="count(/cp/vsap/vsap[@type='user:list']/user)" /><br />
                    <br />
                  </td>
                </tr>
              </table>
            </td>
            <td>
              <table id="homepagedomainmanagement" border="0" cellspacing="0" cellpadding="0">
                <tr class="title">
                  <td class="home" colspan="2"><xsl:copy-of select="/cp/strings/cp_index_domain_management" /></td>
                </tr>
                <tr>
                  <td class="icon"><br /></td>
                  <td><xsl:copy-of select="/cp/strings/cp_index_manage_vh_domains" /><br />
                    <hr />
                    <a href="{$base_url}/cp/domains/"><xsl:copy-of select="/cp/strings/cp_index_domain_list" /></a><br />
                    <xsl:if test="$user_type = 'sa'">
                      <a href="{$base_url}/cp/domains/domain_add_setup.xsl"><xsl:copy-of select="/cp/strings/cp_index_add_domain" /></a><br />
                    </xsl:if>
                  </td>
                </tr>
                <tr class="statusrow">
                  <td colspan="2">
                    <xsl:copy-of select="/cp/strings/cp_index_total_domains" /> 
                    <xsl:value-of select="count(/cp/vsap/vsap[@type='domain:list']/domain)" /><br />
                    <br />
                  </td>
                </tr>
              </table>
            </td>
            <td>
              <table id="homepagemailmanagement" border="0" cellspacing="0" cellpadding="0">
                <tr class="title">
                  <td class="home" colspan="2"><xsl:copy-of select="/cp/strings/cp_index_mail_management" /></td>
                </tr>
                <tr>
                  <td class="icon"><br /></td>
                  <td><xsl:copy-of select="/cp/strings/cp_index_manage_email" /><br />
                    <hr />
                    <a href="{$base_url}/cp/email/"><xsl:copy-of select="/cp/strings/cp_index_email_addresses" /></a><br />
                    <xsl:if test="$email_add != '0'">
                      <a href="{$base_url}/cp/email/add-edit.xsl"><xsl:copy-of select="/cp/strings/cp_index_add_email" /></a><br />
                    </xsl:if>
                  </td>
                </tr>
                <tr class="statusrow">
                  <td colspan="2">
                    <xsl:copy-of select="/cp/strings/cp_index_total_addresses" />
                    <xsl:value-of select="sum(/cp/vsap/vsap[@type='domain:list']/domain/mail_aliases/usage)" /><br />
                    <br />
                  </td>
                </tr>
              </table>
            </td>
          </tr>
        </xsl:if>
        <tr>
          <xsl:if test="$fileman_ok = '1'">
            <td>
              <table id="homepagefilemanagement" border="0" cellspacing="0" cellpadding="0">
                <tr class="title">
                  <td class="home" colspan="2"><xsl:copy-of select="/cp/strings/cp_index_filemanagement" /></td>
                </tr>
                <tr>
                  <td class="icon"><br /></td>
                  <td><xsl:copy-of select="/cp/strings/cp_index_manage_files" /><br />
                    <hr />
                    <a href="{$base_url}/cp/files/"><xsl:copy-of select="/cp/strings/cp_index_file_management" /></a><br />
                  </td>
                </tr>
                <tr class="statusrow">
                  <td colspan="2"><br />
                    <br />
                  </td>
                </tr>
              </table>
            </td>
          </xsl:if>
          <td>
            <table id="homepageprofile" border="0" cellspacing="0" cellpadding="0">
              <tr class="title">
                <td class="home" colspan="2"><xsl:copy-of select="/cp/strings/cp_index_my_profile" /></td>
              </tr>
              <tr>
                <td class="icon"><br /></td>
                <td>
                  <xsl:copy-of select="/cp/strings/cp_index_change_password" /><br />
                  <hr />
                  <a href="{$base_url}/cp/profile/"><xsl:copy-of select="/cp/strings/cp_index_view_profile" /></a><br />
                  <a href="{$base_url}/cp/profile/password.xsl"><xsl:copy-of select="/cp/strings/cp_index_change_my_password" /></a><br />
                </td>
              </tr>
              <tr class="statusrow">
                <td colspan="2"><br />
                  <br />
                </td>
              </tr>
            </table>
          </td>
          <td>
            <table id="homepagepreferences" border="0" cellspacing="0" cellpadding="0">
              <tr class="title">
                <td class="home" colspan="2"><xsl:copy-of select="/cp/strings/cp_index_preferences" /></td>
              </tr>
              <tr>
                <td class="icon"><br /></td>
                <td><xsl:copy-of select="/cp/strings/cp_index_manage_prefs" /><br />
                  <hr />
                  <a href="{$base_url}/cp/prefs/autologout.xsl"><xsl:copy-of select="/cp/strings/cp_index_auto_logout" /></a><br />
                  <a href="{$base_url}/cp/prefs/datetime.xsl"><xsl:copy-of select="/cp/strings/cp_index_date_time" /></a><br />
                  <xsl:if test="$fileman_ok = '1'">
                    <a href="{$base_url}/cp/prefs/fm.xsl"><xsl:copy-of select="/cp/strings/cp_index_fm_prefs" /></a><br />
                  </xsl:if>
                </td>
              </tr>
              <tr class="statusrow">
                <td colspan="2"><br />
                  <br />
                </td>
              </tr>
            </table>
          </td>
          <xsl:if test="$fileman_ok != '1'">
            <td>
              <table id="homepagespacer" border="0" cellspacing="0" cellpadding="0">
                <tr>
                  <td />
                </tr>
              </table>
            </td>
          </xsl:if>
        </tr>

       <xsl:if test="$user_type != 'eu'">
          <tr>          
            <td>
              <table id="homepageserveradmin" border="0" cellspacing="0" cellpadding="0">
                <tr class="title">
                  <td class="home" colspan="2"><xsl:copy-of select="/cp/strings/cp_index_sysadmin" /></td>
                </tr>
                <tr>
                  <td class="icon"><br /></td>
                  <td><xsl:copy-of select="/cp/strings/cp_index_manage_files" /><br />
                    <hr />
                   <xsl:choose>
                    <xsl:when test="$user_type = 'sa'">
                     <a href="{$base_url}/cp/admin/services.xsl"><xsl:copy-of select="/cp/strings/cp_index_manage_services" /></a><br />
                     <a href="{$base_url}/cp/admin/monitor.xsl"><xsl:copy-of select="/cp/strings/cp_index_monitor_services" /></a><br />
                     <a href="{$base_url}/cp/admin/schedule.xsl"><xsl:copy-of select="/cp/strings/cp_index_schedule_tasks" /></a><br />
                     <a href="{$base_url}/cp/admin/loglist.xsl"><xsl:copy-of select="/cp/strings/cp_index_view_logs" /></a><br />
                     <a href="{$base_url}/cp/admin/acctinfo.xsl"><xsl:copy-of select="/cp/strings/cp_index_acctinfo" /></a><br />
                     <a href="{$base_url}/cp/admin/timezone.xsl"><xsl:copy-of select="/cp/strings/cp_index_set_timezone" /></a><br />
                     <a href="{$base_url}/cp/admin/security.xsl"><xsl:copy-of select="/cp/strings/cp_index_set_security" /></a><br />
                     <xsl:if test="/cp/vsap/vsap[@type='auth']/platform='freebsd6' or /cp/vsap/vsap[@type='auth']/platform='linux'">
                       <xsl:choose>
                         <xsl:when test="/cp/vsap/vsap[@type='auth']/siteprefs/disable-firewall"/>
                         <xsl:otherwise>
                           <a href="{$base_url}/cp/admin/firewall.xsl"><xsl:copy-of select="/cp/strings/cp_index_set_firewall" /></a><br />
                         </xsl:otherwise>
                       </xsl:choose>
                     </xsl:if>
                   </xsl:when>
                   <xsl:when test="$user_type = 'da'">
                    <a href="{$base_url}/cp/admin/loglist.xsl"><xsl:copy-of select="/cp/strings/cp_index_view_logs" /></a><br />
                   </xsl:when>
                 </xsl:choose>
                  </td>
                </tr>
                <tr class="statusrow">
                  <td colspan="2"><br />
                    <br />
                  </td>
                </tr>
              </table>
            </td>
            <td>
              <table id="homepagespacer" border="0" cellspacing="0" cellpadding="0">
                <tr>
                  <td />
                </tr>
              </table>
            </td>
            <td>
              <table id="homepagespacer" border="0" cellspacing="0" cellpadding="0">
                <tr>
                  <td />
                </tr>
              </table>
            </td>
          </tr>
        </xsl:if>

      </table>

</xsl:template>
</xsl:stylesheet>
