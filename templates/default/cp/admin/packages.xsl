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
      <!-- append post install messages here -->
      <xsl:choose>
        <xsl:when test="/cp/form/package = 'mod_ruby'">
          <br/><br/><xsl:value-of select="/cp/strings/package_postinstall_mod_ruby" />
        </xsl:when>
        <xsl:when test="/cp/form/package = 'mysql-server'">
          <br/><br/><xsl:value-of select="/cp/strings/package_postinstall_mysql" />
        </xsl:when>
        <xsl:when test="/cp/form/package = 'samba'">
          <br/><br/><xsl:value-of select="/cp/strings/package_postinstall_samba" />
        </xsl:when>
        <xsl:when test="/cp/form/package = 'squirrelmail'">
          <br/><br/><xsl:value-of select="/cp/strings/package_postinstall_squirrelmail_1" />
          <br/><br/><xsl:value-of select="/cp/strings/package_postinstall_squirrelmail_2" />
          <br/><br/><xsl:value-of select="/cp/strings/package_postinstall_squirrelmail_3" />
          <br/><br/><xsl:value-of select="/cp/strings/package_postinstall_squirrelmail_4" />
        </xsl:when>
        <xsl:when test="/cp/form/package='webmin'">
          <br/><br/><xsl:value-of select="/cp/strings/package_postinstall_webmin_1" />
          <br/><br/><xsl:value-of select="/cp/strings/package_postinstall_webmin_2" />
        </xsl:when>
      </xsl:choose>
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

<xsl:variable name="sort_by">
  <xsl:choose>
    <xsl:when test="string(/cp/form/sort)"><xsl:value-of select="/cp/form/sort" /></xsl:when>
    <xsl:otherwise>name</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="sort_order">
  <xsl:choose>
    <xsl:when test="string(/cp/form/order)"><xsl:value-of select="/cp/form/order" /></xsl:when>
    <xsl:otherwise>ascending</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="show_maintained">
  <xsl:choose>
    <xsl:when test="string(/cp/form/chk_show_maintained)">yes</xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="start">
  <xsl:choose>
    <xsl:when test="string(/cp/form/start)"><xsl:value-of select="/cp/form/start" /></xsl:when>
    <xsl:otherwise>1</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="range">
  <xsl:choose>
    <xsl:when test="string(/cp/form/range)"><xsl:value-of select="/cp/form/range" /></xsl:when>
    <xsl:otherwise><xsl:value-of select="/cp/vsap/vsap[@type='user:prefs:load']/user_preferences/sa_packages_per_page"/></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="pattern" select="/cp/form/pattern" />
<xsl:variable name="totalPackages" select="/cp/vsap/vsap[@type='sys:packages:list']/num_packages" />
<xsl:variable name="startPackage" select="/cp/vsap/vsap[@type='sys:packages:list']/start" />
<xsl:variable name="endPackage" select="/cp/vsap/vsap[@type='sys:packages:list']/end" />

<xsl:variable name="prevRange">
  <xsl:choose>
    <xsl:when test="$range &gt;= $startPackage">1</xsl:when>
    <xsl:otherwise><xsl:value-of select="$startPackage - $range"/></xsl:otherwise>
  </xsl:choose>
</xsl:variable>
<xsl:variable name="nextRange" select="$startPackage + $range"/>
<!--xsl:variable name="lastRange" select="$totalPackages - $range + 1"/-->
<xsl:variable name="lastRange" select="format-number(($totalPackages div $range), '###0') * $range + 1"/>


