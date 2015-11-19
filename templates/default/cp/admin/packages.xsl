<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../cp_global.xsl" />

<xsl:variable name="message">
  <xsl:choose>
    <xsl:when test="/cp/msgs/msg[@name='package_update_failure']">
      <xsl:value-of select="/cp/strings/package_update_failure" />&#160;'<xsl:value-of select="/cp/form/package" />'
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='package_update_successful']">
      <xsl:value-of select="/cp/strings/package_update_successful" />&#160;'<xsl:value-of select="/cp/form/package" />'
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='package_install_failure']">
      <xsl:value-of select="/cp/strings/package_install_failure" />&#160;'<xsl:value-of select="/cp/form/package" />'
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='package_install_successful']">
      <xsl:value-of select="/cp/strings/package_install_successful" />&#160;'<xsl:value-of select="/cp/form/package" />'
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='package_uninstall_failure']">
      <xsl:value-of select="/cp/strings/package_uninstall_failure" />&#160;'<xsl:value-of select="/cp/form/package" />'
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='package_uninstall_successful']">
      <xsl:value-of select="/cp/strings/package_uninstall_successful" />&#160;'<xsl:value-of select="/cp/form/package" />'
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='package_reinstall_failure']">
      <xsl:value-of select="/cp/strings/package_reinstall_failure" />&#160;'<xsl:value-of select="/cp/form/package" />'
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='package_reinstall_successful']">
      <xsl:value-of select="/cp/strings/package_reinstall_successful" />&#160;'<xsl:value-of select="/cp/form/package" />'
    </xsl:when>
  </xsl:choose>
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

<xsl:variable name="sort_by"><xsl:value-of select="/cp/vsap/vsap[@type='sys:package:list']/sortby" /></xsl:variable>
<xsl:variable name="sort_type"><xsl:value-of select="/cp/vsap/vsap[@type='sys:package:list']/order" /></xsl:variable>
<xsl:variable name="sort_order"><xsl:value-of select="/cp/vsap/vsap[@type='sys:package:list']/order" /></xsl:variable>

<xsl:variable name="pattern" select="/cp/form/pattern" />

<xsl:variable name="search_all">
  <xsl:choose>
    <xsl:when test="string(/cp/form/search_all)"><xsl:value-of select="/cp/form/search_all"/></xsl:when>
    <xsl:otherwise>no</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="sort_url">packages.xsl?pattern=<xsl:value-of select="/cp/form/pattern" />&amp;search_all=<xsl:value-of select="/cp/form/search_all" />&amp;</xsl:variable>

<xsl:variable name="list_url">packages.xsl?pattern=<xsl:value-of select="/cp/form/pattern" />&amp;search_all=<xsl:value-of select="/cp/form/search_all" />&amp;page=<xsl:value-of select="/cp/form/page" />&amp;sort_by=<xsl:value-of select="/cp/vsap/vsap[@type='sys:package:list']/sortby"/>&amp;sort_type=<xsl:value-of select="/cp/vsap/vsap[@type='sys:package:list']/order"/>&amp;</xsl:variable>

<xsl:variable name="view_url">packageview.xsl?pattern=<xsl:value-of select="/cp/form/pattern" />&amp;search_all=<xsl:value-of select="/cp/form/search_all" />&amp;page=<xsl:value-of select="/cp/form/page" />&amp;sort_by=<xsl:value-of select="/cp/vsap/vsap[@type='sys:package:list']/sortby"/>&amp;sort_type=<xsl:value-of select="/cp/vsap/vsap[@type='sys:package:list']/order"/>&amp;</xsl:variable>

