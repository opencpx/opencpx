<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:import href="../global.xsl" />

  <!-- This will tell the global template which app we are in -->
  <xsl:variable name="app_name">controlpanel</xsl:variable>

  <!-- create a global to track how whether a da can add end users (bug 4731) -->
  <xsl:variable name="eu_add">
    <xsl:choose>
      <xsl:when test="$user_type = 'sa'">-1</xsl:when>
      <xsl:when test="$user_type = 'da'">
        <xsl:variable name="da_user">
          <xsl:value-of select="/cp/vsap/vsap[@type='auth']/username" />
        </xsl:variable>
        <xsl:choose>
          <xsl:when test="/cp/vsap/vsap[@type='domain:admin_list']/domain[admin=$da_user][users/limit='unlimited']">-1</xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="sum(/cp/vsap/vsap[@type='domain:admin_list']/domain[admin=$da_user]/users/limit)" />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
    </xsl:choose>
  </xsl:variable>

  <!-- create a global to track how whether a da can add email (bug 4731) -->
  <xsl:variable name="email_add">
    <xsl:choose>
      <xsl:when test="$user_type = 'sa'">-1</xsl:when>
      <xsl:when test="$user_type = 'da'">
        <xsl:variable name="da_user">
          <xsl:value-of select="/cp/vsap/vsap[@type='auth']/username" />
        </xsl:variable>
        <xsl:choose>
          <xsl:when test="/cp/vsap/vsap[@type='domain:admin_list']/domain[admin=$da_user][mail_aliases/limit='unlimited']">-1</xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="sum(/cp/vsap/vsap[@type='domain:admin_list']/domain[admin=$da_user]/mail_aliases/limit)" />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
    </xsl:choose>
  </xsl:variable>

  <!-- This will build the "navandcontent" menu for the cp section based on the user type -->
  <xsl:variable name="navandcontent_items">
    <menu_items>
      <!-- user management -->
      <xsl:if test="$user_type = 'sa' or $user_type = 'da' or $user_type = 'ma'">
        <menu id="usermanagement" name="{/cp/strings/nv_menu_usermanagement}" class="user" >
          <item href="{$base_url}/cp/users/"><xsl:copy-of select="/cp/strings/nv_user_list" /></item>
          <xsl:if test="$user_type = 'sa'">
            <item href="{$base_url}/cp/users/user_add_profile.xsl?type=da"><xsl:copy-of select="/cp/strings/nv_add_da" /></item>
          </xsl:if>
          <xsl:if test="$eu_add != '0'">
            <xsl:if test="not(/cp/vsap/vsap[@type='auth']/siteprefs/disable-mail-admin)">
              <xsl:if test="$user_type = 'sa' or ($user_type = 'da' and $mail_ok = '1' and /cp/vsap/vsap[@type='auth']/eu_capabilities/mail)">
                <item href="{$base_url}/cp/users/user_add_profile.xsl?type=ma"><xsl:copy-of select="/cp/strings/nv_add_ma" /></item>
              </xsl:if>
            </xsl:if>
            <xsl:choose>
              <xsl:when test="$user_type = 'ma'">
                <xsl:if test="/cp/vsap/vsap[@type='auth']/eu_capabilities/mail">
                  <item href="{$base_url}/cp/users/user_add_profile.xsl?type=eu"><xsl:copy-of select="/cp/strings/nv_add_eu" /></item>
                </xsl:if>
              </xsl:when>
              <xsl:otherwise>
                <item href="{$base_url}/cp/users/user_add_profile.xsl?type=eu"><xsl:copy-of select="/cp/strings/nv_add_eu" /></item>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:if>
        </menu>
      </xsl:if>

      <!-- domain management -->
      <xsl:if test="$user_type = 'sa' or $user_type = 'da' ">
        <menu id="domainmanagement" name="{/cp/strings/nv_menu_domainmanagement}">
          <item href="{$base_url}/cp/domains/"><xsl:copy-of select="/cp/strings/nv_domain_list" /></item>
          <xsl:if test="$user_type = 'sa'">
            <item href="{$base_url}/cp/domains/domain_add_setup.xsl"><xsl:copy-of select="/cp/strings/nv_add_domain" /></item>
            <xsl:if test="/cp/vsap/vsap[@type='auth']/siteprefs/enable-create-csr">
              <item href="{$base_url}/cp/domains/domain_create_csr.xsl"><xsl:copy-of select="/cp/strings/nv_create_csr" /></item>
            </xsl:if>
            <xsl:if test="/cp/vsap/vsap[@type='auth']/siteprefs/enable-install-cert">
              <item href="{$base_url}/cp/domains/domain_cert.xsl"><xsl:copy-of select="/cp/strings/nv_install_cert" /></item>
            </xsl:if>
            <xsl:if test="/cp/vsap/vsap[@type='auth']/siteprefs/enable-selfsigned-cert">
              <item href="{$base_url}/cp/domains/domain_self_signed_cert.xsl"><xsl:copy-of select="/cp/strings/nv_self_signed_cert" /></item>
            </xsl:if>
          </xsl:if>
        </menu>
      </xsl:if>

      <!-- mail management -->
      <xsl:if test="$user_type = 'sa' or (($user_type = 'da' or $user_type = 'ma') and $mail_ok = '1')">
        <menu id="mailmanagement" name="{/cp/strings/nv_menu_mailmanagement}">
          <xsl:if test="$user_type = 'sa' or $user_type = 'da' or $user_type = 'ma'">
            <item href="{$base_url}/cp/email/"><xsl:copy-of select="/cp/strings/nv_email_addresses" /></item>
            <xsl:if test="$email_add != '0'">
              <item href="{$base_url}/cp/email/add-edit.xsl"><xsl:copy-of select="/cp/strings/nv_add_email" /></item>
            </xsl:if>
          </xsl:if>
        </menu>
      </xsl:if>

      <!-- file management -->
      <xsl:if test="$fileman_ok = '1'">
        <menu id="filemanager" name="{/cp/strings/nv_menu_filemanager}">
          <item href="{$base_url}/cp/files/"><xsl:copy-of select="/cp/strings/nv_file_list" /></item>
          <xsl:if test="/cp/vsap/vsap[@type='auth']/product='cloud' and $user_type='sa'">
            <item href="{$base_url}/cp/files/index.xsl?currentUser=apache"><xsl:copy-of select="/cp/strings/nv_file_web_root" /></item>
          </xsl:if>
          <!--item href="{$base_url}/cp/files/recyclebin.xsl"><xsl:copy-of select="/cp/strings/nv_file_recycler" /></item-->
        </menu>
      </xsl:if>
      <!-- this is all end users get... profile and preferences -->
      <menu id="myprofile" name="{/cp/strings/nv_menu_myprofile}">
        <item href="{$base_url}/cp/profile/"><xsl:copy-of select="/cp/strings/nv_view_profile" /></item>
        <item href="{$base_url}/cp/profile/password.xsl"><xsl:copy-of select="/cp/strings/nv_change_password" /></item>
      </menu>
      <menu id="mypreferences" name="{/cp/strings/nv_menu_mypreferences}">
        <item href="{$base_url}/cp/prefs/autologout.xsl"><xsl:copy-of select="/cp/strings/nv_auto_logout" /></item>
        <item href="{$base_url}/cp/prefs/datetime.xsl"><xsl:copy-of select="/cp/strings/nv_date_time" /></item>
        <xsl:if test="$user_type = 'sa' or $user_type = 'da' or $user_type = 'ma'">
          <item href="{$base_url}/cp/prefs/um.xsl"><xsl:copy-of select="/cp/strings/nv_um_prefs" /></item>
        </xsl:if>
        <xsl:if test="$user_type = 'sa' or $user_type = 'da'">
          <item href="{$base_url}/cp/prefs/dm.xsl"><xsl:copy-of select="/cp/strings/nv_dm_prefs" /></item>
        </xsl:if>
        <xsl:if test="$fileman_ok = '1'">
          <item href="{$base_url}/cp/prefs/fm.xsl"><xsl:copy-of select="/cp/strings/nv_fm_prefs" /></item>
        </xsl:if>
        <xsl:if test="$user_type = 'sa'">
          <item href="{$base_url}/cp/prefs/pm.xsl"><xsl:copy-of select="/cp/strings/nv_pm_prefs" /></item>
        </xsl:if>
      </menu>
      
      <!-- system administration -->
      <xsl:choose>
        <xsl:when test="$user_type = 'sa'">
          <menu id="serveradmin" name="{/cp/strings/nv_menu_serveradmin}">
            <item href="{$base_url}/cp/admin/services.xsl"><xsl:copy-of select="/cp/strings/nv_admin_manage_services" /></item>
            <item href="{$base_url}/cp/admin/monitor.xsl"><xsl:copy-of select="/cp/strings/nv_admin_monitor_services" /></item>
            <item href="{$base_url}/cp/admin/packages.xsl"><xsl:copy-of select="/cp/strings/nv_admin_manage_packages" /></item>
            <item href="{$base_url}/cp/admin/schedule.xsl"><xsl:copy-of select="/cp/strings/nv_admin_schedule_tasks" /></item>
            <item href="{$base_url}/cp/admin/loglist.xsl"><xsl:copy-of select="/cp/strings/nv_admin_view_logs" /></item>
            <item href="{$base_url}/cp/admin/acctinfo.xsl"><xsl:copy-of select="/cp/strings/nv_admin_acctinfo" /></item>
            <item href="{$base_url}/cp/admin/timezone.xsl"><xsl:copy-of select="/cp/strings/nv_admin_set_timezone" /></item>
            <item href="{$base_url}/cp/admin/security.xsl"><xsl:copy-of select="/cp/strings/nv_admin_set_security" /></item>
            <xsl:if test="/cp/vsap/vsap[@type='auth']/platform='freebsd6' or /cp/vsap/vsap[@type='auth']/platform='linux'">
              <xsl:choose>
                <xsl:when test="/cp/vsap/vsap[@type='auth']/siteprefs/disable-firewall"/>
                <xsl:otherwise>
                  <item href="{$base_url}/cp/admin/firewall.xsl"><xsl:copy-of select="/cp/strings/nv_admin_set_firewall" /></item>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:if>
          </menu>
        </xsl:when>
        <xsl:when test="$user_type = 'da'">
          <menu id="serveradmin" name="{/cp/strings/nv_menu_serveradmin}">
            <item href="{$base_url}/cp/admin/loglist.xsl"><xsl:copy-of select="/cp/strings/nv_admin_view_logs" /></item>
          </menu>
        </xsl:when>
      </xsl:choose>

      <!-- global tools -->
      <xsl:if test="($shell_ok = '1' and /cp/vsap/vsap[@type='sys:ssh:status']/ssh1_status='enabled') or ($podcast_ok = '1')">
        <menu id="globaltools" name="{/cp/strings/nv_menu_global_tools}">
          <xsl:if test="$shell_ok = '1' and /cp/vsap/vsap[@type='sys:ssh:status']/ssh1_status='enabled'">
            <item href="{$base_url}/cp/admin/shell.xsl"><xsl:copy-of select="/cp/strings/nv_global_tools_shell" /></item>
          </xsl:if>
          <xsl:if test="$podcast_ok = '1'">
            <item href="{$base_url}/cp/admin/podcast_list.xsl"><xsl:copy-of select="/cp/strings/nv_admin_podcast" /></item>
          </xsl:if>
        </menu>
      </xsl:if>
    </menu_items>
  </xsl:variable>

  <!-- templates for the cp section -->

  <!-- this template returns the "titlenavbar" for list views in the cp section -->
  <!--
    Params:
      active_tab - current selected tab (list)
  -->
  <xsl:template name="cp_titlenavbar">
    <xsl:param name="active_tab" />
