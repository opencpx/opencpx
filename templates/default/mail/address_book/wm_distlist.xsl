<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
  xmlns:exslt="http://exslt.org/common"
  exclude-result-prefixes="exslt">
<xsl:import href="../mail_global.xsl" />
<xsl:import href="mail_addressbook_feedback.xsl" />

<xsl:variable name="status">
  <xsl:call-template name="status_message" />
</xsl:variable>

<xsl:variable name="status_image">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='error']">error</xsl:when>
    <xsl:otherwise>success</xsl:otherwise>
  </xsl:choose> 
</xsl:variable>

<xsl:variable name="message">
  <xsl:if test="string($status)">
    <xsl:call-template name="feedback_table">
      <xsl:with-param name="image"><xsl:value-of select="$status_image" /></xsl:with-param>
      <xsl:with-param name="message"><xsl:copy-of select="$status" /> </xsl:with-param>
    </xsl:call-template>
  </xsl:if>
</xsl:variable>

<xsl:variable name="edit">
  <xsl:choose>
    <xsl:when test="string(cp/form/edit)">1</xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="listid">
  <xsl:choose>
    <xsl:when test="string(cp/form/listid)"><xsl:value-of select="/cp/form/listid" /></xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="listAddrs">
  <xsl:choose>
    <xsl:when test="string(/cp/vsap/vsap[@type='webmail:distlist:list']/distlist/addresses)">
      <xsl:copy-of select="/cp/vsap/vsap[@type='webmail:distlist:list']/distlist/addresses/address" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="listname">
  <xsl:choose>
    <xsl:when test="string(/cp/form/txtListName) and (not(string(/cp/form/save_another)) or count(/cp/vsap/vsap[@type='error']))">
      <xsl:value-of select = "/cp/form/txtListName" />
    </xsl:when>
    <xsl:when test="string(/cp/vsap/vsap[@type='webmail:distlist:list']/distlist/name)">
      <xsl:value-of select="/cp/vsap/vsap[@type='webmail:distlist:list']/distlist/name" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="nickname">
  <xsl:choose>
    <xsl:when test="string(/cp/form/txtNickname) and (not(string(/cp/form/save_another)) or count(/cp/vsap/vsap[@type='error']))">
      <xsl:value-of select = "/cp/form/txtNickname" />
    </xsl:when>
    <xsl:when test="string(/cp/vsap/vsap[@type='webmail:distlist:list']/distlist/nickname)">
      <xsl:value-of select="/cp/vsap/vsap[@type='webmail:distlist:list']/distlist/nickname" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="description">
  <xsl:choose>
    <xsl:when test="string(/cp/form/comment) and (not(string(/cp/form/save_another)) or count(/cp/vsap/vsap[@type='error']))">
      <xsl:value-of select = "/cp/form/comment" />
    </xsl:when>
    <xsl:when test="string(/cp/vsap/vsap[@type='webmail:distlist:list']/distlist/description)">
      <xsl:value-of select="/cp/vsap/vsap[@type='webmail:distlist:list']/distlist/description" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="ids">
  <xsl:choose>
    <xsl:when test="string(/cp/form/save_another) and not(string(/cp/vsap/vsap[@type='error']))"></xsl:when>
     <xsl:otherwise><xsl:value-of select="/cp/form/ids" /></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="tmp_selected_addresses">
  <xsl:choose>
    <xsl:when test="string($ids)">
      <xsl:variable name="tmp_ids">
        <xsl:call-template name="extract_csv_list">
          <xsl:with-param name="list" select="$ids" />
        </xsl:call-template>
      </xsl:variable>
      <xsl:variable name="all_ids" select="exslt:node-set($tmp_ids)" />
      <entries>
      <xsl:for-each select="$all_ids/address">
        <xsl:variable name="email">
          <xsl:value-of select="substring-before(.,'|')" />
        </xsl:variable>
        <xsl:variable name="rest">
          <xsl:value-of select="substring-after(.,'|')" />
        </xsl:variable>
        <xsl:variable name="first">
          <xsl:value-of select="substring-before($rest,'|')" />
        </xsl:variable>
        <xsl:variable name="last">
          <xsl:value-of select="substring-after($rest,'|')" />
        </xsl:variable>
        <entry>
          <first><xsl:value-of select="$first" /></first>
          <last><xsl:value-of select="$last" /></last>
          <address><xsl:value-of select="$email" /></address>
        </entry>
      </xsl:for-each>
      </entries>
    </xsl:when>
    <xsl:when test="string(/cp/vsap/vsap[@type='webmail:distlist:list']/distlist/entries/entry)">
      <entries>
      <xsl:for-each select="/cp/vsap/vsap[@type='webmail:distlist:list']/distlist/entries/entry">
        <entry>
          <first><xsl:value-of select="first" /></first>
          <last><xsl:value-of select="last" /></last>
          <address><xsl:value-of select="address" /></address>
        </entry>
      </xsl:for-each>
      </entries>
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="sel_addrs" select="exslt:node-set($tmp_selected_addresses)" />

