<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../cp_global.xsl" />

<xsl:variable name="colspan">3</xsl:variable>

<xsl:variable name="sessionID">
  <xsl:choose>
    <xsl:when test="/cp/form/sessionID"><xsl:value-of select="/cp/form/sessionID"/></xsl:when>
    <xsl:otherwise><xsl:value-of select="/cp/vsap/vsap[@type='files:upload:list']/sessionid"/></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

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
          <xsl:when test="/cp/vsap/vsap[@type='error'] or /cp/msgs/msg='error'">error</xsl:when>
          <xsl:otherwise>success</xsl:otherwise>
        </xsl:choose>
      </xsl:with-param>
      <xsl:with-param name="message">
        <xsl:copy-of select="$message" />
      </xsl:with-param>
    </xsl:call-template>
  </xsl:if>
</xsl:variable>

<!-- this template matches individual files -->
<xsl:template match="/cp/vsap/vsap[@type='files:list']/file">

  <xsl:if test="not((type = 'dir') or
                    (type = 'dirlink') or
                    (type = 'symlink') or
                    (type = 'socket') or
                    (name = '.') or
                    (name = '.shared') or
                    (starts-with(name, '.') and (name != '..')) or
                    ((/cp/vsap/vsap[@type='files:list']/path = /cp/form/doc_root) and (name = '..')))">


    <tr class="roweven">

      <!-- name -->
      <td class="filecolumn">
        <img src="{/cp/strings/podcast_item_select_icons_folder}{cp_icon}.gif" border="0" />&#160;
        <xsl:call-template name="truncate">
          <xsl:with-param name="string" select="name" />
          <xsl:with-param name="fieldlength" select="/cp/strings/podcast_item_select_name_length" />
        </xsl:call-template>
      </td>

      <!-- size -->
      <td class="cpsizecolumn">
        <xsl:call-template name="format_bytes">
          <xsl:with-param name="bytes" select="size"/>
        </xsl:call-template>
      </td>

      <!-- actions -->
      <td>
        <a href="#" onClick="var path = '{/cp/vsap/vsap[@type='files:list']/path}'; window.opener.document.forms[0].fileurl.value = 'http://{/cp/form/domain}' + path.replace('{/cp/form/doc_root}', '') + '/{name}'; window.close();"><xsl:copy-of select="/cp/strings/podcast_item_select_itemselect"/></a>
      </td>

    </tr>
  </xsl:if>
</xsl:template>

