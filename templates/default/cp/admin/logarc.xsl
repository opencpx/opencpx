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

<xsl:variable name="sort_by">
  <xsl:choose>
    <xsl:when test="string(/cp/form/sort)"><xsl:value-of select="/cp/form/sort" /></xsl:when>
    <xsl:otherwise>path</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="sort_order">
  <xsl:choose>
    <xsl:when test="string(/cp/form/order)"><xsl:value-of select="/cp/form/order" /></xsl:when>
    <xsl:otherwise>ascending</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:template match="/">
  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title"><xsl:copy-of select="/cp/strings/cp_title" /> : <xsl:copy-of select="/cp/strings/bc_system_admin_arc_log" /> : <xsl:value-of select="cp/form/domain"/></xsl:with-param>
    <xsl:with-param name="formaction">logarc.xsl</xsl:with-param>
    <xsl:with-param name="feedback" select="$feedback" />
    <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_admin_view_logs" />
    <xsl:with-param name="help_short" select="/cp/strings/system_admin_hlp_short" />
    <xsl:with-param name="help_long"><xsl:copy-of select="/cp/strings/system_admin_hlp_long" /></xsl:with-param>
    <xsl:with-param name="breadcrumb">
      <breadcrumb>
        <section>
          <name><xsl:copy-of select="/cp/strings/bc_system_admin_log" /></name>
          <url><xsl:value-of select="$base_url"/>/cp/admin/loglist.xsl?domain=<xsl:value-of select="cp/form/domain"/></url>
        </section>
        <section>
          <name><xsl:copy-of select="/cp/strings/bc_system_admin_arc_log" /></name>
          <url>#</url>
          <image>SystemAdministration</image>
        </section>
      </breadcrumb>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

    <script src="{$base_url}/cp/admin/logarc.js" language="javascript"/>
    <input type="hidden" name="logname" value="{/cp/form/logname}"/>
    <input type="hidden" name="sort" value="{/cp/form/sort}"/>
    <input type="hidden" name="order" value="{/cp/form/order}"/>
    <input type="hidden" name="domain" value="{/cp/form/domain}"/>
    <input type="hidden" name="action" value="NA"/>

    <xsl:call-template name="cp_titlenavbar">
      <xsl:with-param name="active_tab">admin</xsl:with-param>
    </xsl:call-template>

    <table class="listview" border="0" cellspacing="0" cellpadding="0">
      <tr class="instructionrow">
        <td colspan="5"><xsl:value-of select="/cp/strings/admin_arc_log_select_domain"/>
          <b><xsl:value-of select="/cp/form/logname"/></b>
          <!--select name="domain" onchange="submit()">
            <xsl:for-each select="/cp/vsap/vsap[@type='domain:list']/domain">
              <option value="{name}"><xsl:if test="/cp/form/domain=name"><xsl:attribute name="selected"/></xsl:if>
              <xsl:value-of select="name"/></option>
            </xsl:for-each>
          </select>&#160; <input type="submit" name="btn_domain" value="{/cp/strings/btn_go}" /-->
        </td>
      </tr>

      <tr class="controlrow">
        <td colspan="5"><input type="button" name="delete_file" value="{/cp/strings/log_arc_btn_delete}" onClick="submitItems('{cp:js-escape(/cp/strings/archive_item_select_prompt)}', 'chk_log','{cp:js-escape(/cp/strings/confirm_archives_delete)}','delete')"/>
                        <!--input type="submit" name="do_not_delete" value="{/cp/strings/log_arc_btn_mark_delete}" /-->
        </td>
      </tr>

      <tr class="columnhead">
        <td class="ckboxcolumn"><input type="checkbox" name="cbSelectAll" onClick="check(this.form.chk_log)"/></td>
        <td>
          <xsl:variable name="order">
            <xsl:choose>
              <xsl:when test="$sort_by='path' and $sort_order='ascending'">descending</xsl:when>
              <xsl:otherwise>ascending</xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <a href="{$base_url}/cp/admin/logarc.xsl?logname={/cp/form/logname}&amp;domain={/cp/form/domain}&amp;sort=path&amp;order={$order}"><xsl:value-of select="/cp/strings/log_arc_header_name"/>
            <xsl:if test="$sort_by='path'">
              <xsl:if test="$sort_order='ascending'"><img src="{/cp/strings/img_sortarrowup}" border="0" /></xsl:if>
              <xsl:if test="$sort_order='descending'"><img src="{/cp/strings/img_sortarrowdown}" border="0" /></xsl:if>
            </xsl:if></a>
        </td>
        <td>&#160;</td>
        <td>
          <xsl:variable name="order">
            <xsl:choose>
              <xsl:when test="$sort_by='size' and $sort_order='ascending'">descending</xsl:when>
              <xsl:otherwise>ascending</xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <a href="{$base_url}/cp/admin/logarc.xsl?logname={/cp/form/logname}&amp;domain={/cp/form/domain}&amp;sort=size&amp;order={$order}"><xsl:value-of select="/cp/strings/log_arc_header_size"/>
            <xsl:if test="$sort_by='size'">
              <xsl:if test="$sort_order='ascending'"><img src="{/cp/strings/img_sortarrowup}" border="0" /></xsl:if>
              <xsl:if test="$sort_order='descending'"><img src="{/cp/strings/img_sortarrowdown}" border="0" /></xsl:if>
            </xsl:if></a>
        </td>
        <td><xsl:value-of select="/cp/strings/log_arc_header_actions"/></td>
      </tr>

      <xsl:if test="count(/cp/vsap/vsap[@type='sys:logs:list_archives']/archive) = 0">
        <tr class="rowodd">
          <td colspan="5"><xsl:value-of select="/cp/strings/log_arc_not_exist"/></td>
        </tr>
      </xsl:if>

      <xsl:for-each select="/cp/vsap/vsap[@type='sys:logs:list_archives']/archive">
        <xsl:sort select="*[local-name()=$sort_by]" order="{$sort_order}"/>

          <xsl:variable name="row_id">row<xsl:value-of select="position()"/></xsl:variable>

          <xsl:variable name="row_style">
            <xsl:choose>
              <xsl:when test="position() mod 2 = 1">rowodd</xsl:when>
              <xsl:otherwise>roweven</xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="size">
            <xsl:choose>
              <xsl:when test="string(size)"><xsl:value-of select="size"/></xsl:when>
              <xsl:otherwise>0</xsl:otherwise>
            </xsl:choose>
          </xsl:variable>

          <tr class="{$row_style}">
            <td><input type="checkbox" id="{$row_id}" name="chk_log" value="{path}"/></td>
            <td><label for="{$row_id}"><xsl:value-of select="path"/></label></td>
            <td>&#160;</td>
            <td>
              <xsl:call-template name="format_bytes">
                <xsl:with-param name="bytes" select="$size"/>
              </xsl:call-template>
            </td>
            <td class="actions">
               <a href="{$base_url}/cp/admin/logarc.xsl/VSAPDOWNLOAD/?domain={/cp/form/domain}&amp;target={path}&amp;logname={/cp/form/logname}&amp;action=download"><xsl:value-of select="/cp/strings/log_arc_action_download"/></a>
               |
               <a href="#" onClick="return confirmAction('{cp:js-escape(/cp/strings/confirm_archive_delete)}', '{$base_url}/cp/admin/logarc.xsl?domain={/cp/form/domain}&amp;logname={/cp/form/logname}&amp;action=delete&amp;target={path}&amp;order={/cp/form/order}&amp;sort={/cp/form/sort}')"><xsl:value-of select="/cp/strings/log_arc_action_delete"/></a>
            </td>
          </tr>
        </xsl:for-each>
      </table>

</xsl:template>

</xsl:stylesheet>
