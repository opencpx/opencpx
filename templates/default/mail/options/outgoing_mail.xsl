<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
  xmlns:exslt="http://exslt.org/common"
  exclude-result-prefixes="exslt">

<xsl:import href="../mail_global.xsl" />

<xsl:variable name="message">
  <xsl:if test="string(/cp/msgs/msg)">
    <xsl:copy-of select="/cp/strings/*[local-name()=/cp/msgs/msg/@name]" />
  </xsl:if>
</xsl:variable>

<xsl:variable name="feedback">
  <xsl:if test="$message != ''">
    <xsl:call-template name="feedback_table">
      <xsl:with-param name="image">
        <xsl:choose>
          <xsl:when test="/cp/vsap/vsap[@type='error'] or /cp/msgs/msg='error'">error</xsl:when>
          <xsl:otherwise>success</xsl:otherwise>
        </xsl:choose>
      </xsl:with-param>
      <xsl:with-param name="message">
        <xsl:copy-of select="$message" />
      </xsl:with-param>
    </xsl:call-template>
  </xsl:if>
</xsl:variable>

<xsl:variable name="default_mailbox">
  <xsl:value-of select="/cp/vsap/vsap[@type='auth']/username" />@<xsl:value-of select="/cp/vsap/vsap[@type='user:properties']/user/domain"/>
</xsl:variable>

<xsl:variable name="preferred_from">
  <xsl:choose>
    <xsl:when test="string(/cp/form/preferred_from)">
      <xsl:value-of select="/cp/form/preferred_from" />
    </xsl:when>
    <xsl:when test="string(/cp/vsap/vsap[@type='webmail:options:load']/webmail_options/preferred_from)">
      <xsl:value-of select="/cp/vsap/vsap[@type='webmail:options:load']/webmail_options/preferred_from" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$default_mailbox" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="preferred_replyto">
  <xsl:choose>
    <xsl:when test="string(/cp/form/reply_to_select)">
      <xsl:value-of select="/cp/form/reply_to_select" />
    </xsl:when>
    <xsl:when test="string(/cp/vsap/vsap[@type='webmail:options:load']/webmail_options/reply_to)">
      <xsl:value-of select="/cp/vsap/vsap[@type='webmail:options:load']/webmail_options/reply_to" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$default_mailbox" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:template match="/">
