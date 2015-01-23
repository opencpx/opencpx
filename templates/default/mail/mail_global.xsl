<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:import href="../global.xsl" />

  <!-- This will tell the global template which app we are in -->
  <xsl:variable name="app_name">mail</xsl:variable>

  <!-- Indicates whether user has webmail access -->
  <xsl:variable name="webmail_user">
    <xsl:choose>
      <xsl:when test="/cp/vsap/vsap[@type='auth']/services/webmail">1</xsl:when>
      <xsl:otherwise>0</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <!-- Indicates mail filter tools available -->
  <xsl:variable name="spamassassin_user">
    <xsl:choose>
      <xsl:when test="/cp/vsap/vsap[@type='auth']/capabilities/mail-spamassassin">1</xsl:when>
      <xsl:when test="/cp/vsap/vsap[@type='user:properties']/user/capability/mail-spamassassin">1</xsl:when>
      <xsl:otherwise>0</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="clamav_user">
    <xsl:choose>
      <xsl:when test="/cp/vsap/vsap[@type='auth']/capabilities/mail-clamav">1</xsl:when>
      <xsl:when test="/cp/vsap/vsap[@type='user:properties']/user/capability/mail-clamav">1</xsl:when>
      <xsl:otherwise>0</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <!-- These are the names of the default folders that get created by webmail. These variables are not for
       display on pages, but should be used by conditionals that check for these special folders -->
  <xsl:variable name="inbox">INBOX</xsl:variable>
  <xsl:variable name="sent_items">Sent Items</xsl:variable>
  <xsl:variable name="drafts">Drafts</xsl:variable>
  <xsl:variable name="trash">Trash</xsl:variable>
  <xsl:variable name="quarantine">Quarantine</xsl:variable>
  <xsl:variable name="junk">Junk</xsl:variable>

  <!-- This will build the "navandcontent" menu for the mail section -->
  <xsl:variable name="navandcontent_items">
    <xsl:choose>
      <xsl:when test="$webmail_package='1' and $webmail_user='1'">
    <menu_items>
      <menu id="mailfolders" name="{/cp/strings/nv_menu_mailfolders}">
        <item href="{concat($base_url, '/mail/wm_messages.xsl?folder=', $inbox)}"><xsl:copy-of select="/cp/strings/nv_inbox" /></item>
        <item href="{concat($base_url, '/mail/wm_messages.xsl?folder=', $drafts)}"><xsl:copy-of select="/cp/strings/nv_drafts" /></item>
        <item href="{concat($base_url, '/mail/wm_messages.xsl?folder=', $sent_items)}"><xsl:copy-of select="/cp/strings/nv_sent" /></item>
        <item href="{concat($base_url, '/mail/wm_messages.xsl?folder=', $trash)}"><xsl:copy-of select="/cp/strings/nv_trash" /></item>
        <item href="{concat($base_url, '/mail/wm_compose.xsl')}"><xsl:copy-of select="/cp/strings/nv_compose" /></item>
      </menu>
      <menu id="personalfolders" name="{/cp/strings/nv_menu_folder_management}">
        <item href="{concat($base_url, '/mail/wm_folders.xsl')}"><xsl:copy-of select="/cp/strings/nv_folders" /></item>
        <item href="{concat($base_url, '/mail/wm_addfolder.xsl')}"><xsl:copy-of select="/cp/strings/nv_add_folder" /></item>
      </menu>
      <menu id="addressbook" name="{/cp/strings/nv_menu_addressbook}">
        <item href="{concat($base_url, '/mail/address_book/wm_addresses.xsl')}"><xsl:copy-of select="/cp/strings/nv_addresses" /></item>
        <item href="{concat($base_url, '/mail/address_book/wm_addcontact.xsl')}"><xsl:copy-of select="/cp/strings/nv_add_contact" /></item>
        <item href="{concat($base_url, '/mail/address_book/wm_distlist.xsl')}"><xsl:copy-of select="/cp/strings/nv_add_list" /></item>
        <item href="{concat($base_url, '/mail/address_book/wm_import_export.xsl')}"><xsl:copy-of select="/cp/strings/nv_import_export" /></item>
      </menu>
      <xsl:if test="($spamassassin_package='1' and $spamassassin_user='1') or ($clamav_package='1' and $clamav_user='1')">
        <menu id="mailfilters" name="{/cp/strings/nv_menu_mailfilters}">
        <xsl:if test="$spamassassin_package='1' and $spamassassin_user='1'">
          <item href="{concat($base_url, '/mail/options/wm_spamfilter.xsl')}"><xsl:copy-of select="/cp/strings/nv_spam" /></item>
        </xsl:if>
         <xsl:if test="$clamav_package='1' and $clamav_user='1'">
           <item href="{concat($base_url, '/mail/options/wm_virusscan.xsl')}"><xsl:copy-of select="/cp/strings/nv_virus" /></item>
        </xsl:if>
      </menu>
      </xsl:if>
      <menu id="mailboxoptions" name="{/cp/strings/nv_menu_mailboxoptions}">
        <item href="{concat($base_url, '/mail/options/wm_mailfwd.xsl')}"><xsl:copy-of select="/cp/strings/nv_mail_forward" /></item>
        <item href="{concat($base_url, '/mail/options/wm_autoreply.xsl')}"><xsl:copy-of select="/cp/strings/nv_autoreply" /></item>
      </menu>
      <menu id="webmailoptions" name="{/cp/strings/nv_menu_webmailoptions}">
        <item href="{concat($base_url, '/mail/options/outgoing_mail.xsl')}"><xsl:copy-of select="/cp/strings/nv_outgoing" /></item>
        <item href="{concat($base_url, '/mail/options/folder_display.xsl')}"><xsl:copy-of select="/cp/strings/nv_folder_display" /></item>
        <item href="{concat($base_url, '/mail/options/message_display.xsl')}"><xsl:copy-of select="/cp/strings/nv_message_display" /></item>
      </menu>
    </menu_items>
    </xsl:when>
    <xsl:otherwise>
    <menu_items>
      <xsl:if test="($spamassassin_package='1' and $spamassassin_user='1') or ($clamav_package='1' and $clamav_user='1')">
        <menu id="mailfilters" name="{/cp/strings/nv_menu_mailfilters}">
          <xsl:if test="$spamassassin_package='1' and $spamassassin_user='1'">
            <item href="{concat($base_url, '/mail/options/wm_spamfilter.xsl')}"><xsl:copy-of select="/cp/strings/nv_spam" /></item>
          </xsl:if>
          <xsl:if test="$clamav_package='1' and $clamav_user='1'">
            <item href="{concat($base_url, '/mail/options/wm_virusscan.xsl')}"><xsl:copy-of select="/cp/strings/nv_virus" /></item>
          </xsl:if>
        </menu>
      </xsl:if>
      <menu id="mailboxoptions" name="{/cp/strings/nv_menu_mailboxoptions}">
        <item href="{concat($base_url, '/mail/options/wm_mailfwd.xsl')}"><xsl:copy-of select="/cp/strings/nv_mail_forward" /></item>
        <item href="{concat($base_url, '/mail/options/wm_autoreply.xsl')}"><xsl:copy-of select="/cp/strings/nv_autoreply" /></item>
      </menu>
    </menu_items>
    </xsl:otherwise>
  </xsl:choose>
  </xsl:variable>

  <!-- personal folder count -->
  <xsl:variable name="personal_folder_count">
    <xsl:value-of select="count(/cp/vsap/vsap[@type='webmail:folders:list']/folder[not(@flag='immutable')])" />
  </xsl:variable>

  <xsl:template name="extract_csv_list">
    <xsl:param name="list" />

    <xsl:variable name="nlist" select="$list" />
    <xsl:variable name="first" select="substring-before($nlist, ',')" />
    <xsl:variable name="rest" select="substring-after($nlist, ',')" />
    <xsl:if test="string($first)">
      <address><xsl:value-of select="$first" /></address>
    </xsl:if>
    <xsl:if test="string($rest)">
      <xsl:call-template name="extract_csv_list">
        <xsl:with-param name="list" select="$rest" />
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

  <xsl:template name="format_email_addr">
    <xsl:param name="personal" />
    <xsl:param name="full" />

    <xsl:choose>
      <xsl:when test="contains($full,'@.MISSING-HOST-NAME.')">
        <xsl:if test="$personal != ''">
          <xsl:value-of select="concat('&lt;',substring-before($full,'@.MISSING-HOST-NAME.'),'&gt;')" />
        </xsl:if>
        <xsl:if test="string-length($personal)= 0">
          <xsl:value-of select="substring-before($full,'@.MISSING-HOST-NAME.')" />
        </xsl:if>
      </xsl:when>
      <xsl:when test="contains($full,'INVALID_ADDRESS')"></xsl:when>
      <xsl:otherwise>
        <xsl:if test="$personal != ''">
          <xsl:value-of select="concat('&lt;',$full,'&gt;')" />
        </xsl:if>
        <xsl:if test="string-length($personal) = 0">
          <xsl:value-of select="$full" />
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="format_addr">
    <xsl:param name="personal" />
    <xsl:param name="full" />

    <xsl:if test="$personal!=''">
      <xsl:value-of select="concat('&quot;',$personal,'&quot;',' ')" />
    </xsl:if>
    <xsl:call-template name="format_email_addr">
      <xsl:with-param name="personal" select="$personal" />
      <xsl:with-param name="full" select="$full" />
    </xsl:call-template>
  </xsl:template>
        
</xsl:stylesheet>
