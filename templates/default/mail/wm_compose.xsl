<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="mail_global.xsl" />
<xsl:import href="mail_compose_feedback.xsl" />

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

<!-- test for ie browser -->
<xsl:variable name="ie_browser">
  <xsl:choose>
    <xsl:when test="contains(/cp/request/user_agent,'MSIE')">1</xsl:when>
    <xsl:otherwise>0</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<!-- save fields if arrived from viewmessage -->
<xsl:variable name="folder">
  <xsl:choose>
    <xsl:when test="string(/cp/vsap/vsap[@type='webmail:messages:read']/folder)">
      <xsl:value-of select="/cp/vsap/vsap[@type='webmail:messages:read']/folder" />
    </xsl:when>
    <xsl:when test="string(/cp/form/folder)">
      <xsl:value-of select="/cp/form/folder" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="bc_title">
  <xsl:choose>
    <xsl:when test="string(cp/form/reply)">
      <xsl:value-of select="/cp/strings/bc_wm_compose_reply" />
    </xsl:when>
    <xsl:when test="string(cp/form/reply_all)">
      <xsl:value-of select="/cp/strings/bc_wm_compose_replyall" />
    </xsl:when>
    <xsl:when test="string(cp/form/forward)">
      <xsl:value-of select="/cp/strings/bc_wm_compose_forward" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="/cp/strings/bc_wm_compose" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="goback">
  <xsl:choose>
    <xsl:when test="string(/cp/form/goback)">
      <xsl:value-of select="/cp/form/goback" />
    </xsl:when>
    <xsl:otherwise>mail/wm_messages.xsl</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="uid">
  <xsl:choose>
    <xsl:when test="string(/cp/vsap/vsap[@type='webmail:messages:read']/uid)">
      <xsl:value-of select="/cp/vsap/vsap[@type='webmail:messages:read']/uid" />
    </xsl:when>
    <xsl:when test="string(/cp/form/uid)">
      <xsl:value-of select="/cp/form/uid" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="mailitem">
  <xsl:choose>
    <xsl:when test="string(/cp/form/mailitem)">
      <xsl:value-of select="/cp/form/mailitem" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="msgno">
  <xsl:choose>
    <xsl:when test="string(/cp/form/msgno)">
      <xsl:value-of select="/cp/form/msgno" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="draftid">
  <xsl:choose>
    <xsl:when test="string(/cp/form/draftid)">
      <xsl:value-of select="/cp/form/draftid" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="try_encoding">
  <xsl:choose>
    <xsl:when test="string(/cp/form/try_encoding)">
      <xsl:value-of select="/cp/form/try_encoding" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="forward_source">
  <xsl:choose>
    <xsl:when test="string(/cp/form/forward)">1</xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="to_addrs">
  <xsl:choose>
    <xsl:when test="/cp/form/folder='Drafts'">
      <xsl:choose>
        <xsl:when test="string(/cp/form/txtToName)">
          <xsl:value-of select="/cp/form/txtToName" />
        </xsl:when>
        <xsl:when test="string(/cp/form/to)">
          <xsl:value-of select="/cp/form/to" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:for-each select="/cp/vsap/vsap[@type='webmail:messages:read']/to/address">
            <xsl:variable name="email_addr"> 
              <xsl:call-template name="format_addr">
                <xsl:with-param name="personal" select="personal" />
                <xsl:with-param name="full" select="full" />
              </xsl:call-template>
            </xsl:variable>
            <xsl:if test="$email_addr != ''">
              <xsl:if test="position() != '1'">, </xsl:if>
              <xsl:value-of select="$email_addr" />
            </xsl:if>
          </xsl:for-each>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>

    <xsl:when test="string(/cp/form/reply)">
      <xsl:choose>
        <xsl:when test="string(/cp/vsap/vsap[@type='webmail:messages:read']/reply_to/address/full) != ''">
          <xsl:call-template name="format_addr">
            <xsl:with-param name="personal" select="/cp/vsap/vsap[@type='webmail:messages:read']/reply_to/address/personal" />
            <xsl:with-param name="full" select="/cp/vsap/vsap[@type='webmail:messages:read']/reply_to/address/full" />
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="format_addr">
            <xsl:with-param name="personal" select="/cp/vsap/vsap[@type='webmail:messages:read']/from/address/personal" />
            <xsl:with-param name="full" select="/cp/vsap/vsap[@type='webmail:messages:read']/from/address/full" />
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>

    <xsl:when test="string(/cp/vsap/vsap[@type='webmail:messages:read']/from) and not(/cp/form/forward)">
      <xsl:call-template name="format_addr">
        <xsl:with-param name="personal" select="/cp/vsap/vsap[@type='webmail:messages:read']/from/address/personal" />
        <xsl:with-param name="full" select="/cp/vsap/vsap[@type='webmail:messages:read']/from/address/full" />
      </xsl:call-template>
      <xsl:if test="count(/cp/vsap/vsap[@type='webmail:messages:read']/to/address) > 0 and string(/cp/form/reply_all)">
        <xsl:for-each select="/cp/vsap/vsap[@type='webmail:messages:read']/to/address">
          <xsl:variable name="email_addr"> 
            <xsl:call-template name="format_addr">
              <xsl:with-param name="personal" select="personal" />
              <xsl:with-param name="full" select="full" />
            </xsl:call-template>
          </xsl:variable>
          <xsl:if test="$email_addr != ''">
            <xsl:value-of select="concat(', ',$email_addr)" />
          </xsl:if>
        </xsl:for-each>
      </xsl:if>
    </xsl:when>
    <xsl:when test="string(/cp/form/txtToName)">
      <xsl:value-of select="/cp/form/txtToName" />
    </xsl:when>
    <xsl:when test="string(/cp/form/to)">
      <xsl:value-of select="/cp/form/to" />
    </xsl:when>
    <xsl:when test="string(/cp/form/listid)">
      <xsl:for-each select="/cp/vsap/vsap[@type='webmail:distlist:list']/distlist/entries/entry/address">
        <xsl:value-of select="." />
        <xsl:if test="position() != last()">, </xsl:if>
      </xsl:for-each>  
    </xsl:when>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="forward_to_addrs">
  <xsl:choose>
    <xsl:when test="string(/cp/form/forward)">
      <xsl:for-each select="/cp/vsap/vsap[@type='webmail:messages:read']/to/address">
        <xsl:variable name="email_addr"> 
          <xsl:call-template name="format_addr">
            <xsl:with-param name="personal" select="personal" />
            <xsl:with-param name="full" select="full" />
          </xsl:call-template>
        </xsl:variable>
        <xsl:if test="$email_addr != ''">
          <xsl:if test="position() != '1'">, </xsl:if>
          <xsl:value-of select="$email_addr" />
        </xsl:if>
      </xsl:for-each>
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="from_name">
  <xsl:choose>
    <xsl:when test="string(/cp/form/txtFromName)">
      <xsl:value-of select="/cp/form/txtFromName" />
    </xsl:when>
    <xsl:when test="/cp/form/draftid">
      <xsl:choose>
        <xsl:when test="string(/cp/vsap/vsap[@type='webmail:messages:read']/from/address/personal)">
          <xsl:value-of select="/cp/vsap/vsap[@type='webmail:messages:read']/from/address/personal" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="/cp/vsap/vsap[@type='webmail:messages:read']/from/address/mailbox" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:when test="string(/cp/vsap/vsap[@type='webmail:options:load']/webmail_options/from_name)">
       <xsl:value-of select="/cp/vsap/vsap[@type='webmail:options:load']/webmail_options/from_name" />
    </xsl:when>
    <xsl:otherwise><xsl:value-of select="/cp/vsap/vsap[@type='user:properties']/user/fullname" /></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="forward_from">
  <xsl:choose>
    <xsl:when test="string(/cp/form/forward)">
          <xsl:call-template name="format_addr">
            <xsl:with-param name="personal" select="/cp/vsap/vsap[@type='webmail:messages:read']/from/address/personal" />
            <xsl:with-param name="full" select="/cp/vsap/vsap[@type='webmail:messages:read']/from/address/full" />
          </xsl:call-template>
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="default_mailbox">
  <xsl:value-of select="/cp/vsap/vsap[@type='auth']/username" />@<xsl:value-of select="/cp/vsap/vsap[@type='user:properties']/user/domain"/>
