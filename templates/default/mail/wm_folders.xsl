<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
  xmlns:exslt="http://exslt.org/common"
  exclude-result-prefixes="exslt">
<xsl:import href="mail_global.xsl" />
<xsl:import href="mail_folders_feedback.xsl" />

<xsl:variable name="status">
  <xsl:call-template name="status_message" />
</xsl:variable>

<xsl:variable name="message">
  <xsl:if test="string($status)">
    <xsl:call-template name="feedback_table">
      <xsl:with-param name="image">
        <xsl:choose>
          <xsl:when test="/cp/vsap/vsap[@type='error']">error</xsl:when>
          <xsl:otherwise>success</xsl:otherwise>
        </xsl:choose>
      </xsl:with-param>
      <xsl:with-param name="message"><xsl:copy-of select="$status" /> </xsl:with-param>
    </xsl:call-template>
  </xsl:if>
</xsl:variable>

<xsl:variable name="sort_by">
  <xsl:choose>
    <xsl:when test="string(/cp/form/sort_by)"><xsl:value-of select="/cp/form/sort_by" /></xsl:when>
    <xsl:otherwise>name</xsl:otherwise>
  </xsl:choose>
</xsl:variable>
<xsl:variable name="sort_type">
  <xsl:choose>
    <xsl:when test="string(/cp/form/sort_type)"><xsl:value-of select="/cp/form/sort_type" /></xsl:when>
    <xsl:otherwise>ascending</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="total_folders">
  <xsl:value-of select="count(/cp/vsap/vsap[@type='webmail:folders:list']/folder/name)" />
</xsl:variable>

<xsl:template match="/cp/vsap/vsap[@type='webmail:folders:list']/folder">
  <xsl:variable name="row_id">row<xsl:value-of select="position()"/></xsl:variable>
  <xsl:variable name="row_style">
    <xsl:choose>
      <xsl:when test="position() mod 2 = 1">rowodd</xsl:when>
      <xsl:otherwise>roweven</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <!-- Display the "branded" name for system folders -->
  <xsl:variable name="display_name">
    <xsl:choose>
      <xsl:when test="name = $inbox"><xsl:value-of select="/cp/strings/wm_folders_inbox" /></xsl:when>
      <xsl:when test="name = $sent_items"><xsl:value-of select="/cp/strings/wm_folders_sent_items" /></xsl:when>
      <xsl:when test="name = $drafts"><xsl:value-of select="/cp/strings/wm_folders_drafts" /></xsl:when>
      <xsl:when test="name = $trash"><xsl:value-of select="/cp/strings/wm_folders_trash" /></xsl:when>
      <xsl:when test="name = $junk"><xsl:value-of select="/cp/strings/wm_folders_junk" /></xsl:when>
      <xsl:when test="name = $quarantine"><xsl:value-of select="/cp/strings/wm_folders_quarantine" /></xsl:when>
      <xsl:otherwise><xsl:value-of select="name" /></xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <tr class="{$row_style}">
    <td><xsl:choose>
      <xsl:when test='@flag = "immutable"'><br /></xsl:when>
      <xsl:otherwise>
        <input type="checkbox" id="{$row_id}" name="cbUserID" value="{name}" />
      </xsl:otherwise>
    </xsl:choose>
    </td>
    <td><xsl:choose>
      <xsl:when test='@flag = "immutable"'>
        <label for="{$row_id}"><img src="{/cp/strings/wm_img_foldersystem}" alt="" border="0" /></label>
      </xsl:when>
      <xsl:otherwise>
        <label for="{$row_id}"><img src="{/cp/strings/wm_img_folder}" alt="" border="0" /></label>
      </xsl:otherwise>
    </xsl:choose>
    </td>
    <td>
      <a href="wm_messages.xsl?folder={url_name}">
        <xsl:call-template name="truncate">
          <xsl:with-param name="string"><xsl:value-of select="$display_name" /></xsl:with-param>
          <xsl:with-param name="fieldlength"><xsl:copy-of select="/cp/strings/wm_folders_name_fieldlength" /></xsl:with-param>
        </xsl:call-template>
      </a>
    </td>
    <td class="centeralign"><xsl:value-of select="num_messages" /></td>
    <td class="centeralign"><xsl:value-of select="unseen_messages" /></td>
    <td class="rightalign">
      <xsl:call-template name="format_bytes">
        <xsl:with-param name="bytes" select="size" />
      </xsl:call-template>
    </td>
    <td class="actions">
      <xsl:choose>
        <!-- disable 'clear' link for already-empty folders -->
        <xsl:when test="num_messages = 0">
          <xsl:value-of select="/cp/strings/wm_folders_clear" />
        </xsl:when>

        <!-- All of the others get the clear link -->
        <xsl:otherwise>
          <a href="wm_folders.xsl?clear={url_name}"><xsl:value-of select="/cp/strings/wm_folders_clear" /></a>
        </xsl:otherwise>
      </xsl:choose>
      | 
      <xsl:choose>
        <!-- system folders may not be renamed -->
        <xsl:when test = '@flag = "immutable"'>
          <xsl:value-of select="/cp/strings/wm_folders_rename" />
        </xsl:when>
        <xsl:otherwise>
          <a href="wm_renamefolder.xsl?folder={url_name}"><xsl:value-of select="/cp/strings/wm_folders_rename" /></a>
        </xsl:otherwise>
      </xsl:choose>
    </td>
  </tr>
