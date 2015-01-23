<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../cp_global.xsl" />

<xsl:variable name="message">
  <xsl:if test="string(/cp/msgs/msg)">
    <xsl:copy-of select="/cp/strings/*[local-name()=/cp/msgs/msg/@name]" />
  </xsl:if>
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

<xsl:variable name="app"><xsl:value-of select="/cp/form/application"/></xsl:variable>

<xsl:variable name="pan"><xsl:value-of select="/cp/strings/*[name()=concat('application_name_',$app)]"/></xsl:variable>
<xsl:variable name="display_name">
 <xsl:choose>
   <xsl:when test="string($pan)"><xsl:value-of select="$pan"/></xsl:when>
   <xsl:otherwise><xsl:value-of select="$app"/></xsl:otherwise>
 </xsl:choose>
</xsl:variable>

<xsl:variable name="config_bc_title">
  <xsl:call-template name="transliterate">
    <xsl:with-param name="string"><xsl:value-of select="/cp/strings/bc_system_admin_config_file"/></xsl:with-param>
    <xsl:with-param name="search">__APPLICATION__</xsl:with-param>
    <xsl:with-param name="replace" select="$display_name"/>
  </xsl:call-template>
</xsl:variable>

<xsl:variable name="config_nv_title">
  <xsl:call-template name="transliterate">
    <xsl:with-param name="string"><xsl:value-of select="/cp/strings/nv_admin_config_file"/></xsl:with-param>
    <xsl:with-param name="search">__APPLICATION__</xsl:with-param>
    <xsl:with-param name="replace" select="$display_name"/>
  </xsl:call-template>
</xsl:variable>

<xsl:variable name="config_file_restore_instr">
  <xsl:call-template name="transliterate">
    <xsl:with-param name="string"><xsl:value-of select="/cp/strings/config_file_restore_instr"/></xsl:with-param>
    <xsl:with-param name="search">__APPLICATION__</xsl:with-param>
    <xsl:with-param name="replace" select="$display_name"/>
  </xsl:call-template>
</xsl:variable>

<xsl:variable name="config_path">
  <xsl:choose>
    <xsl:when test="/cp/form/config_path">
      <xsl:value-of select="/cp/form/config_path"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="/cp/vsap/vsap[@type='sys:configfile:list_backups']/path"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="config_filename">
  <xsl:value-of select="/cp/vsap/vsap[@type='sys:configfile:list_backups']/name"/>
</xsl:variable>

<xsl:variable name="last_modified">
  <xsl:call-template name="display_date">
    <xsl:with-param name="date" select="/cp/vsap/vsap[@type='sys:configfile:list_backups']/mdate"/>
  </xsl:call-template>
</xsl:variable>

<xsl:variable name="config_size">
  <xsl:call-template name="format_bytes">
    <xsl:with-param name="bytes" select="/cp/vsap/vsap[@type='sys:configfile:list_backups']/size"/>
  </xsl:call-template>
</xsl:variable>

