<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" xmlns:exslt="http://exslt.org/common">
<xsl:import href="../cp_global.xsl" />

<xsl:variable name="message">
  <xsl:if test="string(/cp/msgs/msg)">
    <xsl:choose>
      <xsl:when test="string(/cp/form/save) or string(/cp/form/cancel)">
        <xsl:copy-of select="/cp/strings/*[local-name()=/cp/msgs/msg/@name]" />
      </xsl:when>
      <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='sys:configfile:list_backups']">
        <xsl:copy-of select="/cp/strings/*[local-name()=/cp/msgs/msg/@name]" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="/cp/strings/*[local-name()=/cp/msgs/msg/@name]" /> '<xsl:value-of select="/cp/form/application"/>'
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

<xsl:variable name="app_sort_by">
  <xsl:choose>
    <xsl:when test="/cp/form/asb='name' or /cp/form/asb='state' or /cp/form/asb='status'"><xsl:value-of select="/cp/form/asb"/></xsl:when>
    <xsl:otherwise>name</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="app_sort_order">
  <xsl:choose>
    <xsl:when test="/cp/form/aso='ascending' or /cp/form/aso='descending'"><xsl:value-of select="/cp/form/aso"/></xsl:when>
    <xsl:otherwise>ascending</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:template match="/">
  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title"><xsl:copy-of select="/cp/strings/cp_title" /> : <xsl:copy-of select="/cp/strings/bc_system_admin_applications" /></xsl:with-param>
    <xsl:with-param name="formaction">applications.xsl</xsl:with-param>
    <xsl:with-param name="feedback" select="$feedback" />
    <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_admin_manage_applications" />
    <xsl:with-param name="help_short" select="/cp/strings/system_admin_hlp_short" />
    <xsl:with-param name="help_long"><xsl:copy-of select="/cp/strings/system_admin_hlp_long" /></xsl:with-param>
    <xsl:with-param name="breadcrumb">
      <breadcrumb>
        <section>
          <name><xsl:copy-of select="/cp/strings/bc_system_admin_applications" /></name>
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
            <xsl:value-of select="/cp/strings/application_manage_applications"/>
          </td>
        </tr>
        <tr class="columnhead">

          <xsl:variable name="name_sort">
           <xsl:choose>
            <xsl:when test="$app_sort_by='name' and $app_sort_order='ascending'">descending</xsl:when>
            <xsl:otherwise>ascending</xsl:otherwise>
           </xsl:choose>
          </xsl:variable>
          <xsl:variable name="name_image">
           <xsl:choose>
            <xsl:when test="$app_sort_by='name' and $app_sort_order='ascending'"><img src="/cpimages/sort_arrow_up.gif" border="0" /></xsl:when>
            <xsl:when test="$app_sort_by='name' and $app_sort_order='descending'"><img src="/cpimages/sort_arrow_down.gif" border="0" /></xsl:when>
            <xsl:otherwise></xsl:otherwise>
           </xsl:choose>
          </xsl:variable>
          <xsl:variable name="state_sort">
           <xsl:choose>
            <xsl:when test="$app_sort_by='state' and $app_sort_order='ascending'">descending</xsl:when>
            <xsl:otherwise>ascending</xsl:otherwise>
           </xsl:choose>
          </xsl:variable>
          <xsl:variable name="state_image">
           <xsl:choose>
            <xsl:when test="$app_sort_by='state' and $app_sort_order='ascending'"><img src="/cpimages/sort_arrow_up.gif" border="0" /></xsl:when>
            <xsl:when test="$app_sort_by='state' and $app_sort_order='descending'"><img src="/cpimages/sort_arrow_down.gif" border="0" /></xsl:when>
            <xsl:otherwise></xsl:otherwise>
           </xsl:choose>
          </xsl:variable>
          <xsl:variable name="status_sort">
           <xsl:choose>
            <xsl:when test="$app_sort_by='status' and $app_sort_order='ascending'">descending</xsl:when>
            <xsl:otherwise>ascending</xsl:otherwise>
           </xsl:choose>
          </xsl:variable>
          <xsl:variable name="status_image">
           <xsl:choose>
            <xsl:when test="$app_sort_by='status' and $app_sort_order='ascending'"><img src="/cpimages/sort_arrow_up.gif" border="0" /></xsl:when>
            <xsl:when test="$app_sort_by='status' and $app_sort_order='descending'"><img src="/cpimages/sort_arrow_down.gif" border="0" /></xsl:when>
            <xsl:otherwise></xsl:otherwise>
           </xsl:choose>
          </xsl:variable>

          <td class="applicationscolumn" nowrap="nowrap"><a href="{$base_url}/cp/admin/applications.xsl?asb=name&amp;aso={$name_sort}"><xsl:value-of select="/cp/strings/application_header_application"/><xsl:copy-of select="$name_image"/></a></td>
          <xsl:if test="/cp/vsap/vsap[@type='sys:account:is_self_managed']/status='1'">
            <td class="appstatcolumn"><a href="{$base_url}/cp/admin/applications.xsl?asb=state&amp;aso={$state_sort}"><xsl:value-of select="/cp/strings/application_header_state"/><xsl:copy-of select="$state_image"/></a></td>
          </xsl:if>
          <td class="versioncolumn"><xsl:value-of select="/cp/strings/application_header_version"/></td>
          <td class="appstatcolumn"><a href="{$base_url}/cp/admin/applications.xsl?asb=status&amp;aso={$status_sort}"><xsl:value-of select="/cp/strings/application_header_status"/><xsl:copy-of select="$status_image"/></a></td>
          <td><xsl:value-of select="/cp/strings/application_header_actions"/></td>
        </tr> 

        <xsl:variable name="applications">
          <xsl:apply-templates select="/cp/vsap/vsap[@type='sys:application:status']/*" mode="add-on"/>
        </xsl:variable> 

        <xsl:call-template name="applications">
          <xsl:with-param name="applications" select="exslt:node-set($applications)"/>
          <xsl:with-param name="sort1" select="$app_sort_by"/>
          <xsl:with-param name="order" select="$app_sort_order"/>
          <xsl:with-param name="self_managed" select="/cp/vsap/vsap[@type='sys:account:is_self_managed']/status"/>
        </xsl:call-template>

      </table>

