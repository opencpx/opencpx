<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="mail_global.xsl" />

<xsl:variable name="folder"><xsl:value-of select="/cp/vsap/vsap[@type='webmail:messages:list']/folder" /></xsl:variable>


<xsl:variable name="disp_folder">
  <xsl:call-template name="truncate"> 
    <xsl:with-param name="string" select="$folder" />
    <xsl:with-param name="fieldlength" select="/cp/strings/wm_messages_folder_selectlength" />
  </xsl:call-template>
</xsl:variable>

<xsl:variable name="folder_url">
  <xsl:value-of select="/cp/vsap/vsap[@type='webmail:folders:list']/folder[name=$folder]/url_name" />
</xsl:variable>

<xsl:variable name="inbox_checkmail">
  <xsl:value-of select="/cp/vsap/vsap[@type='webmail:options:fetch']/webmail_options/inbox_checkmail" />
</xsl:variable>

<xsl:variable name="attachment_view">
  <xsl:value-of select="/cp/vsap/vsap[@type='webmail:options:fetch']/webmail_options/attachment_view" />
</xsl:variable>

<xsl:variable name="sort_by"><xsl:value-of select="/cp/vsap/vsap[@type='webmail:messages:list']/sortby" /></xsl:variable>
<xsl:variable name="sort_type"><xsl:value-of select="/cp/vsap/vsap[@type='webmail:messages:list']/order" /></xsl:variable>

<xsl:variable name="basic_sort_url">wm_messages.xsl?folder=<xsl:value-of select="$folder" />&amp;page=<xsl:value-of select="/cp/form/page" />&amp;</xsl:variable>

<xsl:variable name="message">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='error']">
      <xsl:if test="/cp/msgs/msg[@name='compose_sent_copy_failure']">
         <xsl:copy-of select="/cp/strings/wm_messages_msg_compose_sent_copy_failure" />
      </xsl:if>
      <xsl:if test="/cp/msgs/msg[@name='move_src_read_failure']">
         <xsl:copy-of select="/cp/strings/wm_messages_msg_move_src_read_failure" />
      </xsl:if>
      <xsl:if test="/cp/msgs/msg[@name='move_src_write_failure']">
         <xsl:copy-of select="/cp/strings/wm_messages_msg_move_src_write_failure" />
      </xsl:if>
      <xsl:if test="/cp/msgs/msg[@name='move_dest_over_quota']">
         <xsl:copy-of select="/cp/strings/wm_messages_msg_move_dest_failure_over_quota" />
      </xsl:if>
      <xsl:if test="/cp/msgs/msg[@name='move_failure']">
         <xsl:copy-of select="/cp/strings/wm_messages_msg_move_failure" />
      </xsl:if>
      <xsl:if test="/cp/msgs/msg[@name='move_dest_write_failure']">
         <xsl:copy-of select="/cp/strings/wm_messages_msg_move_dest_failure" />
	 <xsl:if test="string(/cp/form/dest_folder) != '' ">
	    <xsl:value-of select="concat('&quot;',/cp/form/dest_folder,'&quot;','&#160;')" />
         </xsl:if>
         <xsl:copy-of select="/cp/strings/wm_messages_msg_move_dest_failure_write" />
      </xsl:if>
    </xsl:when>
    <xsl:otherwise>
      <xsl:choose>
        <xsl:when test="(/cp/vsap/vsap[@type='webmail:messages:move']) and (string(/cp/form/delete) != '')">
          <xsl:copy-of select="/cp/strings/wm_messages_msg_delete_ok" />
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='webmail:messages:move']">
          <xsl:copy-of select="/cp/strings/wm_messages_msg_move_ok" />
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='webmail:folders:clear']">
          <xsl:copy-of select="/cp/strings/wm_messages_msg_empty_trash" />
        </xsl:when>
        <xsl:when test="/cp/msgs/msg[@name='compose_successful'] and (string(/cp/vsap/vsap[@type='sys:service:status']/sendmail/running) = 'false')">
          <xsl:copy-of select="/cp/strings/wm_messages_msg_compose_no_sendmail" />
        </xsl:when>
        <xsl:when test="/cp/msgs/msg[@name='compose_successful']">
          <xsl:copy-of select="/cp/strings/wm_messages_msg_compose_successful" />
        </xsl:when>
        <xsl:when test="/cp/msgs/msg[@name='compose_savedraft_successful']">
          <xsl:copy-of select="/cp/strings/wm_messages_msg_compose_savedraft_successful" />
        </xsl:when>
      </xsl:choose>
    </xsl:otherwise>
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

