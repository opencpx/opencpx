<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" xmlns:exslt="http://exslt.org/common">
  <xsl:import href="../cp_global.xsl"/>
  <xsl:import href="file_global.xsl"/>

  <xsl:template match="/">
    <xsl:call-template name="bodywrapper">
      <xsl:with-param name="title">
        <xsl:value-of select="/cp/strings/cp_title"/>
        v<xsl:value-of select="/cp/vsap/vsap[@type='auth']/version" /> :
        <xsl:value-of select="/cp/strings/nv_menu_filemanager"/> : 
        <xsl:value-of select="/cp/strings/bc_file_delete"/>
      </xsl:with-param>
      <xsl:with-param name="formaction">delete.xsl</xsl:with-param>
      <xsl:with-param name="feedback" select="''"/>
      <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_file_list"/>
      <xsl:with-param name="help_short" select="/cp/strings/file_list_hlp_short"/>
      <xsl:with-param name="help_long">
        <xsl:value-of select="/cp/strings/file_list_hlp_long_eu"/>
      </xsl:with-param>
      <xsl:with-param name="breadcrumb">
        <breadcrumb>
          <section>
            <name><xsl:value-of select="/cp/strings/bc_file_list"/></name>
            <url><xsl:value-of select="$base_url"/>/cp/files/index.xsl</url>
          </section>
          <section>
            <name><xsl:value-of select="/cp/strings/bc_file_delete"/></name>
            <url>#</url>
            <image>FileManagement</image>
          </section>
        </breadcrumb>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:template>

  <xsl:template name="content">

        <input type="hidden" name="action" value="doDelete"/>
        <input type="hidden" name="currentPath" value="{cp/form/currentPath}"/>
        <table class="formview" border="0" cellspacing="0" cellpadding="0">
          <tr class="title">
            <td colspan="2">
              <xsl:value-of select="/cp/strings/file_action_delete"/>
            </td>
          </tr>

          <tr class="instructionrow">
            <td colspan="2">
              <xsl:value-of select="/cp/strings/file_delete_title"/>
            </td>
          </tr>

          <xsl:if test="$usertype = 'da'">
            <xsl:if test="$source_user != /cp/vsap/vsap[@type='auth']/username">
              <input type="hidden" name="source_user" value="{cp/form/source_user}"/>
            </xsl:if>
          </xsl:if>
          <xsl:for-each select="cp/form/file">
            <tr class="roweven">
              <td class="label">
                <xsl:value-of select="/cp/strings/file_delete_name"/>&#160;<xsl:value-of select="position()"/>:
              </td>
              <td class="contentwidth">
                <xsl:if test="$usertype = 'da'">
                  <xsl:if test="$source_user != /cp/vsap/vsap[@type='auth']/username">
                    <xsl:value-of select="$source_user"/>:
                  </xsl:if>
                </xsl:if>
                <xsl:variable name="path">
                  <!--xsl:if test="cp/form/currentPath != '/'"><xsl:value-of select="cp/form/currentPath"/></xsl:if-->
                  <xsl:value-of select="/cp/form/currentPath"/>
                  <xsl:if test="/cp/form/currentPath != '' and /cp/form/currentPath != '/'">/</xsl:if>
                  <xsl:value-of select="."/>
                </xsl:variable>
                <xsl:value-of select="$path"/><input type="hidden" name="path" value="{$path}"/>
              </td>
            </tr>
          </xsl:for-each>

          <xsl:if test="/cp/form/itemname">
            <tr class="roweven">
              <td class="label">
                <xsl:value-of select="/cp/strings/file_delete_name"/>:
              </td>
              <td class="contentwidth">
                <xsl:if test="$usertype = 'da'">
                  <xsl:if test="$source_user != /cp/vsap/vsap[@type='auth']/username">
                    <xsl:value-of select="$source_user"/>:
                  </xsl:if>
                </xsl:if>
                <xsl:variable name="path">
                  <xsl:value-of select="/cp/form/itemname"/>
                </xsl:variable>
                <xsl:value-of select="$path"/><input type="hidden" name="path" value="{$path}"/>
              </td>
            </tr>
          </xsl:if>

          <tr class="controlrow">
            <td colspan="2">
              <input class="floatright" type="button" name="cmd_cancel" value="{/cp/strings/file_btn_cancel}" onClick="document.forms[0].action.value='cancel';document.forms[0].submit();"/>
              <input class="floatright" type="submit" name="ok" value="{/cp/strings/file_btn_ok}"/>
            </td>
          </tr>

        </table>
  </xsl:template>

</xsl:stylesheet>