<xsl:template match="/cp/vsap/vsap[@type='sys:package:list']/package">

  <xsl:variable name="row_id">row<xsl:value-of select="position()"/></xsl:variable>

  <xsl:variable name="row_style">
    <xsl:choose>
      <xsl:when test="position() mod 2 = 1">rowodd</xsl:when>
      <xsl:otherwise>roweven</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <tr class="{$row_style}">
    <td>
      <xsl:value-of select="name" />
    </td>
    <td>
      <xsl:value-of select="version" />
    </td>
    <xsl:choose>
     <xsl:when test="string(installdate)">
      <td>
        <xsl:call-template name="truncate">
          <xsl:with-param name="string" select="summary"/>
          <xsl:with-param name="fieldlength" select="/cp/strings/package_desc_length" />
        </xsl:call-template>
      </td>
      <td>
       <xsl:call-template name="display_date">
        <xsl:with-param name="date" select="installdate"/>
       </xsl:call-template>
      </td>
      <td><xsl:call-template name="format_bytes"><xsl:with-param name="bytes" select="size"/></xsl:call-template></td>
     </xsl:when>
     <xsl:otherwise>
      <td>
        <xsl:value-of select="summary" />
      </td>
     </xsl:otherwise>
    </xsl:choose>
    <td class="actions">
      <a href="{$view_url}package={name}">
         <xsl:value-of select="/cp/strings/package_view"/>
      </a>

<!-- NOT YET IMPLEMENTED

      <xsl:variable name="uninstall_warning">
        <xsl:choose>
          <xsl:when test="count(required_by/package) = 0"><xsl:value-of select="/cp/strings/confirm_package_uninstall_1"/></xsl:when>
          <xsl:otherwise><xsl:value-of select="/cp/strings/confirm_package_uninstall_2"/></xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      &#160;|&#160;
      <xsl:if test="installed='yes'">
        <xsl:if test="name != 'clamav' and name != 'p5-Mail-SpamAssassin' and name != 'procmail'">
          <a href="#" onClick="return confirmAction('{cp:js-escape($uninstall_warning)}', '{$list_url}package={name}&amp;action=uninstall')">
           <xsl:value-of select="/cp/strings/package_uninstall"/>
          </a>
          &#160;|&#160;
        </xsl:if>
        <a href="#" onClick="return confirmAction('{cp:js-escape(/cp/strings/confirm_package_reinstall)}', '{$list_url}package={name}&amp;action=reinstall')">
         <xsl:value-of select="/cp/strings/package_reinstall"/>
        </a>
        &#160;|&#160;
        <xsl:choose>
          <xsl:when test="update_available='yes'">
            <a href="#" onClick="return confirmAction('{cp:js-escape(/cp/strings/confirm_package_update)}', '{$list_url}package={name}&amp;action=update')">
              <xsl:value-of select="/cp/strings/package_update"/>
            </a>
          </xsl:when>
          <xsl:otherwise><xsl:value-of select="/cp/strings/package_update"/></xsl:otherwise>
        </xsl:choose>
      </xsl:if>

      <xsl:if test="installed='no'">
        <a href="{$list_url}package={name}&amp;action=install')">
         <xsl:value-of select="/cp/strings/package_install"/>
        </a>
      </xsl:if>

-->

    </td>
  </tr>
</xsl:template>

