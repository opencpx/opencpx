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

<xsl:variable name="oldfolder">
  <xsl:choose>
    <xsl:when test="string(/cp/form/folder)">
     <xsl:value-of select="/cp/form/folder" />
    </xsl:when>
    <xsl:otherwise>
     <xsl:value-of select="/cp/form/oldfolder" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="newfolder">
  <xsl:choose>
    <xsl:when test="string(/cp/form/newfolder)">
     <xsl:value-of select="/cp/form/newfolder" />
    </xsl:when>
  </xsl:choose>
</xsl:variable>

<xsl:template match="/">
  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title">
      <xsl:copy-of select="/cp/strings/wm_title" /> : <xsl:copy-of select="/cp/strings/bc_wm_folders" /> : <xsl:copy-of select="/cp/strings/bc_wm_renamefolder" /> : <xsl:value-of select="$oldfolder" />
    </xsl:with-param>
    <xsl:with-param name="formaction">wm_renamefolder.xsl</xsl:with-param>
    <xsl:with-param name="feedback" select="$message" />
    <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_folders"
/>
    <xsl:with-param name="help_short" select="/cp/strings/wm_renamefolder_hlp_short" />
    <xsl:with-param name="help_long" select="/cp/strings/wm_renamefolder_hlp_long" />
    <xsl:with-param name="breadcrumb">
      <breadcrumb>
       <section>
         <name><xsl:copy-of select="/cp/strings/bc_wm_folders" /></name>
         <url><xsl:value-of select="$base_url" />/mail/wm_folders.xsl</url>
         <image>FolderManagement</image>
       </section>
       <section>
         <name><xsl:copy-of select="/cp/strings/bc_wm_renamefolder" /></name>
         <url>#</url>
       </section>
      </breadcrumb>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

      <script src="{concat($base_url, '/mail/mail.js')}" language="JavaScript"></script>
      <input type="hidden" name="oldfolder" value="{$oldfolder}" />
      <input type="hidden" name="save_rename" />
      <table class="formview" border="0" cellspacing="0" cellpadding="0">
        <tr class="title">
          <td colspan="2"><xsl:value-of select="/cp/strings/wm_renamefolder_title" /></td>
        </tr>
        <tr class="instructionrow">
          <td colspan="2"><xsl:value-of select="/cp/strings/wm_renamefolder_instruction" /><br />
          </td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:value-of select="/cp/strings/wm_renamefolder_currentfoldername" /></td>
          <td class="contentwidth"><xsl:value-of select="$oldfolder" /></td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:value-of select="/cp/strings/wm_renamefolder_newfoldername" /></td>
          <td class="contentwidth"><input type="text" name="newfolder" size="40" value="{$newfolder}" maxlength="150" />&#160;<span class="parenthetichelp"><xsl:value-of select="/cp/strings/wm_renamefolder_newfoldernamelimit" /></span></td>
        </tr>
                
        <tr class="controlrow">
          <td colspan="2"><span class="floatright"><input type="button" name="save" value="{/cp/strings/wm_renamefolder_newfoldersave}" onClick="verifyRenameFolder('{cp:js-escape(/cp/strings/wm_renamefolder_alertTxtNoFolderMsg)}','{cp:js-escape(/cp/strings/wm_renamefolder_alertTxtBadFolderName)}')" /><input type="submit" name="cancel" value="{/cp/strings/wm_renamefolder_newfoldercancel}" /></span></td>
        </tr>
      </table>

</xsl:template>
</xsl:stylesheet>

