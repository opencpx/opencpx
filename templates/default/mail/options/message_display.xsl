<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
  xmlns:exslt="http://exslt.org/common"
  exclude-result-prefixes="exslt">

<xsl:import href="../mail_global.xsl" />

<xsl:variable name="message">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='webmail:options:save']/status = 'ok'">
      <xsl:call-template name="feedback_table">
        <xsl:with-param name="image">success</xsl:with-param>
        <xsl:with-param name="message"><xsl:copy-of select="/cp/strings/wm_opt_display_saved_success" /> </xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='webmail:options:save']/status = 'fail'">
      <xsl:call-template name="feedback_table">
        <xsl:with-param name="image">error</xsl:with-param>
        <xsl:with-param name="message"><xsl:copy-of select="/cp/strings/wm_opt_display_saved_failure" /> </xsl:with-param>
      </xsl:call-template>
    </xsl:when>
  </xsl:choose>
</xsl:variable>

<xsl:template match="/">
<xsl:call-template name="bodywrapper">

  <xsl:with-param name="title">
    <xsl:copy-of select="/cp/strings/wm_title" /> : <xsl:copy-of select="/cp/strings/nv_menu_webmailoptions" /> : <xsl:copy-of select="/cp/strings/bc_opt_display" />
  </xsl:with-param>

  <xsl:with-param name="formaction">message_display.xsl</xsl:with-param>
  <xsl:with-param name="feedback"><xsl:copy-of select="$message"/></xsl:with-param>

  <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_message_display" />
  <xsl:with-param name="help_short" select="/cp/strings/wm_opt_display_hlp_short" />
  <xsl:with-param name="help_long" select="/cp/strings/wm_opt_display_hlp_long" />
  <xsl:with-param name="breadcrumb">
    <breadcrumb>
      <section>
        <name><xsl:copy-of select="/cp/strings/bc_opt_display" /></name>
        <url>#</url>
        <image>WebmailOptions</image>
      </section>
    </breadcrumb>
  </xsl:with-param>

</xsl:call-template>
</xsl:template>

<xsl:template name="content">

          <table class="formview" border="0" cellspacing="0" cellpadding="0">
            <tr class="title">
              <td colspan="2"><xsl:value-of select="/cp/strings/wm_opt_display_title"/></td>
            </tr>
            <tr class="instructionrow">
              <td colspan="2"><xsl:value-of select="/cp/strings/wm_opt_display_instr"/></td>
            </tr>

              <!-- making terse variable names here seems vogue -->
              <xsl:variable name="hl_setting" select="/cp/vsap/vsap/webmail_options/url_highlight"/>
              <xsl:variable name="msgs_setting" select="/cp/vsap/vsap/webmail_options/messages_per_page"/>
              <xsl:variable name="tz_setting" select="/cp/vsap/vsap/webmail_options/tz_display"/>
              <xsl:variable name="enc_setting" select="/cp/vsap/vsap/webmail_options/display_encoding"/>
              <xsl:variable name="mult_view_setting" select="/cp/vsap/vsap/webmail_options/multipart_view"/>
              <xsl:variable name="ftch_loc_setting" select="/cp/vsap/vsap/webmail_options/fetch_images_local"/>
              <xsl:variable name="ftch_rem_setting" select="/cp/vsap/vsap/webmail_options/fetch_images_remote"/>
              <xsl:variable name="attach_setting" select="/cp/vsap/vsap/webmail_options/attachment_view"/>

<!-- Temporarily removed (BUG04867) -->
<!--
            <tr class="rowodd">

              <td class="label"><xsl:value-of select="/cp/strings/wm_opt_display_links"/></td>
              <td class="contentwidth">
                <input type="radio" id="highlight_on" name="url_highlight" value="yes" border="0" >
                  <xsl:if test="$hl_setting = 'yes'">
                    <xsl:attribute name="checked" value="checked"/>
                  </xsl:if>
                </input>
                <label for="highlight_on"><xsl:value-of select="/cp/strings/wm_opt_display_links_urlhl"/></label><br />

                <input type="radio" id="highlight_off" name="url_highlight" value="no" border="0" >
                  <xsl:if test="$hl_setting = 'no'">
                    <xsl:attribute name="checked" value="checked"/>
                  </xsl:if>
                </input>
                <label for="highlight_off"><xsl:value-of select="/cp/strings/wm_opt_display_links_urlnohl"/></label><br />
              </td>
            </tr>
