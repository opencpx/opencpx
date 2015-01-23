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

<xsl:variable name="config_path">
  <xsl:choose>
    <xsl:when test="/cp/form/config_path">
      <xsl:value-of select="/cp/form/config_path"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="/cp/vsap/vsap[@type='sys:configfile:fetch']/file/path"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="num_backups_available">
  <xsl:choose>
    <xsl:when test="string(/cp/vsap/vsap[@type='sys:configfile:list_backups']/num_backups_available)">
      <xsl:value-of select="/cp/vsap/vsap[@type='sys:configfile:list_backups']/num_backups_available"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="count(/cp/vsap/vsap[@type='sys:configfile:list_backups']/backup)"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="contents">
  <xsl:choose>
    <xsl:when test="/cp/form/contents">
      <xsl:value-of select="/cp/form/contents"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="/cp/vsap/vsap[@type='sys:configfile:fetch']/file/contents"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:template match="/">
  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title"><xsl:copy-of select="/cp/strings/cp_title" /> : <xsl:copy-of select="/cp/strings/bc_system_config_mysql_settings" /></xsl:with-param>
    <xsl:with-param name="formaction">config_mysql.xsl</xsl:with-param>
    <xsl:with-param name="feedback" select="$feedback" />
    <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_admin_manage_services" />
    <xsl:with-param name="help_short" select="/cp/strings/system_admin_hlp_short" />
    <xsl:with-param name="help_long"><xsl:copy-of select="/cp/strings/system_admin_hlp_long" /></xsl:with-param>
    <xsl:with-param name="breadcrumb">
      <breadcrumb>
        <section>
          <name><xsl:copy-of select="/cp/strings/bc_system_admin_services" /></name>
          <url><xsl:value-of select="$base_url"/>/cp/admin/services.xsl</url>
        </section>
        <section>
          <name><xsl:copy-of select="/cp/strings/bc_system_config_mysql_settings" /></name>
          <url>#</url>
          <image>SystemAdministration</image>
        </section>
      </breadcrumb>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

        <script src="{concat($base_url, '/cp/admin/config_file.js')}" language="javascript"/>
        <script src="{concat($base_url, '/cp/admin/config_mysql.js')}" language="javascript"/>

        <!-- *** Functionality currently disabled per OCN request, but left for 
             *** ease of re-implementation.
        -->
        <!--
        <script language="javascript">
          var logrotatePwExists = '<xsl:value-of select="/cp/vsap/vsap[@type='mysql:logrotate_status']/pw_exists"/>';
          var logrotateMissingPw = '<xsl:value-of select="/cp/strings/mysql_logrotate_missing_password_msg"/>';
        </script>
        -->

        <input type="hidden" name="recover" value="" />
        <input type="hidden" name="save" value="" />
        <input type="hidden" name="cancel" value="" />
        <input type="hidden" name="application" value="mysqld" />

        <table class="formview" border="0" cellspacing="0" cellpadding="0">
          <tr class="title">
            <td colspan="2"><xsl:copy-of select="/cp/strings/mysql_settings_title" /></td>
          </tr>
          <tr class="instructionrow">
            <td colspan="2"><xsl:value-of select="/cp/strings/mysql_settings_instr"/></td>
          </tr>
          <tr class="rowodd">
            <td class="label"><xsl:value-of select="/cp/strings/mysql_password_new_password"/></td>
            <td class="contentwidth">
                <input type="password" name="new_password" size="42" value="" autocomplete="off" />&#160;<span class="parenthetichelp"><xsl:value-of select="/cp/strings/mysql_password_new_password_instr"/></span>
            </td>
          </tr>
          <tr class="roweven">
            <td class="label"><xsl:value-of select="/cp/strings/mysql_password_confirm_password"/></td>
            <td class="contentwidth"><input type="password" name="new_password2" size="42" value="" autocomplete="off" /></td>
          </tr>
          <!-- *** Functionality currently disabled per OCN request, but left for 
               *** ease of re-implementation.
          -->
          <!--
          <tr class="columnhead">
            <td colspan="2"><xsl:copy-of select="/cp/strings/mysql_logrotate_title" /></td>
          </tr>
          <tr class="rowodd">
            <td class="label" colspan="2">
              <span style="vertical-align: top;"><xsl:value-of select="/cp/strings/mysql_logrotate_notice"/></span>&#160;
              <input id="logrotate" name="logrotate" type="hidden">
                <xsl:choose>
                  <xsl:when test="/cp/vsap/vsap[@type='mysql:logrotate_status']/status = 'on'">
                    <xsl:attribute name="value">1</xsl:attribute>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:attribute name="value">0</xsl:attribute>
                  </xsl:otherwise>
                </xsl:choose>
              </input>
            </td>
          </tr>
          -->
          <tr class="columnhead">
            <td class="appstatcolumn" colspan="2">
              <xsl:value-of select="/cp/strings/config_file_path"/>&#160;
              <xsl:value-of select="$config_path"/>
              <xsl:if test="$num_backups_available > 0">
                <span class="floatright">
                  <a href="{$base_url}/cp/admin/config_file_restore.xsl?application=mysqld&amp;config_path={$config_path}">
                  <xsl:value-of select="/cp/strings/config_file_backups_available"/>&#160;
                  <xsl:value-of select="$num_backups_available"/></a>&#160;
                </span>
              </xsl:if>
            </td>
          </tr>
          <tr class="rowodd">
            <td colspan="2">
              <textarea name="contents" rows="16" cols="96" wrap="off"><xsl:value-of select="$contents"/></textarea>
              <br/>
            </td>
          </tr>
          <tr class="controlrow">
            <td colspan="2">
              <xsl:if test="$num_backups_available > 0">
                <input type="button" name="btn_recover" value="{/cp/strings/config_file_recover_btn}"
                  onClick="document.forms[0].recover.value='yes'; document.forms[0].submit();" />
              </xsl:if>
              <span class="floatright">
                <input type="submit" name="btn_save" value="{/cp/strings/btn_save}"
                  onClick="
                    return validateConfigSettings('{cp:js-escape(/cp/strings/admin_password_js_error_password_fmt)}',
                                                  '{cp:js-escape(/cp/strings/admin_password_js_error_password_match)}',
                                                  '{cp:js-escape(/cp/strings/config_file_js_no_changes)}',
                                                  '{cp:js-escape(/cp/strings/config_file_js_save_alert)}')"/>
                <input type="button" name="btn_cancel" value="{/cp/strings/btn_cancel}"
                  onClick="document.forms[0].cancel.value='yes';document.forms[0].submit();" /></span></td>
          </tr>
        </table>

        <!-- the original -->
        <input type="hidden" name="original" value="{$contents}" />
        <input type="hidden" name="logrotate_original" id="logrotate_original" value="" />
        <input type="hidden" name="logrotate_change" id="logrotate_change" value="false" />

</xsl:template>

</xsl:stylesheet>
