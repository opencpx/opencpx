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

<xsl:variable name="goback">mail/address_book/wm_addresses.xsl</xsl:variable>

<xsl:variable name="first">
  <xsl:choose>
    <xsl:when test="cp/vsap/vsap[@type='error']">
      <xsl:value-of select="/cp/form/txtFirst" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="last">
  <xsl:choose>
    <xsl:when test="cp/vsap/vsap[@type='error']">
      <xsl:value-of select="/cp/form/txtLast" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="email">
  <xsl:choose>
    <xsl:when test="cp/vsap/vsap[@type='error']">
      <xsl:value-of select="/cp/form/txtEmail" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="sort_by">
  <xsl:choose>
    <xsl:when test="string(/cp/form/sort_by)"><xsl:value-of select="/cp/form/sort_by" /></xsl:when>
    <xsl:otherwise>
      <xsl:choose>
        <xsl:when test="(/cp/request/locale='ja') or (/cp/request/local='ja_JP')">lastname</xsl:when>
        <xsl:otherwise>firstname</xsl:otherwise>
      </xsl:choose>
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="sort_type">
  <xsl:choose>
    <xsl:when test="string(/cp/form/sort_type)"><xsl:value-of select="/cp/form/sort_type" /></xsl:when>
     <xsl:when test="/cp/vsap/vsap[@type='webmail:options:fetch']/webmail_options/addresses_order!= ''">
       <xsl:value-of select="/cp/vsap/vsap[@type='webmail:options:fetch']/webmail_options/addresses_order" />
     </xsl:when>
    <xsl:otherwise>ascending</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="addressList">
  <xsl:call-template name="mergeAddressLists" />
</xsl:variable>
<xsl:variable name="allAddresses" select="exslt:node-set($addressList)" />