-->
            <tr class="roweven">
              <td class="label"><xsl:value-of select="/cp/strings/wm_opt_display_msgs_pp"/></td>
              <td class="contentwidth">
                <input type="radio" id="mpp10" name="messages_per_page" value="10" border="0">
                  <xsl:if test="$msgs_setting = '10'">
                    <xsl:attribute name="checked" value="checked"/>
                  </xsl:if>
                 </input><label for="mpp10">10</label><br />

                <input type="radio" id="mpp25" name="messages_per_page" value="25" border="0">
                  <xsl:if test="$msgs_setting = '25'">
                    <xsl:attribute name="checked" value="checked"/>
                  </xsl:if>
                 </input><label for="mpp25">25</label><br />

                <input type="radio" id="mpp50" name="messages_per_page" value="50" border="0">
                  <xsl:if test="$msgs_setting = '50'">
                    <xsl:attribute name="checked" value="checked"/>
                  </xsl:if>
                 </input><label for="mpp50">50</label><br />

                <input type="radio" id="mpp100" name="messages_per_page" value="100" border="0">
                  <xsl:if test="$msgs_setting = '100'">
                    <xsl:attribute name="checked" value="checked"/>
                  </xsl:if>
                 </input><label for="mpp100">100</label><br />

              </td>
            </tr>
<!-- disable this for now per Scott 20041108 and bug 4886 -->
<!--
            <tr class="rowodd">
              <td class="label"><xsl:value-of select="/cp/strings/wm_opt_display_tz"/></td>
              <td class="contentwidth">
                <input type="radio" id="tz_self" name="tz_display" value="my" border="0">
                  <xsl:if test="$tz_setting = 'my'">
                    <xsl:attribute name="checked" value="checked"/>
                  </xsl:if>
                 </input>
                 <label for="tz_self"><xsl:value-of select="/cp/strings/wm_opt_display_mytz"/></label><br />

                 <input type="radio" id="tz_sender" name="tz_display" value="sender" border="0" >
                  <xsl:if test="$tz_setting != 'my'">
                    <xsl:attribute name="checked" value="checked"/>
                  </xsl:if>
                 </input>
                 <label for="tz_sender"><xsl:value-of select="/cp/strings/wm_opt_display_sendertz"/></label><br />
              </td>
            </tr>