</xsl:template>

 <xsl:template match="*" mode="add-on">
   <xsl:variable name="app" select="./name"/>
   <xsl:choose>
     <xsl:when test="./name='foobar'">
       <!-- skip: for testing purposes only-->
     </xsl:when>
     <xsl:otherwise>
       <xsl:variable name="pan"><xsl:value-of select="/cp/strings/*[name()=concat('application_name_',$app)]"/></xsl:variable>
       <xsl:variable name="display_name">
        <xsl:choose>
          <xsl:when test="string($pan)"><xsl:value-of select="$pan"/></xsl:when>
          <xsl:otherwise><xsl:value-of select="$app"/></xsl:otherwise>
        </xsl:choose>
       </xsl:variable>
       <application>
        <name><xsl:value-of select="./name"/></name>
        <display_name><xsl:value-of select="$display_name"/></display_name>
        <description><xsl:value-of select="/cp/strings/*[name()=concat('application_desc_',$app)]"/></description>
        <version><xsl:value-of select="./version"/></version>
        <xsl:choose>
          <xsl:when test="./installed='true'">
            <installed><xsl:value-of select="/cp/strings/application_installed"/></installed>
            <installed_span>installed</installed_span>
          </xsl:when>
          <xsl:otherwise>
            <installed><xsl:value-of select="/cp/strings/application_not_installed"/></installed>
            <installed_span>notinstalled</installed_span>
          </xsl:otherwise> 
        </xsl:choose>
        <xsl:choose>
          <xsl:when test="./status='enabled'">
            <status><xsl:value-of select="/cp/strings/application_status_enabled"/></status>
            <status_span>enabled</status_span>
          </xsl:when>
          <xsl:when test="string(./installed)">
            <status><xsl:value-of select="/cp/strings/application_status_disabled"/></status>
            <status_span>disabled</status_span>
          </xsl:when>
          <xsl:otherwise>
            <!-- <status><xsl:value-of select="/cp/strings/application_status_na"/></status> -->
            <status></status>
          </xsl:otherwise> 
        </xsl:choose>
        <xsl:if test="./configurable='true'">
          <configure_command>configure</configure_command>
          <configure_text><xsl:value-of select="/cp/strings/application_configure"/></configure_text>
          <xsl:choose>     
            <xsl:when test="./name='phpmyadmin'">
              <configure_url>config_phpmyadmin.xsl</configure_url>
            </xsl:when>
            <xsl:when test="./name='phppgadmin'">
              <configure_url>config_phppgadmin.xsl</configure_url>
            </xsl:when>
            <xsl:when test="./name='webalizer'">
              <configure_url>config_webalizer.xsl</configure_url>
            </xsl:when>
            <xsl:when test="./name='webdav'">
              <configure_url>config_webdav.xsl</configure_url>
            </xsl:when>
            <xsl:otherwise>
              <configure_url>config_file.xsl?application=<xsl:value-of select="./name"/></configure_url>
            </xsl:otherwise>
          </xsl:choose>     
        </xsl:if>
        <xsl:if test="./disableable='true'">
          <xsl:choose>
            <xsl:when test="./status='enabled'">
              <disable_command>disable</disable_command>
              <disable_text><xsl:value-of select="/cp/strings/application_disable"/></disable_text>
              <disable_confirm_text><xsl:value-of select="/cp/strings/application_disable_confirm_text"/></disable_confirm_text>
            </xsl:when>
            <xsl:otherwise>
              <enable_command>enable</enable_command>
              <enable_text><xsl:value-of select="/cp/strings/application_enable"/></enable_text>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:if>
        <xsl:if test="./installable='true'">
          <xsl:variable name="install_confirm_text">
            <xsl:call-template name="transliterate">
              <xsl:with-param name="string"><xsl:value-of select="/cp/strings/application_install_confirm_text"/></xsl:with-param>
              <xsl:with-param name="search">__VERSION__</xsl:with-param>
              <xsl:with-param name="replace" select="./install_version"/>
            </xsl:call-template>
          </xsl:variable>
          <install_command>install</install_command>
          <install_text><xsl:value-of select="/cp/strings/application_install"/></install_text>
          <install_version><xsl:value-of select="./install_version"/></install_version>
          <install_confirm_text><xsl:value-of select="$install_confirm_text"/></install_confirm_text>
        </xsl:if>
        <xsl:if test="./removable='true'">
          <remove_command>remove</remove_command>
          <remove_text><xsl:value-of select="/cp/strings/application_remove"/></remove_text>
          <remove_confirm_text><xsl:value-of select="/cp/strings/application_remove_confirm_text"/></remove_confirm_text>
        </xsl:if>
        <xsl:if test="./upgradable='true'">
          <xsl:variable name="upgrade_confirm_text">
            <xsl:call-template name="transliterate">
              <xsl:with-param name="string"><xsl:value-of select="/cp/strings/application_upgrade_confirm_text"/></xsl:with-param>
              <xsl:with-param name="search">__VERSION__</xsl:with-param>
              <xsl:with-param name="replace" select="./upgrade_version"/>
            </xsl:call-template>
          </xsl:variable>
          <upgrade_command>upgrade</upgrade_command>
          <upgrade_text><xsl:value-of select="/cp/strings/application_upgrade"/></upgrade_text>
          <upgrade_version><xsl:value-of select="./upgrade_version"/></upgrade_version>
          <upgrade_confirm_text><xsl:value-of select="$upgrade_confirm_text"/></upgrade_confirm_text>
        </xsl:if>
       </application>
     </xsl:otherwise>
   </xsl:choose>
 </xsl:template>

 <xsl:template name="applications">
  <xsl:param name="applications"/>
  <xsl:param name="sort1"/>
  <xsl:param name="order"/>
  <xsl:param name="self_managed"/>

  <xsl:for-each select="$applications/application">
    <xsl:sort select="*[local-name()=$sort1]" order="{$order}"/>
    <xsl:sort select="running" order="{$order}"/>
  
    <xsl:variable name="row_style">
      <xsl:choose>
        <xsl:when test="position() mod 2 = 1">rowodd</xsl:when>
        <xsl:otherwise>roweven</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

   <tr class="{$row_style}">
    <td><a class="description" href="#" title="{description}"><xsl:value-of select="./display_name"/></a></td>
    <xsl:if test="$self_managed='1'">
      <td><span class="{installed_span}"><xsl:value-of select="./installed"/></span></td>
    </xsl:if>
    <td><xsl:value-of select="./version"/></td>
    <td><span class="{status_span}"><xsl:value-of select="./status"/></span></td>
    <td class="actions">
      <xsl:if test="$self_managed='1'">
        <xsl:if test="string(install_command)">
          <a href="#" onClick="return confirmAction('{cp:js-escape(install_confirm_text)}', '{$base_url}/cp/admin/applications.xsl?application={name}&amp;action={install_command}&amp;asb={$app_sort_by}&amp;aso={$app_sort_order}')"><xsl:value-of select="install_text"/></a>
        </xsl:if>
      </xsl:if>
      <xsl:if test="string(configure_command)">
       <a href="{$base_url}/cp/admin/{configure_url}"><xsl:value-of select="configure_text"/></a>
        <xsl:if test="string(enable_command) or string(disable_command)"> | </xsl:if>
      </xsl:if>
      <xsl:if test="string(enable_command)">
       <a href="{$base_url}/cp/admin/applications.xsl?application={name}&amp;action={enable_command}&amp;asb={$app_sort_by}&amp;aso={$app_sort_order}"><xsl:value-of select="enable_text"/></a>
      </xsl:if>
      <xsl:if test="string(disable_command)">
        <a href="#" onClick="return confirmAction('{cp:js-escape(disable_confirm_text)}', '{$base_url}/cp/admin/applications.xsl?application={name}&amp;action={disable_command}&amp;asb={$app_sort_by}&amp;aso={$app_sort_order}')"><xsl:value-of select="disable_text"/></a>
      </xsl:if>
      <xsl:if test="$self_managed='1'">
        <xsl:if test="string(remove_command)">
          | <a href="#" onClick="return confirmAction('{cp:js-escape(remove_confirm_text)}', '{$base_url}/cp/admin/applications.xsl?application={name}&amp;action={remove_command}&amp;asb={$app_sort_by}&amp;aso={$app_sort_order}')"><xsl:value-of select="remove_text"/></a>
        </xsl:if>
        <xsl:if test="string(upgrade_command)">
          | <a href="#" onClick="return confirmAction('{cp:js-escape(upgrade_confirm_text)}', '{$base_url}/cp/admin/applications.xsl?application={name}&amp;action={upgrade_command}&amp;asb={$app_sort_by}&amp;aso={$app_sort_order}')"><xsl:value-of select="upgrade_text"/></a>
        </xsl:if>
      </xsl:if>
    </td> 
  </tr>
 </xsl:for-each>
 </xsl:template>

</xsl:stylesheet>
