<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" xmlns:exslt="http://exslt.org/common">
<xsl:import href="../cp_global.xsl" />

<xsl:variable name="message">
  <xsl:if test="string(/cp/msgs/msg)">
    <xsl:choose>
      <xsl:when test="not(/cp/form/service)">
        <xsl:copy-of select="/cp/strings/*[local-name()=/cp/msgs/msg/@name]" />
      </xsl:when>
      <xsl:when test="/cp/form/service!='server'">	
        <xsl:copy-of select="/cp/strings/*[local-name()=/cp/msgs/msg/@name]" /> '<xsl:value-of select="/cp/form/service"/>'
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="/cp/strings/*[local-name()=/cp/msgs/msg/@name]" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:if>
</xsl:variable>

<xsl:variable name="feedback">
  <xsl:if test="$message != ''">
    <xsl:call-template name="feedback_table">
      <xsl:with-param name="image">
        <xsl:choose>
          <xsl:when test="/cp/vsap/vsap[@type='error'] or /cp/msgs/msg='error'">error</xsl:when>
          <xsl:when test="string(/cp/form/cancel)">message</xsl:when>
          <xsl:otherwise>success</xsl:otherwise>
        </xsl:choose>
      </xsl:with-param>
      <xsl:with-param name="message">
        <xsl:copy-of select="$message" />
      </xsl:with-param>
    </xsl:call-template>
  </xsl:if>
</xsl:variable>

<xsl:variable name="svc_sort_by">
  <xsl:choose>
    <xsl:when test="/cp/form/ssb='name' or /cp/form/ssb='status' or /cp/form/ssb='restart' or /cp/form/ssb='notify' or /cp/form/ssb='last_started_epoch'"><xsl:value-of select="/cp/form/ssb"/></xsl:when>
    <xsl:otherwise>name</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="svc_sort_order">
  <xsl:choose>
    <xsl:when test="/cp/form/sso='ascending' or /cp/form/sso='descending'"><xsl:value-of select="/cp/form/sso"/></xsl:when>
    <xsl:otherwise>ascending</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="mht"><xsl:copy-of select="/cp/strings/service_manage_monitoring" /></xsl:variable> 

