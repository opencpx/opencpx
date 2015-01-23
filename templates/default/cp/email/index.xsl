<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../cp_global.xsl" />

<xsl:variable name="message">
  <xsl:choose>
    <xsl:when test="/cp/msgs/msg[@name='email_address_exists']">'<xsl:value-of select="/cp/form/lhs" />@<xsl:value-of select="/cp/form/domain" />'<xsl:value-of select="/cp/strings/email_add_already_exists" /></xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='email_add_successful']">'<xsl:copy-of select="/cp/form/lhs" />@<xsl:copy-of select="/cp/form/domain" />'<xsl:copy-of select="/cp/strings/cp_msg_email_add" /></xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='email_add_failure']">'<xsl:value-of select="/cp/form/lhs" />@<xsl:value-of select="/cp/form/domain" />'<xsl:value-of select="/cp/strings/cp_msg_email_add_failure" /></xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='email_edit_failure']">'<xsl:value-of select="/cp/form/lhs" />@<xsl:value-of select="/cp/form/domain" />'<xsl:value-of select="/cp/strings/cp_msg_email_edit_failure" /></xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='email_edit_successful']">'<xsl:value-of select="/cp/form/lhs" />@<xsl:value-of select="/cp/form/domain" />'<xsl:value-of select="/cp/strings/cp_msg_email_edit" /></xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='email_delete_failure']">'<xsl:value-of select="/cp/form/address" />' <xsl:value-of select="/cp/strings/cp_msg_email_delete_failure" /></xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='email_delete_successful']">'<xsl:value-of select="/cp/form/address" />' <xsl:value-of select="/cp/strings/cp_msg_email_delete" /></xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='email_delete_failure_multi']"><xsl:value-of select="/cp/strings/cp_msg_email_delete_multi_failure" /></xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='email_delete_successful_multi']"><xsl:value-of select="/cp/strings/cp_msg_email_delete_multi" /></xsl:when>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="feedback">
  <xsl:if test="$message != ''">
    <xsl:call-template name="feedback_table">
      <xsl:with-param name="image">
        <xsl:choose>
          <xsl:when test="/cp/vsap/vsap[@type='error']">error</xsl:when>
          <xsl:when test="/cp/msgs/msg[@name='email_delete_failure']">error</xsl:when>
          <xsl:when test="/cp/msgs/msg[@name='email_delete_failure_multi']">error</xsl:when>
          <xsl:when test="/cp/msgs/msg[@name='email_address_exists']">error</xsl:when>
          <xsl:otherwise>success</xsl:otherwise>
        </xsl:choose>
     </xsl:with-param>
     <xsl:with-param name="message">
       <xsl:value-of select="$message" />
     </xsl:with-param>
   </xsl:call-template>
 </xsl:if>
</xsl:variable>

<xsl:variable name="sort_by">
  <xsl:choose>
    <xsl:when test="string(/cp/form/sort_by)"><xsl:value-of select="/cp/form/sort_by" /></xsl:when>
    <xsl:otherwise>address</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="sort_type">
  <xsl:choose>
    <xsl:when test="string(/cp/form/sort_type)"><xsl:value-of select="/cp/form/sort_type" /></xsl:when>
    <xsl:otherwise>ascending</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="select_domain">
  <xsl:choose>
    <xsl:when test="count(/cp/vsap/vsap[@type='domain:list']/domain) = 1">
      <xsl:value-of select="/cp/vsap/vsap[@type='domain:list']/domain/name" />
    </xsl:when>
    <xsl:when test="string(/cp/form/select_domain)">
      <xsl:value-of select="/cp/form/select_domain" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="show_system">
  <xsl:choose>
    <xsl:when test="/cp/form/show_system='on' or /cp/form/show_system='1'">1</xsl:when>
    <xsl:otherwise>0</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="basic_sort_url"><xsl:value-of select="$base_url" />/cp/email/index.xsl?select_domain=<xsl:if test="string(/cp/form/select_domain)">
  <xsl:value-of select="/cp/form/select_domain" />
  </xsl:if>&amp;</xsl:variable>