<xsl:variable name="subtitle">
  <xsl:choose>
    <xsl:when test="$edit='1'">
      <xsl:copy-of select="/cp/strings/bc_edit_list" /> : <xsl:value-of select="/cp/vsap/vsap[@type='webmail:distlist:list']/distlist/name" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:copy-of select="/cp/strings/bc_add_list" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:template match="/">
  <script src="{$base_url}/mail/address_book/address_book.js" language="JavaScript"></script>
  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title">
      <xsl:copy-of select="/cp/strings/wm_title" /> : <xsl:copy-of select="/cp/strings/nv_menu_addressbook" /> : <xsl:copy-of select="$subtitle" />
    </xsl:with-param>
    <xsl:with-param name="formaction">wm_distlist.xsl</xsl:with-param>
    <xsl:with-param name="feedback" select="$message" />
    <xsl:with-param name="selected_navandcontent">
      <xsl:choose>
        <xsl:when test="$edit = '1'">
          <xsl:value-of select="/cp/strings/nv_addresses" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="/cp/strings/nv_add_list" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:with-param>
    <xsl:with-param name="onload">initializeSelect()</xsl:with-param>
    <xsl:with-param name="help_short" select="/cp/strings/wm_distlist_hlp_short" />
    <xsl:with-param name="help_long" select="/cp/strings/wm_distlist_hlp_long" />
    <xsl:with-param name="breadcrumb">
      <breadcrumb>
        <xsl:choose>
          <xsl:when test="$edit='1'">
            <section>
              <name><xsl:copy-of select="/cp/strings/bc_addresses" /></name>
              <url><xsl:value-of select="$base_url" />/mail/address_book/wm_addresses.xsl</url>
            </section>
            <section>
              <name><xsl:copy-of select="/cp/strings/bc_edit_list" /></name>
              <url>#</url>
              <image>AddressBook</image>
            </section>
          </xsl:when>
          <xsl:otherwise>
            <section>
              <name><xsl:copy-of select="/cp/strings/bc_add_list" /></name>
              <url>#</url>
              <image>AddressBook</image>
            </section>
          </xsl:otherwise>
        </xsl:choose>
      </breadcrumb>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">
      <input type="hidden" name="ids" value="" />
      <input type="hidden" name="edit" value="{$edit}" />
      <input type="hidden" name="listid" value="{$listid}" />
      <input type="hidden" name="save_group" />
      <input type="hidden" name="save_another" />
      <table class="formview" border="0" cellspacing="0" cellpadding="0">
        <tr class="title">
          <td colspan="2">
            <xsl:choose>
              <xsl:when test="$edit = '1'">
                <xsl:copy-of select="/cp/strings/wm_distlist_edit_title" />
              </xsl:when>
              <xsl:otherwise>
                <xsl:copy-of select="/cp/strings/wm_distlist_title" />
              </xsl:otherwise>
            </xsl:choose>
          </td>
        </tr>
        <tr class="instructionrow">
          <td colspan="2">
            <xsl:choose>
              <xsl:when test="$edit = '1'">
                <xsl:copy-of select="/cp/strings/wm_distlist_edit_instruction1" />
              </xsl:when>
              <xsl:otherwise>
                <xsl:copy-of select="/cp/strings/wm_distlist_instruction1" />
              </xsl:otherwise>
            </xsl:choose>
            <br/>
            <xsl:value-of select="/cp/strings/wm_distlist_instruction2" /></td>
        </tr>
        <tr class="controlrow">
          <td colspan="2">
            <span class="floatright">
              <input type="submit" name="save" value="{/cp/strings/wm_distlist_bt_save}" onClick="return verifyAddGroup('save','{cp:js-escape(/cp/strings/wm_distlist_alertDataMissingMsg)}');return false;" />
              <xsl:if test="$edit != '1'">
                <input type="button" name="another" value="{/cp/strings/wm_distlist_bt_savecreate}" onClick="verifyAddGroup('another','{cp:js-escape(/cp/strings/wm_distlist_alertDataMissingMsg)}');" />
              </xsl:if>
              <input type="submit" name="cancel" value="{/cp/strings/wm_distlist_bt_cancel}" />
            </span>
          </td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:value-of select="/cp/strings/wm_distlist_listname" /></td>
          <td class="contentwidth"><input type="text" name="txtListName" size="60" value="{$listname}" /></td>
        </tr>
        <tr class="roweven">
          <td class="label"><xsl:value-of select="/cp/strings/wm_distlist_nickname" /></td>
          <td class="contentwidth"><input type="text" name="txtNickname" size="60" value="{$nickname}" /></td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:value-of select="/cp/strings/wm_distlist_listmembers" /></td>
          <td class="contentwidth">
            <table class="genericstructure" width="180" border="0" cellspacing="0" cellpadding="0">
              <tr>
                <td colspan="3"><input type="text" name="txtSearch" size="24" /><input type="button" name="search" value="{/cp/strings/wm_distlist_bt_search}" onClick="searchEmailAddressbook(this.form.address_notselected,txtSearch,'{cp:js-escape(/cp/strings/wm_distlist_no_search_specified_errmsg)}');" /><input type="button" name="viewall" value="{/cp/strings/wm_distlist_bt_reset}" onClick="restoreViewAll(this.form.address_notselected);" /></td>
              </tr>
              <tr>
                <td><select name="address_notselected" size="15" class="distlist" multiple="multiple">
                  <xsl:for-each select="/cp/vsap/vsap[@type='webmail:addressbook:load']/vCardSet/vCard">
                    <xsl:sort select="Email_Address" />
                    <xsl:variable name="optionvalue">
                      <xsl:value-of select="concat(Email_Address,'|',First_Name,'|',Last_Name)" />
                    </xsl:variable>
                    <option value="{$optionvalue}">
                      <xsl:variable name="format_name">
                        <xsl:value-of select="concat(First_Name,' ',Last_Name)" />
                      </xsl:variable>
                      <xsl:value-of select="Email_Address" />
                    </option>
                  </xsl:for-each>
                </select></td>
                <td><input type="button" name="add" value="{/cp/strings/wm_distlist_bt_addaddr}" onClick="addToList(this.form.address_notselected,this.form.address_selected);" /><br />
                  <input type="button" name="remove" value="{/cp/strings/wm_distlist_bt_deleteaddr}" onClick="removeFromList(this.form.address_selected);" /></td>
                <td><select name="address_selected" size="15" class="distlist" multiple="multiple">
                  <xsl:for-each select="$sel_addrs/entries/entry">
                    <xsl:sort select="address" />
                    <xsl:variable name="optionvalue_sel" >
                      <xsl:value-of select="concat(address,'|',first,'|',last)" />
                    </xsl:variable>
                    <option value="{$optionvalue_sel}">
                      <xsl:variable name="format_sel_name">
                        <xsl:value-of select="concat(first,' ',last)" />
                      </xsl:variable>
                      <xsl:value-of select="address" />
                    </option>
                  </xsl:for-each>
                </select></td>
              </tr>
            </table>
          </td>
        </tr>
        <tr class="roweven">
          <td class="label"><xsl:value-of select="/cp/strings/wm_distlist_description" /></td>
          <td class="contentwidth"><textarea name="comment" rows="5" cols="45"><xsl:value-of select="$description" /></textarea></td>
        </tr>
        <tr class="controlrow">
          <td colspan="2">
            <span class="floatright">
              <input type="submit" name="save" value="{/cp/strings/wm_distlist_bt_save}" onClick="return verifyAddGroup('save','{cp:js-escape(/cp/strings/wm_distlist_alertDataMissingMsg)}');return false;" />
              <xsl:if test="$edit != '1'">
                <input type="button" name="another" value="{/cp/strings/wm_distlist_bt_savecreate}" onClick="verifyAddGroup('another','{cp:js-escape(/cp/strings/wm_distlist_alertDataMissingMsg)}');" />
              </xsl:if>
              <input type="submit" name="cancel" value="{/cp/strings/wm_distlist_bt_cancel}" />
            </span>
          </td>
        </tr>
      </table>

</xsl:template>
</xsl:stylesheet>