<!--
    <table class="titlenavbar" border="0" cellspacing="0" cellpadding="0">
      <tr>
        <td>
          <table class="titlenav" border="0" cellspacing="0" cellpadding="0">
            <tr>
              <xsl:if test="$user_type = 'sa' or $user_type = 'da'">
                <td><a href="{$base_url}/cp/users/"><xsl:attribute name="class">
                  <xsl:choose>
                    <xsl:when test="$active_tab = 'users'">on</xsl:when>
                    <xsl:otherwise>off</xsl:otherwise>
                  </xsl:choose></xsl:attribute><xsl:copy-of select="/cp/strings/titlenavbar_users" /></a></td>
                <td><a href="{$base_url}/cp/domains/"><xsl:attribute name="class">
                  <xsl:choose>
                    <xsl:when test="$active_tab = 'domains'">on</xsl:when>
                    <xsl:otherwise>off</xsl:otherwise>
                  </xsl:choose></xsl:attribute><xsl:copy-of select="/cp/strings/titlenavbar_domains" /></a></td>
                <td><a href="{$base_url}/cp/email/"><xsl:attribute name="class">
                  <xsl:choose>
                    <xsl:when test="$active_tab = 'email'">on</xsl:when>
                    <xsl:otherwise>off</xsl:otherwise>
                  </xsl:choose></xsl:attribute><xsl:copy-of select="/cp/strings/titlenavbar_email" /></a></td>
              </xsl:if>
              <xsl:if test="$fileman_ok = '1'">
                <td><a href="{$base_url}/cp/files/"><xsl:attribute name="class">
                  <xsl:choose>
                    <xsl:when test="$active_tab = 'files'">on</xsl:when>
                    <xsl:otherwise>off</xsl:otherwise>
                  </xsl:choose></xsl:attribute><xsl:copy-of select="/cp/strings/titlenavbar_files" /></a></td>
              </xsl:if>
              <xsl:if test="$user_type = 'sa'">
                <td><a href="{$base_url}/cp/admin/services.xsl"><xsl:attribute name="class">
                  <xsl:choose>
                    <xsl:when test="$active_tab = 'admin'">on</xsl:when>
                    <xsl:otherwise>off</xsl:otherwise>
                  </xsl:choose></xsl:attribute><xsl:copy-of select="/cp/strings/titlenavbar_admin" /></a></td>
              </xsl:if>
            </tr>
          </table>
        </td>
      </tr>
    </table>