<xsl:template match="/cp/vsap/vsap[@type='mail:addresses:list']/address">

  <xsl:variable name="row_id">row<xsl:value-of select="position()"/></xsl:variable>

  <xsl:variable name="row_style">
    <xsl:choose>
      <xsl:when test="position() mod 2 = 1">rowodd</xsl:when>
      <xsl:otherwise>roweven</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:choose>
    <xsl:when test="system and $show_system='0'">
    </xsl:when>
    <xsl:otherwise>
      <tr class="{$row_style}">
        <xsl:choose>
          <xsl:when test="system">
          <td><br /></td>
          </xsl:when>
          <xsl:otherwise>
            <td><input type="checkbox" id="{$row_id}" name="address" value="{source}" /></td>
          </xsl:otherwise>
        </xsl:choose>
        <td>
          <label for="{$row_id}">
            <xsl:call-template name="truncate">
              <xsl:with-param name="string" select="source" />
              <xsl:with-param name="fieldlength" select="/cp/strings/cp_emailaddresscolumn_length" />
            </xsl:call-template>
          </label>
        </td>
        <td>
          <xsl:choose>
            <xsl:when test="dest/@type = 'delete'">
              <xsl:value-of select="/cp/strings/email_addresses_delete" />
            </xsl:when>
            <xsl:when test="dest/@type = 'reject' or substring(dest,2,8) = '|exit 67'">
              <xsl:value-of select="/cp/strings/email_addresses_bounce" />
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="/cp/strings/email_addresses_deliver_to" />
            </xsl:otherwise>
          </xsl:choose>
        </td>
        <td>
        <!-- <xsl:for-each select="delivery/address"> -->
          <xsl:choose>
            <xsl:when test="dest/@type='delete' or dest/@type='reject' or substring(dest,2,8) = '|exit 67'">
              <xsl:value-of select="/cp/strings/email_addresses_none" />
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="truncate">
                <xsl:with-param name="string"><xsl:value-of select="dest" /></xsl:with-param>
                <xsl:with-param name="fieldlength"><xsl:copy-of select="/cp/strings/email_addresses_destination_length" /></xsl:with-param>
              </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>
          <!--  <xsl:if test="position() != last()">, </xsl:if>
                </xsl:for-each> -->
        </td>
        <td class="actions">
          <a href="{$base_url}/cp/email/add-edit.xsl?action=edit&amp;address={url_source}&amp;select_domain={$select_domain}&amp;show_system={$show_system}&amp;sort_by={$sort_by}&amp;sort_type={$sort_type}"><xsl:value-of select="/cp/strings/email_addresses_editaction" /></a>
          <xsl:value-of select="/cp/strings/email_addresses_bar" />
          <xsl:choose>
            <xsl:when test="system">
              <xsl:value-of select="/cp/strings/email_addresses_deleteaction" />
            </xsl:when>
            <xsl:otherwise>
              <a href="{$base_url}/cp/email/index.xsl?Delete=yes&amp;address={url_source}&amp;select_domain={$select_domain}&amp;show_system={$show_system}&amp;sort_by={$sort_by}&amp;sort_type={$sort_type}" onClick="return confirm('{cp:js-escape(/cp/strings/cp_msg_email_js_confirm_one)}')"><xsl:value-of select="/cp/strings/email_addresses_deleteaction" /></a>
            </xsl:otherwise>
          </xsl:choose>
        </td>
      </tr>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="/">
  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title"><xsl:value-of select="/cp/strings/cp_title" /> : <xsl:value-of select="/cp/strings/bc_email_addresses" /></xsl:with-param>
    <xsl:with-param name="formaction"><xsl:value-of select="$base_url" />/cp/email/index.xsl</xsl:with-param>
    <xsl:with-param name="feedback" select="$feedback" />
    <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_email_addresses" />
    <xsl:with-param name="help_short" select="/cp/strings/email_addresses_hlp_short" />
    <xsl:with-param name="help_long" select="/cp/strings/email_addresses_hlp_long" />
    <xsl:with-param name="breadcrumb">
      <breadcrumb>
        <section>
          <name><xsl:value-of select="/cp/strings/bc_email_addresses" /></name>
          <url>#</url>
          <image>EmailAddresses</image>
        </section>
      </breadcrumb>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

      <script src="{concat($base_url, '/cp/cp.js')}" language="JavaScript"></script>
      <input type="hidden" name="sort_by" value="{$sort_by}" />
      <input type="hidden" name="sort_type" value="{$sort_type}" />
      <input type="hidden" name="Delete" value="" />
      <input type="hidden" name="show_system_save" value="{$show_system}" /> 
      <input type="hidden" name="select_domain_save" value="{/cp/form/select_domain}" />

      <xsl:call-template name="cp_titlenavbar">
        <xsl:with-param name="active_tab">email</xsl:with-param>
      </xsl:call-template>

      <table class="listview" border="0" cellspacing="0" cellpadding="0">
        <tr class="instructionrow">
          <td colspan="5">
            <span class="floatrightfix">
              <xsl:value-of select="/cp/strings/email_addresses_addresses" />
              <xsl:value-of select="count(/cp/vsap/vsap[@type='mail:addresses:list']/address[not(system)])" />
              <xsl:if test="string($select_domain)">
                <xsl:value-of select="/cp/strings/email_addresses_of" />
                <xsl:variable name="emails_used">
                  <xsl:value-of select="/cp/vsap/vsap[@type='domain:list']/domain[name=$select_domain]/mail_aliases/limit" />
                </xsl:variable>
                <xsl:choose>
                  <xsl:when test="$emails_used = 'unlimited'">
                    <xsl:value-of select="/cp/strings/email_addresses_unlimited" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="$emails_used" />
                  </xsl:otherwise>
                </xsl:choose>
                <xsl:value-of select="/cp/strings/email_addresses_used" />
              </xsl:if>
            </span>
            <xsl:if test="$user_type != 'ma'">
              <xsl:value-of select="/cp/strings/email_addresses_display_email" />
              <select name="select_domain" size="1">
                <xsl:if test="count(/cp/vsap/vsap[@type='domain:list']/domain) > 1">
                  <option value=""><xsl:value-of select="/cp/strings/email_addresses_all_domains" /></option>
                </xsl:if>
                <xsl:for-each select="/cp/vsap/vsap[@type='domain:list']/domain">
                  <xsl:sort select="translate(name, 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')" />
                  <option value="{name}">
                    <xsl:if test="name = /cp/form/select_domain">
                      <xsl:attribute name="selected">true</xsl:attribute>
                    </xsl:if>
                    <xsl:call-template name="truncate">
                      <xsl:with-param name="string" select="name" />
                      <xsl:with-param name="fieldlength" select="/cp/strings/cp_domain_dropdown_length" />
                    </xsl:call-template>
                  </option>
                </xsl:for-each>
              </select>&#160;<input type="submit" name="Go" value="{/cp/strings/email_addresses_btn_go}" />&#160;&#160;
            </xsl:if>

            <input type="checkbox" id="show_system" name="show_system" value="{$show_system}" onClick="switchSystemDisplay();" >
            <xsl:if test="$show_system='1'">
              <xsl:attribute name="checked">checked</xsl:attribute>
            </xsl:if>
            </input>
            <label for="show_system"><xsl:value-of select="/cp/strings/email_addresses_show_default" /></label>
          </td>
        </tr>
        <tr class="controlrow">
          <td colspan="5">
            <xsl:if test="$email_add != '0'">
              <input class="floatright" type="submit" name="AddEmail" value="{/cp/strings/email_addresses_btn_add}" />
            </xsl:if>
            <input type="button" name="btnDelete" value="{/cp/strings/email_addresses_btn_delete}" onClick="submitCheck('{cp:js-escape(/cp/strings/msg_nochecks)}','address','Delete','yes','{cp:js-escape(/cp/strings/cp_msg_email_js_confirm_multi)}');" />
          </td>
        </tr>
        <tr class="columnhead">
          <td class="ckboxcolumn">
            <input type="checkbox" name="addresses" onClick="check(this.form.address)" value="" />
          </td>
          <!-- Address -->
          <td class="emailaddresscolumn">
            <xsl:variable name="addresssorturl"><xsl:value-of select="$basic_sort_url" />show_system=<xsl:value-of select="$show_system" />&amp;sort_by=address&amp;sort_type=<xsl:choose>
              <xsl:when test="($sort_by = 'address') and ($sort_type = 'ascending')">descending</xsl:when>
              <xsl:otherwise>ascending</xsl:otherwise>
            </xsl:choose></xsl:variable>
            <a href="{$addresssorturl}">
              <xsl:value-of select="/cp/strings/email_addresses_address" />
            </a>&#160;<a href="{$addresssorturl}">
              <xsl:if test="$sort_by = 'address'">
                <xsl:choose>
                  <xsl:when test="$sort_type = 'ascending'"><img src="{/cp/strings/img_sortarrowdown}" border="0" /></xsl:when>
                  <xsl:when test="$sort_type = 'descending'"><img src="{/cp/strings/img_sortarrowup}" border="0" /></xsl:when>
                </xsl:choose>
              </xsl:if>
            </a>
          </td>
          <!-- Delivery -->
          <td class="maildeliverycolumn">
            <xsl:variable name="deliverysorturl"><xsl:value-of select="$basic_sort_url" />show_system=<xsl:value-of select="$show_system" />&amp;sort_by=delivery&amp;sort_type=<xsl:choose>
              <xsl:when test="($sort_by = 'delivery') and ($sort_type = 'ascending')">descending</xsl:when>
              <xsl:otherwise>ascending</xsl:otherwise>
            </xsl:choose></xsl:variable>
            <a href="{$deliverysorturl}">
              <xsl:value-of select="/cp/strings/email_addresses_delivery" />
            </a>&#160;<a href="{$deliverysorturl}">
              <xsl:if test="$sort_by = 'delivery'">
                <xsl:choose>
                  <xsl:when test="$sort_type = 'ascending'"><img src="{/cp/strings/img_sortarrowdown}" border="0" /></xsl:when>
                  <xsl:when test="$sort_type = 'descending'"><img src="{/cp/strings/img_sortarrowup}" border="0" /></xsl:when>
                </xsl:choose>
              </xsl:if>
            </a>
          </td>
          <!-- Destination -->
          <td class="destinationcolumn">
            <xsl:value-of select="/cp/strings/email_addresses_destination" />
          </td>
          <!-- Actions -->
          <td>
            <xsl:value-of select="/cp/strings/email_addresses_actions" />
          </td>
        </tr>

        <xsl:choose>
          <xsl:when test="$sort_by = 'address'">
            <xsl:apply-templates select="/cp/vsap/vsap[@type='mail:addresses:list']/address">
