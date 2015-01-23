<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="mail_global.xsl" />

<xsl:variable name="unread_msg_count">
  <xsl:value-of select="sum(/cp/vsap/vsap[@type='webmail:folders:list']/folder/unseen_messages)" />
</xsl:variable>

<xsl:variable name="contact_count">
  <xsl:value-of select="count(/cp/vsap/vsap[@type='webmail:addressbook:load']/vCardSet/vCard)" />
</xsl:variable>

<xsl:variable name="dist_list_count">
  <xsl:value-of select="count(/cp/vsap/vsap[@type='webmail:distlist:list']/distlist/listid)" />
</xsl:variable>

<xsl:variable name="spamfilter_status">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='mail:spamassassin:status']/status='on'"><xsl:value-of select="/cp/strings/wm_status_enable" /></xsl:when>
    <xsl:otherwise><xsl:value-of select="/cp/strings/wm_status_disable" /></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="virusscan_status">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='mail:clamav:status']/status='on'"><xsl:value-of select="/cp/strings/wm_status_enable" /></xsl:when>
    <xsl:otherwise><xsl:value-of select="/cp/strings/wm_status_disable" /></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="forward_status">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='mail:forward:status']/status='on'"><xsl:value-of select="/cp/strings/wm_status_on" /></xsl:when>
    <xsl:otherwise><xsl:value-of select="/cp/strings/wm_status_off" /></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="autoreply_status">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='mail:autoreply:status']/status='on'"><xsl:value-of select="/cp/strings/wm_status_on" /></xsl:when>
    <xsl:otherwise><xsl:value-of select="/cp/strings/wm_status_off" /></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:template match="/">
  <xsl:call-template name="bodywrapper">
<!--
    <xsl:with-param name="title"><xsl:copy-of select="/cp/strings/wm_title" /></xsl:with-param>
