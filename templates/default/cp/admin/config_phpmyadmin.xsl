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

<xsl:variable name="numAllow">
  <xsl:value-of select="count(/cp/vsap/vsap[@type='app:phpmyadmin:status']/allow_from)"/>
</xsl:variable>

<xsl:variable name="remote_ip_address">
  <xsl:call-template name="transliterate">
    <xsl:with-param name="string"><xsl:value-of select="/cp/strings/access_control_remote_addr"/></xsl:with-param>
    <xsl:with-param name="search">__IP_ADDRESS__</xsl:with-param>
    <xsl:with-param name="replace" select="/cp/request/remote_addr"/>
  </xsl:call-template>
</xsl:variable>

<xsl:template match="/">
  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title"><xsl:copy-of select="/cp/strings/cp_title" /> : <xsl:copy-of select="/cp/strings/bc_system_config_phpmyadmin_settings" /></xsl:with-param>
    <xsl:with-param name="formaction">config_phpmyadmin.xsl</xsl:with-param>
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
          <name><xsl:copy-of select="/cp/strings/bc_system_config_phpmyadmin_settings" /></name>
          <url>#</url>
          <image>SystemAdministration</image>
        </section>
      </breadcrumb>
    </xsl:with-param>
    <xsl:with-param name="onload">
      formSubmitPasswordHandlers( '<xsl:value-of select="cp:js-escape(/cp/strings/admin_password_js_error_password_req)" />', '<xsl:value-of select="cp:js-escape(/cp/strings/admin_password_js_error_password_fmt)" />', '<xsl:value-of select="cp:js-escape(/cp/strings/admin_password_js_error_password_match)" />' );
      formSubmitAccessListHandlers( '<xsl:value-of select="cp:js-escape(/cp/strings/admin_allowfrom_empty)" />', '<xsl:value-of select="cp:js-escape(/cp/strings/admin_allowfrom_invalid)" />' );
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

        <script src="{concat($base_url, '/cp/admin/config_phpadmin.js')}" language="javascript"/>
        <script src="{concat($base_url, '/cp/admin/event_handlers.js')}" language="javascript"/>

        <input type="hidden" name="afa" value="" />
        <input type="hidden" name="save" value="" />
        <input type="hidden" name="cancel" value="" />

        <table class="formview" border="0" cellspacing="0" cellpadding="0">
          <tr class="title">
            <td colspan="2"><xsl:copy-of select="/cp/strings/phpmyadmin_access_control_title" /></td>
          </tr>
          <tr class="instructionrow">
            <td colspan="2"><xsl:value-of select="/cp/strings/phpmyadmin_access_control_instr"/></td>
          </tr>
          <tr class="roweven">
            <td class="label"><xsl:value-of select="/cp/strings/access_control_label"/></td>
            <td>
              <xsl:choose>
                <xsl:when test="/cp/vsap/vsap[@type='app:phpmyadmin:status']/allow_from_all = 'yes'">
                  <xsl:value-of select="/cp/strings/phpmyadmin_access_control_allow_from_all"/><br/>
                  <br/>
                  <xsl:value-of select="/cp/strings/access_control_allow_from_link_change"/>&#160;<a href="#" onClick="document.forms[0].afa.value='no';document.forms[0].submit();"><xsl:value-of select="/cp/strings/access_control_allow_from_link_list"/></a><xsl:value-of select="/cp/strings/access_control_allow_from_link_period"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="/cp/strings/phpmyadmin_access_control_allow_from_list"/><br/>
                  <br/>
                  <select name="allow_list" size="12" multiple="multiple">
                    <xsl:for-each select="/cp/vsap/vsap[@type='app:phpmyadmin:status']/allow_from">
                      <option><xsl:value-of select="."/></option>
                    </xsl:for-each>
                    <xsl:if test="$numAllow='0'">
                      <option value="__EMPTY"><xsl:value-of select="/cp/strings/access_control_empty"/></option>
                    </xsl:if>
                  </select>
                  <br/>
                  <input type="submit" id="submitRemove" name="remove" value="{/cp/strings/access_control_remove_button}" />
                  <p>
                  <input type="text" name="allow_from" size="30"/>&#160;<span class="parenthetichelp"><xsl:value-of select="$remote_ip_address"/></span><br/>
                  <input type="submit" name="add" value="{/cp/strings/access_control_add_button}"
                    onClick="return checkAllowFrom('{cp:js-escape(/cp/strings/admin_allowfrom_empty)}',
                                                    '{cp:js-escape(/cp/strings/admin_allowfrom_invalid)}');" />
                  </p>
                  <p>
                    <xsl:value-of select="/cp/strings/access_control_allow_from_link_change"/>&#160;<a href="#" onClick="document.forms[0].afa.value='yes';document.forms[0].submit();"><xsl:value-of select="/cp/strings/access_control_allow_from_link_all"/></a><xsl:value-of select="/cp/strings/access_control_allow_from_link_period"/>
                  </p>
                </xsl:otherwise>
              </xsl:choose>
            </td>
          </tr>
        </table>
        <br/>

       <table class="formview" border="0" cellspacing="0" cellpadding="0">
          <tr class="title">
            <td colspan="2"><xsl:copy-of select="/cp/strings/phpmyadmin_mysql_password_title" /></td>
          </tr>
          <tr class="instructionrow">
            <td colspan="2"><xsl:value-of select="/cp/strings/phpmyadmin_mysql_password_instr"/></td>
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
          <tr class="controlrow">
            <td colspan="2">
              <span class="floatright">
                <input type="submit" name="btn_save" value="{/cp/strings/btn_save}"
                  onClick="
                    return validateSQLPassword('{cp:js-escape(/cp/strings/admin_password_js_error_password_req)}',
                                               '{cp:js-escape(/cp/strings/admin_password_js_error_password_fmt)}',
                                               '{cp:js-escape(/cp/strings/admin_password_js_error_password_match)}')"/>
                <input type="button" name="btn_cancel" value="{/cp/strings/btn_cancel}"
                  onClick="document.forms[0].cancel.value='yes';document.forms[0].submit();" /></span></td>
          </tr>
        </table>

</xsl:template>

</xsl:stylesheet>

