<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../mail_global.xsl" />
<xsl:import href="mail_options_feedback.xsl" />

<xsl:variable name="status">
  <xsl:call-template name="status_message" />
</xsl:variable>

<xsl:variable name="status2">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='mail:forward:enable']/code = 551">
       <xsl:value-of select="/cp/strings/wm_mailfwd_error_forward_email_error" /> <b><xsl:value-of select="/cp/vsap/vsap[@type='error'][@caller='mail:forward:enable']/message" /></b>
    </xsl:when>
  </xsl:choose>
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
      <xsl:with-param name="message2"><xsl:value-of select="$status2" /></xsl:with-param>
    </xsl:call-template>
  </xsl:if>
</xsl:variable>

<xsl:variable name="forward_mail">
  <xsl:choose>
    <xsl:when test="string(/cp/form/groupForward) and not(string(/cp/form/btnCancel))">
      <xsl:value-of select="/cp/form/groupForward" />
    </xsl:when>
    <xsl:when test="string(cp/vsap/vsap[@type='mail:forward:status']/status)">
     <xsl:value-of select="/cp/vsap/vsap[@type='mail:forward:status']/status" />
    </xsl:when>
    <xsl:otherwise>off</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="forward_email_address">
  <xsl:choose>
    <xsl:when test="string($status) and $status_image='success'">
     <xsl:value-of select="/cp/vsap/vsap[@type='mail:forward:status']/email" />
    </xsl:when>
    <xsl:when test="string(/cp/form/textareaName) and not(string(/cp/form/btnCancel))">
     <xsl:value-of select="/cp/form/textareaName" />
    </xsl:when>
    <xsl:when test="string(/cp/vsap/vsap[@type='mail:forward:status']/email)">
     <xsl:value-of select="/cp/vsap/vsap[@type='mail:forward:status']/email" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="save_copy">
  <xsl:choose>
    <xsl:when test="string(/cp/form/save_copy) and not(string(/cp/form/btnCancel))">on</xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='mail:forward:status']/savecopy='on'">on</xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:template match="/">
  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title">
      <xsl:copy-of select="/cp/strings/wm_title" /> : 
      <xsl:copy-of select="/cp/strings/nv_menu_mailboxoptions" /> : 
      <xsl:copy-of select="/cp/strings/bc_wm_mailfwd" />
    </xsl:with-param>
    <xsl:with-param name="formaction">wm_mailfwd.xsl</xsl:with-param>
    <xsl:with-param name="onload">visibility_forward();</xsl:with-param>
    <xsl:with-param name="feedback" select="$message" />
    <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_mail_forward" />
    <xsl:with-param name="help_short" select="/cp/strings/wm_mailfwd_hlp_short" />
    <xsl:with-param name="help_long" select="/cp/strings/wm_mailfwd_hlp_long" />
    <xsl:with-param name="breadcrumb">
      <breadcrumb>
       <section>
         <name><xsl:copy-of select="/cp/strings/bc_wm_mailfwd" /></name>
         <url>#</url>
         <image>MailboxOptions</image>
       </section>
      </breadcrumb>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

      <script src="{concat($base_url, '/mail/options/mail_options.js')}" language="JavaScript"></script>
      <input type="hidden" name="forward_mail" value="{$forward_mail}" />
      <input type="hidden" name="forward_address" value="{$forward_email_address}" />
      <input type="hidden" name="forward_save_copy" value="{$save_copy}" />
      <input type="hidden" name="save_forward" />
      <table class="formview" border="0" cellspacing="0" cellpadding="0">
        <tr class="title">
          <td colspan="2"><xsl:value-of select="/cp/strings/wm_mailfwd_title" /></td>
        </tr>
        <tr class="instructionrow">
          <td colspan="2"><xsl:value-of select="/cp/strings/wm_mailfwd_instruction" /></td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:value-of select="/cp/strings/wm_mailfwd_label" /></td>
          <td class="contentwidth">
            <xsl:choose>
              <xsl:when test="$forward_mail='off'">
                <input type="radio" id="forward_off" name="groupForward" value="off" checked="checked" onClick="visibility_forward();" border="0" /><label for="forward_off"><xsl:value-of select="/cp/strings/wm_mailfwd_radio_label_1" /></label><br />
                <input type="radio" id="forward_on" name="groupForward" value="on" onClick="visibility_forward();" border="0" /><label for="forward_on"><xsl:value-of select="/cp/strings/wm_mailfwd_radio_label_2" /></label><br />
              </xsl:when>
              <xsl:otherwise>
                <input type="radio" id="forward_off" name="groupForward" value="off" onClick="visibility_forward();" border="0" /><label for="forward_off"><xsl:value-of select="/cp/strings/wm_mailfwd_radio_label_1" /></label><br />
                <input type="radio" id="forward_on" name="groupForward" value="on" checked="checked" onClick="visibility_forward();" border="0" /><label for="forward_on"><xsl:value-of select="/cp/strings/wm_mailfwd_radio_label_2" /></label><br />
              </xsl:otherwise>
            </xsl:choose>
           
            <textarea class="indent" name="textareaName" rows="2" cols="60" ><xsl:value-of select="$forward_email_address" /></textarea><br />
            <span class="indent"><span class="parenthetichelp"><xsl:value-of select="/cp/strings/wm_mailfwd_paren_help" /></span></span><br />
            <br />
            <input class="indent" type="checkbox" id="save_a_copy" name="save_copy" value="on" >
              <xsl:if test="$save_copy='on'">
                <xsl:attribute name="checked">checked</xsl:attribute>
              </xsl:if>
            </input>
            <label for="save_a_copy"><xsl:value-of select="/cp/strings/wm_mailfwd_cbox" /></label>
          </td>
        </tr>
        <tr class="controlrow">
          <td colspan="2"><span class="floatright"><input type="button" name="save" value="{/cp/strings/wm_mailfwd_btn_save}" onClick="validate_forward('{cp:js-escape(/cp/strings/wm_mailfwd_alertTextMsgRequired)}')" /><input type="submit" name="btnCancel" value="{/cp/strings/wm_mailfwd_btn_cancel}" /></span></td>
        </tr>
      </table>
    <br />

</xsl:template>      
</xsl:stylesheet>