<xsl:template match="/">
  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title"><xsl:copy-of select="/cp/strings/cp_title" /> : <xsl:copy-of select="$config_bc_title" /></xsl:with-param>
    <xsl:with-param name="formaction">config_file_restore.xsl</xsl:with-param>
    <xsl:with-param name="feedback" select="$feedback" />
    <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_admin_manage_applications" />
    <xsl:with-param name="help_short" select="/cp/strings/system_admin_hlp_short" />
    <xsl:with-param name="help_long"><xsl:copy-of select="/cp/strings/system_admin_hlp_long" /></xsl:with-param>
    <xsl:with-param name="breadcrumb">
      <breadcrumb>
        <section>
          <name><xsl:copy-of select="/cp/strings/bc_system_admin_applications" /></name>
          <url><xsl:value-of select="$base_url"/>/cp/admin/applications.xsl</url>
        </section>
        <section>
          <name><xsl:copy-of select="$config_bc_title" /></name>
          <url>#</url>
          <image>SystemAdministration</image>
        </section>
      </breadcrumb>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

        <script src="{concat($base_url, '/cp/admin/config_file.js')}" language="javascript"/>

        <input type="hidden" name="done" value="" />
        <input type="hidden" name="application" value="{$app}" />
        <input type="hidden" name="config_path" value="{$config_path}" />

        <table class="formview" border="0" cellspacing="0" cellpadding="0">
          <tr class="title">
            <td colspan="2"><xsl:copy-of select="/cp/strings/config_file_restore_title" /></td>
          </tr>
          <tr class="instructionrow">
            <td colspan="2"><xsl:value-of select="$config_file_restore_instr"/></td>
          </tr>
          <tr class="rowodd">
            <td class="label" valign="top"><xsl:value-of select="/cp/strings/config_file_path"/></td>
            <td class="instructionrow"><xsl:value-of select="$config_path"/></td>
          </tr>
          <tr class="roweven">
            <td class="label" valign="top"><xsl:value-of select="/cp/strings/config_file_last_modified"/></td>
            <td class="instructionrow"><xsl:value-of select="$last_modified"/></td>
          </tr>
          <tr class="rowodd">
            <td class="label" valign="top"><xsl:value-of select="/cp/strings/config_file_size"/></td>
            <td class="instructionrow"><xsl:value-of select="$config_size"/></td>
          </tr>
        </table>
        <table class="listview" border="0" cellspacing="0" cellpadding="0">
          <tr class="columnhead">
            <td class=""><xsl:value-of select="/cp/strings/config_file_restore_version"/></td>
            <td class=""><xsl:value-of select="/cp/strings/config_file_restore_date"/></td>
            <td class=""><xsl:value-of select="/cp/strings/config_file_restore_size"/></td>
            <td class=""><xsl:value-of select="/cp/strings/config_file_restore_actions"/></td>
          </tr>
          <xsl:for-each select="/cp/vsap/vsap[@type='sys:configfile:list_backups']/backup">
            <xsl:variable name="rowclass">
              <xsl:choose>
                <xsl:when test="position() mod 2 = 1">rowodd</xsl:when>
                <xsl:otherwise>roweven</xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <xsl:variable name="backup_path">
              <xsl:value-of select="$config_filename"/>.<xsl:value-of select="./version"/>
            </xsl:variable>
            <xsl:variable name="backup_date">
              <xsl:call-template name="display_date">
                <xsl:with-param name="date" select="./mdate"/>
              </xsl:call-template>
            </xsl:variable>
            <xsl:variable name="backup_size">
              <xsl:call-template name="format_bytes">
                <xsl:with-param name="bytes" select="./size"/>
              </xsl:call-template>
            </xsl:variable>
            <tr class="{$rowclass}">
              <td><xsl:value-of select="$backup_path"/></td>
              <td><xsl:value-of select="$backup_date"/></td>
              <td><xsl:value-of select="$backup_size"/></td>
              <td>
                <a href="#" onClick="return confirmAction('{cp:js-escape(/cp/strings/config_file_restore_confirm)}', '{$base_url}/cp/admin/config_file_restore.xsl?application={$app}&amp;config_path={$config_path}&amp;action=restore&amp;version={./version}')"><xsl:value-of select="/cp/strings/config_file_restore_action"/></a> |
                <a href="{$base_url}/cp/admin/config_backup_view.xsl?application={$app}&amp;config_path={$config_path}&amp;action=diff&amp;version={./version}"><xsl:value-of select="/cp/strings/config_file_restore_diff"/></a> |
                <a href="{$base_url}/cp/admin/config_backup_view.xsl?application={$app}&amp;config_path={$config_path}&amp;action=view&amp;version={./version}"><xsl:value-of select="/cp/strings/config_file_restore_view"/></a>
             </td>
            </tr>
          </xsl:for-each>
        </table>
        <table class="formview" border="0" cellspacing="0" cellpadding="0">
          <tr class="controlrow">
            <td>
              <span class="floatright">
                <input type="button" name="btn_done" value="{/cp/strings/btn_back}"
                  onClick="document.forms[0].done.value='yes'; document.forms[0].submit();" /></span>
            </td>
          </tr>
        </table>

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