<xsl:call-template name="bodywrapper">

  <xsl:with-param name="title">
    <xsl:copy-of select="/cp/strings/wm_title" /> : <xsl:copy-of select="/cp/strings/nv_menu_webmailoptions" /> : <xsl:copy-of select="/cp/strings/bc_opt_outgoing" />
  </xsl:with-param>

  <xsl:with-param name="formaction">outgoing_mail.xsl</xsl:with-param>
  <xsl:with-param name="feedback"><xsl:copy-of select="$feedback" /></xsl:with-param>

  <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_outgoing" />
  <xsl:with-param name="help_short" select="/cp/strings/wm_outgoing_hlp_short" />
  <xsl:with-param name="help_long" select="/cp/strings/wm_outgoing_hlp_long" />
  <xsl:with-param name="breadcrumb">
    <breadcrumb>
      <section>
        <name><xsl:copy-of select="/cp/strings/bc_opt_outgoing" /></name>
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
            <td colspan="2"><xsl:copy-of select="/cp/strings/wm_opt_outgoing_title" /></td>
          </tr>
          <tr class="instructionrow">
            <td colspan="2"><xsl:value-of select="/cp/strings/wm_opt_outgoing_instr"/></td>
          </tr>
          <tr class="rowodd">
            <td class="label"><xsl:value-of select="/cp/strings/wm_opt_outgoing_fromname"/></td>
            <td class="contentwidth"><xsl:value-of select="/cp/strings/wm_opt_outgoing_fromname_instr"/><br />
               <input type="text" name="from_name" size="60" value="{/cp/vsap/vsap/webmail_options/from_name}"/></td>
          </tr>
          <tr class="roweven">
            <td class="label"><xsl:value-of select="/cp/strings/wm_opt_outgoing_primaryemail"/></td>
            <td class="contentwidth"><xsl:value-of select="/cp/strings/wm_opt_outgoing_primaryemail_instr"/><br />
              <select name="preferred_from" size="1">
                <xsl:for-each select="/cp/vsap/vsap[@type='mail:addresses:list']/address">
                  <xsl:if test="not(starts-with(source, '@'))">
                    <xsl:choose>
                      <xsl:when test="source = $preferred_from">
                        <option value="{source}" selected="true"><xsl:value-of select="source" /></option>
                      </xsl:when>
                      <xsl:otherwise>
                        <option value="{source}"><xsl:value-of select="source" /></option>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:if>
                </xsl:for-each>
              </select></td>
          </tr>
          <tr class="rowodd">
            <td class="label"><xsl:value-of select="/cp/strings/wm_opt_outgoing_replyto"/></td>
            <td class="contentwidth">
                <input type="radio" id="replyto_select" name="reply_to_toggle" value="select" border="0">
                  <xsl:if test="/cp/vsap/vsap/webmail_options/reply_to_toggle = 'select'">
                    <xsl:attribute name="checked" value="checked"/>
                  </xsl:if>
                </input>
                <label for="replyto_select"><xsl:value-of select="/cp/strings/wm_opt_outgoing_replyto_select"/></label>
                <select name="reply_to_select" size="1">
                  <xsl:for-each select="/cp/vsap/vsap[@type='mail:addresses:list']/address">
                    <xsl:if test="not(starts-with(source, '@'))">
                      <xsl:choose>
                        <xsl:when test="source = $preferred_replyto">
                          <option value="{source}" selected="true"><xsl:value-of select="source" /></option>
                        </xsl:when>
                        <xsl:otherwise>
                          <option value="{source}"><xsl:value-of select="source" /></option>
                        </xsl:otherwise>
                      </xsl:choose>
                    </xsl:if>
                  </xsl:for-each>
              </select><br />
               <input type="radio" id="replyto_specify" name="reply_to_toggle" value="input" border="0">
                  <xsl:if test="/cp/vsap/vsap/webmail_options/reply_to_toggle = 'input'">
                    <xsl:attribute name="checked" value="checked"/>
                  </xsl:if>
                </input>
               <label for="replyto_specify"><xsl:value-of select="/cp/strings/wm_opt_outgoing_replyto_fill"/></label><br />
               <input class="indent" type="text" name="reply_to_input" size="60"  value="{/cp/vsap/vsap/webmail_options/reply_to}"/></td>
          </tr>
          <tr class="roweven">
            <td class="label"><xsl:value-of select="/cp/strings/wm_opt_outgoing_sig"/></td>
            <td class="contentwidth">
              <input type="radio" id="sig_off" name="signature_toggle" value="off" border="0">
                <xsl:if test="/cp/vsap/vsap/webmail_options/signature_toggle = 'off'">
                  <xsl:attribute name="checked" value="checked"/>
                </xsl:if>
              </input>
              <label for="sig_off"><xsl:value-of select="/cp/strings/wm_opt_outgoing_sig_no_instr"/></label><br />
              <input type="radio" id="sig_on" name="signature_toggle" value="on" border="0">
                <xsl:if test="/cp/vsap/vsap/webmail_options/signature_toggle = 'on'">
                 <xsl:attribute name="checked" value="checked"/>
               </xsl:if>
              </input>
              <label for="sig_on"><xsl:value-of select="/cp/strings/wm_opt_outgoing_sig_yes_instr"/></label><br />
              <textarea class="indent" name="signature" rows="5" cols="60" >
                <xsl:value-of select="/cp/vsap/vsap/webmail_options/signature"/>
              </textarea></td>
          </tr>
          <tr class="rowodd">
            <xsl:variable name="out_enc" select="/cp/vsap/vsap/webmail_options/outbound_encoding"/>
            <td class="label"><xsl:value-of select="/cp/strings/wm_opt_outgoing_enc"/></td>
            <td class="contentwidth"><select name="outbound_encoding">

                  <option value="UTF-8">
                    <xsl:if test="$out_enc = 'UTF-8'">
                      <xsl:attribute name="selected" value="selected"/>
                    </xsl:if>
                    <xsl:value-of select="/cp/strings/wm_opt_display_utf8"/>
                  </option>

                 <option value="US-ASCII">
                    <xsl:if test="$out_enc = 'US_ASCII'">
                      <xsl:attribute name="selected" value="selected"/>
                    </xsl:if>
                    <xsl:value-of select="/cp/strings/wm_opt_display_usascii"/>
                  </option>
      
                  <option value="ISO-2022-JP">
                    <xsl:if test="$out_enc = 'ISO-2022-JP'">
                      <xsl:attribute name="selected" value="selected"/>
                    </xsl:if>
                    <xsl:value-of select="/cp/strings/wm_opt_display_iso2022jp"/>
                  </option>

                  <option value="ISO-8859-1">
                    <xsl:if test="$out_enc = 'ISO-8859-1'">
                      <xsl:attribute name="selected" value="selected"/>
                    </xsl:if>
                    <xsl:value-of select="/cp/strings/wm_opt_display_iso88591"/>
                  </option>
  
            </select>
            <br />
            <span class="tableCellLabelSmall"><xsl:text> </xsl:text>
               <xsl:copy-of select="/cp/strings/wm_opt_outgoing_warn_encoding" /> </span>
            </td>
          </tr>
          <tr class="roweven">
            <td class="label"><xsl:value-of select="/cp/strings/wm_opt_outgoing_save"/></td>
            <td class="contentwidth">
              <input type="radio" id="fcc_yes" name="fcc" value="yes" border="0">
                 <xsl:if test="/cp/vsap/vsap/webmail_options/fcc ='yes'">
                  <xsl:attribute name="checked" value="checked"/>
                </xsl:if>
              </input>
              <label for="fcc_yes"><xsl:value-of select="/cp/strings/wm_opt_outgoing_saveyes"/></label><br />
              <input type="radio" id="fcc_no" name="fcc" value="no" border="0">
                <xsl:if test="/cp/vsap/vsap/webmail_options/fcc ='no'">
                  <xsl:attribute name="checked" value="checked"/>
                </xsl:if>
              </input>
              <label for="fcc_no"><xsl:value-of select="/cp/strings/wm_opt_outgoing_saveno"/></label><br />
            </td>
          </tr>
          <tr class="controlrow">
            <td colspan="2"><span class="floatright"><input type="submit" name="save" value="{/cp/strings/wm_opt_outgoing_save_btn}" /><input type="submit" name="cancel" value="{/cp/strings/wm_opt_outgoing_cancel_btn}" /></span></td>
          </tr>
        </table>
        <br />

</xsl:template>
</xsl:stylesheet>