<xsl:template name="mergeAddressLists">
  <masterAddrList>
  <!-- grab all of the contact entries -->
  <xsl:for-each select="/cp/vsap/vsap[@type='webmail:addressbook:load']/vCardSet/vCard">
    <xsl:variable name="sort_last_name">
      <xsl:value-of select="translate(Last_Name, 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')" />
    </xsl:variable>
    <xsl:variable name="sort_first_name">
      <xsl:value-of select="translate(First_Name, 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')" />
    </xsl:variable>
    <xsl:variable name="sort_nickname">
      <xsl:value-of select="translate(Nickname, 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')" />
    </xsl:variable>
    <xsl:variable name="sort_emailaddress">
      <xsl:value-of select="translate(Email_Address, 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')" />
    </xsl:variable>
    <xsl:variable name="fullname">
      <xsl:choose>
        <xsl:when test="$sort_by='lastname'">
          <xsl:choose>
            <xsl:when test="string-length(Last_Name)>0">
              <xsl:choose>
                <xsl:when test="string-length(First_Name)>0">
                  <xsl:choose>
                    <xsl:when test="(/cp/request/locale='ja') or (/cp/request/local='ja_JP')">
                      <xsl:value-of select="concat(Last_Name,' ',First_Name)" />
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="concat(Last_Name,', ',First_Name)" />
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="Last_Name" />
                </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
           <xsl:otherwise>
              <xsl:choose>
                <xsl:when test="string-length(First_Name)>0">
                  <xsl:value-of select="First_Name" />
                </xsl:when>
                <xsl:otherwise></xsl:otherwise>
              </xsl:choose>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
          <xsl:choose>
            <xsl:when test="string-length(First_Name)>0">
              <xsl:choose>
                <xsl:when test="string-length(Last_Name)>0">
                  <xsl:choose>
                    <xsl:when test="(/cp/request/locale='ja') or (/cp/request/local='ja_JP')">
                      <xsl:value-of select="concat(First_Name,', ',Last_Name)" />
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:value-of select="concat(First_Name,' ',Last_Name)" />
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="First_Name" />
                </xsl:otherwise>
              </xsl:choose>
            </xsl:when>
           <xsl:otherwise>
              <xsl:choose>
                <xsl:when test="string-length(Last_Name)>0">
                  <xsl:value-of select="Last_Name" />
                </xsl:when>
                <xsl:otherwise></xsl:otherwise>
              </xsl:choose>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <addrRef>
      <type>individual</type>
      <uid><xsl:value-of select="@uid" /></uid>
      <last_name><xsl:value-of select="Last_Name" /></last_name>
      <sort_last_name><xsl:value-of select="$sort_last_name" /></sort_last_name>
      <first_name><xsl:value-of select="First_Name" /></first_name>
      <sort_first_name><xsl:value-of select="$sort_first_name" /></sort_first_name>
      <fullname><xsl:value-of select="$fullname" /></fullname>
      <truncated_fullname>
        <xsl:call-template name="truncate">
          <xsl:with-param name="string"><xsl:value-of select="$fullname" /></xsl:with-param>
          <xsl:with-param name="fieldlength"><xsl:value-of select="/cp/strings/wm_addresses_firstlast_fieldlength" /></xsl:with-param>
        </xsl:call-template>
      </truncated_fullname>
      <personal>
        <xsl:choose>
          <xsl:when test="First_Name != '' and Last_Name != ''">
            <xsl:value-of select="concat(First_Name,' ',Last_Name)" />
          </xsl:when>
          <xsl:when test="First_Name != '' and Last_Name = ''">
            <xsl:value-of select="First_Name" />
          </xsl:when>
          <xsl:when test="First_Name = '' and Last_Name != ''">
            <xsl:value-of select="Last_Name" />
          </xsl:when>
          <xsl:otherwise></xsl:otherwise>
        </xsl:choose>
      </personal>
      <nickname><xsl:value-of select="Nickname" /></nickname>
      <truncated_nickname>
        <xsl:call-template name="truncate">
          <xsl:with-param name="string"><xsl:value-of select="Nickname" /></xsl:with-param>
          <xsl:with-param name="fieldlength"><xsl:value-of select="/cp/strings/wm_addresses_nickname_fieldlength" /></xsl:with-param>
        </xsl:call-template>
      </truncated_nickname>
      <sort_nickname><xsl:value-of select="$sort_nickname" /></sort_nickname>
      <emailaddress><xsl:value-of select="Email_Address" /></emailaddress>
      <truncated_emailaddress>
        <xsl:call-template name="truncate">
          <xsl:with-param name="string"><xsl:value-of select="Email_Address" /></xsl:with-param>
          <xsl:with-param name="fieldlength"><xsl:value-of select="/cp/strings/wm_addresses_email_fieldlength" /></xsl:with-param>
        </xsl:call-template>
      </truncated_emailaddress>
      <sort_emailaddress><xsl:value-of select="$sort_emailaddress" /></sort_emailaddress>
      <listid></listid>
    </addrRef>
  </xsl:for-each>

  <!-- grab all of the group list entries -->
  <xsl:for-each select="/cp/vsap/vsap[@type='webmail:distlist:list']/distlist">
    <xsl:variable name="sort_last_name">
      <xsl:value-of select="translate(name, 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')" />
    </xsl:variable>
    <xsl:variable name="sort_first_name">
      <xsl:value-of select="translate(name, 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')" />
    </xsl:variable>
    <xsl:variable name="sort_nickname">
      <xsl:value-of select="translate(nickname, 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')" />
    </xsl:variable>
    <xsl:variable name="emailaddresses">
         <xsl:choose>
           <xsl:when test="string(entries/entry[2]/address)">
             <xsl:value-of select="concat(entries/entry[1]/address,',',entries/entry[2]/address)" />
           </xsl:when>
           <xsl:when test="string(entries/entry[1]/address)">
             <xsl:value-of select="entries/entry[1]/address" />
           </xsl:when>
           <xsl:otherwise></xsl:otherwise>
         </xsl:choose>
    </xsl:variable>
    <xsl:variable name="sort_emailaddress">
      <xsl:value-of select="translate($emailaddresses, 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')" />
    </xsl:variable>
    <addrRef>
      <type>group</type>
      <last_name><xsl:value-of select="name" /></last_name>
      <sort_last_name><xsl:value-of select="$sort_last_name" /></sort_last_name>
      <first_name><xsl:value-of select="name" /></first_name>
      <sort_first_name><xsl:value-of select="$sort_first_name" /></sort_first_name>
      <fullname><xsl:value-of select="name" /></fullname>
      <truncated_fullname>
        <xsl:call-template name="truncate">
          <xsl:with-param name="string"><xsl:value-of select="name" /></xsl:with-param>
          <xsl:with-param name="fieldlength"><xsl:value-of select="/cp/strings/wm_addresses_firstlast_fieldlength" /></xsl:with-param>
        </xsl:call-template>
      </truncated_fullname>
      <personal></personal>
      <nickname><xsl:value-of select="nickname" /></nickname>
      <truncated_nickname>
        <xsl:call-template name="truncate">
          <xsl:with-param name="string"><xsl:value-of select="nickname" /></xsl:with-param>
          <xsl:with-param name="fieldlength"><xsl:value-of select="/cp/strings/wm_addresses_nickname_fieldlength" /></xsl:with-param>
        </xsl:call-template>
      </truncated_nickname>
      <sort_nickname><xsl:value-of select="$sort_nickname" /></sort_nickname>
      <emailaddress>
        <xsl:choose>
          <xsl:when test="string(entries/entry[2]/address)">
            <xsl:value-of select="concat(entries/entry[1]/address,', ',entries/entry[2]/address)" />
          </xsl:when>
          <xsl:when test="string(entries/entry[1]/address)">
            <xsl:value-of select="entries/entry[1]/address" />
          </xsl:when>
          <xsl:otherwise></xsl:otherwise>
        </xsl:choose>
      </emailaddress>
      <truncated_emailaddress>
        <xsl:call-template name="truncate">
          <xsl:with-param name="string">
            <xsl:choose>
              <xsl:when test="string(entries/entry[2]/address)">
                <xsl:value-of select="concat(entries/entry[1]/address,', ',entries/entry[2]/address)" />
              </xsl:when>
              <xsl:when test="string(entries/entry[1]/address)">
                <xsl:value-of select="entries/entry[1]/address" />
              </xsl:when>
              <xsl:otherwise></xsl:otherwise>
            </xsl:choose>
          </xsl:with-param>
          <xsl:with-param name="fieldlength"><xsl:value-of select="/cp/strings/wm_addresses_email_fieldlength" /></xsl:with-param>
        </xsl:call-template>
      </truncated_emailaddress>
      <sort_emailaddress><xsl:value-of select="$sort_emailaddress" /></sort_emailaddress>
      <listid><xsl:value-of select="listid" /></listid>
    </addrRef>
  </xsl:for-each>
  </masterAddrList>