<xsl:template match="/cp/vsap/vsap[@type='sys:packages:list']/package">
  <xsl:variable name="row_style">
    <xsl:choose>
      <xsl:when test="position() mod 2 = 1">rowodd</xsl:when>
      <xsl:otherwise>roweven</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <tr class="{$row_style}">
    <td>
      <xsl:call-template name="truncate">
        <xsl:with-param name="string">
          <xsl:value-of select="name"/>
          <xsl:if test="installed='yes'">&#160;-&#160;<xsl:value-of select="installed_version" /></xsl:if>
        </xsl:with-param>
        <xsl:with-param name="fieldlength" select="/cp/strings/package_name_length" />
      </xsl:call-template>
    </td>
    <td>
      <xsl:value-of select="latest_version" />
    </td>
    <td>
      <xsl:call-template name="truncate">
        <xsl:with-param name="string" select="comment"/>
        <xsl:with-param name="fieldlength" select="/cp/strings/package_desc_length" />
      </xsl:call-template>
    </td>
    <td>
      <xsl:if test="installed='yes'"><span class="running">&#160;</span></xsl:if>
      <xsl:if test="installed!='yes'"><span class="stopped">&#160;</span></xsl:if>
    </td>
    <td class="actions">
      <a href="{$base_url}/cp/admin/packageview.xsl?package={name}">
         <xsl:value-of select="/cp/strings/package_more_info"/>
      </a>
      <xsl:if test="maintained != 'yes'">

      <xsl:variable name="uninstall_warning">
        <xsl:choose>
          <xsl:when test="count(required_by/package) = 0"><xsl:value-of select="/cp/strings/confirm_package_uninstall_1"/></xsl:when>
          <xsl:otherwise><xsl:value-of select="/cp/strings/confirm_package_uninstall_2"/></xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      &#160;|&#160;
      <xsl:if test="installed='yes'">
        <xsl:if test="name != 'clamav' and name != 'p5-Mail-SpamAssassin' and name != 'procmail'">
          <a href="#" onClick="return confirmAction('{cp:js-escape($uninstall_warning)}', '{$base_url}/cp/admin/packages.xsl?package={name}&amp;action=uninstall&amp;start={$startPackage}&amp;range={$range}&amp;pattern={$pattern}&amp;sort={$sort_by}&amp;order={$sort_order}&amp;chk_show_maintained={$show_maintained}')">
           <xsl:value-of select="/cp/strings/package_uninstall"/>
          </a>
          &#160;|&#160;
        </xsl:if>
        <a href="#" onClick="return confirmAction('{cp:js-escape(/cp/strings/confirm_package_reinstall)}', '{$base_url}/cp/admin/packages.xsl?package={name}&amp;action=reinstall&amp;start={$startPackage}&amp;range={$range}&amp;pattern={$pattern}&amp;sort={$sort_by}&amp;order={$sort_order}&amp;chk_show_maintained={$show_maintained}')">
         <xsl:value-of select="/cp/strings/package_reinstall"/>
        </a>
        &#160;|&#160;
        <xsl:choose>
          <xsl:when test="update_available='yes'">
            <a href="#" onClick="return confirmAction('{cp:js-escape(/cp/strings/confirm_package_update)}', '{$base_url}/cp/admin/packages.xsl?package={name}&amp;action=update&amp;start={$startPackage}&amp;range={$range}&amp;pattern={$pattern}&amp;sort={$sort_by}&amp;order={$sort_order}&amp;chk_show_maintained={$show_maintained}')">
              <xsl:value-of select="/cp/strings/package_update"/>
            </a>
          </xsl:when>
          <xsl:otherwise><xsl:value-of select="/cp/strings/package_update"/></xsl:otherwise>
        </xsl:choose>
      </xsl:if>

      <xsl:if test="installed='no'">
        <a href="{$base_url}/cp/admin/packages.xsl?package={name}&amp;action=install&amp;start={$startPackage}&amp;range={$range}&amp;pattern={$pattern}&amp;sort={$sort_by}&amp;order={$sort_order}&amp;chk_show_maintained={$show_maintained}">
         <xsl:value-of select="/cp/strings/package_install"/>
        </a>
      </xsl:if>
      </xsl:if>
    </td>
  </tr>
</xsl:template>