</xsl:variable>

<xsl:variable name="preferred_email">
  <xsl:choose>
    <xsl:when test="/cp/form/txtFromName">
      <xsl:value-of select="/cp/form/txtFromName" />
    </xsl:when>
    <xsl:when test="string(/cp/vsap/vsap[@type='webmail:options:load']/webmail_options/preferred_from)">
      <xsl:value-of select="/cp/vsap/vsap[@type='webmail:options:load']/webmail_options/preferred_from" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$default_mailbox" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="replyto">
  <xsl:value-of select="/cp/vsap/vsap[@type='webmail:options:load']/webmail_options/reply_to" />
</xsl:variable>

<xsl:variable name="cc">
  <xsl:choose>
    <xsl:when test="/cp/form/folder='Drafts'">
      <xsl:for-each select="/cp/vsap/vsap[@type='webmail:messages:read']/cc/address">
        <xsl:variable name="email_addr"> 
          <xsl:call-template name="format_addr">
            <xsl:with-param name="personal" select="personal" />
            <xsl:with-param name="full" select="full" />
          </xsl:call-template>
        </xsl:variable>
        <xsl:if test="$email_addr != ''">
          <xsl:if test="position() != '1'">, </xsl:if>
          <xsl:value-of select="$email_addr" />
        </xsl:if>
      </xsl:for-each>
    </xsl:when>

    <xsl:when test="count(/cp/vsap/vsap[@type='webmail:messages:read']/cc/address) > 0 and string(/cp/form/reply_all)">
      <xsl:for-each select="/cp/vsap/vsap[@type='webmail:messages:read']/cc/address">
        <xsl:variable name="email_addr"> 
          <xsl:call-template name="format_addr">
            <xsl:with-param name="personal" select="personal" />
            <xsl:with-param name="full" select="full" />
          </xsl:call-template>
        </xsl:variable>
        <xsl:if test="$email_addr != ''">
          <xsl:if test="position() != '1'">, </xsl:if>
          <xsl:value-of select="$email_addr" />
        </xsl:if>
      </xsl:for-each>
    </xsl:when>

    <xsl:when test="string(/cp/form/txtCcName)">
      <xsl:value-of select="/cp/form/txtCcName" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="forward_cc">
  <xsl:choose>
    <xsl:when test="string(/cp/form/forward)">
      <xsl:for-each select="/cp/vsap/vsap[@type='webmail:messages:read']/cc/address">
        <xsl:variable name="email_addr"> 
          <xsl:call-template name="format_addr">
            <xsl:with-param name="personal" select="personal" />
            <xsl:with-param name="full" select="full" />
          </xsl:call-template>
        </xsl:variable>
        <xsl:if test="$email_addr != ''">
          <xsl:if test="position() != '1'">, </xsl:if>
          <xsl:value-of select="$email_addr" />
        </xsl:if>
      </xsl:for-each>
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="bcc">
  <xsl:choose>
    <xsl:when test="/cp/form/folder='Drafts'">
      <xsl:for-each select="/cp/vsap/vsap[@type='webmail:messages:read']/bcc/address">
        <xsl:variable name="email_addr"> 
          <xsl:call-template name="format_addr">
            <xsl:with-param name="personal" select="personal" />
            <xsl:with-param name="full" select="full" />
          </xsl:call-template>
        </xsl:variable>
        <xsl:if test="$email_addr != ''">
          <xsl:if test="position() != '1'">, </xsl:if>
          <xsl:value-of select="$email_addr" />
        </xsl:if>
      </xsl:for-each>
    </xsl:when>
    <xsl:when test="string(/cp/form/txtBccName)">
      <xsl:value-of select="/cp/form/txtBccName" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="subject">
  <xsl:choose>
    <xsl:when test="string(/cp/vsap/vsap[@type='webmail:messages:read']/uid)">
      <xsl:choose>
        <xsl:when test="/cp/form/folder='Drafts'">
          <xsl:value-of select="/cp/vsap/vsap[@type='webmail:messages:read']/subject" />
        </xsl:when>
        <xsl:when test="string(/cp/form/forward)">
          <xsl:value-of select="concat('Fwd: ',/cp/vsap/vsap[@type='webmail:messages:read']/subject)" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:choose>
            <xsl:when test="starts-with(/cp/vsap/vsap[@type='webmail:messages:read']/subject,'Re:')">
              <xsl:value-of select="/cp/vsap/vsap[@type='webmail:messages:read']/subject" />
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="concat('Re: ',/cp/vsap/vsap[@type='webmail:messages:read']/subject)" />
            </xsl:otherwise>
          </xsl:choose>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:when test="string(/cp/form/subject)">
      <xsl:value-of select="/cp/form/subject" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="forward_subject">
  <xsl:choose>
    <xsl:when test="string(/cp/vsap/vsap[@type='webmail:messages:read']/uid)">
      <xsl:value-of select="/cp/vsap/vsap[@type='webmail:messages:read']/subject" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="messageid">
  <xsl:value-of select="/cp/vsap/vsap[@type='webmail:send:messageid']/messageid" />