</xsl:template>

<xsl:template name="displayAddresses">
  <xsl:variable name="img_individual"><xsl:value-of select="/cp/strings/wm_img_individual" /></xsl:variable>
  <xsl:variable name="img_group"><xsl:value-of select="/cp/strings/wm_img_group" /></xsl:variable>
  <xsl:variable name="edit"><xsl:value-of select="/cp/strings/wm_addresses_edit" /></xsl:variable>
  <xsl:variable name="compose"><xsl:value-of select="/cp/strings/wm_addresses_compose" /></xsl:variable>
  <xsl:for-each select="$allAddresses/masterAddrList/addrRef">
    <xsl:sort select="sort_first_name[$sort_by='firstname'] |
                      sort_last_name[$sort_by='lastname'] |
                      sort_nickname[$sort_by='nickname'] |
                      sort_emailaddress[$sort_by='emailaddress']"
               order="{$sort_type}"
               data-type="text" />
    <xsl:variable name="row_id">row<xsl:value-of select="position()"/></xsl:variable>
    <xsl:variable name="type_image">
      <xsl:choose>
        <xsl:when test="type='individual'">
          <xsl:value-of select="$img_individual" />
        </xsl:when>
        <xsl:when test="type='group'">
          <xsl:value-of select="$img_group" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$img_individual" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="name"><xsl:value-of select="fullname" /></xsl:variable>
    <xsl:variable name="nickname"><xsl:value-of select="nickname" /></xsl:variable>
    <xsl:variable name="emailaddress"><xsl:value-of select="emailaddress" /></xsl:variable>
    <xsl:variable name="truncated_name"><xsl:value-of select="truncated_fullname" /></xsl:variable>
    <xsl:variable name="truncated_nickname"><xsl:value-of select="truncated_nickname" /></xsl:variable>
    <xsl:variable name="truncated_emailaddress"><xsl:value-of select="truncated_emailaddress" /></xsl:variable>
    <xsl:variable name="uid"><xsl:value-of select="uid" /></xsl:variable>
    <xsl:variable name="listid"><xsl:value-of select="listid" /></xsl:variable>
    <xsl:variable name="boxvalue">
      <xsl:choose>
        <xsl:when test="type='individual'"><xsl:value-of select="concat('ind|',$uid)" /></xsl:when>
        <xsl:otherwise><xsl:value-of select="concat('group|',$listid)" /></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="row_style">
      <xsl:choose>
        <xsl:when test="position() mod 2 = 1">roweven</xsl:when>
        <xsl:otherwise>rowodd</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <tr class="{$row_style}">
      <td><input type="checkbox" id="{$row_id}" name="cbUserID" value="{$boxvalue}" /></td>
      <td><label for="{$row_id}"><img src="{$type_image}" alt="" height="16" width="16" border="0" /></label></td>
      <td width="20%"><label for="{$row_id}"><xsl:value-of select="$truncated_name" /></label><br /></td>
      <td width="20%"><label for="{$row_id}"><xsl:value-of select="$truncated_nickname" /></label><br /></td>
      <td width="20%"><label for="{$row_id}"><xsl:value-of select="$truncated_emailaddress" /></label></td>
      <xsl:variable name="edit_ref">
        <xsl:choose>
          <xsl:when test="type = 'group'">mail/address_book/wm_distlist.xsl</xsl:when>
          <xsl:otherwise>mail/address_book/wm_addcontact.xsl</xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:variable name="url_opt_type">
        <xsl:choose>
          <xsl:when test="type = 'group'">listid</xsl:when>
          <xsl:otherwise>to</xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <xsl:variable name="edit_id">
        <xsl:choose>
          <xsl:when test="type = 'group'"><xsl:value-of select="$listid" /></xsl:when>
          <xsl:otherwise><xsl:value-of select="$uid" /></xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:variable name="compose_id">
        <xsl:choose>
          <xsl:when test="type = 'group'">
            <xsl:value-of select="$edit_id" />
          </xsl:when>
          <xsl:when test="personal!=''">
            <xsl:value-of select="concat('&quot;',personal,'&quot;',' ','&lt;',emailaddress,'&gt;')" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="emailaddress" />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <td class="actions"><a href="{$base_url}/{$edit_ref}?{$url_opt_type}={$edit_id}&amp;edit=1"><xsl:value-of select="$edit" /></a> | <a href="{concat($base_url,'/mail/wm_compose.xsl')}?{$url_opt_type}={$compose_id}&amp;goback={$goback}"><xsl:value-of select="$compose" /></a></td>
    </tr>
  </xsl:for-each>