<xsl:template match="/">
  <xsl:call-template name="blankbodywrapper">
    <xsl:with-param name="title"><xsl:copy-of select="/cp/strings/cp_title" /> : <xsl:copy-of select="/cp/strings/bc_podcast_item_select" /></xsl:with-param>
    <xsl:with-param name="formaction">podcast_item_select.xsl</xsl:with-param>
    <xsl:with-param name="formname">specialwindow</xsl:with-param>
    <xsl:with-param name="formenctype">multipart/form-data</xsl:with-param> 
    <xsl:with-param name="feedback" select='$feedback' />
    <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_global_tools_podcast" />
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

    <script src="{$base_url}/cp/admin/podcast.js" language="javascript" />

    <input type="hidden" name="sessionID" value="{$sessionID}"/>
    <input type="hidden" name="path" value="{/cp/vsap/vsap[@type='files:list']/path}" />
    <input type="hidden" name="doc_root" value="{/cp/form/doc_root}" />
    <input type="hidden" name="domain" value="{/cp/form/domain}" />

    <table class="webmailpopup" border="0" cellpadding="0" cellspacing="0">
      <tr class="columnhead">
        <td colspan="{$colspan}">
          <xsl:copy-of select="/cp/strings/bc_podcast_item_select" />
        </td>
      </tr>
      <tr class="instructionrow">
        <td colspan="{$colspan}">
          <xsl:copy-of select="/cp/strings/podcast_item_select_description" />
        </td>
      </tr>
      <tr class="columnhead">
        <td colspan="{$colspan}">
            <xsl:copy-of select="/cp/strings/podcast_item_select_content" />&#160;<xsl:value-of select="/cp/vsap/vsap[@type='files:list']/path" />
              <select name="view_path" onchange="var elem=document.getElementById('fileupload'); elem.parentNode.removeChild(elem); submit();">
                <option value=""><xsl:copy-of select="/cp/strings/podcast_item_select_changedir" /></option>
                <xsl:for-each select="/cp/vsap/vsap[@type='files:list']/file[type='dir']">
                <xsl:sort order="ascending" />

                  <!-- this variable stores the path to this dir -->
                  <xsl:variable name="full_path">
                    <xsl:choose>
                      <xsl:when test="/cp/vsap/vsap[@type='files:list']/path">
                        <xsl:if test="/cp/vsap/vsap[@type='files:list']/path != '/'">
                          <xsl:value-of select="/cp/vsap/vsap[@type='files:list']/path" />
                        </xsl:if>
                        <xsl:text />/<xsl:value-of select="./name" />
                      </xsl:when>
                    </xsl:choose>
                  </xsl:variable>

                  <xsl:if test="not((./type = 'dirlink') or (starts-with(./name, '.') and (./name != '..')) or ((/cp/vsap/vsap[@type='files:list']/path = /cp/form/doc_root) and (./name = '..')))">
                    <xsl:choose>
                      <xsl:when test="./name = '..'">
                        <option value="{/cp/vsap/vsap[@type='files:list']/parent_dir}">
                          <xsl:value-of select="./name" />
                        </option>
                      </xsl:when>
                      <xsl:otherwise>
                        <option value="{$full_path}">
                          <xsl:text />/<xsl:value-of select="./name" />
                        </option>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:if>
                </xsl:for-each>
              </select>
        </td>
      </tr>
    </table>

    <table class="webmailpopup formview" border="0" cellspacing="0" cellpadding="0">
      <tr class="columnhead">
        <td class="filecolumn"><xsl:copy-of select="/cp/strings/podcast_item_select_name" /></td>
        <td class="cpsizecolumn"><xsl:copy-of select="/cp/strings/podcast_item_select_size" /></td>
        <td><xsl:copy-of select="/cp/strings/podcast_item_select_actions" /></td>
      </tr>

      <!-- show files here -->
      <xsl:apply-templates select="/cp/vsap/vsap[@type='files:list']/file">
        <!-- group directories together when sorting by name... -->
        <xsl:sort select="dir" order="descending" />
        <xsl:sort select="translate(name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')" order="ascending" />
      </xsl:apply-templates>

      <tr class="controlrow">
        <td colspan="{$colspan}" class="floatright">
          <input class="floatright" type="submit" name="cancel" value="{/cp/strings/podcast_item_select_btn_cancel}" onClick="window.close();" />
        </td>
      </tr>
    </table>
    <p />
    <table class="webmailpopup formview" border="0" cellspacing="0" cellpadding="0">
      <tr class="columnhead">
        <td colspan="{$colspan}"><xsl:copy-of select="/cp/strings/podcast_item_select_upload" />&#160;<xsl:value-of select="/cp/vsap/vsap[@type='files:list']/path" /></td>
      </tr>
      <tr class="rowodd">
        <td class="label"><xsl:copy-of select="/cp/strings/podcast_item_select_upload_label" /></td>
        <td><input value="" size="40" name="fileupload" id="fileupload" type="file" /><br /><xsl:copy-of select="/cp/strings/podcast_item_select_upload_format" /></td>
      </tr>
      <tr class="controlrow">
        <td colspan="{$colspan}" class="floatright">
          <input class="floatright" type="submit" name="upload_file_save" value="{/cp/strings/podcast_item_select_btn_upload}" onClick="return validateUpload('{cp:js-escape(/cp/strings/podcast_task_alert_upfile)}');" />
        </td>
      </tr>
    </table>
</xsl:template>
</xsl:stylesheet>
  