<xsl:template match="/">
  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title"><xsl:copy-of select="/cp/strings/cp_title" /> : <xsl:copy-of select="/cp/strings/bc_system_admin_services" /></xsl:with-param>
    <xsl:with-param name="formaction">services.xsl</xsl:with-param>
    <xsl:with-param name="feedback" select="$feedback" />
    <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_admin_manage_services" />
    <xsl:with-param name="help_short" select="/cp/strings/system_admin_hlp_short" />
    <xsl:with-param name="help_long"><xsl:copy-of select="/cp/strings/system_admin_hlp_long" /></xsl:with-param>
    <xsl:with-param name="breadcrumb">
      <breadcrumb>
        <section>
          <name><xsl:copy-of select="/cp/strings/bc_system_admin_services" /></name>
          <url>#</url>
          <image>SystemAdministration</image>
        </section>
      </breadcrumb>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

     <script src="{$base_url}/cp/admin/services.js" language="javascript"/>
     <xsl:call-template name="cp_titlenavbar">
        <xsl:with-param name="active_tab">admin</xsl:with-param>
      </xsl:call-template>

      <table class="listview" border="0" cellspacing="0" cellpadding="0">
        <tr class="instructionrow">
          <td colspan="8">
            <xsl:value-of select="/cp/strings/service_manage_services"/>&#160;
            <xsl:value-of select="/cp/strings/service_manage_monitoring"/>
          </td>
        </tr>
        <tr class="columnhead">

          <xsl:variable name="name_sort">
           <xsl:choose>
            <xsl:when test="$svc_sort_by='name' and $svc_sort_order='ascending'">descending</xsl:when>
            <xsl:otherwise>ascending</xsl:otherwise>
           </xsl:choose>
          </xsl:variable>
          <xsl:variable name="name_image">
           <xsl:choose>
            <xsl:when test="$svc_sort_by='name' and $svc_sort_order='ascending'"><img src="/cpimages/sort_arrow_up.gif" border="0" /></xsl:when>
            <xsl:when test="$svc_sort_by='name' and $svc_sort_order='descending'"><img src="/cpimages/sort_arrow_down.gif" border="0" /></xsl:when>
            <xsl:otherwise></xsl:otherwise>
           </xsl:choose>
          </xsl:variable>
          <xsl:variable name="status_sort">
           <xsl:choose>
            <xsl:when test="$svc_sort_by='status' and $svc_sort_order='ascending'">descending</xsl:when>
            <xsl:otherwise>ascending</xsl:otherwise>
           </xsl:choose>
          </xsl:variable>
          <xsl:variable name="status_image">
           <xsl:choose>
            <xsl:when test="$svc_sort_by='status' and $svc_sort_order='ascending'"><img src="/cpimages/sort_arrow_up.gif" border="0" /></xsl:when>
            <xsl:when test="$svc_sort_by='status' and $svc_sort_order='descending'"><img src="/cpimages/sort_arrow_down.gif" border="0" /></xsl:when>
            <xsl:otherwise></xsl:otherwise>
           </xsl:choose>
          </xsl:variable>
          <xsl:variable name="restart_sort">
           <xsl:choose>
            <xsl:when test="$svc_sort_by='restart' and $svc_sort_order='ascending'">descending</xsl:when>
            <xsl:otherwise>ascending</xsl:otherwise>
           </xsl:choose>
          </xsl:variable>
          <xsl:variable name="restart_image">
           <xsl:choose>
            <xsl:when test="$svc_sort_by='restart' and $svc_sort_order='ascending'"><img src="/cpimages/sort_arrow_up.gif" border="0" /></xsl:when>
            <xsl:when test="$svc_sort_by='restart' and $svc_sort_order='descending'"><img src="/cpimages/sort_arrow_down.gif" border="0" /></xsl:when>
            <xsl:otherwise></xsl:otherwise>
           </xsl:choose>
          </xsl:variable>
          <xsl:variable name="notify_sort">
           <xsl:choose>
            <xsl:when test="$svc_sort_by='notify' and $svc_sort_order='ascending'">descending</xsl:when>
            <xsl:otherwise>ascending</xsl:otherwise>
           </xsl:choose>
          </xsl:variable>
          <xsl:variable name="notify_image">
           <xsl:choose>
            <xsl:when test="$svc_sort_by='notify' and $svc_sort_order='ascending'"><img src="/cpimages/sort_arrow_up.gif" border="0" /></xsl:when>
            <xsl:when test="$svc_sort_by='notify' and $svc_sort_order='descending'"><img src="/cpimages/sort_arrow_down.gif" border="0" /></xsl:when>
            <xsl:otherwise></xsl:otherwise>
           </xsl:choose>
          </xsl:variable>
          <xsl:variable name="last_started_sort">
           <xsl:choose>
            <xsl:when test="$svc_sort_by='last_started_epoch' and $svc_sort_order='ascending'">descending</xsl:when>
            <xsl:otherwise>ascending</xsl:otherwise>
           </xsl:choose>
          </xsl:variable>
          <xsl:variable name="last_started_image">
           <xsl:choose>
            <xsl:when test="$svc_sort_by='last_started_epoch' and $svc_sort_order='ascending'"><img src="/cpimages/sort_arrow_up.gif" border="0" /></xsl:when>
            <xsl:when test="$svc_sort_by='last_started_epoch' and $svc_sort_order='descending'"><img src="/cpimages/sort_arrow_down.gif" border="0" /></xsl:when>
            <xsl:otherwise></xsl:otherwise>
           </xsl:choose>
          </xsl:variable>

          <td class="servicescolumn" nowrap="nowrap"><a href="{$base_url}/cp/admin/services.xsl?ssb=name&amp;sso={$name_sort}"><xsl:value-of select="/cp/strings/service_header_service"/><xsl:copy-of select="$name_image"/></a></td>
          <td class="versioncolumn"><xsl:value-of select="/cp/strings/service_header_version"/></td>
          <td class="servstatcolumn"><a href="{$base_url}/cp/admin/services.xsl?ssb=status&amp;sso={$status_sort}"><xsl:value-of select="/cp/strings/service_header_status"/><xsl:copy-of select="$status_image"/></a></td>
          <td class="servstatcolumn"><a href="{$base_url}/cp/admin/services.xsl?ssb=restart&amp;sso={$restart_sort}"><xsl:value-of select="/cp/strings/service_header_autorestart"/><xsl:copy-of select="$restart_image"/></a></td>
          <td class="servstatcolumn"><a href="{$base_url}/cp/admin/services.xsl?ssb=notify&amp;sso={$notify_sort}"><xsl:value-of select="/cp/strings/service_header_notify"/><xsl:copy-of select="$notify_image"/></a></td>
          <td class="laststartcolumn"><a href="{$base_url}/cp/admin/services.xsl?ssb=last_started_epoch&amp;sso={$last_started_sort}"><xsl:value-of select="/cp/strings/service_header_last_started"/><xsl:copy-of select="$last_started_image"/></a></td>
          <td class="cpactionscolumn"><xsl:value-of select="/cp/strings/service_header_actions"/></td>
        </tr> 

        <xsl:variable name="services">
          <xsl:apply-templates select="/cp/vsap/vsap[@type='sys:service:status']/*" mode="edit-core"/>
          <xsl:apply-templates select="/cp/vsap/vsap[@type='sys:inetd:status']/*" mode="edit-inetd"/>
        </xsl:variable> 

        <xsl:call-template name="services">
          <xsl:with-param name="services" select="exslt:node-set($services)"/>
          <xsl:with-param name="sort1" select="$svc_sort_by"/>
          <xsl:with-param name="order" select="$svc_sort_order"/>
        </xsl:call-template>
      </table>