</xsl:variable>

<xsl:variable name="attachments_display">
  <xsl:choose>
    <xsl:when test="/cp/form/folder='Drafts' or string(/cp/form/forward)">
      <xsl:choose>
        <xsl:when test="string(/cp/vsap/vsap[@type='webmail:send:attachment:list']/attachment)">
          <xsl:for-each select="/cp/vsap/vsap[@type='webmail:send:attachment:list']/attachment">
            <xsl:value-of select="filename" />
            <xsl:if test="position() != last()">
              <xsl:value-of select="concat(';',' ')" />
            </xsl:if>
          </xsl:for-each>
        </xsl:when>
        <xsl:when test="string(/cp/vsap/vsap[@type='webmail:messages:read']/attachments)">
          <xsl:for-each select="/cp/vsap/vsap[@type='webmail:messages:read']/attachments/attachment">
           <xsl:value-of select="concat(name,'; ')" />
          </xsl:for-each>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="cp/strings/wm_compose_attach_default" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="cp/strings/wm_compose_attach_default" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="attachments">
  <xsl:copy-of select="/cp/vsap/vsap[@type='webmail:messages:read']/attachments" />
</xsl:variable>

<xsl:variable name="skip">
  <xsl:text>&#013;&#010;</xsl:text>
</xsl:variable>

