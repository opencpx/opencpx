<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
  xmlns:exslt="http://exslt.org/common"
  exclude-result-prefixes="exslt">
<xsl:import href="mail_global.xsl" />

<xsl:variable name="linkref"><xsl:value-of select="/cp/form/linkref" /></xsl:variable>

<xsl:variable name="search_value">
  <xsl:choose>
    <xsl:when test="string(/cp/form/address_search_top) and not(string(/cp/form/reset))">
      <xsl:value-of select="/cp/form/address_search_top" />
    </xsl:when>
    <xsl:when test="string(/cp/form/address_search_bottom) and not(string(/cp/form/reset))">
      <xsl:value-of select="/cp/form/address_search_bottom" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="sort_by">
  <xsl:choose>
<!-- slightly faster by now having as much dereferencing? - is redundant -->
    <xsl:when test="string(/cp/form/sort_by)"><xsl:value-of select="/cp/form/sort_by" /></xsl:when>
     <xsl:when test="/cp/vsap/vsap[@type='webmail:options:fetch']/webmail_options/sel_addressee_order!= ''">
       <xsl:value-of select="/cp/vsap/vsap[@type='webmail:options:fetch']/webmail_options/sel_addressee_order" />
     </xsl:when>
    <xsl:otherwise>firstname</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="sort_type">
  <xsl:choose>
<!-- slightly faster by now having as much dereferencing? - is redundant -->
    <xsl:when test="string(/cp/form/sort_type)"><xsl:value-of select="/cp/form/sort_type" /></xsl:when>
    <xsl:otherwise>ascending</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="addressList">
  <xsl:call-template name="mergeAddressLists">
    <xsl:with-param name="address" select="/cp/vsap/vsap[@type='webmail:addressbook:load']/vCardSet/vCard" />
    <xsl:with-param name="lists" select="/cp/vsap/vsap[@type='webmail:distlist:list']/distlist" />
  </xsl:call-template>
</xsl:variable>
<xsl:variable name="allAddresses" select="exslt:node-set($addressList)" />