</xsl:template>

 <xsl:template match="*" mode="edit-inetd">
   <xsl:variable name="svc" select="name()"/>
   <xsl:choose>
     <xsl:when test="name()='telnet'">
       <!-- skip telnet: BUG33771 -->
     </xsl:when>
     <xsl:when test="name()='ssh' and /cp/vsap/vsap[@type='auth']/siteprefs/disable-shell"> 
     </xsl:when>
     <xsl:otherwise>
       <service>
         <service_type>2</service_type>
         <name><xsl:value-of select="name()"/></name>
         <version><xsl:value-of select="./version"/></version>
         <description><xsl:value-of select="/cp/strings/*[name()=concat('inetd_desc_',$svc)]"/></description>
         <monitor_text><xsl:value-of select="/cp/strings/service_monitor"/></monitor_text>
         <xsl:choose>
           <xsl:when test="status='enabled' and /cp/vsap/vsap[@type='sys:service:status']/inetd/running='true'">
             <running><xsl:value-of select="/cp/strings/service_running"/></running>
             <running_span>running</running_span>
             <stop_command>stop</stop_command>
             <stop_text><xsl:value-of select="/cp/strings/service_stop"/></stop_text>
             <xsl:choose>
               <xsl:when test="monitor_autorestart='true'">
                 <confirm_stop_text><xsl:value-of select="/cp/strings/confirm_service_stop"/>\n\n<xsl:value-of select="/cp/strings/confirm_service_autorestart"/></confirm_stop_text>
               </xsl:when>
               <xsl:otherwise>
                 <confirm_stop_text><xsl:value-of select="/cp/strings/confirm_service_stop"/></confirm_stop_text>
               </xsl:otherwise>
             </xsl:choose>
           </xsl:when>
           <xsl:otherwise>
             <running><xsl:value-of select="/cp/strings/service_stopped"/></running>
             <running_span>stopped</running_span>
             <start_command>start</start_command>
             <start_text><xsl:value-of select="/cp/strings/service_start"/></start_text>
           </xsl:otherwise> 
         </xsl:choose>
         <xsl:choose>
           <xsl:when test="monitor_autorestart='true'">
             <autorestart><xsl:value-of select="/cp/strings/service_monitored_yes"/></autorestart>
             <autorestart_span>autostart</autorestart_span>
           </xsl:when>
           <xsl:otherwise>
             <autorestart><xsl:value-of select="/cp/strings/service_monitored_no"/></autorestart>
             <autorestart_span>noautostart</autorestart_span>
           </xsl:otherwise> 
         </xsl:choose>
         <xsl:choose>
           <xsl:when test="monitor_notify='true'">
             <notify><xsl:value-of select="/cp/strings/service_monitored_yes"/></notify>
             <notify_span>notify</notify_span>
           </xsl:when>
           <xsl:otherwise>
             <notify><xsl:value-of select="/cp/strings/service_monitored_no"/></notify>
             <notify_span>nonotify</notify_span>
           </xsl:otherwise> 
         </xsl:choose>
         <last_started>
          <xsl:choose>
           <xsl:when test="status='disabled'">
             <xsl:value-of select="/cp/strings/service_last_started_not_applicable"/>
           </xsl:when>
           <xsl:when test="/cp/vsap/vsap[@type='sys:service:status']/inetd/last_started">
             <xsl:call-template name="display_date">
              <xsl:with-param name="date" select="/cp/vsap/vsap[@type='sys:service:status']/inetd/last_started"/>
             </xsl:call-template>
           </xsl:when>
           <xsl:when test="/cp/vsap/vsap[@type='sys:service:status']/inetd/running='true'">
             <xsl:value-of select="/cp/strings/service_last_started_unknown"/>
           </xsl:when>
           <xsl:otherwise>
             <xsl:value-of select="/cp/strings/service_last_started_not_applicable"/>
           </xsl:otherwise>
          </xsl:choose>
         </last_started>
         <last_started_epoch>
          <xsl:choose>
           <xsl:when test="/cp/vsap/vsap[@type='sys:service:status']/inetd/last_started">
            <xsl:value-of select="/cp/vsap/vsap[@type='sys:service:status']/inetd/last_started"/>
           </xsl:when>
           <xsl:otherwise>0</xsl:otherwise>
          </xsl:choose>
         </last_started_epoch>
        <config_url>
         <xsl:choose>
          <xsl:when test="name()='ftp'">config_file.xsl?application=<xsl:value-of select="name()"/></xsl:when>
         </xsl:choose>
        </config_url>
        <config_text><xsl:value-of select="/cp/strings/service_config"/></config_text>
       </service>
     </xsl:otherwise>
   </xsl:choose>
 </xsl:template>

 <xsl:template match="*" mode="edit-core">
   <xsl:variable name="svc" select="name()"/>
   <xsl:choose>
     <xsl:when test="name()='inetd'">
       <!-- skip: control restart/notify of inetd services individually -->
     </xsl:when>
     <xsl:when test="name()='telnetd'">
       <!-- skip: BUG33771 -->
     </xsl:when>
     <xsl:otherwise>
       <service>
        <service_type>1</service_type>
        <name><xsl:value-of select="name()"/></name>
        <version><xsl:value-of select="./version"/></version>
        <description><xsl:value-of select="/cp/strings/*[name()=concat('service_desc_',$svc)]"/></description>
        <xsl:choose>
          <xsl:when test="name()='telnetd'"> 
          </xsl:when>
          <xsl:when test="name()='httpd' or name()='apache'">  <!-- QED: BUG26790 -->
            <running><xsl:value-of select="/cp/strings/service_running"/></running>
            <running_span>running</running_span>
            <restart_command>restart</restart_command>
            <restart_text><xsl:value-of select="/cp/strings/service_restart"/></restart_text>
            <confirm_restart_httpd_text><xsl:value-of select="/cp/strings/confirm_service_restart_httpd"/></confirm_restart_httpd_text>
          </xsl:when>
          <xsl:when test="name()='vsapd'">
            <running><xsl:value-of select="/cp/strings/service_running"/></running>
            <running_span>running</running_span>
          </xsl:when>
          <xsl:when test="running='true'">
            <running><xsl:value-of select="/cp/strings/service_running"/></running>
            <running_span>running</running_span>
            <stop_command>stop</stop_command>
            <stop_text><xsl:value-of select="/cp/strings/service_stop"/></stop_text>
            <xsl:choose>
              <xsl:when test="monitor_autorestart='true'">
                <confirm_stop_text><xsl:value-of select="/cp/strings/confirm_service_stop"/>\n\n<xsl:value-of select="/cp/strings/confirm_service_autorestart"/></confirm_stop_text>
              </xsl:when>
              <xsl:otherwise>
                <confirm_stop_text><xsl:value-of select="/cp/strings/confirm_service_stop"/></confirm_stop_text>
              </xsl:otherwise>
            </xsl:choose>
            <restart_command>restart</restart_command>
            <restart_text><xsl:value-of select="/cp/strings/service_restart"/></restart_text>
            <confirm_restart_text><xsl:value-of select="/cp/strings/confirm_service_restart"/></confirm_restart_text>
            <confirm_restart_httpd_text><xsl:value-of select="/cp/strings/confirm_service_restart_httpd"/></confirm_restart_httpd_text>
          </xsl:when>
          <xsl:otherwise>
            <running><xsl:value-of select="/cp/strings/service_stopped"/></running>
            <running_span>stopped</running_span>
            <start_command>start</start_command>
            <start_text><xsl:value-of select="/cp/strings/service_start"/></start_text>
          </xsl:otherwise> 
        </xsl:choose>
        <xsl:choose>
          <xsl:when test="monitor_autorestart='true'">
            <autorestart><xsl:value-of select="/cp/strings/service_monitored_yes"/></autorestart>
            <autorestart_span>autostart</autorestart_span>
          </xsl:when>
          <xsl:otherwise>
            <autorestart><xsl:value-of select="/cp/strings/service_monitored_no"/></autorestart>
            <autorestart_span>noautostart</autorestart_span>
          </xsl:otherwise> 
        </xsl:choose>
        <xsl:choose>
          <xsl:when test="monitor_notify='true'">
            <notify><xsl:value-of select="/cp/strings/service_monitored_yes"/></notify>
            <notify_span>notify</notify_span>
          </xsl:when>
          <xsl:otherwise>
            <notify><xsl:value-of select="/cp/strings/service_monitored_no"/></notify>
            <notify_span>nonotify</notify_span>
          </xsl:otherwise> 
        </xsl:choose>
        <monitor_text><xsl:value-of select="/cp/strings/service_monitor"/></monitor_text>
        <last_started>
         <xsl:choose>
          <xsl:when test="last_started">
            <xsl:call-template name="display_date">
             <xsl:with-param name="date" select="last_started"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:when test="running='true'">
            <xsl:value-of select="/cp/strings/service_last_started_unknown"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="/cp/strings/service_last_started_not_applicable"/>
          </xsl:otherwise>
         </xsl:choose>
        </last_started>
        <last_started_epoch>
         <xsl:choose>
          <xsl:when test="last_started_epoch">
           <xsl:value-of select="last_started_epoch"/>
          </xsl:when>
          <xsl:otherwise>0</xsl:otherwise>
         </xsl:choose>
        </last_started_epoch>
        <config_url>
         <xsl:choose>
          <xsl:when test="name()='vsapd'"></xsl:when>
          <xsl:when test="name()='mailman'">config_mailman.xsl</xsl:when>
          <xsl:when test="name()='mysqld'">config_mysql.xsl</xsl:when>
          <xsl:when test="name()='postgresql'">config_postgresql.xsl</xsl:when>
          <xsl:when test="name()='mailman'">config_mailman.xsl</xsl:when>
          <xsl:otherwise>config_file.xsl?application=<xsl:value-of select="name()"/></xsl:otherwise>
         </xsl:choose>
        </config_url>
        <config_text><xsl:value-of select="/cp/strings/service_config"/></config_text>
       </service>
     </xsl:otherwise>
   </xsl:choose>

   <xsl:if test="position()=1">
   <service>
     <service_type>0</service_type>
     <name><xsl:value-of select="/cp/strings/service_server"/></name>
     <version></version>
     <description><xsl:value-of select="/cp/strings/service_desc_server"/></description>
     <running><xsl:value-of select="/cp/strings/service_running"/></running>
     <running_span>running</running_span>
     <enabled><xsl:value-of select="/cp/strings/service_enabled"/></enabled>
     <enabled_span>running</enabled_span>
     <restart_command>reboot</restart_command>
     <restart_text><xsl:value-of select="/cp/strings/service_reboot"/></restart_text>
     <confirm_restart_text><xsl:value-of select="/cp/strings/confirm_service_reboot"/></confirm_restart_text>
     <autorestart><xsl:value-of select="/cp/strings/service_monitored_na"/></autorestart>
     <autorestart_span>autostartna</autorestart_span>
     <xsl:choose>
       <xsl:when test="/cp/vsap/vsap[@type='sys:info:uptime']/notify_reboot='true'">
         <notify><xsl:value-of select="/cp/strings/service_monitored_yes"/></notify>
         <notify_span>notify</notify_span>
       </xsl:when>
       <xsl:otherwise>
         <notify><xsl:value-of select="/cp/strings/service_monitored_no"/></notify>
         <notify_span>nonotify</notify_span>
       </xsl:otherwise> 
     </xsl:choose>
     <monitor_text><xsl:value-of select="/cp/strings/service_monitor"/></monitor_text>
     <last_started>
       <xsl:call-template name="display_date">
        <xsl:with-param name="date" select="/cp/vsap/vsap[@type='sys:info:uptime']/date"/>
       </xsl:call-template>
     </last_started>
     <last_started_epoch>
        <xsl:value-of select="/cp/vsap/vsap[@type='sys:info:uptime']/epoch"/>
     </last_started_epoch>
   </service>
   </xsl:if>
 </xsl:template>

 <xsl:template name="services">
  <xsl:param name="services"/>
  <xsl:param name="sort1"/>
  <xsl:param name="order"/>

  <xsl:for-each select="$services/service">
    <xsl:sort select="*[local-name()=$sort1]" order="{$order}"/>
    <xsl:sort select="running" order="{$order}"/>
  
    <xsl:variable name="row_style">
      <xsl:choose>
        <xsl:when test="position() mod 2 = 1">rowodd</xsl:when>
        <xsl:otherwise>roweven</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

   <tr class="{$row_style}">
    <xsl:variable name="svc" select="name"/>
    <td><a class="description" href="#" title="{description}"><xsl:value-of select="$svc"/></a></td>
    <td><xsl:value-of select="version"/></td>
    <td><span class="{running_span}"><xsl:value-of select="running"/></span></td>
    <xsl:choose>
      <xsl:when test="autorestart_span = 'autostartna'">
        <td><span class="{autorestart_span}"><xsl:value-of select="autorestart"/></span></td>
      </xsl:when>
      <xsl:otherwise>
        <td><span class="{autorestart_span}"><a title="{$mht}" href="{$base_url}/cp/admin/monitor.xsl"><xsl:value-of select="autorestart"/></a></span></td>
      </xsl:otherwise>
    </xsl:choose>
    <td><span class="{notify_span}"><a title="{$mht}" href="{$base_url}/cp/admin/monitor.xsl"><xsl:value-of select="notify"/></a></span></td>
    <td><xsl:value-of select="last_started"/></td>
    <td class="actions">
      <xsl:if test="string(config_url)">
        <a href="{$base_url}/cp/admin/{config_url}"><xsl:value-of select="config_text"/></a> |
      </xsl:if>
      <xsl:if test="string(stop_command)">
        <a href="#" onClick="return confirmAction('{cp:js-escape(confirm_stop_text)}', '{$base_url}/cp/admin/services.xsl?service_type={service_type}&amp;service={$svc}&amp;action={stop_command}&amp;ssb={$svc_sort_by}&amp;sso={$svc_sort_order}')"><xsl:value-of select="stop_text"/></a>
        <xsl:if test="string(start_command) or string(restart_command)"> | </xsl:if>
      </xsl:if>

      <xsl:if test="string(start_command)">
        <a href="{$base_url}/cp/admin/services.xsl?service_type={service_type}&amp;service={$svc}&amp;action={start_command}&amp;ssb={$svc_sort_by}&amp;sso={$svc_sort_order}"><xsl:value-of select="start_text"/></a>
        <xsl:if test="string(restart_command)"> | </xsl:if>
      </xsl:if>

      <xsl:if test="string(restart_command)='restart' and string(name)='httpd' ">
        <a href="#" onClick="return confirmAction('{cp:js-escape(confirm_restart_httpd_text)}', '{$base_url}/cp/admin/services.xsl?service_type={service_type}&amp;service={$svc}&amp;action={restart_command}&amp;ssb={$svc_sort_by}&amp;sso={$svc_sort_order}')"><xsl:value-of select="restart_text"/></a>
      </xsl:if>

      <xsl:if test="string(restart_command)='restart' and string(name)!='httpd'">
        <a href="#" onClick="return confirmAction('{cp:js-escape(confirm_restart_text)}', '{$base_url}/cp/admin/services.xsl?service_type={service_type}&amp;service={$svc}&amp;action={restart_command}&amp;ssb={$svc_sort_by}&amp;sso={$svc_sort_order}')"><xsl:value-of select="restart_text"/></a>
      </xsl:if>

      <xsl:if test="string(restart_command)='reboot'">
        <a href="#" onClick="return confirmAction('{cp:js-escape(confirm_restart_text)}', '{$base_url}/cp/admin/services.xsl?service_type={service_type}&amp;service={$svc}&amp;action={restart_command}&amp;ssb={$svc_sort_by}&amp;sso={$svc_sort_order}')"><xsl:value-of select="restart_text"/></a>
      </xsl:if>

    </td> 
  </tr>
 </xsl:for-each>
 </xsl:template>

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