<xsl:variable name="include_sig">
  <xsl:choose>
    <xsl:when test="string(/cp/form/checkboxSig)">1</xsl:when>
    <xsl:when test="cp/vsap/vsap[@type='webmail:options:load']/webmail_options/signature_toggle='on'">1</xsl:when>
    <xsl:otherwise>0</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="signature">
  <xsl:choose>
    <xsl:when test="/cp/form/signature">
      <xsl:value-of select="/cp/form/signature" />
    </xsl:when>
    <xsl:when test="cp/vsap/vsap[@type='webmail:options:load']/webmail_options/signature">
      <xsl:call-template name="format_signature">
        <xsl:with-param name="signature" select="/cp/vsap/vsap[@type='webmail:options:load']/webmail_options/signature" />
        <xsl:with-param name="sig_mark" select="/cp/strings/wm_compose_signature_mark" />
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="sigexpValue">
  <xsl:choose>
    <xsl:when test="$ie_browser='1'">
      <xsl:value-of select="concat('&#13;',$signature)" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="concat('&#13;&#13;',$signature)" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="format_date">
  <xsl:choose>
    <xsl:when test="string(/cp/vsap/vsap[@type='webmail:messages:read']/uid)">
      <xsl:call-template name="format-date">
        <xsl:with-param name="date" select="/cp/vsap/vsap[@type='webmail:messages:read']/date" />
        <xsl:with-param name="type">long</xsl:with-param>
       </xsl:call-template>
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="format_time">
  <xsl:choose>
    <xsl:when test="string(/cp/vsap/vsap[@type='webmail:messages:read']/uid)">
      <xsl:call-template name="format-time">
        <xsl:with-param name="date" select="/cp/vsap/vsap[@type='webmail:messages:read']/date" />
        <xsl:with-param name="type">short</xsl:with-param>
       </xsl:call-template>
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="display_date">
  <xsl:choose>
    <xsl:when test="$format_date!='' and $format_time!=''">
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='user:prefs:load']/user_preferences/dt_order='date'">
          <xsl:value-of select="concat($format_date,' ',$format_time)" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="concat($format_time,' ',$format_date)" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="original_sender">
  <xsl:choose>
    <xsl:when test="string(/cp/vsap/vsap[@type='webmail:messages:read']/uid)">
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='webmail:messages:read']/from/address/personal!=''">
          <xsl:value-of select="/cp/vsap/vsap[@type='webmail:messages:read']/from/address/personal" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="/cp/vsap/vsap[@type='webmail:messages:read']/from/address/full" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>