<xsl:template match="/cp/vsap/vsap[@type='webmail:messages:list']/message">
  <xsl:variable name="row_id">row<xsl:value-of select="position()"/></xsl:variable>
  <xsl:variable name="row_style">
    <xsl:if test='not(flags/flag = "\Seen")'>unread</xsl:if>
    <xsl:choose>
      <xsl:when test="position() mod 2 = 0">roweven</xsl:when>
      <xsl:otherwise>rowodd</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <tr class="{$row_style}">
    <!-- checkbox -->
    <td width="16"><input type="checkbox" id="{$row_id}" name="uid" value="{uid}" /></td>
    <!-- attachment? -->
    <td width="16">
      <xsl:choose>
        <xsl:when test="$attachment_view = 'all'">
          <xsl:choose>
            <xsl:when test='attachments + inline_attachments &gt; 0'><img src="{/cp/strings/wm_img_attachment}" alt="" border="0" /></xsl:when>
            <xsl:otherwise><br /></xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="$attachment_view = 'attachments'">
          <xsl:choose>
            <xsl:when test='attachments &gt; 0'><img src="{/cp/strings/wm_img_attachment}" alt="" border="0" /></xsl:when>
            <xsl:otherwise><br /></xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise><br /></xsl:otherwise>  <!-- attachment_view = "none" -->
      </xsl:choose>
    </td>
    <!-- To/From address -->
    <td>
      <label for="{$row_id}">
      <xsl:call-template name="truncate">
        <xsl:with-param name="string">
          <xsl:choose>
            <xsl:when test="(($folder = $sent_items) or ($folder = $drafts)) and (string-length(to/address/personal) > 0)">
              <xsl:value-of select="to/address/personal" />
            </xsl:when>
            <xsl:when test="($folder = $sent_items) or ($folder = $drafts)">
              <xsl:value-of select="to/address/full_address" />
            </xsl:when>
            <xsl:when test='string-length(from/address/personal)>0'>
              <xsl:value-of select="from/address/personal" />
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="from/address/full_address" />
            </xsl:otherwise>
          </xsl:choose>
        </xsl:with-param>
        <xsl:with-param name="fieldlength"><xsl:copy-of select="/cp/strings/wm_messages_from_fieldlength" /></xsl:with-param>
      </xsl:call-template>
      </label>
      <br />
    </td>
    <!-- Subject -->
    <td>
      <xsl:variable name="atarget">
        <xsl:choose>
          <xsl:when test="($folder = $drafts)">wm_compose.xsl?draftid=<xsl:value-of select="msgno" />&amp;</xsl:when>
          <xsl:otherwise>wm_viewmessage.xsl?</xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <a href="{$atarget}msgno={msgno}&amp;folder={$folder_url}&amp;uid={uid}&amp;sort_by={$sort_by}&amp;sort_type={$sort_type}">
        <xsl:call-template name="truncate">
          <xsl:with-param name="string">
            <xsl:choose>
              <xsl:when test='string-length(subject) > 0'><cp-unescape><xsl:value-of select="subject" /></cp-unescape></xsl:when>
              <xsl:otherwise><xsl:copy-of select="/cp/strings/wm_messages_nosubject" /></xsl:otherwise>
            </xsl:choose>
          </xsl:with-param>
          <xsl:with-param name="fieldlength"><xsl:copy-of select="/cp/strings/wm_messages_subject_fieldlength" /></xsl:with-param>
        </xsl:call-template>
      </a>
    </td>
    <td>
    <!-- NOTE: vsap prefs calls still need to be fixed for date/time formating -->
    <!-- time -->
    <xsl:variable name="timevalue">
      <xsl:call-template name="format-time">
        <xsl:with-param name="date" select="./date" />
        <xsl:with-param name="type">short</xsl:with-param>
      </xsl:call-template>
    </xsl:variable>

    <!-- date -->
    <xsl:variable name="datevalue">
      <xsl:call-template name="format-date">
        <xsl:with-param name="date" select="./date" />
        <xsl:with-param name="type">short</xsl:with-param>
      </xsl:call-template>
    </xsl:variable>

    <!-- now show the date and time -->
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='user:prefs:load']/user_preferences/dt_order='date'">
          <xsl:value-of select="$datevalue" />&#160;<xsl:value-of select="$timevalue" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$timevalue" />&#160;<xsl:value-of select="$datevalue" />
        </xsl:otherwise>
      </xsl:choose>

    </td>
    <!-- size -->
    <td class="rightalign">
      <xsl:call-template name="format_bytes">
        <xsl:with-param name="bytes" select="rfc822_size" />
      </xsl:call-template>
    </td>
  </tr>
