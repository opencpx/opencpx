<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../global.meta.xsl" />
<xsl:template match="/">
<meta>

<!-- run auth code -->
<xsl:call-template name="auth">
  <xsl:with-param name="require_mail">1</xsl:with-param>
  <xsl:with-param name="require_webmail">1</xsl:with-param>
</xsl:call-template>

<xsl:variable name="attach_flag">
  <xsl:choose>
    <xsl:when test="not(string(/cp/form/messageid))">1</xsl:when>
    <xsl:otherwise>0</xsl:otherwise>
  </xsl:choose>
</xsl:variable>
    
<xsl:if test="/cp/form/messageid">
  <xsl:call-template name="dovsap">
    <xsl:with-param name="vsap">
      <vsap type="webmail:send:attachment:list">
        <messageid><xsl:value-of select="/cp/form/messageid" /></messageid>
      </vsap>
    </xsl:with-param>
  </xsl:call-template>
</xsl:if>
 
<!-- run vsap code -->
<xsl:call-template name="dovsap">
  <xsl:with-param name="vsap">
    <vsap>
      <xsl:choose>
        <xsl:when test="string(/cp/form/save_send) or string(/cp/form/save_draft)">
          <xsl:variable name="space"><xsl:text>&#x020;</xsl:text></xsl:variable>
          <xsl:variable name="lt"><xsl:text>&lt;</xsl:text></xsl:variable>
          <xsl:variable name="gt"><xsl:text>&gt;</xsl:text></xsl:variable>
          <vsap type='webmail:send'>
            <To><xsl:value-of select="/cp/form/txtToName" /></To>
            <From><xsl:value-of select="concat(/cp/form/txtFromName,$space,$lt,/cp/form/from,$gt)" /></From>
            <From_Addr><xsl:value-of select="/cp/form/from" /></From_Addr>
            <ReplyTo><xsl:value-of select="/cp/form/replyto" /></ReplyTo>
            <Cc><xsl:value-of select="/cp/form/txtCcName" /></Cc>
            <Bcc><xsl:value-of select="/cp/form/txtBccName" /></Bcc>
            <Subject><xsl:value-of select="/cp/form/subject" /></Subject>
            <Text><xsl:value-of select="/cp/form/body" /></Text>
            <xsl:if test="string(/cp/form/messageid)">
              <messageid><xsl:value-of select="/cp/form/messageid" /></messageid>
            </xsl:if>
            <xsl:if test="string(/cp/form/checkboxSaveSent)">
              <SaveOut>1</SaveOut>
            </xsl:if>
            <xsl:if test="string(/cp/form/save_draft)">
              <SaveDraft>1</SaveDraft>
            </xsl:if>
          </vsap>
        </xsl:when>
        <xsl:when test="string(/cp/form/listid)">
          <vsap type='webmail:distlist:list'>
            <listid><xsl:value-of select="/cp/form/listid"/></listid>
          </vsap>
        </xsl:when>
        <xsl:when test="/cp/form/folder='Drafts' and not(string(/cp/form/save_draft))">
          <vsap type='webmail:messages:read'>
            <folder>Drafts</folder>
            <uid><xsl:value-of select="/cp/form/uid" /></uid>
            <beautify>no</beautify>
          </vsap>
        </xsl:when>
      </xsl:choose>
      <xsl:if test="not(/cp/form/save_send) and not(/cp/form/save_draft) and not(string(/cp/vsap/vsap[@type='error']))">
        <vsap type='webmail:options:load' />
      </xsl:if>

      <!-- get messageid if first time through -->
      <xsl:if test="$attach_flag=1">
        <vsap type="webmail:send:messageid"></vsap>
      </xsl:if>

      <vsap type="user:prefs:load"/>
      <vsap type="user:properties"><user><xsl:value-of select="/cp/vsap/vsap[@type='auth']/username"/></user></vsap>
      <vsap type="mail:addresses:list"><rhs><xsl:value-of select="/cp/vsap/vsap[@type='auth']/username"/></rhs></vsap>
      <vsap type="sys:service:status"/>
    </vsap>
  </xsl:with-param>
</xsl:call-template>

<!-- build attachment files if they exist on initial load of forward -->
<xsl:if test="$attach_flag=1 and (/cp/form/folder='Drafts' or string(/cp/form/forward))">
  <xsl:call-template name="dovsap">
    <xsl:with-param name="vsap">
      <vsap>
        <xsl:for-each select="/cp/vsap/vsap[@type='webmail:messages:read']/attachments/attachment">
          <vsap type="webmail:messages:attachment">
            <uid>
              <xsl:value-of select="/cp/vsap/vsap[@type='webmail:messages:read']/uid" />
            </uid>
            <attach_id>
              <xsl:value-of select="attach_id" />
            </attach_id>
            <folder>
              <xsl:value-of select="/cp/vsap/vsap[@type='webmail:messages:read']/folder" />
            </folder>
            <messageid>
              <xsl:value-of select="/cp/vsap/vsap[@type='webmail:send:messageid']/messageid" />
            </messageid>
          </vsap>          
          <vsap type='webmail:send:attachment:add'>
            <messageid>
              <xsl:value-of select="/cp/vsap/vsap[@type='webmail:send:messageid']/messageid" />
            </messageid>
            <filename>
              <xsl:value-of select="name" />
            </filename>
          </vsap>
        </xsl:for-each>
      </vsap>
    </xsl:with-param>
  </xsl:call-template>