<xsl:variable name="text_msg">
  <xsl:choose>
    <xsl:when test="string(/cp/form/body)">
      <xsl:value-of select="/cp/form/body" />
    </xsl:when>
    <xsl:when test="string(/cp/vsap/vsap[@type='webmail:messages:read']/uid)">
      <xsl:if test="$folder!='Drafts'">
        <xsl:value-of select="concat($skip,$skip,/cp/strings/wm_compose_original_msg,$skip)" />
      </xsl:if>
      <xsl:if test="string(/cp/form/reply) or string(/cp/form/reply_all)">
        <xsl:value-of select="concat(/cp/strings/wm_compose_orig_reply_when,' ',$display_date,' ',$original_sender,' ',/cp/strings/wm_compose_orig_reply_wrote,$skip)" />
      </xsl:if>
      <xsl:if test="string(/cp/form/forward)">
        <xsl:value-of select="concat(/cp/strings/wm_compose_orig_forward_date,$display_date,$skip)" />
        <xsl:value-of select="concat(/cp/strings/wm_compose_orig_forward_from,$forward_from,$skip)" />
        <xsl:value-of select="concat(/cp/strings/wm_compose_orig_forward_to,$forward_to_addrs,$skip)" />
        <xsl:if test="$forward_cc!=''">
          <xsl:value-of select="concat(/cp/strings/wm_compose_orig_forward_cc,$forward_cc,$skip)" />
        </xsl:if>
        <xsl:value-of select="concat(/cp/strings/wm_compose_orig_forward_subject,$forward_subject,$skip,$skip)" />
      </xsl:if>
      <xsl:value-of select="/cp/vsap/vsap[@type='webmail:messages:read']/body" />
      <xsl:if test="$include_sig='1' and $signature != '' and $folder!='Drafts'">
        <xsl:value-of select="$sigexpValue" />
      </xsl:if>
      <xsl:value-of select="$skip" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:if test="$include_sig='1' and $folder!='Drafts'">
        <xsl:value-of select="$sigexpValue" />
      </xsl:if>
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="save_sent_items">
  <xsl:choose>
    <xsl:when test="string(/cp/form/checkboxSaveSent)">1</xsl:when>
    <xsl:when test="string(/cp/vsap/vsap[@type='webmail:options:load']/webmail_options/fcc)">
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='webmail:options:load']/webmail_options/fcc='no'">0</xsl:when>
        <xsl:otherwise>1</xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:otherwise>0</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:template name="format_signature">
  <xsl:param name="signature" />
  <xsl:param name="sig_mark" />

  <xsl:variable name="sig_line">
    <xsl:value-of select="substring-before($signature,'&#13;&#10;')" />
  </xsl:variable>

  <xsl:variable name="remaining_lines">
    <xsl:value-of select="substring-after($signature,'&#13;&#10;')" />
  </xsl:variable>

  <xsl:choose>
    <xsl:when test="$sig_line!='' or $remaining_lines!=''">
      <xsl:value-of select="concat($sig_mark,$sig_line,'&#13;&#10;')" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="concat($sig_mark,$signature)" />
    </xsl:otherwise>
  </xsl:choose>

  <xsl:if test="$remaining_lines!=''">
    <xsl:call-template name="format_signature">
      <xsl:with-param name="signature" select="$remaining_lines" />
      <xsl:with-param name="sig_mark" select="$sig_mark" />
    </xsl:call-template>
  </xsl:if>
</xsl:template>

<xsl:variable name="init_focus">
  <xsl:choose>
    <xsl:when test="string(/cp/form/reply) or string(/cp/form/reply_all) or string(/cp/form/forward)">document.forms[0].body.focus();</xsl:when>
    <xsl:otherwise>document.forms[0].txtToName.focus();</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:template match="/">
  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title">
      <xsl:copy-of select="/cp/strings/wm_title" /> : <xsl:copy-of select="$bc_title" />
    </xsl:with-param>
    <xsl:with-param name="formaction">wm_compose.xsl</xsl:with-param>
    <xsl:with-param name="feedback" select="$message" />
    <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_compose" />
    <xsl:with-param name="onload"><xsl:value-of select="$init_focus" /> setTextAreaCursor(document.forms[0].body); </xsl:with-param>