</xsl:template>

<xsl:variable name="controlrow">
  <td colspan="6">
    <span class="floatright">
      <xsl:value-of select="/cp/strings/wm_messages_messages" />
      <xsl:value-of select="/cp/vsap/vsap/first_message" />
      <xsl:value-of select="/cp/strings/wm_messages_dash" />
      <xsl:value-of select="/cp/vsap/vsap/last_message" />
      <xsl:value-of select="/cp/strings/wm_messages_of" />
      <xsl:value-of select="/cp/vsap/vsap/num_messages" />

      <xsl:value-of select="/cp/strings/wm_messages_bar" />

      <xsl:choose>
        <xsl:when test='/cp/vsap/vsap/page = 1'>
          <xsl:value-of select="/cp/strings/wm_messages_first" />
        </xsl:when>
        <xsl:otherwise>
          <a href="{$base_url}/mail/wm_messages.xsl?page=1&amp;folder={$folder_url}&amp;sort_by={$sort_by}&amp;sort_type={$sort_type}">
            <xsl:value-of select="/cp/strings/wm_messages_first" />
          </a>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:value-of select="/cp/strings/wm_messages_bar" />
      <xsl:choose>
        <xsl:when test='string-length(/cp/vsap/vsap/prev_page) > 0'>
          <a href="{$base_url}/mail/wm_messages.xsl?page={/cp/vsap/vsap/prev_page}&amp;folder={$folder_url}&amp;sort_by={$sort_by}&amp;sort_type={$sort_type}">
            <xsl:value-of select="/cp/strings/wm_messages_prev" />
          </a>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="/cp/strings/wm_messages_prev" />
        </xsl:otherwise>
      </xsl:choose>
      <xsl:value-of select="/cp/strings/wm_messages_bar" />
      <xsl:choose>
        <xsl:when test='string-length(/cp/vsap/vsap/next_page) > 0'>
          <a href="{$base_url}/mail/wm_messages.xsl?page={/cp/vsap/vsap/next_page}&amp;folder={$folder_url}&amp;sort_by={$sort_by}&amp;sort_type={$sort_type}">
            <xsl:value-of select="/cp/strings/wm_messages_next" />
          </a>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="/cp/strings/wm_messages_next" />
        </xsl:otherwise>
      </xsl:choose>
      <xsl:value-of select="/cp/strings/wm_messages_bar" />
      <xsl:choose>
        <xsl:when test='/cp/vsap/vsap/page = /cp/vsap/vsap/total_pages'>
          <xsl:value-of select="/cp/strings/wm_messages_last" />
        </xsl:when>
        <xsl:otherwise>
          <a href="{$base_url}/mail/wm_messages.xsl?page={/cp/vsap/vsap/total_pages}&amp;folder={$folder_url}&amp;sort_by={$sort_by}&amp;sort_type={$sort_type}">
            <xsl:value-of select="/cp/strings/wm_messages_last" />
          </a>
        </xsl:otherwise>
      </xsl:choose>
    </span>

    <input type="button" name="selectdelete" value="{/cp/strings/wm_messages_bt_delete}" onClick="submitCheck('{cp:js-escape(/cp/strings/msg_nochecks)}', 'uid', 'delete', 'yes');" />

    <span class="nonstatus"><xsl:value-of select="/cp/strings/wm_messages_or" /></span>
    <select name="dest_folder" onChange="syncselects()" size="1">
      <option value=""><xsl:value-of select="/cp/strings/wm_messages_move_to" /></option>
      <option value="{$inbox}"><xsl:value-of select="/cp/strings/wm_folders_inbox" /></option>
      <option value="{$drafts}"><xsl:value-of select="/cp/strings/wm_folders_drafts" /></option>
      <option value="{$sent_items}"><xsl:value-of select="/cp/strings/wm_folders_sent_items" /></option>
      <option value="{$trash}"><xsl:value-of select="/cp/strings/wm_folders_trash" /></option>
      <option value="{$junk}"><xsl:value-of select="/cp/strings/wm_folders_junk" /></option>
      <option value="{$quarantine}"><xsl:value-of select="/cp/strings/wm_folders_quarantine" /></option>
      <xsl:for-each select="/cp/vsap/vsap[@type='webmail:folders:list']/folder[name != '']">
        <xsl:sort select="translate(name, 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')" />
        <xsl:if test='(string-length(name) > 0) and (name != $trash) and (name != $inbox) and (name != $sent_items) and (name != $drafts) and (name != $quarantine) and (name != $junk)'>
          <option value="{name}">
            <xsl:call-template name="truncate">
              <xsl:with-param name="string"><xsl:value-of select="name" /></xsl:with-param>
              <xsl:with-param name="fieldlength"><xsl:copy-of select="/cp/strings/wm_messages_folder_selectlength" /></xsl:with-param>
            </xsl:call-template>
          </option>
        </xsl:if>
      </xsl:for-each>
    </select>
    <input type="button" name="selectmove" value="{/cp/strings/wm_messages_bt_move}" onClick="submitMoveMail('{cp:js-escape(/cp/strings/msg_nochecks)}', '{cp:js-escape(/cp/strings/wm_messages_msg_select_folder)}');" />
    <xsl:if test="$folder = $inbox">
      &#160;<input type="submit" name="compose" value="{/cp/strings/wm_messages_bt_compose}" />
    </xsl:if>
  </td>