<xsl:template name="mergeAddressLists">
  <xsl:param name="address" />
  <xsl:param name="lists" />
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
                    <xsl:value-of select="concat(Last_Name,', ',First_Name)" />
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
                    <xsl:value-of select="concat(First_Name,' ',Last_Name)" />
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
      <xsl:variable name="boxname">
        <xsl:choose>
          <xsl:when test="string-length(First_Name) > 0 and string-length(Last_Name) > 0">
            <xsl:value-of select="concat(First_Name,' ',Last_Name)" />
          </xsl:when>
          <xsl:when test="string-length(First_Name) > 0 and string-length(Last_Name) = 0">
            <xsl:value-of select="First_Name" />
          </xsl:when>
          <xsl:when test="string-length(First_Name) = 0 and string-length(Last_Name) > 0">
            <xsl:value-of select="Last_Name" />
          </xsl:when>
          <xsl:otherwise></xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <addrRef>
        <type>individual</type>
        <last_name><xsl:value-of select="Last_Name" /></last_name>
        <sort_last_name><xsl:value-of select="$sort_last_name" /></sort_last_name>
        <first_name><xsl:value-of select="First_Name" /></first_name>
        <sort_first_name><xsl:value-of select="$sort_first_name" /></sort_first_name>
        <fullname>
          <xsl:call-template name="truncate">
            <xsl:with-param name="string"><xsl:value-of select="$fullname" /></xsl:with-param>
            <xsl:with-param name="fieldlength"><xsl:value-of select="/cp/strings/wm_selectaddr_firstlast_fieldlength" /></xsl:with-param>
          </xsl:call-template>
        </fullname>
        <boxname><xsl:value-of select="$boxname" /></boxname>
        <nickname>
          <xsl:call-template name="truncate">
            <xsl:with-param name="string"><xsl:value-of select="Nickname" /></xsl:with-param>
            <xsl:with-param name="fieldlength"><xsl:value-of select="/cp/strings/wm_selectaddr_nickname_fieldlength" /></xsl:with-param>
          </xsl:call-template>
        </nickname>
        <sort_nickname><xsl:value-of select="$sort_nickname" /></sort_nickname>
        <emailaddress>
          <xsl:call-template name="truncate">
            <xsl:with-param name="string"><xsl:value-of select="Email_Address" /></xsl:with-param>
            <xsl:with-param name="fieldlength"><xsl:value-of select="/cp/strings/wm_selectaddr_email_fieldlength" /></xsl:with-param>
          </xsl:call-template>
        </emailaddress>
        <fullemailaddress><xsl:value-of select="Email_Address" /></fullemailaddress>
        <sort_emailaddress><xsl:value-of select="$sort_emailaddress" /></sort_emailaddress>
        <listid></listid>
      </addrRef>
    </xsl:for-each>

    <!-- grab all of the group list entries -->
    <xsl:for-each select="/cp/vsap/vsap/distlist">
      <xsl:variable name="showemailaddress">
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
      <xsl:variable name="sort_last_name">
        <xsl:value-of select="translate(name, 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')" /> 
      </xsl:variable>
      <xsl:variable name="sort_first_name">
        <xsl:value-of select="translate(name, 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')" />
      </xsl:variable>
      <xsl:variable name="sort_nickname">
        <xsl:value-of select="translate(nickname, 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')" />
      </xsl:variable>
      <xsl:variable name="sort_emailaddress">
        <xsl:value-of select="translate($showemailaddress, 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')" />
      </xsl:variable>
      <addrRef>
        <type>group</type>
        <last_name><xsl:value-of select="name" /></last_name>
        <sort_last_name><xsl:value-of select="$sort_last_name" /></sort_last_name>
        <first_name><xsl:value-of select="name" /></first_name>
        <sort_first_name><xsl:value-of select="$sort_first_name" /></sort_first_name>
        <fullname>
          <xsl:call-template name="truncate">
            <xsl:with-param name="string"><xsl:value-of select="name" /></xsl:with-param>
            <xsl:with-param name="fieldlength"><xsl:value-of select="/cp/strings/wm_selectaddr_firstlast_fieldlength" /></xsl:with-param>
          </xsl:call-template>
        </fullname>
        <boxname></boxname>
        <nickname>
          <xsl:call-template name="truncate">
            <xsl:with-param name="string"><xsl:value-of select="nickname" /></xsl:with-param>
            <xsl:with-param name="fieldlength"><xsl:value-of select="/cp/strings/wm_selectaddr_nickname_fieldlength" /></xsl:with-param>
          </xsl:call-template>
        </nickname>
        <sort_nickname><xsl:value-of select="$sort_nickname" /></sort_nickname>
        <showemailaddress>
          <xsl:call-template name="truncate">
            <xsl:with-param name="string"><xsl:value-of select="$showemailaddress" /></xsl:with-param>
            <xsl:with-param name="fieldlength"><xsl:value-of select="/cp/strings/wm_selectaddr_email_fieldlength" /></xsl:with-param>
          </xsl:call-template>
        </showemailaddress>
        <emailaddress>
          <xsl:for-each select="entries/entry/address">
            <xsl:value-of select="." />
            <xsl:if test="position() != last()">, </xsl:if>
          </xsl:for-each>
        </emailaddress>
        <sort_emailaddress><xsl:value-of select="$sort_emailaddress" /></sort_emailaddress>
        <listid><xsl:value-of select="listid" /></listid>
      </addrRef>
    </xsl:for-each>
  </masterAddrList>
</xsl:template>

