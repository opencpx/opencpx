<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../global.xsl" />
<xsl:import href="mail_global.xsl" />

<xsl:variable name="message">
      <xsl:call-template name="feedback_table">
        <xsl:with-param name="image">error</xsl:with-param>
        <xsl:with-param name="message">There was an error</xsl:with-param>
      </xsl:call-template>
<!--
  <xsl:choose>
    <xsl:when test="/cp/vsap[@type='error']">
      <xsl:call-template name="feedback_table">
        <xsl:with-param name="image">error</xsl:with-param>
        <xsl:with-param name="message">There was an error</xsl:with-param>
      </xsl:call-template>
     </xsl:when>
     <xsl:otherwise>
      <xsl:call-template name="feedback_table">
        <xsl:with-param name="image">success</xsl:with-param>
        <xsl:with-param name="message">There was an error</xsl:with-param>
      </xsl:call-template>
     </xsl:otherwise>
  </xsl:choose>
-->
</xsl:variable>

<xsl:variable name="messageid">
  <xsl:value-of select="/cp/form/messageid" />
</xsl:variable>

<xsl:variable name="attachment_count">
  <xsl:value-of select="count(/cp/vsap/vsap[@type='webmail:send:attachment:list']/attachment)" />
</xsl:variable>

<xsl:variable name="total_size">
  <xsl:value-of select="sum(/cp/vsap/vsap[@type='webmail:send:attachment:list']/attachment/size)" />
</xsl:variable>   