</xsl:variable>


<xsl:template match="/">
  <xsl:variable name="current_nv">
    <xsl:choose>
      <xsl:when test="$folder = $inbox">
        <xsl:value-of select="/cp/strings/nv_inbox" />
      </xsl:when>
      <xsl:when test="$folder = $drafts">
        <xsl:value-of select="/cp/strings/nv_drafts" />
      </xsl:when>
      <xsl:when test="$folder = $sent_items">
        <xsl:value-of select="/cp/strings/nv_sent" />
      </xsl:when>
      <xsl:when test="$folder = $trash">
        <xsl:value-of select="/cp/strings/nv_trash" />
      </xsl:when>
      <xsl:otherwise>
        <!-- personal folder -->
        <xsl:value-of select="/cp/strings/nv_folders" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="subtitle">
    <xsl:if test="$current_nv = /cp/strings/nv_folders">
      <xsl:copy-of select="/cp/strings/bc_wm_folders" /> :
    </xsl:if>
    <xsl:choose>
      <xsl:when test="$folder = $inbox">
        <xsl:copy-of select="/cp/strings/bc_inbox" />
      </xsl:when>
      <xsl:when test="$folder = $sent_items">
        <xsl:copy-of select="/cp/strings/bc_sent" />
      </xsl:when>
      <xsl:when test="$folder = $drafts">
        <xsl:copy-of select="/cp/strings/bc_drafts" />
      </xsl:when>
      <xsl:when test="$folder = $trash">
        <xsl:copy-of select="/cp/strings/bc_trash" />
      </xsl:when>
      <xsl:when test="$folder = $quarantine">
        <xsl:copy-of select="/cp/strings/bc_quarantine" />
      </xsl:when>
      <xsl:when test="$folder = $junk">
        <xsl:copy-of select="/cp/strings/bc_junk" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$disp_folder" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title"><xsl:copy-of select="/cp/strings/wm_title" /> : <xsl:copy-of select="$subtitle"/></xsl:with-param>
    <xsl:with-param name="formaction">wm_messages.xsl</xsl:with-param>
    <xsl:with-param name="feedback" select="$feedback" />
    <xsl:with-param name="selected_navandcontent" select="$current_nv" />
    <xsl:with-param name="help_short" select="/cp/strings/wm_messages_hlp_short" />
    <xsl:with-param name="help_long" select="/cp/strings/wm_messages_hlp_long" />
    <xsl:with-param name="breadcrumb">
      <breadcrumb>
        <xsl:if test="$current_nv = /cp/strings/nv_folders">
          <section>
            <name><xsl:copy-of select="/cp/strings/bc_wm_folders" /></name>
            <url><xsl:value-of select="$base_url" />/mail/wm_folders.xsl</url>
          </section>
        </xsl:if>
        <section>
          <name>
            <xsl:choose>
              <xsl:when test="$folder = $inbox">
                <xsl:copy-of select="/cp/strings/bc_inbox" />
              </xsl:when>
              <xsl:when test="$folder = $sent_items">
                <xsl:copy-of select="/cp/strings/bc_sent" />
              </xsl:when>
              <xsl:when test="$folder = $drafts">
                <xsl:copy-of select="/cp/strings/bc_drafts" />
              </xsl:when>
              <xsl:when test="$folder = $trash">
                <xsl:copy-of select="/cp/strings/bc_trash" />
              </xsl:when>
              <xsl:when test="$folder = $quarantine">
                <xsl:copy-of select="/cp/strings/bc_quarantine" />
              </xsl:when>
              <xsl:when test="$folder = $junk">
                <xsl:copy-of select="/cp/strings/bc_junk" />
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$disp_folder" />
              </xsl:otherwise>
            </xsl:choose>
          </name>
          <url>#</url>
          <image>MailMessages</image>
        </section>
      </breadcrumb>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

      <script src="{concat($base_url, '/mail/mail.js')}" language="JavaScript"></script>
      <xsl:if test="($folder = $inbox) and ($inbox_checkmail > 0)">
        <script>setTimeout("window.location.replace('wm_messages.xsl?checkmail=true')", <xsl:value-of select="$inbox_checkmail" /> * 60 * 1000);</script>
      </xsl:if>

      <input type="hidden" name="folder" value="{$folder}" />
      <input type="hidden" name="delete" />
      <input type="hidden" name="move" />
      <input type="hidden" name="page" value="{/cp/form/page}" />
      <input type="hidden" name="num_messages" value="{/cp/vsap/vsap/num_messages}" />
      <input type="hidden" name="sort_by" value="{$sort_by}" />
      <input type="hidden" name="sort_type" value="{$sort_type}" />

      <table class="listview" border="0" cellspacing="0" cellpadding="0">
        <tr class="title">
          <td colspan="6">
            <xsl:choose>
              <xsl:when test="$folder = $inbox">
                <xsl:value-of select="/cp/strings/wm_folders_inbox" />&#160;<a href="wm_messages.xsl?checkmail=true"><xsl:value-of select="/cp/strings/wm_messages_check_mail" /></a>
              </xsl:when>
              <xsl:when test="$folder = $trash">
                <xsl:value-of select="/cp/strings/wm_folders_trash" />&#160;<a href="wm_messages.xsl?emptytrash=true&amp;folder={$trash}"><xsl:value-of select="/cp/strings/wm_messages_empty_trash" /></a>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$disp_folder" />
              </xsl:otherwise>
            </xsl:choose>
          </td>
        </tr>
        <tr class="controlrow">
          <xsl:copy-of select="$controlrow" />
        </tr>
        <tr class="columnhead">

          <!-- header with checkbox in it -->
          <td class="ckboxcolumn"><input type="checkbox" name="msgnos" onClick="check(this.form.uid)" value="" /></td>
          <!-- header row with attachment picture -->
          <td class="imagecolumn"><img src="{/cp/strings/wm_img_attachment}" alt="" border="0" /></td>
          <!-- From or To header row (sortable) -->
          <td class="to-fromcolumn">
            <xsl:variable name="sendersorturl"><xsl:value-of select="$basic_sort_url" />sort_by=from&amp;sort_type=<xsl:choose>
              <xsl:when test="($sort_by = 'from') and ($sort_type = 'ascending')">descending</xsl:when>
              <xsl:otherwise>ascending</xsl:otherwise>
            </xsl:choose></xsl:variable>
            <a href="{$sendersorturl}">
              <xsl:choose>
                <xsl:when test="($folder = $sent_items) or ($folder = $drafts)">
                  <xsl:copy-of select="/cp/strings/wm_messages_to" />
                </xsl:when>
                <xsl:otherwise><xsl:copy-of select="/cp/strings/wm_messages_from" /></xsl:otherwise>
              </xsl:choose>
            </a>&#160;<a href="{$sendersorturl}">
              <xsl:if test="$sort_by = 'from'">
                <xsl:choose>
                  <xsl:when test="$sort_type = 'ascending'"><img src="{/cp/strings/img_sortarrowdown}" border="0" /></xsl:when>
                  <xsl:when test="$sort_type = 'descending'"><img src="{/cp/strings/img_sortarrowup}" border="0" /></xsl:when>
                </xsl:choose>
              </xsl:if>
            </a>
          </td>
          <!-- Subject header row (sortable) -->
          <td class="subjectcolumn">
            <xsl:variable name="subjectsorturl"><xsl:value-of select="$basic_sort_url" />sort_by=subject&amp;sort_type=<xsl:choose>
              <xsl:when test="($sort_by = 'subject') and ($sort_type = 'ascending')">descending</xsl:when>
              <xsl:otherwise>ascending</xsl:otherwise>
            </xsl:choose></xsl:variable>
            <a href="{$subjectsorturl}">
              <xsl:value-of select="/cp/strings/wm_messages_subject" />
            </a>&#160;<a href="{$subjectsorturl}">
              <xsl:if test="$sort_by = 'subject'">
                <xsl:choose>
                  <xsl:when test="$sort_type = 'ascending'"><img src="{/cp/strings/img_sortarrowdown}" border="0" /></xsl:when>
                  <xsl:when test="$sort_type = 'descending'"><img src="{/cp/strings/img_sortarrowup}" border="0" /></xsl:when>
                </xsl:choose>
              </xsl:if>
            </a>
          </td>
          <!-- date header row (sortable) -->
          <td class="datecolumn">
            <xsl:variable name="datesorturl"><xsl:value-of select="$basic_sort_url" />sort_by=date&amp;sort_type=<xsl:choose>
              <xsl:when test="($sort_by = 'date') and ($sort_type = 'ascending')">descending</xsl:when>
              <xsl:otherwise>ascending</xsl:otherwise>
            </xsl:choose></xsl:variable>
            <a href="{$datesorturl}">
              <xsl:value-of select="/cp/strings/wm_messages_date" />
            </a>&#160;<a href="{$datesorturl}">
              <xsl:if test="$sort_by='date'">
                <xsl:choose>
                  <xsl:when test="$sort_type = 'ascending'"><img src="{/cp/strings/img_sortarrowdown}" border="0" /></xsl:when>
                  <xsl:when test="$sort_type = 'descending'"><img src="{/cp/strings/img_sortarrowup}" border="0" /></xsl:when>
                </xsl:choose>
              </xsl:if>
            </a>
          </td>
          <!-- size header row (sortable) -->
          <td>
            <xsl:variable name="sizesorturl"><xsl:value-of select="$basic_sort_url" />sort_by=size&amp;sort_type=<xsl:choose>
              <xsl:when test="($sort_by = 'size') and ($sort_type = 'ascending')">descending</xsl:when>
              <xsl:otherwise>ascending</xsl:otherwise>
            </xsl:choose></xsl:variable>
            <a href="{$sizesorturl}">
              <xsl:value-of select="/cp/strings/wm_messages_size" />
            </a>&#160;<a href="{$sizesorturl}">
              <xsl:if test="$sort_by = 'size'">
                <xsl:choose>
                  <xsl:when test="$sort_type = 'ascending'"><img src="{/cp/strings/img_sortarrowdown}" border="0" /></xsl:when>
                  <xsl:when test="$sort_type = 'descending'"><img src="{/cp/strings/img_sortarrowup}" border="0" /></xsl:when>
                </xsl:choose>
              </xsl:if>
            </a>
          </td>
        </tr>

        <!-- show all the messages now -->
        <xsl:apply-templates select="/cp/vsap/vsap[@type='webmail:messages:list']/message" />

        <!-- empty box message -->
        <xsl:if test="count(/cp/vsap/vsap[@type='webmail:messages:list']/message) = 0">
          <tr class="roweven">
            <td colspan="6">
              <strong>
                <xsl:choose>
                  <xsl:when test="$folder = $trash">
                    <xsl:copy-of select="/cp/strings/wm_messages_trash_empty" />
                  </xsl:when>
                  <xsl:when test="$folder = $inbox">
                    <xsl:copy-of select="/cp/strings/wm_messages_inbox_empty" />
                  </xsl:when>
                  <xsl:when test="$folder = $sent_items">
                    <xsl:copy-of select="/cp/strings/wm_messages_sent_empty" />
                  </xsl:when>
                  <xsl:when test="$folder = $drafts">
                    <xsl:copy-of select="/cp/strings/wm_messages_drafts_empty" />
                  </xsl:when>
                  <xsl:when test="$folder = $quarantine">
                    <xsl:copy-of select="/cp/strings/wm_messages_quarantine_empty" />
                  </xsl:when>
                  <xsl:when test="$folder = $junk">
                    <xsl:copy-of select="/cp/strings/wm_messages_junk_empty" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:copy-of select="/cp/strings/wm_messages_empty1" />
                    <xsl:value-of select="$disp_folder" />
                    <xsl:copy-of select="/cp/strings/wm_messages_empty2" />
                  </xsl:otherwise>
                </xsl:choose>
              </strong>
            </td>
          </tr>
        </xsl:if>

        <tr class="controlrow">
          <xsl:copy-of select="$controlrow" />
        </tr>
      </table>

</xsl:template>

</xsl:stylesheet>
