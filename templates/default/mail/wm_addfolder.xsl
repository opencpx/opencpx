<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="mail_global.xsl" />
<xsl:import href="mail_folders_feedback.xsl" />

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

<xsl:variable name="newfolder">
  <xsl:choose>
    <xsl:when test="string(/cp/form/save_another) and not(string(/cp/form/vsap/vsap[@type='error']))"></xsl:when>
    <xsl:when test="string(/cp/form/newfolder)">
     <xsl:value-of select="/cp/form/newfolder" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:template match="/">
  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title">
      <xsl:copy-of select="/cp/strings/wm_title" /> : <xsl:copy-of select="/cp/strings/bc_wm_addfolder" />
    </xsl:with-param>
    <xsl:with-param name="formaction">wm_addfolder.xsl</xsl:with-param>
    <xsl:with-param name="feedback" select="$message" />
    <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_add_folder" />
    <xsl:with-param name="help_short" select="/cp/strings/wm_addfolder_hlp_short" />
    <xsl:with-param name="help_long" select="/cp/strings/wm_addfolder_hlp_long" />
    <xsl:with-param name="breadcrumb">
      <breadcrumb>
       <section>
         <name><xsl:copy-of select="/cp/strings/bc_wm_addfolder" /></name>
         <url>#</url>
         <image>FolderManagement</image>
       </section>
      </breadcrumb>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

      <script src="{concat($base_url, '/mail/mail.js')}" language="JavaScript"></script>
      <input type="hidden" name="save_folder" />
      <input type="hidden" name="save_another" />
      <input type="hidden" name="cancel" value="" />
      <xsl:if test="/cp/vsap/vsap[@type='webmail:options:load']/webmail_options/use_mailboxlist='yes'">
        <input type="hidden" name="subscribe_folder" value="yes" />
      </xsl:if>
      <table class="formview" border="0" cellspacing="0" cellpadding="0">
        <tr class="title">
          <td colspan="2"><xsl:value-of select="/cp/strings/wm_addfolder_title" /></td>
        </tr>
        <tr class="instructionrow">
          <td colspan="2"><xsl:value-of select="/cp/strings/wm_addfolder_instruction" /><br />
          </td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:value-of select="/cp/strings/wm_addfolder_newfoldername" /></td>
          <td class="contentwidth"><input type="text" name="newfolder" size="40" value="{$newfolder}" maxlength="150" />&#160;<span class="parenthetichelp"><xsl:value-of select="/cp/strings/wm_addfolder_newfoldernamelimit" /></span></td>
        </tr>
        <tr class="controlrow">
          <td colspan="2">
            <span class="floatright">
              <input type="submit" name="save" value="{/cp/strings/wm_addfolder_newfoldersave}" 
                onClick="return verifyAddFolder('save','{cp:js-escape(/cp/strings/wm_addfolder_alertNoFolderMsg)}','{cp:js-escape(/cp/strings/wm_addfolder_alertBadFolderName)}');" />
              <input type="button" name="another" value="{/cp/strings/wm_addfolder_options}" 
                onClick="verifyAddFolder('another','{cp:js-escape(/cp/strings/wm_addfolder_alertNoFolderMsg)}','{cp:js-escape(/cp/strings/wm_addfolder_alertBadFolderName)}');" />
              <input type="button" name="btn_cancel" value="{/cp/strings/wm_addfolder_newfoldercancel}" 
                onClick="document.forms[0].cancel.value='yes';document.forms[0].submit();" />
            </span>
          </td>
        </tr>
      </table>

</xsl:template>
</xsl:stylesheet>
