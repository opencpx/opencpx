<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="mail_global.xsl" />

<xsl:variable name="folder"><xsl:value-of select="/cp/vsap/vsap[@type='webmail:messages:read']/folder" /></xsl:variable>

<xsl:variable name="folder_url">
  <xsl:choose>
    <xsl:when test="$folder = $inbox">INBOX</xsl:when>
    <xsl:otherwise><xsl:value-of select="/cp/vsap/vsap[@type='webmail:folders:list']/folder[name=$folder]/url_name" /></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="sort_by"><xsl:value-of select="/cp/form/sort_by" /></xsl:variable>
<xsl:variable name="sort_type"><xsl:value-of select="/cp/form/sort_type" /></xsl:variable>
<xsl:variable name="viewpref"><xsl:value-of select="/cp/form/viewpref" /></xsl:variable>
<xsl:variable name="uid"><xsl:value-of select="/cp/vsap/vsap[@type='webmail:messages:read']/uid" /></xsl:variable>

<xsl:variable name="msg_x_of_x">
  <xsl:value-of select="/cp/strings/wm_viewmessage_message" />
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='webmail:messages:read']/position"><xsl:value-of select="/cp/vsap/vsap[@type='webmail:messages:read']/position" /></xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='webmail:messages:read']/msgno"><xsl:value-of select="/cp/vsap/vsap[@type='webmail:messages:read']/msgno" /></xsl:when>
    <xsl:otherwise><xsl:value-of select="/cp/form/msgno" /></xsl:otherwise>
  </xsl:choose>
  <xsl:value-of select="/cp/strings/wm_viewmessage_of" /><xsl:value-of select="/cp/vsap/vsap/num_messages" />
</xsl:variable>

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