<xsl:template name="displayAddresses">
  <xsl:variable name="img_individual"><xsl:value-of select="/cp/strings/wm_img_individual" /></xsl:variable>
  <xsl:variable name="img_group"><xsl:value-of select="/cp/strings/wm_img_group" /></xsl:variable>
  <xsl:for-each select="$allAddresses/masterAddrList/addrRef">
    <xsl:sort select="sort_first_name[$sort_by='firstname'] |
                      sort_last_name[$sort_by='lastname'] |
                      sort_nickname[$sort_by='nickname'] |
                      sort_emailaddress[$sort_by='emailaddress']"
               order="{$sort_type}"
               data-type="text" />

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
    <xsl:variable name="boxname"><xsl:value-of select="boxname" /></xsl:variable>
    <xsl:variable name="nickname"><xsl:value-of select="nickname" /></xsl:variable>
    <xsl:variable name="emailaddress"><xsl:value-of select="emailaddress" /></xsl:variable>
    <xsl:variable name="fullemailaddress"><xsl:value-of select="fullemailaddress" /></xsl:variable>
    <xsl:variable name="showemailaddress"><xsl:value-of select="showemailaddress" /></xsl:variable>
    <xsl:variable name="listid"><xsl:value-of select="listid" /></xsl:variable>
    <xsl:variable name="boxvalue">
      <xsl:choose>
        <xsl:when test="type='individual'">
          <xsl:choose>
            <xsl:when test="string-length($boxname)>0">
              <xsl:value-of select="concat('&quot;',$boxname,'&quot;',' ','&lt;',$fullemailaddress,'&gt;')" />
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="$emailaddress" />
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise><xsl:value-of select="$emailaddress" /></xsl:otherwise> 
      </xsl:choose>
    </xsl:variable>

    <xsl:if test="contains(
                              translate($boxvalue, 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
                              translate($search_value, 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')
                          ) or contains(
                              translate($name, 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
                              translate($search_value, 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')
                          ) or contains(
                              translate($boxvalue, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),
                              translate($search_value, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')
                          ) or contains(
                              translate($name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),
                              translate($search_value, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')
                          ) or contains(
                              translate($nickname, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),
                              translate($search_value, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')
                          ) or contains(
                              translate($nickname, 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'),
                              translate($search_value, 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')
                          )">

      <xsl:variable name="to_row_id">to<xsl:value-of select="position()"/></xsl:variable>
      <xsl:variable name="cc_row_id">cc<xsl:value-of select="position()"/></xsl:variable>
      <xsl:variable name="bcc_row_id">bcc<xsl:value-of select="position()"/></xsl:variable>
      <xsl:variable name="type_row_id"><xsl:value-of select="$linkref"/><xsl:value-of select="position()"/></xsl:variable>
      <xsl:variable name="row_style">
        <xsl:choose>
          <xsl:when test="position() mod 2 = 1">roweven</xsl:when>
          <xsl:otherwise>rowodd</xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <tr class="{$row_style}">
        <td><input type="checkbox" id="{$to_row_id}" name="to" value="{$boxvalue}" /></td>
        <td><input type="checkbox" id="{$cc_row_id}" name="cc" value="{$boxvalue}" /></td>
        <td><input type="checkbox" id="{$bcc_row_id}" name="bcc" value="{$boxvalue}" /></td>
        <td><label for="{$type_row_id}"><img src="{$type_image}" alt=""  /></label></td>
        <td><label for="{$type_row_id}"><xsl:value-of select="$name" /></label><br /></td>
        <td><label for="{$type_row_id}"><xsl:value-of select="$nickname" /></label><br /></td>
        <xsl:choose>
          <xsl:when test="type='individual'">
            <td><label for="{$type_row_id}"><xsl:value-of select="$emailaddress" /></label></td>
          </xsl:when>
          <xsl:otherwise>
            <td><label for="{$type_row_id}"><xsl:value-of select="$showemailaddress" /></label></td>
          </xsl:otherwise>
        </xsl:choose>
      </tr>
    </xsl:if>
  </xsl:for-each>
</xsl:template>

<xsl:template match="/">
  <xsl:call-template name="blankbodywrapper">
    <xsl:with-param name="title">
      <xsl:copy-of select="/cp/strings/wm_title" /> : <xsl:value-of select="/cp/strings/wm_selectaddr_title" />
    </xsl:with-param>
    <xsl:with-param name="formaction">wm_select-addressee.xsl</xsl:with-param>
    <xsl:with-param name="formname">specialwindow</xsl:with-param>
    <xsl:with-param name="feedback" />
    <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_inbox" />
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

      <input type="hidden" name="linkref" value="{/cp/form/linkref}" />
      <table class="webmailpopup" border="0" cellspacing="0" cellpadding="0">
        <tr class="title">
          <td colspan="7"><xsl:value-of select="/cp/strings/wm_selectaddr_title" /></td>
        </tr>
        <tr class="controlrow">
          <td colspan="7"><input class="floatright" onClick="window.close()" type="button" name="address_new" value="{/cp/strings/wm_selectaddr_bt_cancel}" /><input class="floatright" onClick="closeAddress()" type="button" name="address_new" value="{/cp/strings/wm_selectaddr_bt_ok}" /><input type="text" name="address_search_top" value="" /> <input type="submit" name="search" value="{/cp/strings/wm_selectaddr_bt_search}" /><input type="submit" name="reset" value="{/cp/strings/wm_selectaddr_bt_reset}" /></td>
        </tr>
        <tr class="columnhead">
          <td class="ckboxcolumn">To</td>
          <td class="ckboxcolumn">Cc</td>
          <td class="ckboxcolumn">Bcc</td>
          <td class="imagecolumn"><br />
          </td>

          <xsl:variable name="firstnamesorturl">wm_select-addressee.xsl?sort_by=firstname&amp;sort_type=<xsl:choose>
            <xsl:when test="($sort_by='firstname') and ($sort_type='ascending')">descending</xsl:when>
            <xsl:otherwise>ascending</xsl:otherwise>
          </xsl:choose></xsl:variable>
          <xsl:variable name="lastnamesorturl">wm_select-addressee.xsl?sort_by=lastname&amp;sort_type=<xsl:choose>
            <xsl:when test="($sort_by='lastname') and ($sort_type='ascending')">descending</xsl:when>
            <xsl:otherwise>ascending</xsl:otherwise>
          </xsl:choose></xsl:variable>

        <td class="namecolumnpopup">
          <xsl:choose>
            <xsl:when test="$sort_by='firstname'">
              <a href="{$firstnamesorturl}">
                <xsl:value-of select="/cp/strings/wm_selectaddr_first" />
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
                <xsl:value-of select="/cp/strings/wm_selectaddr_last" />
              </a>
            </xsl:when>
            <xsl:when test="$sort_by='lastname'">
              <a href="{$lastnamesorturl}">
                <xsl:value-of select="/cp/strings/wm_selectaddr_last" />
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
                <xsl:value-of select="/cp/strings/wm_selectaddr_first" />
              </a>
            </xsl:when>
            <xsl:otherwise>
              <a href="{$firstnamesorturl}">
                <xsl:value-of select="/cp/strings/wm_selectaddr_first" />
              </a>&#160;
              <a href="{$lastnamesorturl}">
                <xsl:value-of select="/cp/strings/wm_selectaddr_last" />
              </a>
            </xsl:otherwise>
          </xsl:choose>
        </td>

          <xsl:variable name="nicknamesorturl">wm_select-addressee.xsl?sort_by=nickname&amp;sort_type=<xsl:choose>
            <xsl:when test="($sort_by='nickname') and ($sort_type='ascending')">descending</xsl:when>
            <xsl:otherwise>ascending</xsl:otherwise>
          </xsl:choose></xsl:variable>

          <td class="nicknamecolumnpopup"><a href="{$nicknamesorturl}"><xsl:value-of select="/cp/strings/wm_selectaddr_nickname" /><xsl:if test="$sort_by='nickname'"><xsl:choose><xsl:when test="$sort_type='ascending'"><img src="{/cp/strings/img_sortarrowdown}" alt="" height="15" width="15" border="0" /></xsl:when><xsl:otherwise><img src="{/cp/strings/img_sortarrowup}" alt="" height="15" width="15" border="0" /></xsl:otherwise></xsl:choose></xsl:if></a></td>

          <xsl:variable name="emailsorturl">wm_select-addressee.xsl?sort_by=emailaddress&amp;sort_type=<xsl:choose>
            <xsl:when test="($sort_by='emailaddress') and ($sort_type='ascending')">descending</xsl:when>
            <xsl:otherwise>ascending</xsl:otherwise>
          </xsl:choose></xsl:variable>

          <td class="emailaddresscolumnpopup" ><a href="{$emailsorturl}"><xsl:value-of select="/cp/strings/wm_selectaddr_email" /><xsl:if test="$sort_by='emailaddress'"><xsl:choose><xsl:when test="$sort_type='ascending'"><img src="{/cp/strings/img_sortarrowdown}" alt="" height="15" width="15" border="0" /></xsl:when><xsl:otherwise><img src="{/cp/strings/img_sortarrowup}" alt="" height="15" width="15" border="0" /></xsl:otherwise></xsl:choose></xsl:if></a></td>

        </tr>
        <xsl:call-template name="displayAddresses" />
        <tr class="controlrow">
          <td colspan="7"><input class="floatright" onClick="window.close()" type="button" name="address_new" value="{/cp/strings/wm_selectaddr_bt_cancel}" /><input class="floatright" onClick="closeAddress()" type="button" name="address_new" value="{/cp/strings/wm_selectaddr_bt_ok}" /><input type="text" name="address_search_bottom" value="" /> <input type="submit" name="search" value="{/cp/strings/wm_selectaddr_bt_search}" /><input type="submit" name="reset" value="{/cp/strings/wm_selectaddr_bt_reset}" /></td>
        </tr>
      </table>

</xsl:template>
</xsl:stylesheet>
