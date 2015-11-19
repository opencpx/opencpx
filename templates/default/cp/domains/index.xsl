<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../cp_global.xsl" />

<xsl:variable name="message">
  <xsl:choose>
    <xsl:when test="/cp/msgs/msg[@name='domain_add_successful']">
      '<xsl:copy-of select="/cp/form/domain" />'<xsl:copy-of select="/cp/strings/cp_msg_domain_add" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='domain_delete_successful']">
      '<xsl:copy-of select="/cp/form/domain" />'<xsl:copy-of select="/cp/strings/cp_msg_domain_delete" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='domain_delete_failure']">
      '<xsl:copy-of select="/cp/form/domain" />'<xsl:copy-of select="/cp/strings/cp_msg_domain_delete_failure" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='domain_multi_delete_successful']">
      <xsl:copy-of select="/cp/strings/cp_msg_domain_delete_multi" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='domain_multi_delete_failure']">
      <xsl:copy-of select="/cp/strings/cp_msg_domain_delete_multi_failure" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='domain_enable_successful']">
      '<xsl:copy-of select="/cp/form/domain" />'<xsl:copy-of select="/cp/strings/cp_msg_domain_enable" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='domain_enable_failure']">
      '<xsl:copy-of select="/cp/form/domain" />'<xsl:copy-of select="/cp/strings/cp_msg_domain_enable_failure" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='domain_disable_successful']">
      '<xsl:copy-of select="/cp/form/domain" />'<xsl:copy-of select="/cp/strings/cp_msg_domain_disable" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='domain_disable_failure']">
      '<xsl:copy-of select="/cp/form/domain" />'<xsl:copy-of select="/cp/strings/cp_msg_domain_disable_failure" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='domain_self_signed_cert_success']">
      <xsl:copy-of select="/cp/strings/domain_self_signed_cert_success" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='domain_self_signed_cert_permission_denied']">
      <xsl:copy-of select="/cp/strings/domain_self_signed_cert_permission_denied" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='domain_self_signed_cert_domain_missing']">
      <xsl:copy-of select="/cp/strings/domain_self_signed_cert_domain_missing" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='domain_self_signed_cert_openssl_failed']">
      <xsl:copy-of select="/cp/strings/domain_self_signed_cert_openssl_failed" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='domain_self_signed_cert_unknown_error']">
      <xsl:copy-of select="/cp/strings/domain_self_signed_cert_unknown_error" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='domain_cert_success']">
      <xsl:copy-of select="/cp/strings/domain_cert_success" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='domain_cert_permission_denied']">
      <xsl:copy-of select="/cp/strings/domain_cert_permission_denied" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='domain_cert_missing']">
      <xsl:copy-of select="/cp/strings/domain_cert_missing" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='domain_cert_openssl_failed']">
      <xsl:copy-of select="/cp/strings/domain_cert_openssl_failed" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='domain_cert_unknown_error']">
      <xsl:copy-of select="/cp/strings/domain_cert_unknown_error" />
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

<xsl:variable name="show_usage">
  <xsl:choose>
    <xsl:when test="/cp/form/show_usage='1'">1</xsl:when>
    <xsl:otherwise>0</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="sort_by">
  <xsl:choose>
    <xsl:when test="(/cp/vsap/vsap[@type='domain:paged_list']/sortby = 'usage') and ($show_usage='0')">admin</xsl:when>
    <xsl:otherwise><xsl:value-of select="/cp/vsap/vsap[@type='domain:paged_list']/sortby" /></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="sort_type"><xsl:value-of select="/cp/vsap/vsap[@type='domain:paged_list']/order" /></xsl:variable>

<xsl:variable name="selected_user">
  <!-- login id of selected user (current logged in user by default) -->
  <xsl:choose>
    <xsl:when test="string(/cp/form/select_admin)"><xsl:value-of select="/cp/form/select_admin" /></xsl:when>
    <xsl:otherwise><xsl:value-of select="/cp/vsap/vsap[@type='auth']/username" /></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="basic_sort_url">index.xsl?select_admin=<xsl:if test="string(/cp/form/select_admin)">
  <xsl:value-of select="/cp/form/select_admin" />
  </xsl:if>&amp;</xsl:variable>