</xsl:template>

<xsl:template match="/">
  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title"><xsl:copy-of select="/cp/strings/wm_title" /> : <xsl:copy-of select="/cp/strings/bc_wm_folders" /></xsl:with-param>
    <xsl:with-param name="formaction">wm_folders.xsl</xsl:with-param>
    <xsl:with-param name="feedback" select="$message" />
    <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_folders" />
    <xsl:with-param name="help_short" select="/cp/strings/wm_folders_hlp_short" />
    <xsl:with-param name="help_long" select="/cp/strings/wm_folders_hlp_long" />
    <xsl:with-param name="breadcrumb">
      <breadcrumb>
       <section>
         <name><xsl:copy-of select="/cp/strings/bc_wm_folders" /></name>
         <url>#</url>
         <image>FolderManagement</image>
       </section>
      </breadcrumb>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

      <script src="{concat($base_url, '/mail/mail.js')}" language="JavaScript"></script>
      <input type="hidden" name="confirmdelete" value="" />
      <input type="hidden" name="confirmunsubscribe" value="" />
      <table class="listview" border="0" cellspacing="0" cellpadding="0">
        <tr class="title">
          <td colspan="7"><xsl:value-of select="/cp/strings/wm_folders_title" /></td>
        </tr>
        <tr class="controlrow">
          <td colspan="7"><span class="floatright"><input type="submit" name="addfolder" value="{/cp/strings/wm_folders_bt_addfolder}" /><xsl:if test="/cp/vsap/vsap[@type='webmail:options:load']/webmail_options/use_mailboxlist='yes'"><input type="submit" name="subscribefolder" value="{/cp/strings/wm_folders_bt_subscribefolder}" /></xsl:if></span><input type="button" name="button" value="{/cp/strings/wm_folders_bt_deletefolder}" onClick="submitButton('delete','cbUserID', '{cp:js-escape(/cp/strings/wm_folders_delete_confirm)}', '{cp:js-escape(/cp/strings/wm_folders_delete_alert)}', {$personal_folder_count});" /><xsl:if test="/cp/vsap/vsap[@type='webmail:options:load']/webmail_options/use_mailboxlist='yes'"><input type="button" name="button" value="{/cp/strings/wm_folders_bt_unsubscribefolder}" onClick="unsubscribeButton('unsubscribe','cbUserID', '{cp:js-escape(/cp/strings/wm_folders_unsubscribe_confirm)}', '{cp:js-escape(/cp/strings/wm_folders_unsubscribe_alert)}', {$personal_folder_count});" /></xsl:if></td>
        </tr>
        <tr class="columnhead">
          <td class="ckboxcolumn"><input type="checkbox" name="cbSelectAll" value="" onClick="check(this.form.cbUserID);" /></td>
          <td class="imagecolumn"><br />
          </td>

          <td class="foldername">
            <xsl:variable name="namesorturl">wm_folders.xsl?sort_by=name&amp;sort_type=<xsl:choose>
              <xsl:when test="($sort_by='name') and ($sort_type='ascending')">descending</xsl:when>
              <xsl:otherwise>ascending</xsl:otherwise>
            </xsl:choose></xsl:variable>
            <a href="{$namesorturl}">
              <xsl:value-of select="/cp/strings/wm_folders_foldername" />
            </a>&#160;<a href="{$namesorturl}">
              <xsl:if test="$sort_by='name'">
                <xsl:choose>
                  <xsl:when test="$sort_type='ascending'">
                    <img src="{/cp/strings/img_sortarrowdown}" alt="" border="0"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <img src="{/cp/strings/img_sortarrowup}" alt="" border="0"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:if>
            </a>
          </td>

          <td class="messagescolumn">
            <xsl:variable name="msgsorturl">wm_folders.xsl?sort_by=message&amp;sort_type=<xsl:choose>
              <xsl:when test="($sort_by='message') and ($sort_type='ascending')">descending</xsl:when>
              <xsl:otherwise>ascending</xsl:otherwise>
            </xsl:choose></xsl:variable>
            <a href="{$msgsorturl}">
              <xsl:value-of select="/cp/strings/wm_folders_messages" />
            </a>&#160;<a href="{$msgsorturl}">
              <xsl:if test="$sort_by='message'">
                <xsl:choose>
                  <xsl:when test="$sort_type='ascending'">
                    <img src="{/cp/strings/img_sortarrowdown}" alt="" border="0"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <img src="{/cp/strings/img_sortarrowup}" alt="" border="0"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:if>
            </a>
          </td>

          <td class="unreadcolumn">
            <xsl:variable name="unreadsorturl">wm_folders.xsl?sort_by=unread&amp;sort_type=<xsl:choose>
              <xsl:when test="($sort_by='unread') and ($sort_type='ascending')">descending</xsl:when>
              <xsl:otherwise>ascending</xsl:otherwise>
            </xsl:choose></xsl:variable>
            <a href="{$unreadsorturl}">
              <xsl:value-of select="/cp/strings/wm_folders_unread" />
            </a>&#160;<a href="{$unreadsorturl}">
              <xsl:if test="$sort_by='unread'">
                <xsl:choose>
                  <xsl:when test="$sort_type='ascending'">
                    <img src="{/cp/strings/img_sortarrowdown}" alt="" border="0"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <img src="{/cp/strings/img_sortarrowup}" alt="" border="0"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:if>
            </a>
          </td>

          <td class="sizecolumn">
            <xsl:variable name="sizesorturl">wm_folders.xsl?sort_by=size&amp;sort_type=<xsl:choose>
              <xsl:when test="($sort_by='size') and ($sort_type='ascending')">descending</xsl:when>
              <xsl:otherwise>ascending</xsl:otherwise>
            </xsl:choose></xsl:variable>
            <a href="{$sizesorturl}">
              <xsl:value-of select="/cp/strings/wm_folders_size" />
            </a>&#160;<a href="{$sizesorturl}">
              <xsl:if test="$sort_by='size'">
                <xsl:choose>
                  <xsl:when test="$sort_type='ascending'">
                    <img src="{/cp/strings/img_sortarrowdown}" alt="" border="0"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <img src="{/cp/strings/img_sortarrowup}" alt="" border="0"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:if>
            </a>
          </td>

          <td><xsl:value-of select="/cp/strings/wm_folders_action" /></td>
        </tr>

        <xsl:apply-templates select="/cp/vsap/vsap[@type='webmail:folders:list']/folder">
          <xsl:sort select="@order" data-type="number" order="ascending" />
          <xsl:sort select="num_messages[$sort_by='message'] 
                              | unseen_messages[$sort_by='unread'] 
                              | size[$sort_by='size']"
            order="{$sort_type}" data-type="number" />
          <xsl:sort select="translate(name, 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')"
            order="{$sort_type}" data-type="text" />
        </xsl:apply-templates>

        <tr class="totalrow">
          <td colspan="2"><xsl:value-of select="/cp/strings/wm_folders_totals" /></td>
          <td>
            <xsl:value-of select="concat($total_folders,' ',/cp/strings/wm_folders_total_folders)" />
          </td>
          <td class="centeralign">
            <xsl:value-of select="sum(/cp/vsap/vsap[@type='webmail:folders:list']/folder/num_messages)" />
          </td>
          <td class="centeralign">
            <xsl:value-of select="sum(/cp/vsap/vsap[@type='webmail:folders:list']/folder/unseen_messages)" />
          </td>
          <td class="rightalign">
            <xsl:call-template name="format_bytes">
              <xsl:with-param name="bytes" select="sum(/cp/vsap/vsap[@type='webmail:folders:list']/folder/size)" />
            </xsl:call-template>
          </td>
          <td><br /></td>
        </tr>

        <tr class="controlrow">
          <td colspan="7"><span class="floatright"><input type="submit" name="addfolder" value="{/cp/strings/wm_folders_bt_addfolder}" /><xsl:if test="/cp/vsap/vsap[@type='webmail:options:load']/webmail_options/use_mailboxlist='yes'"><input type="submit" name="subscribefolder" value="{/cp/strings/wm_folders_bt_subscribefolder}" /></xsl:if></span><input type="button" name="button" value="{/cp/strings/wm_folders_bt_deletefolder}" onClick="submitButton('delete','cbUserID', '{cp:js-escape(/cp/strings/wm_folders_delete_confirm)}', '{cp:js-escape(/cp/strings/wm_folders_delete_alert)}', {$personal_folder_count});" /><xsl:if test="/cp/vsap/vsap[@type='webmail:options:load']/webmail_options/use_mailboxlist='yes'"><input type="button" name="button" value="{/cp/strings/wm_folders_bt_unsubscribefolder}" onClick="unsubscribeButton('unsubscribe','cbUserID', '{cp:js-escape(/cp/strings/wm_folders_unsubscribe_confirm)}', '{cp:js-escape(/cp/strings/wm_folders_unsubscribe_alert)}', {$personal_folder_count});" /></xsl:if></td>
        </tr>
      </table>

</xsl:template>
</xsl:stylesheet>