-->
            <tr class="rowodd">
              <td class="label"><xsl:value-of select="/cp/strings/wm_opt_display_encoding"/></td>
              <td class="contentwidth"><select name="display_encoding">

                  <option value="UTF-8">
                    <xsl:if test="$enc_setting = 'UTF-8'">
                      <xsl:attribute name="selected" value="selected"/>
                    </xsl:if>
                    <xsl:value-of select="/cp/strings/wm_opt_display_utf8"/>
                  </option>

                  <option value="US-ASCII">
                    <xsl:if test="$enc_setting = 'US_ASCII'">
                      <xsl:attribute name="selected" value="selected"/>
                    </xsl:if>
                    <xsl:value-of select="/cp/strings/wm_opt_display_usascii"/>
                  </option>

                  <option value="ISO-2022-JP">
                    <xsl:if test="$enc_setting = 'ISO-2022-JP'">
                      <xsl:attribute name="selected" value="selected"/>
                    </xsl:if>
                    <xsl:value-of select="/cp/strings/wm_opt_display_iso2022jp"/>
                  </option>

                  <option value="ISO-8859-1">
                    <xsl:if test="$enc_setting = 'ISO-8859-1'">
                      <xsl:attribute name="selected" value="selected"/>
                    </xsl:if>
                    <xsl:value-of select="/cp/strings/wm_opt_display_iso88591"/>
                  </option>

                </select></td>
             </tr>

            <!-- multipart message viewing preference -->
            <tr class="roweven">
              <td class="label"><xsl:value-of select="/cp/strings/wm_opt_display_multipart_view"/></td>
              <td class="contentwidth">
                <input type="radio" id="mpv_text" name="multipart_view" value="text" border="0">
                  <xsl:if test="$mult_view_setting = 'text'">
                    <xsl:attribute name="checked" value="checked"/>
                  </xsl:if>
                 </input><label for="mpv_text"><xsl:value-of select="/cp/strings/wm_opt_display_multipart_text"/></label><br />

                <input type="radio" id="mpv_html" name="multipart_view" value="html" border="0">
                  <xsl:if test="$mult_view_setting = 'html'">
                    <xsl:attribute name="checked" value="checked"/>
                  </xsl:if>
                 </input><label for="mpv_html"><xsl:value-of select="/cp/strings/wm_opt_display_multipart_html"/></label><br />
              </td>
            </tr>

            <!-- local image display preference -->
            <tr class="rowodd">
              <td class="label"><xsl:value-of select="/cp/strings/wm_opt_display_images_local"/></td>
              <td class="contentwidth">
                <input type="radio" id="embedded_images_no" name="fetch_images_local" value="no" border="0">
                  <xsl:if test="$ftch_loc_setting = 'no'">
                    <xsl:attribute name="checked" value="checked"/>
                  </xsl:if>
                 </input><label for="embedded_images_no"><xsl:value-of select="/cp/strings/wm_opt_display_images_local_no"/></label><br />

                <input type="radio" id="embedded_images_yes" name="fetch_images_local" value="yes" border="0">
                  <xsl:if test="$ftch_loc_setting = 'yes'">
                    <xsl:attribute name="checked" value="checked"/>
                  </xsl:if>
                 </input><label for="embedded_images_yes"><xsl:value-of select="/cp/strings/wm_opt_display_images_local_yes"/></label><br />
              </td>
            </tr>

            <!-- remote image display preference -->
            <tr class="roweven">
              <td class="label"><xsl:value-of select="/cp/strings/wm_opt_display_images_remote"/></td>
              <td class="contentwidth">
                <input type="radio" id="remote_images_no" name="fetch_images_remote" value="no" border="0">
                  <xsl:if test="$ftch_rem_setting = 'no'">
                    <xsl:attribute name="checked" value="checked"/>
                  </xsl:if>
                 </input><label for="remote_images_no"><xsl:value-of select="/cp/strings/wm_opt_display_images_remote_no"/></label><br />

                <input type="radio" id="remote_images_yes" name="fetch_images_remote" value="yes" border="0">
                  <xsl:if test="$ftch_rem_setting = 'yes'">
                    <xsl:attribute name="checked" value="checked"/>
                  </xsl:if>
                 </input><label for="remote_images_yes"><xsl:value-of select="/cp/strings/wm_opt_display_images_remote_yes"/></label><br />
              </td>
            </tr>

            <!-- attachment dislpay preference -->
            <tr class="rowodd">
              <td class="label"><xsl:value-of select="/cp/strings/wm_opt_display_attachment_view"/></td>
              <td class="contentwidth">
                <input type="radio" id="av1" name="attachment_view" value="attachments" border="0">
                  <xsl:if test="$attach_setting = 'attachments'">
                    <xsl:attribute name="checked" value="checked"/>
                  </xsl:if>
                 </input><label for="av1"><xsl:value-of select="/cp/strings/wm_opt_display_attachment_view_attachments"/></label><br />

                <input type="radio" id="av2" name="attachment_view" value="all" border="0">
                  <xsl:if test="$attach_setting = 'all'">
                    <xsl:attribute name="checked" value="checked"/>
                  </xsl:if>
                 </input><label for="av2"><xsl:value-of select="/cp/strings/wm_opt_display_attachment_view_all"/></label><br />

                <input type="radio" id="av3" name="attachment_view" value="none" border="0">
                  <xsl:if test="$attach_setting = 'none'">
                    <xsl:attribute name="checked" value="checked"/>
                  </xsl:if>
                 </input><label for="av3"><xsl:value-of select="/cp/strings/wm_opt_display_attachment_view_none"/></label><br />
              </td>
            </tr>

             <tr class="controlrow">
             <td colspan="2"><span class="floatright"><input type="submit" name="save" value="{/cp/strings/wm_opt_display_save_btn}" /><input type="submit" name="cancel" value="{/cp/strings/wm_opt_display_cancel_btn}" /></span></td>
            </tr>
          </table>

</xsl:template>
</xsl:stylesheet>