<xsl:template match="/cp/vsap/vsap[@type='domain:paged_list']/domain">

  <xsl:variable name="row_id">row<xsl:value-of select="position()"/></xsl:variable>

  <xsl:variable name="row_style">
    <xsl:choose>
      <xsl:when test="position() mod 2 = 1">rowodd</xsl:when>
      <xsl:otherwise>roweven</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <tr class="{$row_style}">
    <xsl:choose>
      <xsl:when test="(
                        ($user_type != 'sa')
                        or (users/usage != 0)
                        or (@type = 'server') 
                        or (name = /cp/request/hostname)
                      )">
        <!-- NOTE: Domains can only be deleted if: the sa is doing the deleting;
                   the domain is not the current domain used to access the cp;
                   the domain is not the server domain; and the domain doesn't
                   have any end users -->
        <td><br /></td>
      </xsl:when>
      <xsl:otherwise>
        <td><input type="checkbox" id="{$row_id}" name="domain" value="{name}" /></td>
      </xsl:otherwise>
    </xsl:choose>

    <td>
      <a href="http://{name}" target="_blank">
      <xsl:call-template name="truncate">
        <xsl:with-param name="string" select="name" />
        <xsl:with-param name="fieldlength" select="/cp/strings/domain_list_domain_length" />
      </xsl:call-template>
      </a>
    </td>
    <td>
      <xsl:value-of select="admin" />
    </td>
    <td>
      <xsl:choose>
        <xsl:when test="disabled = '0'">
          <xsl:value-of select="/cp/strings/domain_list_status_enabled" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="/cp/strings/domain_list_status_disabled" />
        </xsl:otherwise>
      </xsl:choose>
    </td>
    <td>
      <xsl:choose>
        <xsl:when test="users/limit = 'unlimited'">
          <a href="../users/index.xsl?select_admin={admin}&amp;select_domain={name}"><xsl:value-of select="users/usage" /></a>
        </xsl:when>
        <xsl:otherwise>
          <a href="../users/index.xsl?select_admin={admin}&amp;select_domain={name}">
            <xsl:value-of select="users/usage" />
            <xsl:value-of select="/cp/strings/domain_list_users_of" />
            <xsl:value-of select="users/limit" />
          </a>
        </xsl:otherwise>
      </xsl:choose>
    </td>
    <td>
      <xsl:choose>
        <xsl:when test="mail_aliases/limit = 'unlimited'">
          <a href="../email/index.xsl?select_domain={name}"><xsl:value-of select="mail_aliases/usage" /></a>
        </xsl:when>
        <xsl:otherwise>
          <a href="../email/index.xsl?select_domain={name}">
            <xsl:value-of select="mail_aliases/usage" />
            <xsl:value-of select="/cp/strings/domain_list_users_of" />
            <xsl:value-of select="mail_aliases/limit" />
          </a>
        </xsl:otherwise>
      </xsl:choose>
    </td>
    <xsl:if test="$show_usage='1'">
      <td class="rightalign">
        <xsl:value-of select="format-number(diskspace/usage, '###.#')" />&#160;
        <xsl:choose>
          <xsl:when test="diskspace/units = 'GB'">
            <xsl:value-of select="/cp/strings/gb" />
          </xsl:when>
          <xsl:when test="diskspace/units = 'MB'">
            <xsl:value-of select="/cp/strings/mb" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="/cp/strings/kb" />
          </xsl:otherwise>
        </xsl:choose>
      </td>
    </xsl:if>
    <td class="actions"><xsl:if test="$show_usage='0'"><xsl:attribute name="colspan">2</xsl:attribute></xsl:if>

      <xsl:choose>
        <xsl:when test="@type = 'server'">
          <xsl:value-of select="/cp/strings/domain_list_properties" />
        </xsl:when>
        <xsl:otherwise>
          <a href="domain_properties.xsl?domain={name}"><xsl:value-of select="/cp/strings/domain_list_properties" /></a>
        </xsl:otherwise>
      </xsl:choose>

      <xsl:if test="$user_type = 'sa'">
        <xsl:value-of select="/cp/strings/domain_list_bar" />
        <xsl:choose>
          <xsl:when test="(@type = 'server') or (name = /cp/request/hostname)">
            <xsl:value-of select="/cp/strings/domain_list_disable" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:choose>
              <xsl:when test="disabled='0'">
                <a href="index.xsl?domain={name}&amp;action=disable" onClick="return confirm('{cp:js-escape(/cp/strings/domain_properties_js_verify_disable)}');return false;">
                  <xsl:value-of select="/cp/strings/domain_list_disable" />
                </a>
              </xsl:when>
              <xsl:otherwise>
                <a href="index.xsl?domain={name}&amp;action=enable" >
                  <xsl:value-of select="/cp/strings/domain_list_enable" />
                </a>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:if>

      <xsl:if test="$user_type = 'sa'">
        <xsl:value-of select="/cp/strings/domain_list_bar" />
        <xsl:choose>
          <xsl:when test="( 
                            (users/usage != 0)
                            or (@type = 'server')
                            or (name = /cp/request/hostname)
                          )">
            <xsl:value-of select="/cp/strings/domain_list_delete" />
          </xsl:when>
          <xsl:otherwise>
            <a href="index.xsl?domain={name}&amp;action=delete" onClick="return confirm('{cp:js-escape(/cp/strings/domain_properties_js_action_verify_delete)}');return false;" ><xsl:value-of select="/cp/strings/domain_list_delete" /></a>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:if>
    </td>
  </tr>
