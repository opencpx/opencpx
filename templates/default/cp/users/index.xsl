<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:exslt="http://exslt.org/common"
                exclude-result-prefixes="exslt">
<xsl:import href="../cp_global.xsl" />

<xsl:variable name="chk_service">
  <xsl:value-of select="/cp/strings/cp_service_checked" />
</xsl:variable>

<xsl:variable name="colspan">
  <xsl:choose>
    <xsl:when test="$user_type='da'">12</xsl:when>
    <xsl:when test="$user_type='ma'">9</xsl:when>
    <xsl:otherwise>8</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="sort_by">
  <xsl:choose>
    <xsl:when test="$user_type='ma' and /cp/vsap/vsap[@type='user:list']/sortby='domain'">login</xsl:when>
    <xsl:otherwise><xsl:value-of select="/cp/vsap/vsap[@type='user:list']/sortby" /></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="sort_type"><xsl:value-of select="/cp/vsap/vsap[@type='user:list']/order" /></xsl:variable>

<xsl:variable name="basic_sort_url">index.xsl?page=<xsl:value-of select="/cp/form/page" />&amp;</xsl:variable>
<xsl:variable name="basic_edit_url">index.xsl?edit=yes&amp;page=<xsl:value-of select="/cp/form/page" />&amp;</xsl:variable>

<xsl:variable name="message">
  <xsl:choose>
    <xsl:when test="/cp/msgs/msg[@name='user_add_failure']">
      <!-- FIXME: no delete error message defined -->
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='user_add_successful']">
      '<xsl:copy-of select="/cp/form/txtLoginID_Prefix" /><xsl:copy-of select="/cp/form/txtLoginID" />'<xsl:copy-of select="/cp/strings/cp_msg_user_add" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='user_delete_threshold_exceeded']">
      <xsl:copy-of select="/cp/strings/cp_msg_users_delete_threshold_exceeded" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='user_delete_failure']">
      <xsl:copy-of select="/cp/strings/cp_msg_users_delete_failure" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='user_delete_successful']">
      <xsl:choose>
        <xsl:when test="count(/cp/form/login_id) > 1">
          <xsl:copy-of select="/cp/strings/cp_msg_users_delete" />
        </xsl:when>
        <xsl:otherwise>
          '<xsl:value-of select="/cp/form/login_id" />'<xsl:copy-of select="/cp/strings/cp_msg_user_delete" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='user_set_status_failure_user_permission']">
      <xsl:copy-of select="/cp/strings/user_profile_err_user_permission" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='user_set_status_failure_other']">
      <!-- FIXME: no set_status error message defined -->
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='user_set_status_successful']">
      <xsl:choose>
        <xsl:when test="/cp/form/set_status = 'enable'">
          '<xsl:value-of select="/cp/form/login_id" />'<xsl:copy-of select="/cp/strings/cp_msg_user_enabled" />
        </xsl:when>
        <xsl:otherwise>
          '<xsl:value-of select="/cp/form/login_id" />'<xsl:copy-of select="/cp/strings/cp_msg_user_disabled" />
        </xsl:otherwise>
      </xsl:choose>
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

