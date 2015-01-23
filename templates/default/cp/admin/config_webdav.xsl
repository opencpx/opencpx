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

<xsl:variable name="numUsers">
  <xsl:value-of select="count(/cp/vsap/vsap[@type='app:webdav:user_list']/user)"/>
</xsl:variable>

<xsl:template match="/">
  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title"><xsl:copy-of select="/cp/strings/cp_title" /> : <xsl:copy-of select="/cp/strings/bc_system_config_webdav_settings" /></xsl:with-param>
    <xsl:with-param name="formaction">config_webdav.xsl</xsl:with-param>
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
          <name><xsl:copy-of select="/cp/strings/bc_system_config_webdav_settings" /></name>
          <url>#</url>
          <image>SystemAdministration</image>
        </section>
      </breadcrumb>
    </xsl:with-param>
    <xsl:with-param name="onload">
      submitWebDavUser( '<xsl:value-of select="cp:js-escape(/cp/strings/webdav_js_error_login_req)" />', '<xsl:value-of select="cp:js-escape(/cp/strings/webdav_js_error_login_fmt_chars)" />', '<xsl:value-of select="cp:js-escape(/cp/strings/webdav_js_error_login_fmt_start)" />', '<xsl:value-of select="cp:js-escape(/cp/strings/admin_password_js_error_password_req)" />', '<xsl:value-of select="cp:js-escape(/cp/strings/admin_password_js_error_password_fmt)" />', '<xsl:value-of select="cp:js-escape(/cp/strings/admin_password_js_error_password_match)" />' );
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

        <script src="{concat($base_url, '/cp/admin/config_webdav.js')}" language="javascript"/>
        <script src="{concat($base_url, '/cp/admin/event_handlers.js')}" language="javascript"/>

        <input type="hidden" name="addUser" value="" />
        <input type="hidden" name="editUser" value="" />
        <input type="hidden" name="removeUser" value="" />
        <input type="hidden" name="cancel" value="" />

        <table class="formview" border="0" cellspacing="0" cellpadding="0">
          <tr class="title">
            <td colspan="3"><xsl:copy-of select="/cp/strings/webdav_user_list_title" /></td>
          </tr>
          <tr class="instructionrow">
            <td colspan="3"><xsl:value-of select="/cp/strings/webdav_user_list_instr"/></td>
          </tr>
          <tr class="roweven">
            <td class="label"><xsl:value-of select="/cp/strings/webdav_user_list"/></td>
            <td>
              <select name="user_list" size="12" multiple="multiple" style="width:105px" onClick="toggleEditUserFormVisibility();">
                <xsl:for-each select="/cp/vsap/vsap[@type='app:webdav:user_list']/user">
                  <option><xsl:value-of select="."/></option>
                </xsl:for-each>
                <xsl:if test="$numUsers='0'">
                  <option value="__EMPTY"><xsl:value-of select="/cp/strings/webdav_user_list_empty"/></option>
                </xsl:if>
              </select>
              <br/>
              <input type="button" id="submitRemove" name="remove" value="{/cp/strings/webdav_user_remove_button}" 
                  onClick="document.forms[0].removeUser.value='yes'; document.forms[0].submit();" />
            </td>
            <td class="contentwidth">
              <div id="webdavEditForm" style="display:none;">
                <xsl:value-of select="/cp/strings/webdav_edit_user"/>&#160;
                <input name="edit_user" size="42" readonly="readonly" style="border:0px; font-weight:bold;" value=""/><br/>
                <br/>
                <xsl:value-of select="/cp/strings/webdav_edit_password"/><br/>
                <input type="password" name="edit_password" size="42" value="" autocomplete="off" /><br/>
                <span class="parenthetichelp"><xsl:value-of select="/cp/strings/webdav_password_instr"/></span><br/>
                <br/>
                <xsl:value-of select="/cp/strings/webdav_password_confirm"/><br/>
                <input type="password" name="edit_confirm_password" size="42" value="" autocomplete="off" /><br/>
                <br/>
                <input type="button" id="submitEdit" name="edit" value="{/cp/strings/webdav_user_edit_button}"
                    onClick="validateWebDavUser('{cp:js-escape(/cp/strings/webdav_js_error_login_req)}',
                                        '{cp:js-escape(/cp/strings/webdav_js_error_login_fmt_chars)}',
                                        '{cp:js-escape(/cp/strings/webdav_js_error_login_fmt_start)}',
                                        '{cp:js-escape(/cp/strings/admin_password_js_error_password_req)}',
                                        '{cp:js-escape(/cp/strings/admin_password_js_error_password_fmt)}',
                                        '{cp:js-escape(/cp/strings/admin_password_js_error_password_match)}', 1);" />
              </div>
            </td>
          </tr>
        </table>
        <br/>

        <table class="formview" border="0" cellspacing="0" cellpadding="0">
          <tr class="title">
            <td colspan="2"><xsl:copy-of select="/cp/strings/webdav_new_user_title" /></td>
          </tr>
          <tr class="roweven">
            <td class="label"><xsl:value-of select="/cp/strings/webdav_new_user"/></td>
            <td class="contentwidth"><input name="add_user" size="42" value="" autocomplete="off" /></td>
          </tr>
          <tr class="rowodd">
            <td class="label"><xsl:value-of select="/cp/strings/webdav_new_password"/></td>
            <td class="contentwidth">
                <input type="password" name="add_password" size="42" value="" autocomplete="off" />&#160;<span class="parenthetichelp"><xsl:value-of select="/cp/strings/webdav_password_instr"/></span>
            </td>
          </tr>
          <tr class="roweven">
            <td class="label"><xsl:value-of select="/cp/strings/webdav_password_confirm"/></td>
            <td class="contentwidth"><input type="password" name="add_confirm_password" size="42" value="" autocomplete="off" /></td>
          </tr>
          <tr class="controlrow">
            <td colspan="2">
              <span class="floatright">
                <input type="button" id="submitNew" name="add" value="{/cp/strings/webdav_user_add_button}"
                  onClick="validateWebDavUser('{cp:js-escape(/cp/strings/webdav_js_error_login_req)}',
                                        '{cp:js-escape(/cp/strings/webdav_js_error_login_fmt_chars)}',
                                        '{cp:js-escape(/cp/strings/webdav_js_error_login_fmt_start)}',
                                        '{cp:js-escape(/cp/strings/admin_password_js_error_password_req)}',
                                        '{cp:js-escape(/cp/strings/admin_password_js_error_password_fmt)}',
                                        '{cp:js-escape(/cp/strings/admin_password_js_error_password_match)}', 0);"/>
                <input type="button" name="btn_cancel" value="{/cp/strings/btn_cancel}"
                  onClick="document.forms[0].cancel.value='yes';document.forms[0].submit();" />
              </span>
            </td>
          </tr>
        </table>

</xsl:template>

</xsl:stylesheet>