<xsl:template name="format_size">
  <xsl:param name="size" />
  <xsl:choose>
    <xsl:when test="$size &gt; 0">
      <xsl:value-of select="concat(format-number(($size) div (1024), '#.##'),' ')" />
    </xsl:when>
    <xsl:otherwise>0</xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="/">
  <xsl:call-template name="blankbodywrapper">
    <xsl:with-param name="title">
      <xsl:copy-of select="/cp/strings/wm_title" /> : <xsl:value-of select="/cp/strings/wm_addeditattach_title" />
    </xsl:with-param>
    <xsl:with-param name="formaction">wm_add-edit-attachment.xsl</xsl:with-param>
    <xsl:with-param name="formname">specialwindow</xsl:with-param>
    <xsl:with-param name="formenctype">multipart/form-data</xsl:with-param> 
    <xsl:with-param name="feedback" />
    <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_inbox" />
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

    <!-- Load the mail javascript, and make sure attachments are recorded in the composition window -->
    <script src="{concat($base_url, '/mail/mail.js')}" language="JavaScript"></script>

    <input type="hidden" name="messageid" value="{/cp/form/messageid}" />

      <xsl:for-each select="/cp/vsap/vsap[@type='webmail:send:attachment:list']/attachment">
        <xsl:if test="(string-length(./size) > 0) and (./filename != string(/cp/form/remove))">
          <input type="hidden" name="filename" value="{filename}" />
        </xsl:if>
      </xsl:for-each>

      <!-- Generate the path used to remove all files -->
      <xsl:variable name="remove_all_path">
        <xsl:value-of select="concat('wm_add-edit-attachment.xsl?remove_all=1&amp;messageid=',$messageid)" />
      </xsl:variable>

    <xsl:variable name="inst4_help">
      <xsl:call-template name="transliterate">
        <xsl:with-param name="string"><xsl:value-of select="/cp/strings/wm_addeditattach_step2_inst4"/></xsl:with-param>
        <xsl:with-param name="search">__TOTAL__</xsl:with-param>
        <xsl:with-param name="replace" select="$attachment_count"/>
      </xsl:call-template>
    </xsl:variable>

      <!-- Load the mail javascript and make sure attachments are recorded in the composition window -->
      <xsl:if test="$attachment_count &lt; 5"> 
        <table class="webmailpopup" border="0" cellspacing="0" cellpadding="0">
          <tr class="title">
            <td colspan="2"><xsl:value-of select="/cp/strings/wm_addeditattach_title" /></td>
          </tr>
          <tr class="rowodd">
            <td class="label"><xsl:value-of select="/cp/strings/wm_addeditattach_step1_title" /></td>
            <td><xsl:value-of select="/cp/strings/wm_addeditattach_step1_click" /><strong><xsl:value-of select="/cp/strings/wm_addeditattach_step1_browse" /></strong><xsl:value-of select="/cp/strings/wm_addeditattach_step1_instr" /><br />
              <input type="file" name="fileupload" size="23" /><br />
              <span class="parenthetichelp"><xsl:value-of select="/cp/strings/wm_addeditattach_step1_help" /></span><br />
            </td>
          </tr>
          <tr class="roweven">
            <td class="label"><xsl:value-of select="/cp/strings/wm_addeditattach_step2_title" /></td>
            <td><xsl:value-of select="/cp/strings/wm_addeditattach_step2_click" /><strong><xsl:value-of select="/cp/strings/wm_addeditattach_step2_attachfile" /></strong><xsl:value-of select="/cp/strings/wm_addeditattch_step2_period" /><input type="submit" name="attach_file" value="{/cp/strings/wm_addeditattach_step2_bt_attachfile}" />&#160;<br />

            </td>
          </tr>
          <tr class="instructionrow">
            <td colspan="2"><xsl:value-of select="/cp/strings/wm_addeditattach_step2_inst1" /><br />
               <xsl:value-of select="/cp/strings/wm_addeditattach_step2_inst2" /><br />
               
              <hr />
              <xsl:value-of select="/cp/strings/wm_addeditattach_step2_inst3" />
              <xsl:value-of select="$inst4_help" />&#160;<xsl:value-of select="/cp/strings/wm_addeditattach_step2_inst5" /><br />
            </td>
          </tr>
        </table>
      </xsl:if>

    <xsl:if test="$attachment_count = 5">
     <table class="webmailpopup" border="0" cellspacing="0" cellpadding="0">
      <tr class="title">
        <td colspan="2"><xsl:value-of select="/cp/strings/wm_addeditattach_title" /></td>
      </tr>
      <tr class="instructionrow">
       <td>
        <xsl:value-of select="$inst4_help"/>
        <br/>
       </td>
      </tr>
     </table>
    </xsl:if>
  
        <!--table of attached files goes here-->
        <xsl:if test="$attachment_count &gt; 0">
        <table class="webmailpopup" border="0" cellspacing="1" cellpadding="2" width="100%">
            <tr height="1">
              <td colspan="3" bgcolor="black" height="1"></td>
            </tr>
            <tr class="columnhead">
            <td class="attachedfilecolumnpopup" align="left"><span class="tableHeaderLabel"><heading_attachedfile><xsl:value-of select="/cp/strings/wm_addeditattach_attachedfile" /></heading_attachedfile></span></td>
            <td class="sizecolumnpopup" width="90"><span class="tableHeaderLabel"><heading_size><xsl:value-of select="/cp/strings/wm_addeditattach_size" /></heading_size></span></td>
            <td class="actioncolumnpopup" width="90"><span class="tableHeaderLabel"><heading_actions><xsl:value-of select="/cp/strings/wm_addeditattach_actions" /></heading_actions></span></td>
          </tr>
          <xsl:for-each select="/cp/vsap/vsap[@type='webmail:send:attachment:list']/attachment">
            <xsl:variable name="remove_file">
              <xsl:value-of select="concat('wm_add-edit-attachment.xsl?messageid=',$messageid,'&amp;remove=',url_filename)" />
            </xsl:variable>
            <tr class="rowodd">
              <td width="60%">
                <xsl:call-template name="truncate">
                  <xsl:with-param name="string"><xsl:value-of select="filename" /></xsl:with-param>
                  <xsl:with-param name="fieldlength"><xsl:copy-of select="/cp/strings/wm_addeditattach_name_fieldlength" /></xsl:with-param>
                </xsl:call-template>
              </td>
              <td class="rightalign">
                <xsl:call-template name="format_bytes">
                  <xsl:with-param name="bytes" select="size" />
                </xsl:call-template>
              </td>
              <td><a href="{$remove_file}"><xsl:copy-of select="/cp/strings/wm_addeditattach_remove" /></a></td>
            </tr>
          </xsl:for-each>
          <tr class="roweven">
            <td><strong><xsl:copy-of select="/cp/strings/wm_addeditattach_total" /></strong><br /></td>
            <td class="rightalign">
              <xsl:call-template name="format_bytes">
                <xsl:with-param name="bytes" select="$total_size" />
              </xsl:call-template>
            </td>
            <td><a href="{$remove_all_path}"><xsl:value-of select="/cp/strings/wm_addeditattach_removeall" /></a></td>
          </tr>
          <tr height="1">
            <td colspan="3" bgcolor="black" height="1"></td>
          </tr>
        </table>
        </xsl:if>

        <table class="webmailpopup" border="0" cellspacing="0" cellpadding="0">
          <tr class="roweven">
            <td class="label"><xsl:value-of select="/cp/strings/wm_addeditattach_step3_title" /></td>
            <td><xsl:value-of select="/cp/strings/wm_addeditattach_step3_click" /><strong><xsl:value-of select="/cp/strings/wm_addeditattach_step3_done" /></strong><xsl:value-of select="/cp/strings/wm_addeditattach_step3_inst" /><br />
            </td>
          </tr>
          <tr class="controlrow">
            <td colspan="2"><input class="floatright" onClick="RecordAttachments('{cp:js-escape(/cp/strings/wm_addeditattach_default)}');window.close()" type="button" name="goback" value="{/cp/strings/wm_addeditattach_bt_done}" /></td>
          </tr>
        </table>

</xsl:template>
</xsl:stylesheet>
  