<xsl:variable name="selected_user">
  <!-- login id of selected user (current logged in user by default) -->
  <xsl:choose>
    <xsl:when test="string(/cp/form/select_admin)"><xsl:value-of select="/cp/form/select_admin" /></xsl:when>
    <xsl:when test="string(/cp/form/select_domain)">
      <xsl:value-of select="/cp/vsap/vsap[@type='user:list']/user[usertype='da']/login_id" />
    </xsl:when>
    <xsl:otherwise><xsl:value-of select="/cp/vsap/vsap[@type='auth']/username" /></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:template match="/cp/vsap/vsap[@type='user:list']/user">

  <xsl:variable name="domain_name">
    <xsl:value-of select="domain" />
  </xsl:variable>

  <xsl:variable name="row_id">row<xsl:value-of select="position()"/></xsl:variable>

  <xsl:variable name="row_style">
    <xsl:choose>
      <xsl:when test="position() mod 2 = 1">rowodd</xsl:when>
      <xsl:otherwise>roweven</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <tr class="{$row_style}">
    <td>
      <xsl:choose>
        <!-- can't delete self -->
        <xsl:when test="login_id = /cp/vsap/vsap[@type='auth']/username"><br /></xsl:when>
        <!-- mail admin cannot get properties for or disable another mail admin (or self) -->
        <xsl:when test="usertype='ma' and $user_type='ma'"><br /></xsl:when>
        <!-- only end users and domain admins with no domains can be deleted -->
        <xsl:when test="usertype='eu' or usertype='ma' or (usertype='da' and count(domains/domain)=0)">
          <input type="checkbox" id="{$row_id}" name="login_id" value="{login_id}" />
        </xsl:when>
        <xsl:otherwise><br /></xsl:otherwise>
      </xsl:choose>
    </td>
    <td>
      <label for="{$row_id}"><xsl:value-of select="login_id" /></label>
    </td>
    <td>
      <xsl:choose>
        <xsl:when test="usertype != 'da' or (usertype = 'da' and count(domains/domain) = 0)">
          <xsl:call-template name="truncate">
            <xsl:with-param name="string" select="domain" />
            <xsl:with-param name="fieldlength" select="/cp/strings/user_list_domain_length" />
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/form/select_domain != ''">
          <xsl:call-template name="truncate">
            <xsl:with-param name="string" select="/cp/form/select_domain" />
            <xsl:with-param name="fieldlength" select="/cp/strings/user_list_domain_length" />
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="usertype='da' and $user_type='ma'">
          <xsl:call-template name="truncate">
            <xsl:with-param name="string" select="domain" />
            <xsl:with-param name="fieldlength" select="/cp/strings/user_list_domain_length" />
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:if test="usertype != 'da'">
            <xsl:call-template name="truncate">
              <xsl:with-param name="string" select="domain" />
              <xsl:with-param name="fieldlength" select="/cp/strings/user_list_domain_length" />
            </xsl:call-template>
            <br />
          </xsl:if>
          <xsl:for-each select="domains/domain">
            <xsl:sort select="translate(name, 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')" />
            <xsl:call-template name="truncate">
              <xsl:with-param name="string" select="name" />
              <xsl:with-param name="fieldlength" select="/cp/strings/user_list_domain_length" />
            </xsl:call-template>
            <br />
          </xsl:for-each>
        </xsl:otherwise>
      </xsl:choose>
    </td>
    <xsl:if test="$user_type='sa' or $user_type='da'">
      <td>
        <xsl:choose>
          <xsl:when test="usertype='sa'">
            <xsl:copy-of select="/cp/strings/cp_sa" />
          </xsl:when>
          <xsl:when test="usertype='da'">
            <xsl:copy-of select="/cp/strings/cp_da" />
          </xsl:when>
          <xsl:when test="usertype='ma'">
            <xsl:copy-of select="/cp/strings/cp_ma" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:copy-of select="/cp/strings/cp_eu" />
          </xsl:otherwise>
        </xsl:choose>
      </td>
    </xsl:if>
    <td>
      <xsl:choose>
        <xsl:when test="status = 'enabled'">
          <xsl:copy-of select="/cp/strings/user_list_status_enabled" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:copy-of select="/cp/strings/user_list_status_disabled" />
        </xsl:otherwise>
      </xsl:choose>
    </td>
    <xsl:if test="$user_type='da' or $user_type='ma'">
      <xsl:if test="/cp/vsap/vsap[@type='auth']/services/mail">
        <td class="centeralign">
        <xsl:choose>
          <xsl:when test="services/mail">
            <img src="{$chk_service}" alt="" border="0" />
          </xsl:when>
          <xsl:otherwise><br /></xsl:otherwise>
        </xsl:choose>
        </td>
      </xsl:if>
    </xsl:if>
    <xsl:if test="$user_type='ma'">
      <xsl:if test="/cp/vsap/vsap[@type='auth']/services/webmail">
        <td class="centeralign">
        <xsl:choose>
          <xsl:when test="services/webmail">
            <img src="{$chk_service}" alt="" border="0" />
          </xsl:when>
          <xsl:otherwise><br /></xsl:otherwise>
        </xsl:choose>
        </td>
      </xsl:if>
    </xsl:if>
    <xsl:if test="$user_type='da'">
      <xsl:if test="/cp/vsap/vsap[@type='auth']/services/ftp">
        <td class="centeralign">
        <xsl:choose>
          <xsl:when test="services/ftp">
            <img src="{$chk_service}" alt="" border="0" />
          </xsl:when>
          <xsl:otherwise><br /></xsl:otherwise>
        </xsl:choose>
        </td>
      </xsl:if>
      <xsl:if test="/cp/vsap/vsap[@type='auth']/services/fileman">
        <td class="centeralign">
        <xsl:choose>
          <xsl:when test="services/fileman">
            <img src="{$chk_service}" alt="" border="0" />
          </xsl:when>
          <xsl:otherwise><br /></xsl:otherwise>
        </xsl:choose>
        </td>
      </xsl:if>
      <xsl:if test="not(/cp/vsap/vsap[@type='auth']/siteprefs/disable-shell)">
        <xsl:if test="/cp/vsap/vsap[@type='auth']/services/shell">
          <td class="centeralign">
          <xsl:choose>
            <xsl:when test="services/shell">
              <img src="{$chk_service}" alt="" border="0" />
            </xsl:when>
            <xsl:otherwise><br /></xsl:otherwise>
          </xsl:choose>
          </td>
        </xsl:if>
      </xsl:if>
    </xsl:if>
    <td class="rightalign">
      <xsl:choose>
        <xsl:when test="usertype = 'sa' and user_quota/limit != 0">
          <xsl:value-of select="user_quota/limit" />&#160;
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="quota/limit" />&#160;
        </xsl:otherwise>
      </xsl:choose>
      <xsl:choose>
        <xsl:when test="quota/units = 'GB'">
          <xsl:value-of select="/cp/strings/gb" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="/cp/strings/mb" />
        </xsl:otherwise>
      </xsl:choose>
    </td>
    <td class="rightalign">
      <xsl:choose>
        <!-- these are the conditions such that the group quota is the limit for disk usage for this user -->
        <xsl:when test="(quota/grp_limit > 0) and ((quota/limit = 0) or (quota/grp_limit &lt;= quota/limit))">
          <xsl:value-of select="format-number( ((quota/grp_usage div quota/grp_limit) * 100), '##.#')" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="format-number( ((quota/usage div quota/limit) * 100), '##.#')" />
        </xsl:otherwise>
      </xsl:choose>
      <xsl:copy-of select="/cp/strings/cp_quota_percent" />
    </td>
    <td class="actions">
      <xsl:choose>
        <!-- mail admin cannot get properties for or disable server admin -->
        <xsl:when test="usertype='sa' and $user_type='ma'">
          <xsl:copy-of select="/cp/strings/user_list_properties" />
          <xsl:copy-of select="/cp/strings/user_list_bar" />
          <xsl:copy-of select="/cp/strings/user_list_disable" />
        </xsl:when>
        <!-- mail admin cannot get properties for or disable domain admin parent -->
        <xsl:when test="usertype='da' and $user_type='ma'">
          <xsl:copy-of select="/cp/strings/user_list_properties" />
          <xsl:copy-of select="/cp/strings/user_list_bar" />
          <xsl:copy-of select="/cp/strings/user_list_disable" />
        </xsl:when>
        <!-- mail admin cannot get properties for or disable another mail admin (or self) -->
        <xsl:when test="usertype='ma' and $user_type='ma'">
          <xsl:copy-of select="/cp/strings/user_list_properties" />
          <xsl:copy-of select="/cp/strings/user_list_bar" />
          <xsl:copy-of select="/cp/strings/user_list_disable" />
        </xsl:when>
        <!-- you can't get properties on or disable yourself here -->
        <xsl:when test="login_id != /cp/vsap/vsap[@type='auth']/username">
          <a href="{$base_url}/cp/users/user_properties.xsl?login_id={login_id}"><xsl:value-of select="/cp/strings/user_list_properties" /></a>
          <xsl:copy-of select="/cp/strings/user_list_bar" />
          <xsl:choose>
            <xsl:when test="status = 'enabled'">
              <xsl:choose>
                <xsl:when test="usertype = 'da'">
                  <a href="{$basic_edit_url}set_status=disable&amp;login_id={login_id}" onClick="return confirm('{cp:js-escape(/cp/strings/user_list_disable_da)}')"><xsl:value-of select="/cp/strings/user_list_disable" /></a>
                </xsl:when>
                <xsl:otherwise>
                  <a href="{$basic_edit_url}set_status=disable&amp;login_id={login_id}" onClick="return confirm('{cp:js-escape(/cp/strings/user_list_disable_eu)}')"><xsl:value-of select="/cp/strings/user_list_disable" /></a>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
              <xsl:choose>
                <xsl:when test="usertype='eu' or usertype='ma'">
                  <xsl:choose>
                    <xsl:when test="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain_name]/disabled='0'">
                      <a href="{$basic_edit_url}set_status=enable&amp;login_id={login_id}"><xsl:value-of select="/cp/strings/user_list_enable" /></a>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="/cp/strings/user_list_enable" />
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                  <a href="{$basic_edit_url}set_status=enable&amp;login_id={login_id}"><xsl:value-of select="/cp/strings/user_list_enable" /></a>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:choose>
            <xsl:when test="usertype='sa'">
              <a href="{$base_url}/cp/users/user_properties.xsl?login_id={login_id}"><xsl:value-of select="/cp/strings/user_list_properties" /></a>
            </xsl:when>
            <xsl:otherwise>
              <xsl:copy-of select="/cp/strings/user_list_properties" />
            </xsl:otherwise>
          </xsl:choose>
          <xsl:copy-of select="/cp/strings/user_list_bar" />
          <xsl:copy-of select="/cp/strings/user_list_disable" />
        </xsl:otherwise>
      </xsl:choose>
      <xsl:copy-of select="/cp/strings/user_list_bar" />
      <xsl:choose>
        <!-- can't delete self -->
        <xsl:when test="login_id = /cp/vsap/vsap[@type='auth']/username">
          <xsl:value-of select="/cp/strings/user_list_delete" />
        </xsl:when>
        <!-- mail admin cannot get properties for or disable another mail admin (or self) -->
        <xsl:when test="usertype='ma' and $user_type='ma'">
          <xsl:value-of select="/cp/strings/user_list_delete" />
        </xsl:when>
        <!-- only end users and domain admins with no domains can be deleted -->
        <xsl:when test="usertype='eu' or usertype='ma' or (usertype='da' and count(domains/domain)=0)">
          <a href="{$basic_edit_url}delete=yes&amp;login_id={login_id}" onClick="return confirm('{cp:js-escape(/cp/strings/user_list_delete_one_confirm)}')"><xsl:value-of select="/cp/strings/user_list_delete" /></a>
        </xsl:when>
        <xsl:otherwise><xsl:value-of select="/cp/strings/user_list_delete" /></xsl:otherwise>
      </xsl:choose>
    </td>
  </tr>