<xsl:template match="/">
  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title">
      <xsl:copy-of select="/cp/strings/cp_title" />
      v<xsl:value-of select="/cp/vsap/vsap[@type='auth']/version" /> :
      <xsl:copy-of select="/cp/strings/bc_system_admin_packages" />
    </xsl:with-param>
    <xsl:with-param name="formaction">packages.xsl</xsl:with-param>
    <xsl:with-param name="feedback" select="$feedback" />
    <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_admin_manage_packages" />
    <xsl:with-param name="help_short" select="/cp/strings/system_admin_hlp_short" />
    <xsl:with-param name="help_long"><xsl:copy-of select="/cp/strings/system_admin_hlp_long" /></xsl:with-param>
    <xsl:with-param name="breadcrumb">
      <breadcrumb>
        <section>
          <name><xsl:copy-of select="/cp/strings/bc_system_admin_packages" /></name>
          <url>#</url>
          <image>SystemAdministration</image>
        </section>
      </breadcrumb>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

      <script src="{$base_url}/cp/admin/packages.js" language="javascript"/>

      <input type="hidden" name="sort_by" value="{$sort_by}" />
      <input type="hidden" name="sort_type" value="{$sort_type}" />
      <input type="hidden" name="sort_order" value="{$sort_order}" />

      <xsl:call-template name="cp_titlenavbar">
        <xsl:with-param name="active_tab">admin</xsl:with-param>
      </xsl:call-template>

      <table class="formview" border="0" cellspacing="0" cellpadding="0">
        <tr class="instructionrow">
	    <td colspan="2"><xsl:value-of select="/cp/strings/packages_description"/></td>
        </tr>
        <tr class="roweven">
          <td class="label"><xsl:value-of select="/cp/strings/package_search"/></td>
          <td class="contentwidth">
            <input type="text" size="20" name="pattern" value="{$pattern}"/>&#160;
            <input type="submit" name="search" value="{/cp/strings/btn_search}"/>&#160;
            <input type="submit" name="reset" onClick="this.form.pattern.value=''; this.form.search_all.value='no'; this.form.search.click(); return false;" value="{/cp/strings/btn_reset}"/><br/>
            <input type="radio" name="search_all" value="no">
              <xsl:if test="$search_all='no'"><xsl:attribute name="checked"/></xsl:if>
            </input> <xsl:value-of select="/cp/strings/package_search_installed"/><br/>
            <input type="radio" name="search_all" value="yes">
              <xsl:if test="$search_all='yes'"><xsl:attribute name="checked"/></xsl:if>
            </input> <xsl:value-of select="/cp/strings/package_search_all"/><br/>
          </td>
        </tr>
        <tr class="roweven">
          <td colspan="2">
           <span class="floatright">
              <xsl:choose>
                <xsl:when test='/cp/vsap/vsap/page = 1'>
                  <xsl:value-of select="/cp/strings/package_first" />
                </xsl:when>
                <xsl:otherwise>
                  <a href="{$sort_url}page=1&amp;sort_by={$sort_by}&amp;sort_type={$sort_type}">
                    <xsl:value-of select="/cp/strings/package_first" />
                  </a>
                </xsl:otherwise>
              </xsl:choose>
              |
              <xsl:choose>
                <xsl:when test='string-length(/cp/vsap/vsap/prev_page) > 0'>
                  <a href="{$sort_url}page={/cp/vsap/vsap/prev_page}&amp;sort_by={$sort_by}&amp;sort_type={$sort_type}">
                    <xsl:value-of select="/cp/strings/package_prev" />
                  </a>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="/cp/strings/package_prev" />
                </xsl:otherwise>
              </xsl:choose>
              |
              <xsl:choose>
                <xsl:when test='string-length(/cp/vsap/vsap/next_page) > 0'>
                  <a href="{$sort_url}page={/cp/vsap/vsap/next_page}&amp;sort_by={$sort_by}&amp;sort_type={$sort_type}">
                    <xsl:value-of select="/cp/strings/package_next" />
                  </a>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="/cp/strings/package_next" />
                </xsl:otherwise>
              </xsl:choose>
              |
              <xsl:choose>
                <xsl:when test='/cp/vsap/vsap/page = /cp/vsap/vsap/total_pages'>
                  <xsl:value-of select="/cp/strings/package_last" />
                </xsl:when>
                <xsl:otherwise>
                  <a href="{$sort_url}page={/cp/vsap/vsap/total_pages}&amp;sort_by={$sort_by}&amp;sort_type={$sort_type}">
                    <xsl:value-of select="/cp/strings/package_last" />
                  </a>
                </xsl:otherwise>
              </xsl:choose>

           </span>

           <xsl:value-of select="/cp/strings/package_display_range"/>&#160;
           <xsl:value-of select="/cp/vsap/vsap[@type='sys:package:list']/first_package"/> - 
           <xsl:value-of select="/cp/vsap/vsap[@type='sys:package:list']/last_package"/> 
           (<xsl:value-of select="/cp/strings/package_display_total"/>&#160;
            <xsl:value-of select="/cp/vsap/vsap[@type='sys:package:list']/num_packages"/>)
          </td>
        </tr>
      </table>


      <table class="listview" border="0" cellspacing="0" cellpadding="0">
        <tr class="columnhead">

          <!-- Package Name -->
          <td class="contentwidth">
            <xsl:variable name="namesorturl"><xsl:value-of select="$sort_url" />sort_by=name&amp;sort_type=<xsl:choose>
              <xsl:when test="($sort_by = 'name') and ($sort_type = 'ascending')">descending</xsl:when>
              <xsl:otherwise>ascending</xsl:otherwise>
            </xsl:choose></xsl:variable>
            <a href="{$namesorturl}">
              <xsl:value-of select="/cp/strings/packages_header_name"/>
            </a>&#160;<a href="{$namesorturl}">
              <xsl:if test="$sort_by = 'name'">
                <xsl:choose>
                  <xsl:when test="$sort_type = 'ascending'"><img src="{/cp/strings/img_sortarrowdown}" border="0" /></xsl:when>
                  <xsl:when test="$sort_type = 'descending'"><img src="{/cp/strings/img_sortarrowup}" border="0" /></xsl:when>
                </xsl:choose>
              </xsl:if>
            </a>
          </td>

          <!-- Package Version -->
          <td class="contentwidth"><xsl:value-of select="/cp/strings/packages_header_version"/></td>

          <!-- Package Description -->
          <td class="contentwidth"><xsl:value-of select="/cp/strings/packages_header_desc"/></td>

          <xsl:if test="$search_all = 'no'">

            <!-- Install Date -->
            <td class="contentwidth">
              <xsl:variable name="timesorturl"><xsl:value-of select="$sort_url" />sort_by=installtime&amp;sort_type=<xsl:choose>
                <xsl:when test="($sort_by = 'installtime') and ($sort_type = 'descending')">ascending</xsl:when>
                <xsl:otherwise>descending</xsl:otherwise>
              </xsl:choose></xsl:variable>
              <a href="{$timesorturl}">
                <xsl:value-of select="/cp/strings/packages_header_installed"/>
              </a>&#160;<a href="{$timesorturl}">
                <xsl:if test="$sort_by = 'installtime'">
                  <xsl:choose>
                    <xsl:when test="$sort_type = 'ascending'"><img src="{/cp/strings/img_sortarrowdown}" border="0" /></xsl:when>
                    <xsl:when test="$sort_type = 'descending'"><img src="{/cp/strings/img_sortarrowup}" border="0" /></xsl:when>
                  </xsl:choose>
                </xsl:if>
              </a>
            </td>

            <!-- Size -->
            <td class="contentwidth">
              <xsl:variable name="sizesorturl"><xsl:value-of select="$sort_url" />sort_by=size&amp;sort_type=<xsl:choose>
                <xsl:when test="($sort_by = 'size') and ($sort_type = 'descending')">ascending</xsl:when>
                <xsl:otherwise>descending</xsl:otherwise>
              </xsl:choose></xsl:variable>
              <a href="{$sizesorturl}">
                <xsl:value-of select="/cp/strings/packages_header_size"/>
              </a>&#160;<a href="{$sizesorturl}">
                <xsl:if test="$sort_by = 'size'">
                  <xsl:choose>
                    <xsl:when test="$sort_type = 'ascending'"><img src="{/cp/strings/img_sortarrowdown}" border="0" /></xsl:when>
                    <xsl:when test="$sort_type = 'descending'"><img src="{/cp/strings/img_sortarrowup}" border="0" /></xsl:when>
                  </xsl:choose>
                </xsl:if>
              </a>
            </td>

          </xsl:if>

          <!-- Actions -->
          <td><xsl:value-of select="/cp/strings/packages_header_actions"/></td>

        </tr>

        <xsl:apply-templates select="/cp/vsap/vsap[@type='sys:package:list']/package"/>

      </table>

</xsl:template>

</xsl:stylesheet>