</xsl:if>

<xsl:if test="string(/cp/form/save_draft)">
  <xsl:call-template name="dovsap">
    <xsl:with-param name="vsap">
      <vsap>
        <vsap type='webmail:messages:save'>
          <folder>Drafts</folder>
          <message><xsl:value-of select="/cp/vsap/vsap[@type='webmail:send']/email_msg" /></message>
        </vsap>
      </vsap>
    </xsl:with-param>
  </xsl:call-template>
</xsl:if>

<xsl:if test="not(/cp/vsap/vsap[@type='error']) and string(/cp/form/checkboxSaveSent) and not(string(/cp/form/save_draft)) and not(string(/cp/form/btn_cancel))">
  <xsl:call-template name="dovsap">
    <xsl:with-param name="vsap">
      <vsap>
        <vsap type='webmail:messages:save'>
          <folder>Sent Items</folder>
          <message><xsl:value-of select="/cp/vsap/vsap[@type='webmail:send']/email_msg" /></message>
        </vsap>
      </vsap>
    </xsl:with-param>
  </xsl:call-template>
</xsl:if>

<!-- set compose status message -->
<xsl:choose>
  <xsl:when test="string(/cp/form/save_send)">
    <xsl:choose>
      <xsl:when test="not(string(/cp/form/checkboxSaveSent)) and not(/cp/vsap/vasp[@type='error'])">
        <xsl:call-template name="set_message">
          <xsl:with-param name="name">compose_successful</xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="string(/cp/form/checkboxSaveSent)">
        <xsl:choose>
          <xsl:when test="not(/cp/vsap/vsap[@type='error'])">
            <xsl:call-template name="set_message">
              <xsl:with-param name="name">compose_successful</xsl:with-param>
            </xsl:call-template>
          </xsl:when>
          <xsl:when test="/cp/vsap/vsap[@type='error'] and /cp/vsap/vsap[@type='error']/@caller = 'webmail:messages:save'">
            <xsl:call-template name="set_message">
              <xsl:with-param name="name">compose_sent_copy_failure</xsl:with-param>
            </xsl:call-template>
          </xsl:when>
        </xsl:choose>
      </xsl:when>
    </xsl:choose>
  </xsl:when>
  <xsl:when test="string(/cp/form/save_draft) and not(/cp/vsap/vsap[@type='error'])">
    <xsl:call-template name="set_message">
      <xsl:with-param name="name">compose_savedraft_successful</xsl:with-param>
    </xsl:call-template>
  </xsl:when>
</xsl:choose>

<!-- delete message if draft and successfully sent -->
<xsl:if test="(string(/cp/form/save_send) or string(/cp/form/save_draft)) and /cp/form/folder='Drafts' and not(string(/cp/vsap/vsap[@type='error']))">
  <xsl:call-template name="dovsap">
    <xsl:with-param name="vsap">
      <vsap>
        <vsap type='webmail:messages:delete'>
          <folder><xsl:value-of select="/cp/form/folder" /></folder>
          <uid><xsl:value-of select="/cp/form/uid" /></uid>
        </vsap>
      </vsap>
    </xsl:with-param>
  </xsl:call-template>
</xsl:if>
 
<!-- redirect to the appropriate page -->
<xsl:choose>
<!-- if successfully sent, return to appropriate UHF context -->
  <xsl:when test="(string(/cp/form/save_send) or string(/cp/form/save_draft))">
    <xsl:choose>
      <xsl:when test="not(string(/cp/vsap/vsap[@type='error'])) and string(/cp/form/save_draft)">
        <redirect>
          <path>mail/wm_messages.xsl</path>
        </redirect>
      </xsl:when>
      <xsl:when test="not(string(/cp/vsap/vsap[@type='error'])) or /cp/vsap/vsap[@type='error']/@caller='webmail:messages:save'">
        <xsl:choose>
          <xsl:when test="/cp/form/goback!='mail/address_book/wm_addresses.xsl'">
            <redirect>
              <path>mail/wm_messages.xsl</path>
            </redirect>
          </xsl:when>
          <xsl:otherwise>
            <redirect>
              <path><xsl:value-of select="/cp/form/goback" /></path>
            </redirect>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
    </xsl:choose>
  </xsl:when>
  <xsl:when test="string(/cp/form/btn_cancel)">
    <redirect>
      <path><xsl:value-of select="/cp/form/goback" /></path>
    </redirect>
  </xsl:when>
</xsl:choose>

<!-- if that's all done, we just show the page -->
<showpage />

</meta>
</xsl:template>
</xsl:stylesheet>