-->
  </xsl:template>

  <!-- this template returns a comma delimited list of user services for the profile view pages -->
  <!--
    Params:
      services - services returned by vsap (in the form <mail/><ftp/><shell/>...)
  -->
  <xsl:template name="list_services">
    <xsl:param name="services" />

    <xsl:variable name="has_podcast">
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='auth']/siteprefs/disable-podcast">0</xsl:when>
        <xsl:when test="$services/podcast">1</xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="has_shell">
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='auth']/siteprefs/disable-shell">0</xsl:when>
        <xsl:when test="$services/shell">1</xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:if test="$services/mail">
      <xsl:copy-of select="/cp/strings/cp_service_mail" />
      <xsl:if test="$services/ftp or $services/fileman or ($has_podcast='1') or ($has_shell='1')">, </xsl:if>
    </xsl:if>
    <xsl:if test="$services/ftp">
      <xsl:copy-of select="/cp/strings/cp_service_ftp" />
      <xsl:if test="$services/fileman or ($has_podcast='1') or ($has_shell='1')">, </xsl:if>
    </xsl:if>
    <xsl:if test="$services/fileman">
      <xsl:copy-of select="/cp/strings/cp_service_fm" />
      <xsl:if test="($has_podcast='1') or ($has_shell='1')">, </xsl:if>
    </xsl:if>
    <xsl:if test="$has_podcast='1'">
      <xsl:copy-of select="/cp/strings/cp_service_pc" />
      <xsl:if test="$has_shell='1'">, </xsl:if>
    </xsl:if>

    <xsl:if test="$has_shell='1'"><xsl:copy-of select="/cp/strings/cp_service_shell" /></xsl:if>
  </xsl:template>

  <!-- this template returns a comma delimited list of services an end-user is eligible for -->
  <!--
    Params:
      services - end-user capabilities returned by vsap (in the form <mail/><ftp/><shell/>...)
  -->
  <xsl:template name="list_eu_capabilities">
    <xsl:param name="eu_capability" />

    <xsl:variable name="has_shell">
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='auth']/siteprefs/disable-shell">0</xsl:when>
        <xsl:when test="$eu_capability/shell">1</xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:if test="$eu_capability/mail">
      <xsl:copy-of select="/cp/strings/cp_service_mail" />
      <xsl:if test="$eu_capability/ftp or ($has_shell='1') or $eu_capability/fileman or $eu_capability/zeroquota">, </xsl:if>
    </xsl:if>
    <xsl:if test="$eu_capability/ftp">
      <xsl:copy-of select="/cp/strings/cp_service_ftp" />
      <xsl:if test="($has_shell='1') or $eu_capability/fileman or $eu_capability/zeroquota">, </xsl:if>
    </xsl:if>
    <xsl:if test="$eu_capability/fileman">
      <xsl:copy-of select="/cp/strings/cp_service_fm" />
      <xsl:if test="($has_shell='1') or $eu_capability/zeroquota">, </xsl:if>
    </xsl:if>
    <xsl:if test="$has_shell='1'">
      <xsl:copy-of select="/cp/strings/cp_service_shell" />
      <xsl:if test="$eu_capability/zeroquota">, </xsl:if>
    </xsl:if>
    <xsl:if test="$eu_capability/zeroquota"><xsl:copy-of select="/cp/strings/cp_service_zeroquota" /></xsl:if>
    <xsl:if test="not($eu_capability/mail) and not($eu_capability/ftp) and ($has_shell='0') and not($eu_capability/fileman)"><br /></xsl:if>
  </xsl:template>

  <!-- this template returns a comma delimited list of mail capabilities for the profile view pages -->
  <!-- this template returns a comma delimited list of mail capabilities for the profile view pages -->
  <!--
    Params:
      capabilities - capabilities returned by vsap (in the form <webmail/><mail-spamassassin/><mail-clamav/>...)
  -->
  <xsl:template name="list_mail_capabilities">
    <xsl:param name="capabilities" />

    <xsl:if test="($webmail_package='1' and $capabilities/webmail)"><xsl:copy-of select="/cp/strings/cp_service_webmail" /><xsl:if test="($spamassassin_package='1' and $capabilities/mail-spamassassin) or ($clamav_package='1' and $capabilities/mail-clamav)">, </xsl:if></xsl:if>
    <xsl:if test="$spamassassin_package='1' and $capabilities/mail-spamassassin"><xsl:copy-of select="/cp/strings/cp_service_spamassassin" /><xsl:if test="$clamav_package='1' and $capabilities/mail-clamav">, </xsl:if></xsl:if>
    <xsl:if test="$clamav_package='1' and $capabilities/mail-clamav"><xsl:copy-of select="/cp/strings/cp_service_clamav" /></xsl:if>
    <xsl:if test="not($capabilities/webmail) and not($capabilities/mail-spamassassin) and not($capabilities/mail-clamav)"><br /></xsl:if>
  </xsl:template>

  <!-- this template returns the formated user quota for the profile view pages -->
  <!--
    Params:
      quota - quota node returned by vsap:user:list (or vsap:user:properties) :
              <quota>
                <usage>2.2421875</usage>
                <limit>0</limit>
                <units>MB</units>
              </quota>
  -->
  <xsl:template name="print_quota">
    <xsl:param name="quota" />

    <xsl:variable name="usage">
      <xsl:choose>
        <!-- these are the conditions such that the group quota is the limit for disk usage for this user -->
        <xsl:when test="($quota/grp_limit > 0) and (($quota/limit = 0) or ($quota/grp_limit &lt;= $quota/limit))">
          <xsl:value-of select="$quota/grp_usage" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$quota/usage" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="limit">
      <xsl:choose>
        <!-- these are the conditions such that the group quota is the limit for disk usage for this user -->
        <xsl:when test="($quota/grp_limit > 0) and (($quota/limit = 0) or ($quota/grp_limit &lt;= $quota/limit))">
          <xsl:value-of select="$quota/grp_limit" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$quota/limit" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="units">
      <xsl:choose>
        <xsl:when test="quota/units = 'GB'">
          <xsl:value-of select="/cp/strings/gb" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="/cp/strings/mb" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:choose>
      <xsl:when test="$quota/allocated">
        <!-- for server and domain admins -->
        <xsl:copy-of select="/cp/strings/cp_quota_allocated" />
        <xsl:value-of select="$quota/allocated" />&#160;
        <xsl:value-of select="$units" />
      </xsl:when>
      <xsl:otherwise>
        <!-- for server and domain admins -->
        <xsl:copy-of select="/cp/strings/cp_quota_limit" />
        <xsl:value-of select="$quota/limit" />&#160;
        <xsl:value-of select="$units" />
      </xsl:otherwise>
    </xsl:choose>

    <span class="indent"><xsl:copy-of select="/cp/strings/cp_quota_used" />
      <xsl:value-of select="format-number($usage, '###.#')" />&#160;
      <xsl:value-of select="$units" />

    <xsl:choose>
      <xsl:when test="$quota/allocated">
        <xsl:if test="$quota/allocated > 0">
          <xsl:copy-of select="/cp/strings/cp_quota_paren_open" />
          <xsl:value-of select="format-number( (($quota/usage div $quota/allocated) * 100), '##.#')" />
          <xsl:copy-of select="/cp/strings/cp_quota_percent" />
          <xsl:copy-of select="/cp/strings/cp_quota_paren_close" />
        </xsl:if>
      </xsl:when>
      <xsl:otherwise>
        <xsl:if test="$limit > 0">
          <xsl:copy-of select="/cp/strings/cp_quota_paren_open" />
          <xsl:value-of select="format-number( (($usage div $limit) * 100), '##.#')" />
          <xsl:copy-of select="/cp/strings/cp_quota_percent" />
          <xsl:copy-of select="/cp/strings/cp_quota_paren_close" />
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
    </span> 
  </xsl:template>

  <!-- this template returns the formated date for services and package pages -->
  <!--
    Params:
      date - date node returned by services:list, package:list, and package:info
                  <year>2015</year>
                  <month>8</month>
                  <day>14</day>
                  <hour>23</hour>
                  <hour12>11</hour12>
                  <minute>19</minute>
                  <second>16</second>
                  <o_year>2015</o_year>
                  <o_month>8</o_month>
                  <o_day>14</o_day>
                  <o_hour>23</o_hour>
                  <o_hour12>11</o_hour12>
                  <o_minute>19</o_minute>
                  <o_second>16</o_second>
                  <o_offset>+0000</o_offset>
  -->
  <xsl:template name="display_date">
   <xsl:param name="date"/>

   <xsl:variable name="format_date">
    <xsl:call-template name="format-date">
     <xsl:with-param name="date" select="$date"/>
     <xsl:with-param name="type">short</xsl:with-param>
    </xsl:call-template>
   </xsl:variable>
   <xsl:variable name="format_time">
    <xsl:call-template name="format-time">
     <xsl:with-param name="date" select="$date"/>
     <xsl:with-param name="type">short</xsl:with-param>
    </xsl:call-template>
   </xsl:variable>

   <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='user:prefs:load']/user_preferences/dt_order='date'">
     <xsl:value-of select="concat($format_date,' ',$format_time)" />
    </xsl:when>
    <xsl:otherwise>
     <xsl:value-of select="concat($format_time,' ',$format_date)" />
    </xsl:otherwise>
   </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