<xsl:template match="/">
  <xsl:variable name="current_nv">
    <xsl:choose>
      <xsl:when test="(/cp/form/folder = $inbox) or ($folder = $inbox)">
        <xsl:value-of select="/cp/strings/nv_inbox" />
      </xsl:when>
      <xsl:when test="(/cp/form/folder = $drafts)">
        <xsl:value-of select="/cp/strings/nv_drafts" />
      </xsl:when>
      <xsl:when test="(/cp/form/folder = $sent_items)">
        <xsl:value-of select="/cp/strings/nv_sent" />
      </xsl:when>
      <xsl:when test="(/cp/form/folder = $trash)">
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
        <xsl:value-of select="/cp/form/folder" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="subject_subtitle">
    <xsl:choose>
      <xsl:when test="string-length(/cp/vsap/vsap[@type='webmail:messages:read']/subject) > 0">
        <xsl:value-of select="/cp/vsap/vsap[@type='webmail:messages:read']/subject" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="/cp/strings/wm_viewmessage_nosubject" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title"><xsl:copy-of select="/cp/strings/wm_title" /> : <xsl:copy-of select="$subtitle"/> : <xsl:copy-of select="$subject_subtitle"/></xsl:with-param>
    <xsl:with-param name="formaction">wm_viewmessage.xsl</xsl:with-param>
    <xsl:with-param name="feedback" select="$feedback" />
    <xsl:with-param name="selected_navandcontent" select="$current_nv" />
    <xsl:with-param name="help_short" select="/cp/strings/wm_viewmessage_hlp_short" />
    <xsl:with-param name="help_long" select="/cp/strings/wm_viewmessage_hlp_long" />
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
                <xsl:value-of select="/cp/form/folder" />
              </xsl:otherwise>
            </xsl:choose>
          </name>
          <url><xsl:value-of select="$base_url" />/mail/wm_messages.xsl?folder=<xsl:value-of select="$folder_url" /></url>
        </section>
        <section>
          <name>
            <xsl:value-of select="/cp/strings/wm_viewmessage_bc_1" />
            <xsl:choose>
              <xsl:when test="/cp/vsap/vsap[@type='webmail:messages:read']/position"><xsl:value-of select="/cp/vsap/vsap[@type='webmail:messages:read']/position" /></xsl:when>
              <xsl:when test="/cp/vsap/vsap[@type='webmail:messages:read']/msgno"><xsl:value-of select="/cp/vsap/vsap[@type='webmail:messages:read']/msgno" /></xsl:when>
              <xsl:otherwise><xsl:value-of select="/cp/form/msgno" /></xsl:otherwise>
            </xsl:choose>
            <xsl:value-of select="/cp/strings/wm_viewmessage_bc_2" />
            <xsl:value-of select="/cp/vsap/vsap/num_messages" />
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

      <input type="hidden" name="folder" value="{/cp/vsap/vsap/folder}" />
      <input type="hidden" name="num_messages" value="{/cp/vsap/vsap/num_messages}" />
      <input type="hidden" name="sort_by" value="{$sort_by}" />
      <input type="hidden" name="sort_type" value="{$sort_type}" />
      <input type="hidden" name="goback" value="mail/wm_viewmessage.xsl" />
      <input type="hidden" name="uid" value="{$uid}" />
      <input type="hidden" name="next_uid" value="{/cp/vsap/vsap/next_uid}" />
      <input type="hidden" name="mailitem" value="{$uid}" />
      <input type="hidden" name="msgno" value="{/cp/vsap/vsap[@type='webmail:messages:read']/msgno}" />
      <input type="hidden" name="move" />
      <input type="hidden" name="quote" value="{/cp/strings/wm_viewmessage_quote}" />

      <table class="formview" border="0" cellspacing="0" cellpadding="0">
        <tr class="title">
          <td colspan="2">
            <span class="floatright">
              <xsl:choose>
                <xsl:when test='string-length(/cp/vsap/vsap/prev_uid) > 0'>
                  <a href="{$base_url}/mail/wm_viewmessage.xsl?uid={/cp/vsap/vsap/prev_uid}&amp;folder={$folder_url}&amp;sort_by={$sort_by}&amp;sort_type={$sort_type}"><xsl:value-of select="/cp/strings/wm_viewmessage_prev" /></a>
                </xsl:when>
                <xsl:when test='string-length(/cp/vsap/vsap/prev_msgno) > 0'>
                  <a href="{$base_url}/mail/wm_viewmessage.xsl?msgno={/cp/vsap/vsap/prev_msgno}&amp;folder={$folder_url}&amp;sort_by={$sort_by}&amp;sort_type={$sort_type}"><xsl:value-of select="/cp/strings/wm_viewmessage_prev" /></a>
                </xsl:when>
                <xsl:otherwise>
                  <span class="inactive"><xsl:copy-of select="/cp/strings/wm_viewmessage_prev" /></span>
                </xsl:otherwise>
              </xsl:choose>
              <xsl:copy-of select="/cp/strings/wm_viewmessage_bar" />
              <xsl:choose>
                <xsl:when test='string-length(/cp/vsap/vsap/next_uid) > 0'>
                  <a href="{$base_url}/mail/wm_viewmessage.xsl?uid={/cp/vsap/vsap/next_uid}&amp;folder={$folder_url}&amp;sort_by={$sort_by}&amp;sort_type={$sort_type}"><xsl:copy-of select="/cp/strings/wm_viewmessage_next" /></a>
                </xsl:when>
                <xsl:when test='string-length(/cp/vsap/vsap/next_msgno) > 0'>
                  <a href="{$base_url}/mail/wm_viewmessage.xsl?msgno={/cp/vsap/vsap/next_msgno}&amp;folder={$folder_url}&amp;sort_by={$sort_by}&amp;sort_type={$sort_type}"><xsl:copy-of select="/cp/strings/wm_viewmessage_next" /></a>
                </xsl:when>
                <xsl:otherwise>
                  <span class="inactive"><xsl:copy-of select="/cp/strings/wm_viewmessage_next" /></span>
                </xsl:otherwise>
              </xsl:choose>
            </span>
            <xsl:value-of select="/cp/strings/wm_viewmessage_title_1" />
            <xsl:choose>
              <xsl:when test="/cp/vsap/vsap[@type='webmail:messages:read']/position"><xsl:value-of select="/cp/vsap/vsap[@type='webmail:messages:read']/position" /></xsl:when>
              <xsl:when test="/cp/vsap/vsap[@type='webmail:messages:read']/msgno"><xsl:value-of select="/cp/vsap/vsap[@type='webmail:messages:read']/msgno" /></xsl:when>
              <xsl:otherwise><xsl:value-of select="/cp/form/msgno" /></xsl:otherwise>
            </xsl:choose>
            <xsl:value-of select="/cp/strings/wm_viewmessage_title_2" />
            <xsl:value-of select="/cp/vsap/vsap/num_messages" />
          </td>
        </tr>
        <tr class="controlrow">
          <td colspan="2">
            <span class="floatright">
              <input type="submit" name="reply" value="{/cp/strings/wm_viewmessage_btn_reply}" />
              <input type="submit" name="reply_all" value="{/cp/strings/wm_viewmessage_btn_replyall}" />
              <input type="submit" name="forward" value="{/cp/strings/wm_viewmessage_btn_forward}" />
            </span>

            <input type="submit" name="delete" value="{/cp/strings/wm_messages_bt_delete}" />
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
            <input type="button" name="selectmove" value="{/cp/strings/wm_messages_bt_move}" onClick="submitMoveMail(0, '{cp:js-escape(/cp/strings/wm_messages_msg_select_folder)}');" />
          </td>
        </tr>
        <tr class="messagerow">
          <td colspan="2" >
            <span class="floatright">
              <a href="{concat($base_url, '/mail/wm_rawmessage.xsl?uid=',$uid,'&amp;folder=',$folder_url)}"
                 target="_blank"><xsl:value-of select="/cp/strings/wm_viewmessage_raw" /></a>
              <xsl:value-of select="/cp/strings/wm_viewmessage_bar" />
              <a href="{concat($base_url, '/mail/wm_printmessage.xsl?uid=',$uid,'&amp;folder=',$folder_url)}"
                 target="_blank"><xsl:value-of select="/cp/strings/wm_viewmessage_print" /></a>
            </span>
          </td>
        </tr>
        <!-- From -->
        <tr class="messagerow">
          <td class="messagelabel">
            <xsl:value-of select="/cp/strings/wm_viewmessage_from" /> <br />
          </td>
          <td class="contentwidth">
            <xsl:value-of select="/cp/vsap/vsap[@type='webmail:messages:read']/from/address/personal" />
            &lt;<a href="{concat('wm_compose.xsl?to=',/cp/vsap/vsap[@type='webmail:messages:read']/from/address/full)}">
              <xsl:value-of select="/cp/vsap/vsap[@type='webmail:messages:read']/from/address/full" />
            </a>&gt;
            <br />
          </td>
        </tr>
        <!-- To -->
        <tr class="messagerow">
          <td class="messagelabel">
            <xsl:value-of select="/cp/strings/wm_viewmessage_to" /> <br />
          </td>
          <td class="contentwidth">
            <xsl:for-each select="/cp/vsap/vsap[@type='webmail:messages:read']/to/address">
              <xsl:value-of select="personal" />
              &lt;<a href="wm_compose.xsl?to={full}"><xsl:value-of select="full" /></a>&gt;
              <br />
            </xsl:for-each>
            <xsl:if test="not(/cp/vsap/vsap[@type='webmail:messages:read']/to/address)">
              <br />
            </xsl:if>
          </td>
        </tr>
        <!-- Cc -->
        <tr class="messagerow">
          <td class="messagelabel">
            <xsl:value-of select="/cp/strings/wm_viewmessage_cc" /> <br />
          </td>
          <td class="contentwidth">
            <xsl:for-each select="/cp/vsap/vsap[@type='webmail:messages:read']/cc/address">
              <xsl:value-of select="personal" />
              &lt;<a href="wm_compose.xsl?to={full}"><xsl:value-of select="full" /></a>&gt;
              <br />
            </xsl:for-each>
            <xsl:if test="not(/cp/vsap/vsap[@type='webmail:messages:read']/cc/address)">
              <br />
            </xsl:if>
          </td>
        </tr>
        <!-- Subject -->
        <tr class="messagerow">
          <td class="messagelabel">
            <xsl:value-of select="/cp/strings/wm_viewmessage_subject" /> <br />
          </td>
          <td class="contentwidth">
            <xsl:choose>
              <xsl:when test="string-length(/cp/vsap/vsap[@type='webmail:messages:read']/subject) > 0">
                <xsl:value-of select="/cp/vsap/vsap[@type='webmail:messages:read']/subject" />
              </xsl:when>
              <xsl:otherwise>
                <xsl:copy-of select="/cp/strings/wm_viewmessage_nosubject" />
              </xsl:otherwise>
            </xsl:choose>
            <br />
          </td>
        </tr>
        <!-- Date -->
        <tr class="messagerow">
          <td class="messagelabel">
            <xsl:value-of select="/cp/strings/wm_viewmessage_date" /> <br />
          </td>
          <td class="contentwidth">
            <xsl:call-template name="format-date">
              <xsl:with-param name="date" select="/cp/vsap/vsap[@type='webmail:messages:read']/date" />
            </xsl:call-template>
            <br />
          </td>
        </tr>
        <!-- Time -->
        <tr class="messagerow">
          <td class="messagelabel">
            <xsl:value-of select="/cp/strings/wm_viewmessage_time" /> <br />
          </td>
          <td class="contentwidth">
            <xsl:call-template name="format-time">
              <xsl:with-param name="date" select="/cp/vsap/vsap[@type='webmail:messages:read']/date" />
              <xsl:with-param name="type">short</xsl:with-param>
            </xsl:call-template>
            <br />
          </td>
        </tr>
        <!-- Attachments -->
        <tr class="messagerow">
          <td class="messagelabel">
            <xsl:value-of select="/cp/strings/wm_viewmessage_attachments" />
          </td>
          <td class="contentwidth">
            <xsl:choose>
              <xsl:when test="count(/cp/vsap/vsap[@type='webmail:messages:read']/attachments/attachment) > 0">
                <xsl:for-each select="/cp/vsap/vsap[@type='webmail:messages:read']/attachments/attachment">
                  <img src="{/cp/strings/wm_img_attachment}" alt="" border="0" />
                  <xsl:variable name="attach_id"><xsl:value-of select="attach_id" /></xsl:variable>
                  <a href="wm_viewmessage.xsl/VSAPDOWNLOAD/{url_name}?uid={$uid}&amp;attach_id={$attach_id}&amp;folder={$folder_url}&amp;download=true&amp;clientencoding={/cp/vsap/vsap[@type='webmail:options:load']/webmail_options/display_encoding}" target="_blank">
                    <xsl:value-of select="name" />
                  </a>
                  <xsl:if test="position() != last()"><xsl:value-of select="/cp/strings/wm_viewmessage_comma" /></xsl:if>
                </xsl:for-each>
              </xsl:when>
              <xsl:otherwise>
                <xsl:copy-of select="/cp/strings/wm_viewmessage_no_attachments" />
              </xsl:otherwise>
            </xsl:choose>
            <input type="hidden" name="total_attachments" value="{count(/cp/vsap/vsap[@type='webmail:messages:read']/attachments/attachment)}" />
          </td>
        </tr>
        <!-- encoding prompt -->
        <tr class="controlrow">
          <td colspan="2">
            <span class="floatright">
              <span class="nonstatus"><xsl:copy-of select="/cp/strings/wm_viewmessage_other_encoding" /></span>
              <select name="try_encoding" size="1" onChange="document.forms[0].submit()">
                <option value=""><xsl:copy-of select="/cp/strings/wm_viewmessage_prompt_encoding" /></option>
                <option value="UTF-8">
                  <xsl:if test="/cp/form/try_encoding = 'UTF-8'"><xsl:attribute name="selected">true</xsl:attribute></xsl:if>
                  <xsl:copy-of select="/cp/strings/wm_enc_UTF-8" />
                </option>
                <option value="US-ASCII">
                  <xsl:if test="/cp/form/try_encoding = 'US-ASCII'"><xsl:attribute name="selected">true</xsl:attribute></xsl:if>
                  <xsl:copy-of select="/cp/strings/wm_enc_US-ASCII" />
                </option>
                <option value="ISO-2022-JP">
                  <xsl:if test="/cp/form/try_encoding = 'ISO-2022-JP'"><xsl:attribute name="selected">true</xsl:attribute></xsl:if>
                  <xsl:copy-of select="/cp/strings/wm_enc_ISO-2022-JP" />
                </option>
                <option value="ISO-8859-1">
                  <xsl:if test="/cp/form/try_encoding = 'ISO-8859-1'"><xsl:attribute name="selected">true</xsl:attribute></xsl:if>
                  <xsl:copy-of select="/cp/strings/wm_enc_ISO-8859-1" />
                </option>
              </select>
            </span>

            <!-- alternative message view parts -->
            <xsl:if test="/cp/vsap/vsap[@type='webmail:messages:read']/alt_parts">
              <xsl:value-of select="/cp/strings/wm_viewmessage_alt_title" />
              <xsl:for-each select="/cp/vsap/vsap[@type='webmail:messages:read']/alt_parts/alt">
                <xsl:variable name="alt"><xsl:value-of select="." /></xsl:variable>
                <xsl:choose>
                  <xsl:when test="/cp/vsap/vsap[@type='webmail:messages:read']/alt_view != $alt">
                   <a href="wm_viewmessage.xsl?uid={$uid}&amp;folder={$folder_url}&amp;sort_by={$sort_by}&amp;sort_type={$sort_type}&amp;viewpref={$alt}"><xsl:value-of select="/cp/strings/*[local-name() = concat('wm_viewmessage_alt_', $alt)]" /></a>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="/cp/strings/*[local-name() = concat('wm_viewmessage_alt_', $alt)]" />
                  </xsl:otherwise>
                </xsl:choose>
                <xsl:if test="position() != last()"><xsl:value-of select="/cp/strings/wm_viewmessage_bar" /></xsl:if>
              </xsl:for-each>
            </xsl:if>

            <!-- image viewing -->
            <xsl:variable name="img_emb">
              <xsl:value-of select="/cp/vsap/vsap[@type='webmail:messages:read']/localimages" />
            </xsl:variable>

            <xsl:variable name="img_rem">
              <xsl:value-of select="/cp/vsap/vsap[@type='webmail:messages:read']/remoteimages" />
            </xsl:variable>

            <xsl:if test="/cp/vsap/vsap[@type='webmail:messages:read']/has_local_images = 'yes'">
              <xsl:if test="/cp/vsap/vsap[@type='webmail:messages:read']/alt_parts">
                <br />
              </xsl:if>
                
              <xsl:value-of select="/cp/strings/wm_viewmessage_img_emb_title" />
              <xsl:choose>
                <xsl:when test="$img_emb = 'yes'">
                  <xsl:value-of select="/cp/strings/wm_viewmessage_img_show" />
                  <xsl:value-of select="/cp/strings/wm_viewmessage_bar" />
                  <a href="wm_viewmessage.xsl?uid={$uid}&amp;folder={$folder_url}&amp;sort_by={$sort_by}&amp;sort_type={$sort_type}&amp;localimages=no&amp;remoteimages={$img_rem}&amp;viewpref={$viewpref}"><xsl:value-of select="/cp/strings/wm_viewmessage_img_hide" /></a>
                </xsl:when>
                <xsl:otherwise>
                  <a href="wm_viewmessage.xsl?uid={$uid}&amp;folder={$folder_url}&amp;sort_by={$sort_by}&amp;sort_type={$sort_type}&amp;localimages=yes&amp;remoteimages={$img_rem}&amp;viewpref={$viewpref}"><xsl:value-of select="/cp/strings/wm_viewmessage_img_show" /></a>
                  <xsl:value-of select="/cp/strings/wm_viewmessage_bar" />
                  <xsl:value-of select="/cp/strings/wm_viewmessage_img_hide" />
                </xsl:otherwise>
              </xsl:choose>
            </xsl:if>

            <xsl:if test="/cp/vsap/vsap[@type='webmail:messages:read']/has_remote_images = 'yes'">
              <xsl:if test="count(/cp/vsap/vsap[@type='webmail:messages:read']/alt_parts) > 0 or /cp/vsap/vsap[@type='webmail:messages:read']/has_local_images = 'yes'">
                <br />
              </xsl:if>
              <xsl:value-of select="/cp/strings/wm_viewmessage_img_rem_title" />
              <xsl:choose>
                <xsl:when test="$img_rem = 'yes'">
                  <xsl:value-of select="/cp/strings/wm_viewmessage_img_show" />
                  <xsl:value-of select="/cp/strings/wm_viewmessage_bar" />
                  <a href="wm_viewmessage.xsl?uid={$uid}&amp;folder={$folder_url}&amp;sort_by={$sort_by}&amp;sort_type={$sort_type}&amp;localimages={$img_emb}&amp;remoteimages=no&amp;viewpref={$viewpref}"><xsl:value-of select="/cp/strings/wm_viewmessage_img_hide" /></a>
                </xsl:when>
                <xsl:otherwise>
                  <a href="wm_viewmessage.xsl?uid={$uid}&amp;folder={$folder_url}&amp;sort_by={$sort_by}&amp;sort_type={$sort_type}&amp;localimages={$img_emb}&amp;remoteimages=yes&amp;viewpref={$viewpref}"><xsl:value-of select="/cp/strings/wm_viewmessage_img_show" /></a>
                  <xsl:value-of select="/cp/strings/wm_viewmessage_bar" />
                  <xsl:value-of select="/cp/strings/wm_viewmessage_img_hide" />
                </xsl:otherwise>
              </xsl:choose>
            </xsl:if>

          </td>
        </tr>

        <!-- Message Body -->
        <tr class="messagerow">
          <td class="message" colspan="2">
            <cp-unescape><xsl:value-of select="/cp/vsap/vsap[@type='webmail:messages:read']/body" /></cp-unescape>
          </td>
        </tr>

        <tr class="controlrow">
          <td colspan="2">
            <span class="floatright">
              <input type="submit" name="reply" value="{/cp/strings/wm_viewmessage_btn_reply}" />
              <input type="submit" name="reply_all" value="{/cp/strings/wm_viewmessage_btn_replyall}" />
              <input type="submit" name="forward" value="{/cp/strings/wm_viewmessage_btn_forward}" />
            </span>

            <input type="submit" name="delete" value="{/cp/strings/wm_messages_bt_delete}" />
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
            <input type="button" name="selectmove" value="{/cp/strings/wm_messages_bt_move}" onClick="submitMoveMail(0, '{cp:js-escape(/cp/strings/wm_messages_msg_select_folder)}');" />
          </td>
        </tr>
      </table>

</xsl:template>

</xsl:stylesheet>