</xsl:template>

<xsl:template match="/">
  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title">
      <xsl:copy-of select="/cp/strings/wm_title" /> : <xsl:copy-of select="/cp/strings/nv_menu_addressbook" /> : <xsl:copy-of select="/cp/strings/bc_addresses" />
    </xsl:with-param>
    <xsl:with-param name="formaction">wm_addresses.xsl</xsl:with-param>
    <xsl:with-param name="feedback"><xsl:copy-of select="$message" /></xsl:with-param>
    <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_addresses" />
    <xsl:with-param name="onload"><xsl:if test="string(/cp/form/export)">location = '<xsl:value-of select="concat($base_url, '/mail/address_book/wm_addresses.xsl/DOWNLOAD/addressbook_export.', /cp/form/export_format ,'?path=/.cpx_tmp/addressbook_export.', /cp/form/export_format )" />';</xsl:if></xsl:with-param>
    <xsl:with-param name="help_short" select="/cp/strings/wm_addresses_hlp_short" />
    <xsl:with-param name="help_long" select="/cp/strings/wm_addresses_hlp_long" />
    <xsl:with-param name="breadcrumb">
      <breadcrumb>
        <section>
          <name><xsl:copy-of select="/cp/strings/bc_addresses" /></name>
          <url>#</url>
          <image>AddressBook</image>
        </section>
      </breadcrumb>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

    <script src="{concat($base_url, '/mail/address_book/address_book.js')}" language="JavaScript"></script>
    <input type="hidden" name="impexp" />
    <input type="hidden" name="addcontact" />
    <input type="hidden" name="addlist" />
    <input type="hidden" name="save_quickadd" />

    <table class="listview" border="0" cellspacing="0" cellpadding="0">
      <tr class="title">
        <td colspan="6"><xsl:value-of select="/cp/strings/wm_addresses_title" /></td>
      </tr>
      <tr class="controlrow">
        <td colspan="6">
          <span class="floatright">
            <input type="button" name="impexp_btn" value="{/cp/strings/wm_addresses_bt_impexp}" onClick="if(document.forms[0].impexp.value='yes') document.forms[0].submit();" />
            <input type="button" name="addcontact_btn" value="{/cp/strings/wm_addresses_bt_addcontact}" onClick="if(document.forms[0].addcontact.value='yes') document.forms[0].submit();" />
            <input type="button" name="addlist_btn" value="{/cp/strings/wm_addresses_bt_addlist}" onClick="if(document.forms[0].addlist.value='yes') document.forms[0].submit();" />
          </span>
          <input type="button" name="delete" value="{/cp/strings/wm_addresses_bt_delete}" onClick="submitCheck('{cp:js-escape(/cp/strings/msg_nochecks)}', 'cbUserID', 'delete', '', '{cp:js-escape(/cp/strings/msg_confirm_delete)}');" />
        </td>
      </tr>
      <tr class="columnhead">
        <td class="ckboxcolumn"><input type="checkbox" name="cbSelectAll" value="" onClick="check(this.form.cbUserID);" /></td>
        <td class="imagecolumn"><br />
        </td>
          <xsl:variable name="firstnamesorturl"><xsl:value-of select="$base_url" />/mail/address_book/wm_addresses.xsl?sort_by=firstname&amp;sort_type=<xsl:choose>
            <xsl:when test="($sort_by='firstname') and ($sort_type='ascending')">descending</xsl:when>
            <xsl:otherwise>ascending</xsl:otherwise>
          </xsl:choose></xsl:variable>
          <xsl:variable name="lastnamesorturl"><xsl:value-of select="$base_url" />/mail/address_book/wm_addresses.xsl?sort_by=lastname&amp;sort_type=<xsl:choose>
            <xsl:when test="($sort_by='lastname') and ($sort_type='ascending')">descending</xsl:when>
            <xsl:otherwise>ascending</xsl:otherwise>
          </xsl:choose></xsl:variable>

        <td class="namecolumn">
          <xsl:choose>
            <xsl:when test="$sort_by='firstname'">
              <a href="{$firstnamesorturl}">
                <xsl:value-of select="/cp/strings/wm_addresses_first" />
              </a>&#160;
              <a href="{$firstnamesorturl}">
                <xsl:choose>
                  <xsl:when test="$sort_type='ascending'">
                    <img src="{/cp/strings/img_sortarrowdown}" alt="" height="15" width="15" border="0" />
                  </xsl:when>
                  <xsl:otherwise>
                    <img src="{/cp/strings/img_sortarrowup}" alt="" height="15" width="15" border="0" />
                  </xsl:otherwise>
                </xsl:choose>
              </a>&#160;
              <a href="{$lastnamesorturl}">
                <xsl:value-of select="/cp/strings/wm_addresses_last" />
              </a>
            </xsl:when>
            <xsl:when test="$sort_by='lastname'">
              <a href="{$lastnamesorturl}">
                <xsl:value-of select="/cp/strings/wm_addresses_last" />
              </a>&#160;
              <a href="{$lastnamesorturl}">
                <xsl:choose>
                  <xsl:when test="$sort_type='ascending'">
                    <img src="{/cp/strings/img_sortarrowdown}" alt="" height="15" width="15" border="0" />
                  </xsl:when>
                  <xsl:otherwise>
                    <img src="{/cp/strings/img_sortarrowup}" alt="" height="15" width="15" border="0" />
                  </xsl:otherwise>
                </xsl:choose>
              </a>&#160;
              <a href="{$firstnamesorturl}">
                <xsl:value-of select="/cp/strings/wm_addresses_first" />
              </a>
            </xsl:when>
            <xsl:otherwise>
              <a href="{$firstnamesorturl}">
                <xsl:value-of select="/cp/strings/wm_addresses_first" />
              </a>&#160;
              <a href="{$lastnamesorturl}">
                <xsl:value-of select="/cp/strings/wm_addresses_last" />
              </a>
            </xsl:otherwise>
          </xsl:choose>
        </td>

        <xsl:variable name="nicknamesorturl"><xsl:value-of select="$base_url" />/mail/address_book/wm_addresses.xsl?sort_by=nickname&amp;sort_type=<xsl:choose>
          <xsl:when test="($sort_by='nickname') and ($sort_type='ascending')">descending</xsl:when>
          <xsl:otherwise>ascending</xsl:otherwise>
        </xsl:choose></xsl:variable>

        <td class="nicknamecolumn"><a href="{$nicknamesorturl}"><xsl:value-of select="/cp/strings/wm_addresses_nickname" /><xsl:if test="$sort_by='nickname'"><xsl:choose><xsl:when test="$sort_type='ascending'"><img src="{/cp/strings/img_sortarrowdown}" alt="" height="15" width="15" border="0" /></xsl:when><xsl:otherwise><img src="{/cp/strings/img_sortarrowup}" alt="" height="15" width="15" border="0" /></xsl:otherwise></xsl:choose></xsl:if></a></td>

          <xsl:variable name="emailsorturl"><xsl:value-of select="$base_url" />/mail/address_book/wm_addresses.xsl?sort_by=emailaddress&amp;sort_type=<xsl:choose>
            <xsl:when test="($sort_by='emailaddress') and ($sort_type='ascending')">descending</xsl:when>
            <xsl:otherwise>ascending</xsl:otherwise>
          </xsl:choose></xsl:variable>

        <td class="emailaddresscolumn" ><a href="{$emailsorturl}"><xsl:value-of select="/cp/strings/wm_addresses_emailaddress" /><xsl:if test="$sort_by='emailaddress'"><xsl:choose><xsl:when test="$sort_type='ascending'"><img src="{/cp/strings/img_sortarrowdown}" alt="" height="15" width="15" border="0" /></xsl:when><xsl:otherwise><img src="{/cp/strings/img_sortarrowup}" alt="" height="15" width="15" border="0" /></xsl:otherwise></xsl:choose></xsl:if></a></td>

        <td><xsl:value-of select="/cp/strings/wm_addresses_actions" /></td>
      </tr>
      <xsl:call-template name="displayAddresses" />

      <tr class="controlrow">
        <td colspan="6">
          <span class="floatright">
            <input type="button" name="impexp_btn" value="{/cp/strings/wm_addresses_bt_impexp}" onClick="if(document.forms[0].impexp.value='yes') document.forms[0].submit();" />
            <input type="button" name="addcontact_btn" value="{/cp/strings/wm_addresses_bt_addcontact}" onClick="if(document.forms[0].addcontact.value='yes') document.forms[0].submit();" />
            <input type="button" name="addlist_btn" value="{/cp/strings/wm_addresses_bt_addlist}" onClick="if(document.forms[0].addlist.value='yes') document.forms[0].submit();" />
          </span>
          <input type="button" name="delete" value="{/cp/strings/wm_addresses_bt_delete}" onClick="submitCheck('{cp:js-escape(/cp/strings/msg_nochecks)}', 'cbUserID', 'delete', '', '{cp:js-escape(/cp/strings/msg_confirm_delete)}');" />
        </td>
      </tr>
    </table>
    <br />
    <table class="formview" border="0" cellspacing="0" cellpadding="0">
      <tr class="title">
        <td colspan="2"><span class="floatright"><xsl:value-of select="/cp/strings/wm_addresses_quickadd_req" /></span><xsl:value-of select="/cp/strings/wm_addresses_quickadd" /></td>
      </tr>
      <tr class="rowodd">
        <td class="label"><xsl:value-of select="/cp/strings/wm_addresses_lastname" /></td>
        <td class="contentwidth"><input type="text" name="txtLast" size="60" value="{$last}" /></td>
      </tr>
      <tr class="roweven">
        <td class="label"><xsl:value-of select="/cp/strings/wm_addresses_firstname" /></td>
        <td class="contentwidth"><input type="text" name="txtFirst" size="60" value="{$first}" /></td>
      </tr>
      <tr class="rowodd">
        <td class="label"><xsl:value-of select="/cp/strings/wm_addresses_extemailaddress" /></td>
        <td class="contentwidth"><input type="text" name="txtEmail" size="60" value="{$email}" /></td>
      </tr>
      <tr class="controlrow">
        <td colspan="2"><span class="floatright"><input type="button" name="add" value="{/cp/strings/wm_addresses_bt_add}" onClick="verifyQuickAdd('{cp:js-escape(/cp/strings/wm_addresses_alertNoEmailAddrMsg)}','{cp:js-escape(/cp/strings/wm_addresses_alertFmtEmailAddrMsg)}');" /></span></td>
      </tr>
    </table>

</xsl:template>
</xsl:stylesheet>