</xsl:template>

<xsl:template match="/">
  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title"><xsl:copy-of select="/cp/strings/cp_title" /> : <xsl:copy-of select="/cp/strings/bc_user_list" /></xsl:with-param>
    <xsl:with-param name="formaction"><xsl:value-of select="$base_url" />/cp/users/index.xsl</xsl:with-param>
    <xsl:with-param name="feedback" select="$feedback" />
    <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_user_list" />
    <xsl:with-param name="help_short" select="/cp/strings/user_list_hlp_short" />
    <xsl:with-param name="help_long">
      <xsl:choose>
        <xsl:when test="$user_type='sa'">
          <xsl:copy-of select="/cp/strings/user_list_hlp_long_sa" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:copy-of select="/cp/strings/user_list_hlp_long_da" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:with-param>
    <xsl:with-param name="breadcrumb">
      <breadcrumb>
        <section>
          <name><xsl:copy-of select="/cp/strings/bc_user_list" /></name>
          <url>#</url>
          <image>UserManagement</image>
        </section>
      </breadcrumb>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

      <script src="{concat($base_url, '/cp/cp.js')}" language="JavaScript"></script>

      <input type="hidden" name="sort_by" value="{$sort_by}" />
      <input type="hidden" name="sort_type" value="{$sort_type}" />
      <input type="hidden" name="delete" />

      <xsl:call-template name="cp_titlenavbar">
        <xsl:with-param name="active_tab">users</xsl:with-param>
      </xsl:call-template>

      <table class="listview" border="0" cellspacing="0" cellpadding="0">
        <tr class="instructionrow">
          <td colspan="{$colspan}">
            <span class="floatright">
              <xsl:call-template name="print_quota">
                <!-- Show quota for current user (sa or da) or for selected da -->
                <xsl:with-param name="quota" select="/cp/vsap/vsap[@type='user:list']/quota" />
              </xsl:call-template>
            </span>

            <xsl:if test="$user_type != 'ma'">
              <xsl:choose>
                <xsl:when test="$user_type='sa'">
                  <xsl:copy-of select="/cp/strings/user_list_display_users" />
                  <select name="select_admin" size="1" onChange="set_domains(this.value)">
                    <option value=""><xsl:value-of select="/cp/strings/user_list_all_admins" /></option>
                    <xsl:choose>
                      <xsl:when test="/cp/vsap/vsap[@type='auth']/platform = 'linux'">
                        <option value="apache">
                          <xsl:if test="/cp/form/select_admin = 'apache'">
                            <xsl:attribute name="selected">true</xsl:attribute>
                          </xsl:if>
                          <xsl:value-of select="/cp/strings/user_list_primary_admin" /> (apache)
                        </option>
                      </xsl:when>
                      <xsl:otherwise>
                        <option value="www">
                          <xsl:if test="/cp/form/select_admin = 'www'">
                            <xsl:attribute name="selected">true</xsl:attribute>
                          </xsl:if>
                          <xsl:value-of select="/cp/strings/user_list_primary_admin" /> (www)
                        </option>
                      </xsl:otherwise>
                    </xsl:choose>
                    <xsl:for-each select="/cp/vsap/vsap[@type='user:list_da']/admin">
                      <xsl:sort select="translate(., 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')" />
                      <xsl:choose>
                        <xsl:when test="(. = 'apache') and (/cp/vsap/vsap[@type='auth']/platform = 'linux')" />
                        <xsl:when test="(. = 'www') and (/cp/vsap/vsap[@type='auth']/platform = 'freebsd4')" />
                        <xsl:when test="(. = 'www') and (/cp/vsap/vsap[@type='auth']/platform = 'freebsd6')" />
                        <xsl:otherwise>
                          <option value="{.}">
                            <xsl:if test=". = /cp/form/select_admin">
                              <xsl:attribute name="selected">true</xsl:attribute>
                            </xsl:if><xsl:value-of select="." />
                          </option>
                        </xsl:otherwise>
                      </xsl:choose>
                    </xsl:for-each>
                  </select>
                  <xsl:copy-of select="/cp/strings/user_list_for" />
                </xsl:when>
  
                <xsl:otherwise>
                  <xsl:copy-of select="/cp/strings/user_list_display_users_da" />
                </xsl:otherwise>
  
              </xsl:choose>
  
              <select name="select_domain" style="width:200px;" size="1" onFocus="setWidth(this, document.forms[0].select_admin.value)" onBlur="restoreWidth(this, document.forms[0].select_admin.value)" onChange="restoreWidth(this, document.forms[0].select_admin.value)" onClick="setWidth(this, document.forms[0].select_admin.value)" onKeyPress="setWidth(this, document.forms[0].select_admin.value)">
              </select>&#160;<xsl:copy-of select="/cp/strings/user_list_for_2" />
              <input type="submit" name="go" value="{/cp/strings/user_list_btn_go}" />
              <span id="ruler" style="font-size: 10pt; position:absolute; visibility:hidden;"></span>
  
              <script language="javascript">
                var admins = new Object(); <!-- hash of arrays of domains owned by each admin -->
                var domains = new Array(); <!-- all domains -->
                var admins_truncated = new Object(); <!-- hash of arrays of domains (truncated form) owned by each admin -->
                var domains_truncated = new Array(); <!-- all domains (truncated form) -->
                var all_domains_txt = "<xsl:value-of select="/cp/strings/user_list_all_domains" />";
                var selected_domain = "<xsl:value-of select="/cp/form/select_domain" />";
                var rulerSpan = document.getElementById('ruler');
  
                function setWidth( obj, admin ) {
                  obj.style.width = '175px';
                  var domains_array;
                  if (admin == "") {
                    domains_array = domains;
                  } else {
                    domains_array = admins[admin];
                  }
                  var domains_select = document.forms[0].select_domain;
                  for (var i = 0; i &lt; domains_array.length; i++) {
                    domains_select.options[i + 1].text = domains_array[i];
                  }
                }

                function restoreWidth( obj, admin ) {
                  obj.style.width = '175px';
                  var domains_truncated_array;
                  if (admin == "") {
                    domains_truncated_array = domains_truncated;
                  } else {
                    domains_truncated_array = admins_truncated[admin];
                  }
                  var domains_select = document.forms[0].select_domain;
                  for (var i = 0; i &lt; domains_truncated_array.length; i++) {
                    domains_select.options[i + 1].text = domains_truncated_array[i];
                  }
                }

                function add_domain(admin, name, truncated_name) {
                  domains[domains.length] = name;
                  domains_truncated[domains_truncated.length] = truncated_name;
                  if (!admins[admin]) {
                    admins[admin] = new Array();
                  }
                  admins[admin][ admins[admin].length ] = name;
                  if (!admins_truncated[admin]) {
                    admins_truncated[admin] = new Array();
                  }
                  admins_truncated[admin][ admins_truncated[admin].length ] = truncated_name;
                }
  
                function set_domains(admin) {
                  var maxWidth = 0;
                  var domains_select = document.forms[0].select_domain;
                  domains_select.options.length = 0;
  
                  var option = new Option(all_domains_txt, "");
                  domains_select.options[0] = option;
  
                  var domains_array;
                  var domains_truncated_array;
                  if (admin == "") {
                    domains_array = domains;
                    domains_truncated_array = domains_truncated;
                  } else {
                    domains_array = admins[admin];
                    domains_truncated_array = admins_truncated[admin];
                  }
  
                  for (var i = 0; i &lt; domains_array.length; i++) {
                    option = new Option(domains_truncated_array[i], domains_array[i]);
                    option.selected = (domains_array[i] == selected_domain);
                    domains_select.options[i + 1] = option;
                    rulerSpan.innerHTML = domains_array[i];
                    var myWidth = rulerSpan.offsetWidth;
                    if (myWidth > maxWidth) {
                      maxWidth = myWidth;
                    }
                  }
                  if (maxWidth &lt; 150) {
                    maxWidth = 175;
                  }
                  else {
                    maxWidth = maxWidth + 25;  // slop for the down arrow of the select element
                  }
                }
  
                <xsl:for-each select="/cp/vsap/vsap[@type='domain:list']/domain">
                  <xsl:sort select="translate(name, 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')" />
                add_domain("<xsl:value-of select="admin" />", "<xsl:value-of select="name" />",
                           "<xsl:call-template name="truncate">
                                <xsl:with-param name="string" select="name" />
                                <xsl:with-param name="fieldlength" select="28" />
                            </xsl:call-template>");
                </xsl:for-each>
  
                <xsl:choose>
                  <xsl:when test="$user_type='sa'">
                    set_domains(document.forms[0].select_admin.value);
                  </xsl:when>
                  <xsl:otherwise>
                    set_domains("");
                  </xsl:otherwise>
                </xsl:choose>
              </script>
            </xsl:if>

          </td>
        </tr>
        <tr class="controlrow">
          <td colspan="{$colspan}">

            <span class="floatright">
              <xsl:value-of select="/cp/strings/user_list_users" />
              <xsl:value-of select="/cp/vsap/vsap/first_user" />
              <xsl:value-of select="/cp/strings/user_list_dash" />
              <xsl:value-of select="/cp/vsap/vsap/last_user" />
              <xsl:value-of select="/cp/strings/user_list_of" />
              <xsl:value-of select="/cp/vsap/vsap/num_users" />

              <xsl:value-of select="/cp/strings/user_list_bar" />

              <xsl:choose>
                <xsl:when test='/cp/vsap/vsap/page = 1'>
                  <xsl:value-of select="/cp/strings/user_list_first" />
                </xsl:when>
                <xsl:otherwise>
                  <a href="{$base_url}/cp/users/index.xsl?page=1&amp;sort_by={$sort_by}&amp;sort_type={$sort_type}&amp;select_admin={/cp/form/select_admin}&amp;select_domain={/cp/form/select_domain}">
                    <xsl:value-of select="/cp/strings/user_list_first" />
                  </a>
                </xsl:otherwise>
              </xsl:choose>
              <xsl:value-of select="/cp/strings/user_list_bar" />
              <xsl:choose>
                <xsl:when test='string-length(/cp/vsap/vsap/prev_page) > 0'>
                  <a href="{$base_url}/cp/users/index.xsl?page={/cp/vsap/vsap/prev_page}&amp;sort_by={$sort_by}&amp;sort_type={$sort_type}&amp;select_admin={/cp/form/select_admin}&amp;select_domain={/cp/form/select_domain}">
                    <xsl:value-of select="/cp/strings/user_list_prev" />
                  </a>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="/cp/strings/user_list_prev" />
                </xsl:otherwise>
              </xsl:choose>
              <xsl:value-of select="/cp/strings/user_list_bar" />
              <xsl:choose>
                <xsl:when test='string-length(/cp/vsap/vsap/next_page) > 0'>
                  <a href="{$base_url}/cp/users/index.xsl?page={/cp/vsap/vsap/next_page}&amp;sort_by={$sort_by}&amp;sort_type={$sort_type}&amp;select_admin={/cp/form/select_admin}&amp;select_domain={/cp/form/select_domain}">
                    <xsl:value-of select="/cp/strings/user_list_next" />
                  </a>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="/cp/strings/user_list_next" />
                </xsl:otherwise>
              </xsl:choose>
              <xsl:value-of select="/cp/strings/user_list_bar" />
              <xsl:choose>
                <xsl:when test='/cp/vsap/vsap/page = /cp/vsap/vsap/total_pages'>
                  <xsl:value-of select="/cp/strings/user_list_last" />
                </xsl:when>
                <xsl:otherwise>
                  <a href="{$base_url}/cp/users/index.xsl?page={/cp/vsap/vsap/total_pages}&amp;sort_by={$sort_by}&amp;sort_type={$sort_type}&amp;select_admin={/cp/form/select_admin}&amp;select_domain={/cp/form/select_domain}">
                    <xsl:value-of select="/cp/strings/user_list_last" />
                  </a>
                </xsl:otherwise>
              </xsl:choose>
            </span>

            <input type="button" name="deleteBtn" value="{/cp/strings/user_list_btn_delete}" onClick="if (checkUserRemoveThreshold('{cp:js-escape(/cp/strings/cp_msg_users_delete_threshold_exceeded)}', 'login_id')) submitCheck('{cp:js-escape(/cp/strings/msg_nochecks)}', 'login_id', 'delete', 'yes', '{cp:js-escape(/cp/strings/user_list_delete_confirm)}');" />
          </td>
        </tr>
        <tr class="columnhead">
          <td class="ckboxcolumn"><input type="checkbox" name="login_ids" onClick="check(this.form.login_id)" value="" /></td>

          <!-- Login ID -->
          <td class="loginidcolumn">
            <xsl:variable name="loginsorturl"><xsl:value-of select="$basic_sort_url" />sort_by=login_id&amp;sort_type=<xsl:choose>
              <xsl:when test="($sort_by = 'login_id') and ($sort_type = 'ascending')">descending</xsl:when>
              <xsl:otherwise>ascending</xsl:otherwise>
            </xsl:choose></xsl:variable>
            <a href="{$loginsorturl}">
              <xsl:copy-of select="/cp/strings/user_list_login" />
            </a>&#160;<a href="{$loginsorturl}">
              <xsl:if test="$sort_by = 'login_id'">
                <xsl:choose>
                  <xsl:when test="$sort_type = 'ascending'"><img src="{/cp/strings/img_sortarrowdown}" border="0" /></xsl:when>
                  <xsl:when test="$sort_type = 'descending'"><img src="{/cp/strings/img_sortarrowup}" border="0" /></xsl:when>
                </xsl:choose>
              </xsl:if>
            </a>
          </td>

          <!-- Domain -->
          <td class="domaincolumn">
            <xsl:variable name="domainsorturl"><xsl:value-of select="$basic_sort_url" />sort_by=domain&amp;sort_type=<xsl:choose>
              <xsl:when test="($sort_by = 'domain') and ($sort_type = 'ascending')">descending</xsl:when>
              <xsl:otherwise>ascending</xsl:otherwise>
            </xsl:choose></xsl:variable>
            <a href="{$domainsorturl}">
              <xsl:copy-of select="/cp/strings/user_list_domain" />
            </a>&#160;<a href="{$domainsorturl}">
              <xsl:if test="$sort_by = 'domain'">
                <xsl:choose>
                  <xsl:when test="$sort_type = 'ascending'"><img src="{/cp/strings/img_sortarrowdown}" border="0" /></xsl:when>
                  <xsl:when test="$sort_type = 'descending'"><img src="{/cp/strings/img_sortarrowup}" border="0" /></xsl:when>
                </xsl:choose>
              </xsl:if>
            </a>
          </td>

          <!-- User Type -->
          <xsl:if test="$user_type='sa' or $user_type='da'">
            <td class="usertypecolumn">
              <xsl:variable name="usertypesorturl"><xsl:value-of select="$basic_sort_url" />sort_by=usertype&amp;sort_type=<xsl:choose>
                <xsl:when test="($sort_by = 'usertype') and ($sort_type = 'ascending')">descending</xsl:when>
                <xsl:otherwise>ascending</xsl:otherwise>
              </xsl:choose></xsl:variable>
              <a href="{$usertypesorturl}">
                <xsl:copy-of select="/cp/strings/user_list_user_type" />
              </a>&#160;<a href="{$usertypesorturl}">
              <xsl:if test="$sort_by = 'usertype'">
                <xsl:choose>
                  <xsl:when test="$sort_type = 'ascending'"><img src="{/cp/strings/img_sortarrowdown}" border="0" /></xsl:when>
                  <xsl:when test="$sort_type = 'descending'"><img src="{/cp/strings/img_sortarrowup}" border="0" /></xsl:when>
                </xsl:choose>
               </xsl:if>
              </a>
            </td>
          </xsl:if>

          <!-- Status -->
          <td class="statuscolumn">
            <xsl:variable name="statussorturl"><xsl:value-of select="$basic_sort_url" />sort_by=status&amp;sort_type=<xsl:choose>
              <xsl:when test="($sort_by = 'status') and ($sort_type = 'ascending')">descending</xsl:when>
              <xsl:otherwise>ascending</xsl:otherwise>
            </xsl:choose></xsl:variable>
            <a href="{$statussorturl}">
              <xsl:copy-of select="/cp/strings/user_list_status" />
            </a>&#160;<a href="{$statussorturl}">
              <xsl:if test="$sort_by = 'status'">
                <xsl:choose>
                  <xsl:when test="$sort_type = 'ascending'"><img src="{/cp/strings/img_sortarrowdown}" border="0" /></xsl:when>
                  <xsl:when test="$sort_type = 'descending'"><img src="{/cp/strings/img_sortarrowup}" border="0" /></xsl:when>
                </xsl:choose>
              </xsl:if>
            </a>
          </td>

          <!-- Services -->
          <xsl:if test="$user_type='da' or $user_type='ma'">
            <xsl:if test="/cp/vsap/vsap[@type='auth']/services/mail">
              <td class="mailservicecolumn">
                <xsl:copy-of select="/cp/strings/user_list_mail" />
              </td>
            </xsl:if>
          </xsl:if>
          <xsl:if test="$user_type='ma'">
            <xsl:if test="/cp/vsap/vsap[@type='auth']/services/webmail">
              <td class="mailservicecolumn">
                <xsl:copy-of select="/cp/strings/user_list_webmail" />
              </td>
            </xsl:if>
          </xsl:if>
          <xsl:if test="$user_type='da'">
            <xsl:if test="/cp/vsap/vsap[@type='auth']/services/ftp">
              <td class="ftpservicecolumn">
                <xsl:copy-of select="/cp/strings/user_list_ftp" />
              </td>
            </xsl:if>
            <xsl:if test="/cp/vsap/vsap[@type='auth']/services/fileman">
              <td class="ftpservicecolumn">
                <xsl:copy-of select="/cp/strings/user_list_fm" />
              </td>
            </xsl:if>
            <xsl:if test="not(/cp/vsap/vsap[@type='auth']/siteprefs/disable-shell)">
              <xsl:if test="/cp/vsap/vsap[@type='auth']/services/shell">
                <td class="shellservicecolumn">
                  <xsl:copy-of select="/cp/strings/user_list_shell" />
                </td>
              </xsl:if>
            </xsl:if>
          </xsl:if>

          <!-- Limit -->
          <td class="rightalign">
            <xsl:variable name="limitsorturl"><xsl:value-of select="$basic_sort_url" />sort_by=limit&amp;sort_type=<xsl:choose>
              <xsl:when test="($sort_by = 'limit') and ($sort_type = 'ascending')">descending</xsl:when>
              <xsl:otherwise>ascending</xsl:otherwise>
            </xsl:choose></xsl:variable>
            <a href="{$limitsorturl}">
              <xsl:copy-of select="/cp/strings/user_list_limit" />
            </a>&#160;<a href="{$limitsorturl}">
              <xsl:if test="$sort_by = 'limit'">
                <xsl:choose>
                  <xsl:when test="$sort_type = 'ascending'"><img src="{/cp/strings/img_sortarrowdown}" border="0" /></xsl:when>
                  <xsl:when test="$sort_type = 'descending'"><img src="{/cp/strings/img_sortarrowup}" border="0" /></xsl:when>
                </xsl:choose>
              </xsl:if>
            </a>
          </td>
          <!-- Used -->
          <td class="rightalign">
            <xsl:variable name="usedsorturl"><xsl:value-of select="$basic_sort_url" />sort_by=used&amp;sort_type=<xsl:choose>
              <xsl:when test="($sort_by = 'used') and ($sort_type = 'ascending')">descending</xsl:when>
              <xsl:otherwise>ascending</xsl:otherwise>
            </xsl:choose></xsl:variable>
            <a href="{$usedsorturl}">
              <xsl:copy-of select="/cp/strings/user_list_used" />
            </a>&#160;<a href="{$usedsorturl}">
              <xsl:if test="$sort_by = 'used'">
                <xsl:choose>
                  <xsl:when test="$sort_type = 'ascending'"><img src="{/cp/strings/img_sortarrowdown}" border="0" /></xsl:when>
                  <xsl:when test="$sort_type = 'descending'"><img src="{/cp/strings/img_sortarrowup}" border="0" /></xsl:when>
                </xsl:choose>
              </xsl:if>
            </a>
          </td>
          <!-- Actions -->
          <td><xsl:copy-of select="/cp/strings/user_list_actions" /></td>
        </tr>

        <!-- show all the users now -->
        <xsl:apply-templates select="/cp/vsap/vsap[@type='user:list']/user"/>

        <tr class="controlrow">
          <td colspan="{$colspan}">
            <xsl:if test="$eu_add != '0'">
              <input class="floatright" type="submit" name="add_eu" value="{/cp/strings/user_list_btn_add_eu}" />
              <xsl:if test="not(/cp/vsap/vsap[@type='auth']/siteprefs/disable-mail-admin)">
                <xsl:if test="$user_type='sa' or ($user_type='da' and $mail_ok='1')">
                  <input class="floatright" type="submit" name="add_ma" value="{/cp/strings/user_list_btn_add_ma}" />
                </xsl:if>
              </xsl:if>
            </xsl:if>
            <xsl:if test="$user_type='sa'">
              <input class="floatright" type="submit" name="add_da" value="{/cp/strings/user_list_btn_add_da}" />
            </xsl:if>
            <input type="button" name="deleteBtn" value="{/cp/strings/user_list_btn_delete}" onClick="if (checkUserRemoveThreshold('{cp:js-escape(/cp/strings/cp_msg_users_delete_threshold_exceeded)}', 'login_id')) submitCheck('{cp:js-escape(/cp/strings/msg_nochecks)}', 'login_id', 'delete', 'yes', '{cp:js-escape(/cp/strings/user_list_delete_confirm)}');" />
          </td>
        </tr>

      </table>

</xsl:template>

</xsl:stylesheet>