<xsl:template match="/">
  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title"><xsl:copy-of select="/cp/strings/cp_title" /> : <xsl:copy-of select="/cp/strings/bc_system_admin_packages" /></xsl:with-param>
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
      <input type="hidden" name="sort" value="{$sort_by}"/>
      <input type="hidden" name="order" value="{$sort_order}"/>

      <xsl:call-template name="cp_titlenavbar">
        <xsl:with-param name="active_tab">admin</xsl:with-param>
      </xsl:call-template>

      <table class="formview" border="0" cellspacing="0" cellpadding="0">
        <tr class="instructionrow">
	    <td colspan="2"><xsl:value-of select="/cp/strings/packages_description"/></td>
        </tr>
        <tr class="roweven">
          <td class="label"><xsl:value-of select="/cp/strings/package_search"/></td>
          <td class="contentwidth"><input type="text" size="20" name="pattern" value="{$pattern}"/>&#160;<input type="submit" name="search" value="{/cp/strings/btn_search}"/>&#160;<input type="submit" name="reset" onClick="this.form.pattern.value=''; this.form.search.click(); return false;" value="{/cp/strings/btn_reset}"/><br/><input type="checkbox" name="chk_pkg_desc" value="yes"><xsl:if test="/cp/form/chk_pkg_desc"><xsl:attribute name="checked"/></xsl:if></input><xsl:value-of select="/cp/strings/package_search_name_desc"/></td>
        </tr>
        <tr class="instructionrow">
          <td class="label"><xsl:value-of select="/cp/strings/package_display_options"/></td>
       	<td class="contentwidth"><xsl:value-of select="/cp/strings/packages_per_page"/>
         <select name="range" size="1">
                <option value="10"><xsl:if test="$range='10'"><xsl:attribute name="selected" value="1"/></xsl:if>10</option>
                <option value="25"><xsl:if test="$range='25'"><xsl:attribute name="selected" value="1"/></xsl:if>25</option>
                <option value="50"><xsl:if test="$range='50'"><xsl:attribute name="selected" value="1"/></xsl:if>50</option>
                <option value="100"><xsl:if test="$range='100'"><xsl:attribute name="selected" value="1"/></xsl:if>100</option>
              </select>&#160;   
         <br/><input type="checkbox" name="chk_show_maintained" value="yes"><xsl:if test="/cp/form/chk_show_maintained"><xsl:attribute name="checked"/></xsl:if></input><xsl:value-of select="/cp/strings/package_display_automatically_maintained"/></td>
	</tr>
	<tr class="controlrow"><td colspan="2"><span class="floatright"><input type="submit" name="setpackagesperpage" value="{/cp/strings/btn_update}" /></span></td></tr>
        <tr class="roweven">
          <td colspan="2"><span class="floatright">
            <xsl:choose>
              <xsl:when test="$startPackage &lt; 2">
                <xsl:value-of select="/cp/strings/package_first"/> | 
                <xsl:value-of select="/cp/strings/package_prev"/> | 
              </xsl:when>
              <xsl:otherwise>
                <a href="{$base_url}/cp/admin/packages.xsl?start=1&amp;range={$range}&amp;pattern={$pattern}&amp;sort={$sort_by}&amp;order={$sort_order}&amp;chk_show_maintained={$show_maintained}"><xsl:value-of select="/cp/strings/package_first"/></a> | 
                <a href="{$base_url}/cp/admin/packages.xsl?start={$prevRange}&amp;range={$range}&amp;pattern={$pattern}&amp;sort={$sort_by}&amp;order={$sort_order}&amp;chk_show_maintained={$show_maintained}"><xsl:value-of select="/cp/strings/package_prev"/></a> | 
              </xsl:otherwise>
            </xsl:choose>

            <xsl:choose>
              <xsl:when test="$endPackage = $totalPackages">
                <xsl:value-of select="/cp/strings/package_next"/> | 
                <xsl:value-of select="/cp/strings/package_last"/>
              </xsl:when>
              <xsl:otherwise>
                <a href="{$base_url}/cp/admin/packages.xsl?start={$nextRange}&amp;range={$range}&amp;pattern={$pattern}&amp;sort={$sort_by}&amp;order={$sort_order}&amp;chk_show_maintained={$show_maintained}"><xsl:value-of select="/cp/strings/package_next"/></a> | 
                <a href="{$base_url}/cp/admin/packages.xsl?start={$lastRange}&amp;range={$range}&amp;pattern={$pattern}&amp;sort={$sort_by}&amp;order={$sort_order}&amp;chk_show_maintained={$show_maintained}"><xsl:value-of select="/cp/strings/package_last"/></a>
              </xsl:otherwise>
            </xsl:choose></span>

            <xsl:value-of select="/cp/strings/package_display_index1"/>&#160;<xsl:value-of select="$startPackage"/> - <xsl:value-of select="$endPackage"/> (<xsl:value-of select="/cp/strings/package_display_index2"/>&#160;<xsl:value-of select="$totalPackages"/>)
          </td>
        </tr>
      </table>


      <table class="listview" border="0" cellspacing="0" cellpadding="0">
        <tr class="columnhead">
          <td class="contentwidth">
            <xsl:variable name="order">
              <xsl:choose>
                <xsl:when test="$sort_by='name' and $sort_order='ascending'">descending</xsl:when>
                <xsl:otherwise>ascending</xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <a href="{$base_url}/cp/admin/packages.xsl?start=1&amp;range={$range}&amp;pattern={$pattern}&amp;sort=name&amp;order={$order}&amp;chk_show_maintained={$show_maintained}">
              <xsl:if test="$sort_by='name'">
                <xsl:if test="$sort_order='ascending'"><img src="{/cp/strings/img_sortarrowup}" border="0" /></xsl:if>
                <xsl:if test="$sort_order='descending'"><img src="{/cp/strings/img_sortarrowdown}" border="0" /></xsl:if>
              </xsl:if>              
              <xsl:value-of select="/cp/strings/packages_header_name"/>
            </a>
          </td>
          <td class="contentwidth"><xsl:value-of select="/cp/strings/packages_header_version"/></td>
          <td class="contentwidth">
            <xsl:variable name="order">
              <xsl:choose>
                <xsl:when test="$sort_by='desc' and $sort_order='ascending'">descending</xsl:when>
                <xsl:otherwise>ascending</xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <a href="{$base_url}/cp/admin/packages.xsl?start=1&amp;range={$range}&amp;pattern={$pattern}&amp;sort=desc&amp;order={$order}&amp;chk_show_maintained={$show_maintained}">
              <xsl:if test="$sort_by='desc'">
                <xsl:if test="$sort_order='ascending'"><img src="{/cp/strings/img_sortarrowup}" border="0" /></xsl:if>
                <xsl:if test="$sort_order='descending'"><img src="{/cp/strings/img_sortarrowdown}" border="0" /></xsl:if>
              </xsl:if>              
              <xsl:value-of select="/cp/strings/packages_header_desc"/>
            </a>
          </td>
          <td class="contentwidth">
            <xsl:variable name="order">
              <xsl:choose>
                <xsl:when test="$sort_by='installed' and $sort_order='ascending'">descending</xsl:when>
                <xsl:otherwise>ascending</xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <a href="{$base_url}/cp/admin/packages.xsl?start=1&amp;range={$range}&amp;pattern={$pattern}&amp;sort=installed&amp;order={$order}&amp;chk_show_maintained={$show_maintained}">
              <xsl:if test="$sort_by='installed'">
                <xsl:if test="$sort_order='ascending'"><img src="{/cp/strings/img_sortarrowup}" border="0" /></xsl:if>
                <xsl:if test="$sort_order='descending'"><img src="{/cp/strings/img_sortarrowdown}" border="0" /></xsl:if>
              </xsl:if>              
              <xsl:value-of select="/cp/strings/packages_header_installed"/>
            </a>
          </td>
          <td><xsl:value-of select="/cp/strings/packages_header_actions"/></td>
        </tr>

        <xsl:apply-templates select="/cp/vsap/vsap[@type='sys:packages:list']/package"/>

      </table>

</xsl:template>

</xsl:stylesheet>

