<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../mail_global.xsl" />
<xsl:import href="mail_options_feedback.xsl" />

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

<xsl:variable name="autoreply_mail">
  <xsl:choose>
    <xsl:when test="string(/cp/form/groupAutoreply) and not(string(/cp/form/btnCancel))">
      <xsl:value-of select="/cp/form/groupAutoreply" />
    </xsl:when>
    <xsl:when test="string(cp/vsap/vsap[@type='mail:autoreply:status']/status)">
      <xsl:value-of select="/cp/vsap/vsap[@type='mail:autoreply:status']/status"/>
    </xsl:when>
    <xsl:otherwise>off</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="autoreply_msg">
  <xsl:choose>
    <xsl:when test="string(/cp/form/textareaName) and not(string(/cp/form/btnCancel))">
     <xsl:value-of select="/cp/form/textareaName" />
    </xsl:when>
    <xsl:when test="string(cp/vsap/vsap[@type='mail:autoreply:status']/message)">
      <xsl:value-of select="/cp/vsap/vsap[@type='mail:autoreply:status']/message"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="/cp/strings/wm_autoreply_template"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="autoreply_subject">
  <xsl:choose>
    <xsl:when test="string(/cp/form/subject) and not(string(/cp/form/btnCancel))">
     <xsl:value-of select="/cp/form/subject" />
    </xsl:when>
    <xsl:when test="string(cp/vsap/vsap[@type='mail:autoreply:status']/subject)">
      <xsl:value-of select="/cp/vsap/vsap[@type='mail:autoreply:status']/subject"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="/cp/strings/wm_autoreply_subject_default"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="autoreply_replyto">
  <xsl:choose>
    <xsl:when test="string(/cp/form/replyto) and not(string(/cp/form/btnCancel))">
     <xsl:value-of select="/cp/form/replyto" />
    </xsl:when>
    <xsl:when test="string(cp/vsap/vsap[@type='mail:autoreply:status']/replyto)">
      <xsl:value-of select="/cp/vsap/vsap[@type='mail:autoreply:status']/replyto"/>
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="autoreply_interval">
  <xsl:choose>
    <xsl:when test="string(/cp/form/interval) and not(string(/cp/form/btnCancel))">
      <xsl:value-of select="/cp/form/interval" />
    </xsl:when>
    <xsl:when test="string(cp/vsap/vsap[@type='mail:autoreply:status']/interval)">
      <xsl:value-of select="/cp/vsap/vsap[@type='mail:autoreply:status']/interval"/>
    </xsl:when>
    <xsl:otherwise>7</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="autoreply_encoding">
  <xsl:choose>
    <xsl:when test="string(/cp/form/encoding) and not(string(/cp/form/btnCancel))">
      <xsl:value-of select="/cp/form/encoding" />
    </xsl:when>
    <xsl:when test="string(cp/vsap/vsap[@type='mail:autoreply:status']/encoding)">
      <xsl:value-of select="/cp/vsap/vsap[@type='mail:autoreply:status']/encoding"/>
    </xsl:when>
    <xsl:otherwise>UTF-8</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:template match="/">
  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title">
      <xsl:copy-of select="/cp/strings/wm_title" /> : 
      <xsl:copy-of select="/cp/strings/nv_menu_mailboxoptions" /> : 
      <xsl:copy-of select="/cp/strings/bc_wm_autoreply" />
    </xsl:with-param>
    <xsl:with-param name="formaction">wm_autoreply.xsl</xsl:with-param>
    <xsl:with-param name="onload">visibility_autoreply();</xsl:with-param>
    <xsl:with-param name="feedback" select="$message" />
    <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_autoreply" />
    <xsl:with-param name="help_short" select="/cp/strings/wm_autoreply_hlp_short" />
    <xsl:with-param name="help_long" select="/cp/strings/wm_autoreply_hlp_long" />
    <xsl:with-param name="breadcrumb">
      <breadcrumb>
       <section>
         <name><xsl:copy-of select="/cp/strings/bc_wm_autoreply" /></name>
         <url>#</url>
         <image>MailboxOptions</image>
       </section>
      </breadcrumb>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

      <script src="{concat($base_url, '/mail/options/mail_options.js')}" language="JavaScript"></script>
      <input type="hidden" name="autoreply_mail" value="{$autoreply_mail}" />
      <input type="hidden" name="autoreply_message" value="{$autoreply_msg}" />
      <input type="hidden" name="autoreply_replyto" value="{$autoreply_replyto}" />
      <input type="hidden" name="autoreply_subject" value="{$autoreply_subject}" />
      <input type="hidden" name="autoreply_encoding" value="{$autoreply_encoding}" />
      <input type="hidden" name="autoreply_interval" value="{$autoreply_interval}" />
      <input type="hidden" name="save_autoreply" />

      <table class="formview" border="0" cellspacing="0" cellpadding="0">
        <tr class="title">
          <td colspan="2"><xsl:value-of select="/cp/strings/wm_autoreply_title" /></td>
        </tr>
        <tr class="instructionrow">
          <td colspan="2"><xsl:value-of select="/cp/strings/wm_autoreply_instruction" /></td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:value-of select="/cp/strings/wm_autoreply_label" /></td>
          <td class="contentwidth">
            <xsl:choose>
              <xsl:when test="$autoreply_mail='on'">
            <input type="radio" id="autoreply_off" name="groupAutoreply" value="off" onClick="visibility_autoreply();" border="0" /><label for="autoreply_off"><xsl:value-of select="/cp/strings/wm_autoreply_radio_label_1" /></label><br />
            <input type="radio" id="autoreply_on" name="groupAutoreply" value="on" checked="checked" onClick="visibility_autoreply();" border="0" /><label for="autoreply_on"><xsl:value-of select="/cp/strings/wm_autoreply_radio_label_2" /></label><br />
              </xsl:when>
              <xsl:otherwise>
                <input type="radio" id="autoreply_off" name="groupAutoreply" value="off" onClick="visibility_autoreply();" checked="checked" border="0" /><label for="autoreply_off"><xsl:value-of select="/cp/strings/wm_autoreply_radio_label_1" /></label><br />
                <input type="radio" id="autoreply_on" name="groupAutoreply" value="on" onClick="visibility_autoreply();" border="0" /><label for="autoreply_on"><xsl:value-of select="/cp/strings/wm_autoreply_radio_label_2" /></label><br />
              </xsl:otherwise>
            </xsl:choose>
            <br />
            <div class="indent">
            <xsl:value-of select="/cp/strings/wm_autoreply_replyto" /><br />
            <input type="text" name="replyto" size="42" value="{$autoreply_replyto}" />
            </div>
            <br />
            <div class="indent">
            <xsl:value-of select="/cp/strings/wm_autoreply_subject" /><br />
            <input type="text" name="subject" size="42" value="{$autoreply_subject}" />
            </div>
            <br />
            <textarea class="indent" name="textareaName" rows="6" cols="42" ><xsl:value-of select="$autoreply_msg" /></textarea><br />
            <br />
          </td>
        </tr>

        <tr class="rowodd">
          <td class="label"><xsl:value-of select="/cp/strings/wm_autoreply_interval_label" /></td>
          <td class="contentwidth">
            <xsl:choose>
              <xsl:when test="$autoreply_interval='0'">
                <input type="radio" id="interval_none" name="interval" value="0" checked="checked" border="0" /><label for="interval_none"><xsl:value-of select="/cp/strings/wm_autoreply_interval_radio_0" /></label><br />
              </xsl:when>
              <xsl:otherwise>
                <input type="radio" id="interval_none" name="interval" value="0" border="0" /><label for="interval_none"><xsl:value-of select="/cp/strings/wm_autoreply_interval_radio_0" /></label><br />
              </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
              <xsl:when test="$autoreply_interval='1'">
                <input type="radio" id="interval_1day" name="interval" value="1" checked="checked" border="0" /><label for="interval_1day"><xsl:value-of select="/cp/strings/wm_autoreply_interval_radio_1" /></label><br />
              </xsl:when>
              <xsl:otherwise>
                <input type="radio" id="interval_1day" name="interval" value="1" border="0" /><label for="interval_1day"><xsl:value-of select="/cp/strings/wm_autoreply_interval_radio_1" /></label><br />
              </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
              <xsl:when test="$autoreply_interval='3'">
                <input type="radio" id="interval_3days" name="interval" value="3" checked="checked" border="0" /><label for="interval_3days"><xsl:value-of select="/cp/strings/wm_autoreply_interval_radio_3" /></label><br />
              </xsl:when>
              <xsl:otherwise>
                <input type="radio" id="interval_3days" name="interval" value="3" border="0" /><label for="interval_3days"><xsl:value-of select="/cp/strings/wm_autoreply_interval_radio_3" /></label><br />
              </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
              <xsl:when test="$autoreply_interval='7'">
                <input type="radio" id="interval_1week" name="interval" value="7" checked="checked" border="0" /><label for="interval_1week"><xsl:value-of select="/cp/strings/wm_autoreply_interval_radio_7" /></label><br />
              </xsl:when>
              <xsl:otherwise>
                <input type="radio" id="interval_1week" name="interval" value="7" border="0" /><label for="interval_1week"><xsl:value-of select="/cp/strings/wm_autoreply_interval_radio_7" /></label><br />
              </xsl:otherwise>
            </xsl:choose>
          </td>
        </tr>

          <tr class="rowodd">
            <td class="label"><xsl:value-of select="/cp/strings/wm_opt_autoreply_enc"/></td>
            <td class="contentwidth"><select name="encoding">

                  <option value="UTF-8">
                    <xsl:if test="$autoreply_encoding = 'UTF-8'">
                      <xsl:attribute name="selected" value="selected"/>
                    </xsl:if>
                    <xsl:value-of select="/cp/strings/wm_opt_display_utf8"/>
                  </option>

                 <option value="US-ASCII">
                    <xsl:if test="$autoreply_encoding = 'US-ASCII'">
                      <xsl:attribute name="selected" value="selected"/>
                    </xsl:if>
                    <xsl:value-of select="/cp/strings/wm_opt_display_usascii"/>
                  </option>
      
                  <option value="ISO-2022-JP">
                    <xsl:if test="$autoreply_encoding = 'ISO-2022-JP'">
                      <xsl:attribute name="selected" value="selected"/>
                    </xsl:if>
                    <xsl:value-of select="/cp/strings/wm_opt_display_iso2022jp"/>
                  </option>

                  <option value="ISO-8859-1">
                    <xsl:if test="$autoreply_encoding = 'ISO-8859-1'">
                      <xsl:attribute name="selected" value="selected"/>
                    </xsl:if>
                    <xsl:value-of select="/cp/strings/wm_opt_display_iso88591"/>
                  </option>
  
            </select>
            </td>
          </tr>

        <tr class="controlrow">
          <td colspan="2"><span class="floatright"><input type="button" name="save" value="{/cp/strings/wm_autoreply_btn_save}" onClick="validate_autoreply('{cp:js-escape(/cp/strings/wm_autoreply_alertTextMsgRequired)}')" /><input type="submit" name="btnCancel" value="{/cp/strings/wm_autoreply_btn_cancel}" /></span></td>
        </tr>
      </table>
    <br />
    
</xsl:template>
</xsl:stylesheet>


