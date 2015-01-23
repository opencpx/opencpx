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
        <xsl:with-param name="message"><xsl:copy-of select="/cp/strings/wm_opt_folder_saved_success" /> </xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='user:prefs:save']/status = 'fail'">
      <xsl:call-template name="feedback_table">
        <xsl:with-param name="image">error</xsl:with-param>
        <xsl:with-param name="message"><xsl:copy-of select="/cp/strings/wm_opt_folder_saved_failure" /> </xsl:with-param>
      </xsl:call-template>
    </xsl:when>
  </xsl:choose>
</xsl:variable>

<xsl:template match="/">
<xsl:call-template name="bodywrapper">

  <xsl:with-param name="title">
    <xsl:copy-of select="/cp/strings/wm_title" /> : <xsl:copy-of select="/cp/strings/nv_menu_webmailoptions" /> : <xsl:copy-of select="/cp/strings/bc_opt_folder" />
  </xsl:with-param>

  <xsl:with-param name="formaction">folder_display.xsl</xsl:with-param>
  <xsl:with-param name="feedback"><xsl:copy-of select="$message"/></xsl:with-param>

  <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_folder_display" />
  <xsl:with-param name="breadcrumb">
    <breadcrumb>
      <section>
        <name><xsl:copy-of select="/cp/strings/bc_opt_folder" /></name>
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
              <td colspan="2"><xsl:value-of select="/cp/strings/wm_opt_folder_title"/></td>
            </tr>
            <tr class="instructionrow">
              <td colspan="2"><xsl:value-of select="/cp/strings/wm_opt_folder_instr"/></td>
            </tr>

              <!-- making terse variable names here seems vogue -->
              <xsl:variable name="use_mbl" select="/cp/vsap/vsap/webmail_options/use_mailboxlist"/>
              <xsl:variable name="inbox_checkmail" select="/cp/vsap/vsap/webmail_options/inbox_checkmail"/>

            <tr class="roweven">
              <td class="label"><xsl:value-of select="/cp/strings/wm_opt_folder_display"/></td>
              <td class="contentwidth">
                <input type="radio" id="list_all" name="use_mailboxlist" value="no" border="0">
                  <xsl:if test="$use_mbl = 'no'">
                    <xsl:attribute name="checked" value="checked"/>
                  </xsl:if>
                 </input><label for="list_all"><xsl:value-of select="/cp/strings/wm_opt_folder_display_all"/></label><br />

                <input type="radio" id="list_subscribed" name="use_mailboxlist" value="yes" border="0">
                  <xsl:if test="$use_mbl = 'yes'">
                    <xsl:attribute name="checked" value="checked"/>
                  </xsl:if>
                 </input><label for="list_subscribed"><xsl:value-of select="/cp/strings/wm_opt_folder_display_subscribed"/></label><br />

              </td>
            </tr>

            <tr class="rowodd">
              <td class="label"><xsl:value-of select="/cp/strings/wm_opt_inbox_checkmail"/></td>
              <td class="contentwidth"><xsl:value-of select="/cp/strings/wm_opt_inbox_checkmail_desc"/><br />

                <input type="radio" id="checkmail_off" name="inbox_checkmail" value="0" border="0">
                  <xsl:if test="$inbox_checkmail = '0'">
                    <xsl:attribute name="checked" value="checked"/>
                  </xsl:if>
                 </input><label for="checkmail_off"><xsl:value-of select="/cp/strings/wm_opt_inbox_checkmail_0"/></label><br />

                <input type="radio" id="checkmail_1min" name="inbox_checkmail" value="1" border="0">
                  <xsl:if test="$inbox_checkmail = '1'">
                    <xsl:attribute name="checked" value="checked"/>
                  </xsl:if>
                 </input><label for="checkmail_1min"><xsl:value-of select="/cp/strings/wm_opt_inbox_checkmail_1"/></label><br />

                <input type="radio" id="checkmail_5min" name="inbox_checkmail" value="5" border="0">
                  <xsl:if test="$inbox_checkmail = '5'">
                    <xsl:attribute name="checked" value="checked"/>
                  </xsl:if>
                 </input><label for="checkmail_5min"><xsl:value-of select="/cp/strings/wm_opt_inbox_checkmail_5"/></label><br />

                <input type="radio" id="checkmail_10min" name="inbox_checkmail" value="10" border="0">
                  <xsl:if test="$inbox_checkmail = '10'">
                    <xsl:attribute name="checked" value="checked"/>
                  </xsl:if>
                 </input><label for="checkmail_10min"><xsl:value-of select="/cp/strings/wm_opt_inbox_checkmail_10"/></label><br />

                <input type="radio" id="checkmail_15min" name="inbox_checkmail" value="15" border="0">
                  <xsl:if test="$inbox_checkmail = '15'">
                    <xsl:attribute name="checked" value="checked"/>
                  </xsl:if>
                 </input><label for="checkmail_15min"><xsl:value-of select="/cp/strings/wm_opt_inbox_checkmail_15"/></label><br />

              </td>
            </tr>

             <tr class="controlrow">
             <td colspan="2"><span class="floatright"><input type="submit" name="save" value="{/cp/strings/wm_opt_folder_save_btn}" /><input type="submit" name="cancel" value="{/cp/strings/wm_opt_folder_cancel_btn}" /></span></td>
            </tr>
          </table>

</xsl:template>
</xsl:stylesheet>