</xsl:template>

<xsl:template match="/">
  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title">
      <xsl:value-of select="/cp/strings/cp_title" />
      v<xsl:value-of select="/cp/vsap/vsap[@type='auth']/version" /> :
      <xsl:value-of select="/cp/strings/bc_domain_list" />
    </xsl:with-param>
    <xsl:with-param name="formaction">index.xsl</xsl:with-param>
    <xsl:with-param name="feedback" select="$feedback" />
    <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_domain_list" />
    <xsl:with-param name="help_short" select="/cp/strings/domain_list_hlp_short" />
    <xsl:with-param name="help_long">
      <xsl:choose>
        <xsl:when test="$user_type = 'sa'">
          <xsl:value-of select="/cp/strings/domain_list_hlp_long_sa" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="/cp/strings/domain_list_hlp_long_da" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:with-param>
    <xsl:with-param name="breadcrumb">
      <breadcrumb>
        <section>
          <name><xsl:value-of select="/cp/strings/bc_domain_list" /></name>
          <url>#</url>
          <image>DomainManagement</image>
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
        <xsl:with-param name="active_tab">domains</xsl:with-param>
      </xsl:call-template>

      <table class="listview" border="0" cellspacing="0" cellpadding="0">
        <tr class="instructionrow">
          <td colspan="8">
            <span class="floatrightfix">
              <xsl:call-template name="print_quota">
                <!-- Show quota for current user (sa or da) or for selected da -->
                <xsl:with-param name="quota" select="/cp/vsap/vsap[@type='user:properties']/user[login_id=$selected_user]/quota" />
              </xsl:call-template>
            </span>
            <xsl:choose>
              <xsl:when test="$user_type = 'sa'">
                <xsl:value-of select="/cp/strings/domain_list_display_domains" />
                <select name="select_admin" size="1">
                  <option value=""><xsl:value-of select="/cp/strings/domain_list_all_admins" /></option>
                  <xsl:choose>
                    <xsl:when test="/cp/vsap/vsap[@type='auth']/platform = 'linux'">
                      <option value="apache"><xsl:value-of select="/cp/strings/domain_list_primary_admin" /> (apache)</option>
                    </xsl:when>
                    <xsl:otherwise>
                      <option value="www"><xsl:value-of select="/cp/strings/domain_list_primary_admin" /> (www)</option>
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
                </select>&#160;<input type="submit" name="go" value="{/cp/strings/domain_list_btn_go}" />
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="/cp/strings/domain_list_da_title" />
              </xsl:otherwise>
            </xsl:choose>

            <input class="indent" id="show_usage" type="checkbox" name="show_usage" value="{$show_usage}" onClick="switchUsageDisplay();" >
            <xsl:if test="$show_usage='1'">
              <xsl:attribute name="checked">checked</xsl:attribute>
            </xsl:if>
            </input>
            <label for="show_usage"><xsl:value-of select="/cp/strings/domain_list_show_usage" /></label>
          </td>
        </tr>
        <xsl:if test="$user_type = 'sa' or $user_type = 'da'">
          <tr class="controlrow">
            <td colspan="8">

            <span class="floatright">
              <xsl:value-of select="/cp/strings/domain_list_domains" />
              <xsl:value-of select="/cp/vsap/vsap/first_domain" />
              <xsl:value-of select="/cp/strings/domain_list_dash" />
              <xsl:value-of select="/cp/vsap/vsap/last_domain" />
              <xsl:value-of select="/cp/strings/domain_list_of" />
              <xsl:value-of select="/cp/vsap/vsap/num_domains" />

              <xsl:value-of select="/cp/strings/domain_list_bar" />

              <xsl:choose>
                <xsl:when test='/cp/vsap/vsap/page = 1'>
                  <xsl:value-of select="/cp/strings/domain_list_first" />
                </xsl:when>
                <xsl:otherwise>
                  <a href="{$base_url}/cp/domains/index.xsl?page=1&amp;sort_by={$sort_by}&amp;sort_type={$sort_type}&amp;select_admin={/cp/form/select_admin}">
                    <xsl:value-of select="/cp/strings/domain_list_first" />
                  </a>
                </xsl:otherwise>
              </xsl:choose>

              <xsl:value-of select="/cp/strings/domain_list_bar" />
              <xsl:choose>
                <xsl:when test='string-length(/cp/vsap/vsap/prev_page) > 0'>
                  <a href="{$base_url}/cp/domains/index.xsl?page={/cp/vsap/vsap/prev_page}&amp;sort_by={$sort_by}&amp;sort_type={$sort_type}&amp;select_admin={/cp/form/select_admin}">
                    <xsl:value-of select="/cp/strings/domain_list_prev" />
                  </a>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="/cp/strings/domain_list_prev" />
                </xsl:otherwise>
              </xsl:choose>
              <xsl:value-of select="/cp/strings/domain_list_bar" />
              <xsl:choose>
                <xsl:when test='string-length(/cp/vsap/vsap/next_page) > 0'>
                  <a href="{$base_url}/cp/domains/index.xsl?page={/cp/vsap/vsap/next_page}&amp;sort_by={$sort_by}&amp;sort_type={$sort_type}&amp;select_admin={/cp/form/select_admin}">
                    <xsl:value-of select="/cp/strings/domain_list_next" />
                  </a>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="/cp/strings/domain_list_next" />
                </xsl:otherwise>
              </xsl:choose>
              <xsl:value-of select="/cp/strings/domain_list_bar" />
              <xsl:choose>
                <xsl:when test='/cp/vsap/vsap/page = /cp/vsap/vsap/total_pages'>
                  <xsl:value-of select="/cp/strings/domain_list_last" />
                </xsl:when>
                <xsl:otherwise>
                  <a href="{$base_url}/cp/domains/index.xsl?page={/cp/vsap/vsap/total_pages}&amp;sort_by={$sort_by}&amp;sort_type={$sort_type}&amp;select_admin={/cp/form/select_admin}">
                    <xsl:value-of select="/cp/strings/domain_list_last" />
                  </a>
                </xsl:otherwise>
              </xsl:choose>
              <!-- <input class="floatright" type="submit" name="add_domain" value="{/cp/strings/domain_list_btn_add}" /> -->
              </span>

              <xsl:if test="$user_type = 'sa'">
                <input type="button" name="deleteBtn" value="{/cp/strings/domain_list_btn_delete}" onClick="submitCheck('{cp:js-escape(/cp/strings/domain_properties_js_button_verify_delete_null)}','domain', 'delete', 'yes', '{cp:js-escape(/cp/strings/domain_properties_js_button_verify_delete)}');" />
              </xsl:if>
            </td>
          </tr>
        </xsl:if>
        <tr class="columnhead">
          <xsl:choose>
            <xsl:when test="$user_type = 'sa'">
              <td class="ckboxcolumn"><input type="checkbox" name="domains" onClick="check(this.form.domain)" value="" /></td>
            </xsl:when>
            <xsl:otherwise>
              <td><br /></td>
            </xsl:otherwise>
          </xsl:choose>

          <!-- Name -->
          <td class="domaincolumn">
            <xsl:variable name="domainsorturl"><xsl:value-of select="$basic_sort_url" />show_usage=<xsl:value-of select="$show_usage" />&amp;sort_by=name&amp;sort_type=<xsl:choose>
              <xsl:when test="($sort_by = 'name') and ($sort_type = 'ascending')">descending</xsl:when>
              <xsl:otherwise>ascending</xsl:otherwise>
            </xsl:choose></xsl:variable>
            <a href="{$domainsorturl}">
              <xsl:value-of select="/cp/strings/domain_list_domain" />
            </a>&#160;<a href="{$domainsorturl}">
              <xsl:if test="$sort_by = 'name'">
                <xsl:choose>
                  <xsl:when test="$sort_type = 'ascending'"><img src="{/cp/strings/img_sortarrowdown}" border="0" /></xsl:when>
                  <xsl:when test="$sort_type = 'descending'"><img src="{/cp/strings/img_sortarrowup}" border="0" /></xsl:when>
                </xsl:choose>
              </xsl:if>
            </a>
          </td>
          <!-- Admin -->
          <td class="loginidcolumn">
            <xsl:variable name="adminsorturl"><xsl:value-of select="$basic_sort_url" />show_usage=<xsl:value-of select="$show_usage" />&amp;sort_by=admin&amp;sort_type=<xsl:choose>
              <xsl:when test="($sort_by = 'admin') and ($sort_type = 'ascending')">descending</xsl:when>
              <xsl:otherwise>ascending</xsl:otherwise>
            </xsl:choose></xsl:variable>
            <a href="{$adminsorturl}">
              <xsl:value-of select="/cp/strings/domain_list_admin" />
            </a>&#160;<a href="{$adminsorturl}">
              <xsl:if test="$sort_by = 'admin'">
                <xsl:choose>
                  <xsl:when test="$sort_type = 'ascending'"><img src="{/cp/strings/img_sortarrowdown}" border="0" /></xsl:when>
                  <xsl:when test="$sort_type = 'descending'"><img src="{/cp/strings/img_sortarrowup}" border="0" /></xsl:when>
                </xsl:choose>
              </xsl:if>
            </a>
          </td>
          <!-- Status -->
          <td class="statuscolumn">
            <xsl:variable name="statussorturl"><xsl:value-of select="$basic_sort_url" />show_usage=<xsl:value-of select="$show_usage" />&amp;sort_by=status&amp;sort_type=<xsl:choose>
              <xsl:when test="($sort_by = 'status') and ($sort_type = 'ascending')">descending</xsl:when>
              <xsl:otherwise>ascending</xsl:otherwise>
            </xsl:choose></xsl:variable>
            <a href="{$statussorturl}">
              <xsl:value-of select="/cp/strings/domain_list_status" />
            </a>&#160;<a href="{$statussorturl}">
              <xsl:if test="$sort_by = 'status'">
                <xsl:choose>
                  <xsl:when test="$sort_type = 'ascending'"><img src="{/cp/strings/img_sortarrowdown}" border="0" /></xsl:when>
                  <xsl:when test="$sort_type = 'descending'"><img src="{/cp/strings/img_sortarrowup}" border="0" /></xsl:when>
                </xsl:choose>
              </xsl:if>
            </a>
          </td>
          <!-- Users -->
          <td class="maxuserscolumn"><xsl:value-of select="/cp/strings/domain_list_users" /></td>
          <!-- Addresses -->
          <td class="maxaddressescolumn"><xsl:value-of select="/cp/strings/domain_list_addresses" /></td>
          <xsl:if test="$show_usage='1'">
            <!-- Usage -->
            <td class="usedcolumn">
              <xsl:variable name="usedsorturl"><xsl:value-of select="$basic_sort_url" />show_usage=<xsl:value-of select="$show_usage" />&amp;sort_by=usage&amp;sort_type=<xsl:choose>
                <xsl:when test="($sort_by = 'usage') and ($sort_type = 'ascending')">descending</xsl:when>
                <xsl:otherwise>ascending</xsl:otherwise>
              </xsl:choose></xsl:variable>
              <a href="{$usedsorturl}">
                <xsl:value-of select="/cp/strings/domain_list_usage" />
              </a>&#160;<a href="{$usedsorturl}">
                <xsl:if test="$sort_by = 'usage'">
                  <xsl:choose>
                    <xsl:when test="$sort_type = 'ascending'"><img src="{/cp/strings/img_sortarrowdown}" border="0" /></xsl:when>
                    <xsl:when test="$sort_type = 'descending'"><img src="{/cp/strings/img_sortarrowup}" border="0" /></xsl:when>
                  </xsl:choose>
                </xsl:if>
              </a>
            </td>
          </xsl:if>
          <!-- Actions -->
          <td><xsl:if test="$show_usage='0'"><xsl:attribute name="colspan">2</xsl:attribute></xsl:if><xsl:value-of select="/cp/strings/domain_list_actions" /></td>
        </tr>

        <!-- show all the domains now -->
        <xsl:apply-templates select="/cp/vsap/vsap[@type='domain:paged_list']/domain"/>

        <xsl:if test="$user_type = 'sa'">
          <tr class="controlrow">
            <td colspan="8">
              <input class="floatright" type="submit" name="add_domain" value="{/cp/strings/domain_list_btn_add}" />
              <input type="button" name="deleteBtn" value="{/cp/strings/domain_list_btn_delete}" onClick="submitCheck('{cp:js-escape(/cp/strings/domain_properties_js_button_verify_delete_null)}','domain', 'delete', 'yes', '{cp:js-escape(/cp/strings/domain_properties_js_button_verify_delete)}');" />
            </td>
          </tr>
        </xsl:if>
      </table>

</xsl:template>

</xsl:stylesheet>