<!-- the following triggers a problem in IE Mac 5.2 - commenting out for now -->
<!--
    <xsl:with-param name="onunload">composeCheck('<xsl:value-of select="/cp/strings/wm_compose_alertTextDiscardMessage" />');</xsl:with-param>
-->
    <xsl:with-param name="help_short" select="/cp/strings/wm_compose_hlp_short" />
    <xsl:with-param name="help_long" select="/cp/strings/wm_compose_hlp_long" />
    <xsl:with-param name="breadcrumb">
      <breadcrumb>
        <section>
          <name><xsl:copy-of select="$bc_title" /></name>
          <url>#</url>
          <image>MailMessages</image>
        </section>
      </breadcrumb>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

      <script src="{concat($base_url, '/mail/mail.js')}" language="JavaScript"></script>
      <input type="hidden" name="messageid" value="{$messageid}" />
      <input type="hidden" name="attachments" value="{$attachments}" />

      <input type="hidden" name="save_send" />
      <input type="hidden" name="btn_cancel" value="" />
      <input type="hidden" name="noconfirm" value="no" />
      <input type="hidden" name="replyto" value="{$replyto}" />
      <input type="hidden" name="signature" value="{$signature}" />
      <input type="hidden" name="sigexpValue" value="{$sigexpValue}" />
      <input type="hidden" name="save_sent_items" value="{$save_sent_items}" />
      <input type="hidden" name="forward_source" value="{$forward_source}" />
      <input type="hidden" name="folder" value="{$folder}" />
      <input type="hidden" name="goback" value="{$goback}" />
      <input type="hidden" name="uid" value="{$uid}" />
      <input type="hidden" name="mailitem" value="{$mailitem}" />
      <input type="hidden" name="msgno" value="{$msgno}" />
      <input type="hidden" name="draftid" value="{$draftid}" />
      <input type="hidden" name="try_encoding" value="{$try_encoding}" />

      <table class="formview" border="0" cellspacing="0" cellpadding="0">
        <tr class="title">
          <td colspan="2"><xsl:value-of select="/cp/strings/wm_compose_title" /></td>
        </tr>
        <tr class="controlrow">
          <td colspan="2"><span class="floatright"><input type="button" name="btn_send" value="{/cp/strings/wm_compose_bt_send}" onClick="verifyCompose('{cp:js-escape(/cp/strings/wm_compose_alertTextNoTo)}');" /><input type="submit" name="save_draft" value="{/cp/strings/wm_compose_bt_savedraft}" /><input type="button" name="cancel" value="{/cp/strings/wm_compose_bt_cancel}" onClick="document.forms[0].btn_cancel.value='yes';document.forms[0].noconfirm.value='yes';document.forms[0].submit();" /></span></td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:value-of select="/cp/strings/wm_compose_from" /></td>
          <td class="contentwidth"><input type="text" name="txtFromName" value="{$from_name}" size="42" tabindex="1" />
            <select name="from" size="1" tabindex="2">
              <xsl:for-each select="/cp/vsap/vsap[@type='mail:addresses:list']/address">
                <xsl:sort select="translate(source, 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')" />
                <xsl:if test="not(starts-with(source, '@'))">
                  <xsl:choose>
                    <xsl:when test="source = $preferred_email">
                      <option value="{source}" selected="true"><xsl:value-of select="source" /></option>
                    </xsl:when>
                    <xsl:otherwise>
                      <option value="{source}"><xsl:value-of select="source" /></option>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:if>
              </xsl:for-each>
            </select>
          </td>
        </tr>
        <tr class="roweven">
          <td class="label"><a href="OpenAddressBook_To" target="_blank" onClick="showAddress('to'); return false;"><xsl:value-of select="/cp/strings/wm_compose_to" /></a></td>
          <td class="contentwidth"><input type="text" name="txtToName" size="60" value="{$to_addrs}" tabindex="3" />
            <span class="parenthetichelp"><xsl:value-of select="/cp/strings/wm_compose_email_address_help" /></span></td>
        </tr>
        <tr class="rowodd">
          <td class="label"><a href="OpenAddressbook_Cc" target="_blank" onClick="showAddress('cc'); return false;"><xsl:value-of select="/cp/strings/wm_compose_cc" /></a></td>
          <td class="contentwidth"><input type="text" name="txtCcName" size="60" value="{$cc}" tabindex="4" />
            <span class="parenthetichelp"><xsl:value-of select="/cp/strings/wm_compose_email_address_help" /></span></td>
        </tr>
        <tr class="roweven">
          <td class="label"><a href="OpenAddressBook_Bcc" target="_blank" onClick="showAddress('bcc'); return false;"><xsl:value-of select="/cp/strings/wm_compose_bcc" /></a></td>
          <td class="contentwidth"><input type="text" name="txtBccName" size="60" value="{$bcc}" tabindex="5" /> 
            <span class="parenthetichelp"><xsl:value-of select="/cp/strings/wm_compose_email_address_help" /></span></td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:value-of select="/cp/strings/wm_compose_subject" /></td>
          <td class="contentwidth"><input type="text" name="subject" size="60" value="{$subject}" tabindex="6" /></td>
        </tr>
        <tr class="roweven">
          <td class="label"><xsl:value-of select="/cp/strings/wm_compose_message" /></td>
          <td class="contentwidth"><textarea name="body" rows="12" cols="78" wrap="virtual" tabindex="7"><cp-unescape><xsl:value-of select="$text_msg" /></cp-unescape></textarea></td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:value-of select="/cp/strings/wm_compose_options" /></td>
          <td class="contentwidth">
            <xsl:choose>
              <xsl:when test="$include_sig='1'">
                <input type="checkbox" checked="yes" id="include_sig" name="checkboxSig" value="1" onClick="addRemoveSig('{cp:js-escape(/cp/strings/wm_compose_alertTextSigMissing)}')" /><label for="include_sig"><xsl:value-of select="/cp/strings/wm_compose_inc_signature" /></label><br />
              </xsl:when>
              <xsl:when test="$include_sig='0' and $signature=''">
                <input type="checkbox" id="include_sig" name="checkboxSig" value="0" onClick="addRemoveSig('{cp:js-escape(/cp/strings/wm_compose_alertTextSigMissing)}')" disabled="1" /><label for="include_sig"><xsl:value-of select="/cp/strings/wm_compose_inc_signature" /></label><br />
              </xsl:when>
              <xsl:otherwise>
                <input type="checkbox" id="include_sig" name="checkboxSig" value="0" onClick="addRemoveSig('{cp:js-escape(/cp/strings/wm_compose_alertTextSigMissing)}')" /><label for="include_sig"><xsl:value-of select="/cp/strings/wm_compose_inc_signature" /></label><br />
              </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
              <xsl:when test="$save_sent_items = 1">
                <input type="checkbox" checked="yes" id="save_sent" name="checkboxSaveSent" value="checkboxValue" /><label for="save_sent"><xsl:value-of select="/cp/strings/wm_compose_save_sent_copy" /></label>
              </xsl:when>
              <xsl:otherwise>
                <input type="checkbox" id="save_sent" name="checkboxSaveSent" value="checkboxValue" /><label for="save_sent"><xsl:value-of select="/cp/strings/wm_compose_save_sent_copy" /></label>
              </xsl:otherwise>
            </xsl:choose>
          </td>
        </tr>
        <tr class="roweven">
          <td class="label"><xsl:value-of select="/cp/strings/wm_compose_attachments" /></td>
          <td class="contentwidth">
            <input type="text" name="attachments_display" value="{$attachments_display}" disabled="disabled" size="60" /> <a href="javascript:ScriptAttach()" onClick='document.forms[0].noconfirm.value="yes";'><xsl:value-of select="/cp/strings/wm_compose_attach_addedit" /></a></td>
        </tr>
        <tr class="controlrow">
          <td colspan="2"><span class="floatright"><input type="button" name="btn_send" value="{/cp/strings/wm_compose_bt_send}" onClick="verifyCompose('{cp:js-escape(/cp/strings/wm_compose_alertTextNoTo)}');" /><input type="submit" name="save_draft" value="{/cp/strings/wm_compose_bt_savedraft}" /><input type="button" name="cancel" value="{/cp/strings/wm_compose_bt_cancel}" onClick="document.forms[0].btn_cancel.value='yes';document.forms[0].noconfirm.value='yes';document.forms[0].submit();" /></span></td>
        </tr>
      </table>

</xsl:template>
</xsl:stylesheet>