-->
    <xsl:with-param name="title" select="/cp/strings/wm_title" />
    <xsl:with-param name="formaction">mail/index.xsl</xsl:with-param>
    <xsl:with-param name="feedback" />
    <xsl:with-param name="selected_navandcontent" />
    <xsl:with-param name="help_short" select="/cp/strings/wm_index_hlp_short" />
    <xsl:with-param name="help_long" select="/cp/strings/wm_index_hlp_long" />
    <xsl:with-param name="breadcrumb" />
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

      <!-- Display webmail menu or mail menu -->
      <xsl:choose>

        <xsl:when test="$webmail_package='1' and $webmail_user='1'">

              <!-- Display webmail menu -->
              <table id="homepage" border="0" cellspacing="0" cellpadding="0">
                <tr>
                  <td>
                    <table id="homepagemailfolders" border="0" cellspacing="0" cellpadding="0">
                      <tr class="title">
                        <td colspan="2"><xsl:value-of select="/cp/strings/wm_index_mailfolders" /></td>
                      </tr>
                      <tr>
                        <td class="icon"><br />
                        </td>
                        <td><xsl:value-of select="/cp/strings/wm_index_composeview" /><br />
                          <hr />
                          <a href="{concat($base_url, '/mail/wm_messages.xsl?folder=', $inbox)}"><xsl:value-of select="/cp/strings/wm_index_inbox" /></a> <br />
                          <a href="{concat($base_url, '/mail/wm_messages.xsl?folder=', $trash)}"><xsl:value-of select="/cp/strings/wm_index_trash" /></a> <br />
                          <a href="{concat($base_url, '/mail/wm_compose.xsl')}"><xsl:value-of select="/cp/strings/wm_index_compose" /></a><br />
                        </td>
                      </tr>
                      <tr class="statusrow">
                        <td colspan="2"><xsl:value-of select="/cp/strings/wm_index_unreadmessages" /><xsl:value-of select="$unread_msg_count" /><br />
                          <br />
                        </td>
                      </tr>
                    </table>
                  </td>
                  <td>
                    <table id="homepagefoldermgmt" border="0" cellspacing="0" cellpadding="0">
                      <tr class="title">
                        <td colspan="2"><xsl:value-of select="/cp/strings/wm_index_foldermgmtsheader" /></td>
                      </tr>
                      <tr>
                        <td class="icon"><br />
                        </td>
                        <td><xsl:value-of select="/cp/strings/wm_index_storemessages" /><br />
                           
                          <hr />
                          <a href="{concat($base_url, '/mail/wm_folders.xsl')}"><xsl:value-of select="/cp/strings/wm_index_folders" /></a><br />
                           <a href="{concat($base_url, '/mail/wm_addfolder.xsl')}"><xsl:value-of select="/cp/strings/wm_index_add_folder" /></a><br />
                        </td>
                      </tr>
                      <tr class="statusrow">
                        <td colspan="2"><xsl:value-of select="/cp/strings/wm_index_personalfolders" /><xsl:value-of select="$personal_folder_count" /><br />
                          <br />
                        </td>
                      </tr>
                    </table>
                  </td>
                  <td>
                    <table id="homepageaddressbook" border="0" cellspacing="0" cellpadding="0">
                      <tr class="title">
                        <td colspan="2"><xsl:value-of select="/cp/strings/wm_index_addressbookmgmtheader" /></td>
                      </tr>
                      <tr>
                        <td class="icon"><br />
                        </td>
                        <td><xsl:value-of select="/cp/strings/wm_index_managecontacts" /><br />
                           
                          <hr />
                          <a href="{concat($base_url, '/mail/address_book/wm_addresses.xsl')}"><xsl:value-of select="/cp/strings/wm_index_addresses" /></a><br />
                           <a href="{concat($base_url, '/mail/address_book/wm_addcontact.xsl')}"><xsl:value-of select="/cp/strings/wm_index_add_contact" /></a><br />
                          <a href="{concat($base_url, '/mail/address_book/wm_distlist.xsl')}"><xsl:value-of select="/cp/strings/wm_index_add_list" /></a><br />
                          <a href="{concat($base_url, '/mail/address_book/wm_import_export.xsl')}"><xsl:value-of select="/cp/strings/wm_index_import_export" /></a><br />
                        </td>
                      </tr>
                      <tr class="statusrow">
                        <td colspan="2"><xsl:value-of select="/cp/strings/wm_index_contacts" /><xsl:value-of select="$contact_count" /> <br />
                          <xsl:value-of select="/cp/strings/wm_index_distlists" /><xsl:value-of select="$dist_list_count" /></td>
                      </tr>
                    </table>
                  </td>
                </tr>
                <tr>
                  <xsl:if test="($spamassassin_package='1' and $spamassassin_user='1') or ($clamav_package='1' and $clamav_user='1')">
                    <td>
                      <table id="homepagemailfilters" border="0" cellspacing="0" cellpadding="0">
                        <tr class="title">
                          <td colspan="2"><xsl:value-of select="/cp/strings/wm_index_mailfilters" /></td>
                        </tr>
                        <tr>
                          <td class="icon"><br /></td>
                          <td><xsl:value-of select="/cp/strings/wm_index_subscribefilters" /><br />
                            <hr />
                            <xsl:if test="$spamassassin_package='1' and $spamassassin_user='1'">
                              <a href="{concat($base_url, '/mail/options/wm_spamfilter.xsl')}"><xsl:value-of select="/cp/strings/wm_index_spam" /></a><br />
                            </xsl:if>
                            <xsl:if test="$clamav_package='1' and $clamav_user='1'">
                              <a href="{concat($base_url, '/mail/options/wm_virusscan.xsl')}"><xsl:value-of select="/cp/strings/wm_index_virus" /></a><br />
                            </xsl:if>
                          </td>
                        </tr>
                        <tr class="statusrow">
                          <td colspan="2">
                            <xsl:if test="$spamassassin_package='1' and $spamassassin_user='1'">
                              <xsl:value-of select="/cp/strings/wm_index_spamassassin" /><xsl:value-of select="$spamfilter_status" /><br />
                            </xsl:if>
                            <xsl:if test="$clamav_package='1' and $clamav_user='1'">
                              <xsl:value-of select="/cp/strings/wm_index_antivirus" /><xsl:value-of select="$virusscan_status" /><br />
                            </xsl:if>
                          </td>
                        </tr>
                      </table>
                    </td>
                  </xsl:if>
                  <td>
                    <table id="homepagemailboxoptions" border="0" cellspacing="0" cellpadding="0">
                      <tr class="title">
                        <td colspan="2"><xsl:value-of select="/cp/strings/wm_index_mailoptions" /></td>
                      </tr>
                      <tr>
                        <td class="icon"><br />
                        </td>
                        <td><xsl:value-of select="/cp/strings/wm_index_maildeliveryautoreply" /><br />
                           
                          <hr />
                          <a href="{concat($base_url, '/mail/options/wm_mailfwd.xsl')}"><xsl:value-of select="/cp/strings/wm_index_mail_forward" /></a><br />
                           <a href="{concat($base_url, '/mail/options/wm_autoreply.xsl')}"><xsl:value-of select="/cp/strings/wm_index_autoreply" /></a><br />
                        </td>
                      </tr>
                      <tr class="statusrow">
                        <td colspan="2"><xsl:value-of select="/cp/strings/wm_index_mailforward" /><xsl:value-of select="$forward_status" /><br />
                           <xsl:value-of select="/cp/strings/wm_index_mailautoreply" /><xsl:value-of select="$autoreply_status" /><br />
                        </td>
                      </tr>
                    </table>
                  </td>
                  <td>
                    <table id="homepagewebmailoptions" border="0" cellspacing="0" cellpadding="0">
                      <tr class="title">
                        <td colspan="2"><xsl:value-of select="/cp/strings/wm_index_webmailoptions" /></td>
                      </tr>
                      <tr>
                        <td class="icon"><br />
                        </td>
                        <td><xsl:value-of select="/cp/strings/wm_index_webmaildisplay" /><br />
                           
                          <hr />
                          <a href="{concat($base_url, '/mail/options/outgoing_mail.xsl')}"><xsl:value-of select="/cp/strings/wm_index_outgoing" /></a><br />
                           <a href="{concat($base_url, '/mail/options/message_display.xsl')}"><xsl:value-of select="/cp/strings/wm_index_display" /></a><br />
                        </td>
                      </tr>
                      <tr class="statusrow">
                        <td colspan="2"><br />
                          <br />
                        </td>
                      </tr>
                    </table>
                  </td>
                </tr>
              </table>
        </xsl:when>

        <xsl:otherwise>

              <!-- Display mail menu -->
            <table id="homepage" border="0" cellspacing="0" cellpadding="0">
              <tr>
                <xsl:if test="($spamassassin_package='1' and $spamassassin_user='1') or ($clamav_package='1' and $clamav_user='1')">
                  <td>
                    <table id="homepagemailfilters" border="0" cellspacing="0" cellpadding="0">
                      <tr class="title">
                        <td colspan="2"><xsl:value-of select="/cp/strings/wm_index_mailfilters" /></td>
                      </tr>
                      <tr>
                        <td class="icon"><br /></td>
                        <td><xsl:value-of select="/cp/strings/wm_index_subscribefilters" /><br />
                          <hr />
                          <xsl:if test="$spamassassin_package='1' and $spamassassin_user='1'">
                             <a href="{concat($base_url, '/mail/options/wm_spamfilter.xsl')}"><xsl:value-of select="/cp/strings/wm_index_spam" /></a><br />
                           </xsl:if>
                          <xsl:if test="$clamav_package='1' and $clamav_user='1'">
                             <a href="{concat($base_url, '/mail/options/wm_virusscan.xsl')}"><xsl:value-of select="/cp/strings/wm_index_virus" /></a><br />
                           </xsl:if>
                        </td>
                      </tr>
                      <tr class="statusrow">
                        <td colspan="2">
                          <xsl:if test="$spamassassin_package='1' and $spamassassin_user='1'">
                            <xsl:value-of select="/cp/strings/wm_index_spamassassin" /><xsl:value-of select="$spamfilter_status" /><br />
                          </xsl:if>
                          <xsl:if test="$clamav_package='1' and $clamav_user='1'">
                            <xsl:value-of select="/cp/strings/wm_index_antivirus" /><xsl:value-of select="$virusscan_status" /><br />
                          </xsl:if>
                        </td>
                      </tr>
                    </table>
                  </td>
                  </xsl:if>
                  <td>
                    <table id="homepagemailboxoptions" border="0" cellspacing="0" cellpadding="0">
                      <tr class="title">
                        <td colspan="2"><xsl:value-of select="/cp/strings/wm_index_mailoptions" /></td>
                      </tr>
                      <tr>
                        <td class="icon"><br />
                        </td>
                        <td><xsl:value-of select="/cp/strings/wm_index_maildeliveryautoreply" /><br />
                           
                          <hr />
                          <a href="{concat($base_url, '/mail/options/wm_mailfwd.xsl')}"><xsl:value-of select="/cp/strings/wm_index_mail_forward" /></a><br />
                           <a href="{concat($base_url, '/mail/options/wm_autoreply.xsl')}"><xsl:value-of select="/cp/strings/wm_index_autoreply" /></a><br />
                        </td>
                      </tr>
                      <tr class="statusrow">
                        <td colspan="2"><xsl:value-of select="/cp/strings/wm_index_mailforward" /><xsl:value-of select="$forward_status" /><br />
                           <xsl:value-of select="/cp/strings/wm_index_mailautoreply" /><xsl:value-of select="$autoreply_status" /><br />
                        </td>
                      </tr>
                    </table>
                  </td>
                  <td>
                    <table id="homepagespacer" border="0" cellspacing="0" cellpadding="0">
                      <tr>
                        <td />
                      </tr>
                    </table>
                  </td>
                </tr>
              </table>
        </xsl:otherwise>
      </xsl:choose>
   
</xsl:template>
</xsl:stylesheet>
