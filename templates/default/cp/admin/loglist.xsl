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
    <xsl:with-param name="title">
      <xsl:copy-of select="/cp/strings/cp_title" />
      v<xsl:value-of select="/cp/vsap/vsap[@type='auth']/version" /> :
      <xsl:copy-of select="/cp/strings/bc_system_admin_log" />
    </xsl:with-param>
    <xsl:with-param name="formaction">loglist.xsl</xsl:with-param>
    <xsl:with-param name="feedback" select="$feedback" />
    <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_admin_view_logs" />
    <xsl:with-param name="help_short" select="/cp/strings/system_admin_hlp_short" />
    <xsl:with-param name="help_long"><xsl:copy-of select="/cp/strings/system_admin_hlp_long" /></xsl:with-param>
    <xsl:with-param name="breadcrumb">
      <breadcrumb>
        <section>
          <name><xsl:copy-of select="/cp/strings/bc_system_admin_log" /></name>
          <url>#</url>
          <image>SystemAdministration</image>
        </section>
      </breadcrumb>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

      <script src="{$base_url}/cp/admin/logarc.js" language="javascript"/>
      <input type="hidden" name="sort" value="{/cp/form/sort}"/>
      <input type="hidden" name="order" value="{/cp/form/order}"/>

      <xsl:call-template name="cp_titlenavbar">
        <xsl:with-param name="active_tab">admin</xsl:with-param>
      </xsl:call-template>

      <table class="listview" border="0" cellspacing="0" cellpadding="0">
        <tr class="instructionrow">
          <td colspan="4"><xsl:value-of select="/cp/strings/admin_log_select_domain"/>
            <select name="domain" onchange="submit()">
             <xsl:if test="string(/cp/form/domain)=''">
                <option value=""><xsl:value-of select="/cp/strings/admin_log_select"/></option>
              </xsl:if>
              <xsl:for-each select="/cp/vsap/vsap[@type='domain:list']/domain">
                <option value="{name}"><xsl:if test="/cp/form/domain=name"><xsl:attribute name="selected"/></xsl:if>
                <xsl:value-of select="name"/></option>
              </xsl:for-each>
            </select>
          </td>
        </tr>

        <tr class="columnhead">
          <td>
            <xsl:variable name="order">
              <xsl:choose>
                <xsl:when test="$sort_by='path' and $sort_order='ascending'">descending</xsl:when>
                <xsl:otherwise>ascending</xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <a href="{$base_url}/cp/admin/loglist.xsl?domain={/cp/form/domain}&amp;sort=path&amp;order={$order}"><xsl:value-of select="/cp/strings/log_header_name"/>
              <xsl:if test="$sort_by='path'">
                <xsl:if test="$sort_order='ascending'"><img src="{/cp/strings/img_sortarrowup}" border="0" /></xsl:if>
                <xsl:if test="$sort_order='descending'"><img src="{/cp/strings/img_sortarrowdown}" border="0" /></xsl:if>
              </xsl:if></a>
          </td>
          <td>
            <xsl:variable name="order">
              <xsl:choose>
                <xsl:when test="$sort_by='size' and $sort_order='ascending'">descending</xsl:when>
                <xsl:otherwise>ascending</xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <a href="{$base_url}/cp/admin/loglist.xsl?domain={/cp/form/domain}&amp;sort=size&amp;order={$order}"><xsl:value-of select="/cp/strings/log_header_size"/>
              <xsl:if test="$sort_by='size'">
                <xsl:if test="$sort_order='ascending'"><img src="{/cp/strings/img_sortarrowup}" border="0" /></xsl:if>
                <xsl:if test="$sort_order='descending'"><img src="{/cp/strings/img_sortarrowdown}" border="0" /></xsl:if>
              </xsl:if></a>
          </td>
          <td>
            <xsl:variable name="order">
              <xsl:choose>
                <xsl:when test="$sort_by='number_archived' and $sort_order='ascending'">descending</xsl:when>
                <xsl:otherwise>ascending</xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <a href="{$base_url}/cp/admin/loglist.xsl?domain={/cp/form/domain}&amp;sort=number_archived&amp;order={$order}"><xsl:value-of select="/cp/strings/log_header_archives"/>
              <xsl:if test="$sort_by='number_archived'">
                <xsl:if test="$sort_order='ascending'"><img src="{/cp/strings/img_sortarrowup}" border="0" /></xsl:if>
                <xsl:if test="$sort_order='descending'"><img src="{/cp/strings/img_sortarrowdown}" border="0" /></xsl:if>
              </xsl:if></a>
          </td>
          <td><xsl:value-of select="/cp/strings/log_header_actions"/></td>
        </tr>

        <xsl:choose>
          <xsl:when test="string(/cp/form/domain)=''">
            <tr class="rowodd">
              <td colspan="4"><xsl:value-of select="/cp/strings/log_select_domain"/></td>
            </tr>
          </xsl:when>
  
          <xsl:when test="count(/cp/vsap/vsap[@type='sys:logs:list']/log) = 0">
            <tr class="rowodd">
              <td colspan="4"><xsl:value-of select="/cp/strings/log_not_exist"/></td>
            </tr>
          </xsl:when>

          <xsl:otherwise>
            <xsl:for-each select="/cp/vsap/vsap[@type='sys:logs:list']/log">
              <xsl:sort select="*[local-name()=$sort_by]" order="{$sort_order}"/>

              <xsl:variable name="row_style">
                <xsl:choose>
                  <xsl:when test="position() mod 2 = 1">rowodd</xsl:when>
                  <xsl:otherwise>roweven</xsl:otherwise>
                </xsl:choose>
              </xsl:variable>
              <xsl:variable name="archives">
                <xsl:choose>
                  <xsl:when test="string(number_archived)"><xsl:value-of select="number_archived"/></xsl:when>
                  <xsl:otherwise>0</xsl:otherwise>
                </xsl:choose>
              </xsl:variable>
              <xsl:variable name="size">
                <xsl:choose>
                  <xsl:when test="string(size)"><xsl:value-of select="size"/></xsl:when>
                  <xsl:otherwise>0</xsl:otherwise>
               </xsl:choose>
             </xsl:variable>

             <tr class="{$row_style}">
               <td><xsl:value-of select="path"/></td>
               <td>
                 <xsl:call-template name="format_bytes">
                   <xsl:with-param name="bytes" select="$size"/>
                 </xsl:call-template>
               </td>
               <td><xsl:value-of select="$archives"/></td>
               <td class="actions">
                 <xsl:choose>
                   <xsl:when test="$size = 0">
                     <xsl:value-of select="/cp/strings/log_action_view_chunk"/>
                     | 
                     <xsl:value-of select="/cp/strings/log_action_download"/>
                     <xsl:if test="/cp/vsap/vsap[@type='auth']/server_admin">
                       | <xsl:value-of select="/cp/strings/log_action_archive"/>
                     </xsl:if>
                   </xsl:when>
                   <xsl:otherwise>
                     <a target="_blank" href="{$base_url}/cp/admin/logview.xsl?path={path}&amp;size={$size}&amp;domain={/cp/form/domain}&amp;sort={$sort_by}&amp;order={$sort_order}"><xsl:value-of select="/cp/strings/log_action_view_chunk"/></a>
                     | 
                     <a href="{$base_url}/cp/admin/loglist.xsl/VSAPDOWNLOAD/?domain={/cp/form/domain}&amp;path={path}&amp;action=download"><xsl:value-of select="/cp/strings/log_action_download"/></a>
                     <xsl:if test="/cp/vsap/vsap[@type='auth']/server_admin">
                       | <a href="#" onClick="return confirmAction('{cp:js-escape(/cp/strings/log_action_archive_confirm)}', '{$base_url}/cp/admin/loglist.xsl?domain={/cp/form/domain}&amp;path={path}&amp;action=archive&amp;order={/cp/form/order}&amp;sort={/cp/form/sort}')"><xsl:value-of select="/cp/strings/log_action_archive"/></a>
                     </xsl:if>
                   </xsl:otherwise>
                  </xsl:choose>             
                  <xsl:if test="$archives != '0'">
                    | <a href="{$base_url}/cp/admin/logarc.xsl?logname={path}&amp;domain={/cp/form/domain}"><xsl:value-of select="/cp/strings/log_action_view_archive"/></a>
                  </xsl:if>
                </td>
              </tr>
            </xsl:for-each>
          </xsl:otherwise>
        </xsl:choose>
      </table>

</xsl:template>

 
</xsl:stylesheet>