<!-- REMOVED. This will become a preference someday -->
<!--              <xsl:sort select="translate(source_domain, 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')" order="{$sort_type}" /> -->
              <xsl:sort select="translate(source, 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')" order="{$sort_type}" />
            </xsl:apply-templates>
          </xsl:when>
          <xsl:when test="$sort_by = 'delivery'">
            <xsl:apply-templates select="/cp/vsap/vsap[@type='mail:addresses:list']/address">
              <xsl:sort select="translate(dest/@type,'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')" order="{$sort_type}" />
              <xsl:sort select="translate(source_domain, 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')" order="{$sort_type}" />
              <xsl:sort select="translate(source, 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')" order="{$sort_type}" />
            </xsl:apply-templates>
          </xsl:when>
        </xsl:choose>

        <tr class="controlrow">
          <td colspan="5">
            <xsl:if test="$email_add != '0'">
              <input class="floatright" type="submit" name="AddEmail" value="{/cp/strings/email_addresses_btn_add}" />
            </xsl:if>
            <input type="button" name="btnDelete" value="{/cp/strings/email_addresses_btn_delete}" onClick="submitCheck('{cp:js-escape(/cp/strings/msg_nochecks)}','address','Delete','yes','{cp:js-escape(/cp/strings/cp_msg_email_js_confirm_multi)}');" />
          </td>
        </tr>
      </table>

</xsl:template>

</xsl:stylesheet>
