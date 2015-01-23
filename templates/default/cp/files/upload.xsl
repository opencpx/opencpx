<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
 <xsl:import href="../cp_global.xsl"/>

 <xsl:variable name="feedback">
  <xsl:if test="/cp/vsap/vsap[@type='error']/code = 104">
   <xsl:call-template name="feedback_table">
    <xsl:with-param name="image">error</xsl:with-param>
    <xsl:with-param name="message"><xsl:copy-of select="/cp/strings/error_quota_exceeded"/></xsl:with-param>
   </xsl:call-template>
  </xsl:if>
 </xsl:variable>

 <xsl:variable name="sessionID">
  <xsl:choose>
   <xsl:when test="/cp/form/sessionID"><xsl:value-of select="/cp/form/sessionID"/></xsl:when>
   <xsl:otherwise><xsl:value-of select="/cp/vsap/vsap[@type='files:upload:list']/sessionid"/></xsl:otherwise>
  </xsl:choose>
 </xsl:variable>

 <xsl:variable name="uploadCount">
  <xsl:value-of select="count(/cp/vsap/vsap[@type='files:upload:list']/upload)"/>
 </xsl:variable>

 <xsl:variable name="totalSize">
  <xsl:value-of select="sum(/cp/vsap/vsap[@type='files:upload:list']/upload/size)"/>
 </xsl:variable>

 <xsl:variable name="userType">
  <xsl:choose>
   <xsl:when test="/cp/vsap/vsap[@type='auth']/server_admin">
     <xsl:choose>
       <xsl:when test="/cp/vsap/vsap[@type='auth']/siteprefs/limited-file-manager">da</xsl:when>
       <xsl:otherwise>sa</xsl:otherwise>
     </xsl:choose>
   </xsl:when>
   <xsl:when test="/cp/vsap/vsap[@type='auth']/domain_admin">da</xsl:when>
   <xsl:otherwise>eu</xsl:otherwise>
  </xsl:choose>
 </xsl:variable>

 <xsl:variable name="numEndUsers">
  <xsl:if test="$userType = 'da'">
   <xsl:value-of select="count(/cp/vsap/vsap[@type='user:list:eu']/user)"/>
  </xsl:if>
 </xsl:variable>

 <xsl:variable name="currentUser">
  <xsl:if test="$userType = 'da' and $numEndUsers > 1">
   <xsl:choose>
    <xsl:when test="string(/cp/form/currentUser)">
     <xsl:value-of select="/cp/form/currentUser"/>
    </xsl:when>
    <xsl:otherwise>
     <xsl:value-of select="/cp/vsap/vsap[@type='auth']/username"/>
    </xsl:otherwise>
   </xsl:choose>
  </xsl:if>
 </xsl:variable>

 <xsl:variable name="currentDir">
   <xsl:value-of select="/cp/form/currentDir"/>
 </xsl:variable>

 <xsl:template name="formatSize">
  <xsl:param name="size"/>
  <xsl:choose>
   <xsl:when test="$size &gt; 0">
    <xsl:value-of select="concat(format-number(($size) div (1024), '#.##'),' ')"/>
   </xsl:when>
   <xsl:otherwise>0</xsl:otherwise>
  </xsl:choose>
 </xsl:template>

 <xsl:template match="/">
  <xsl:call-template name="blankbodywrapper">
   <xsl:with-param name="title">
    <xsl:value-of select="/cp/strings/cp_title"/> : <xsl:value-of select="/cp/strings/nv_menu_filemanager"/> : <xsl:value-of select="/cp/strings/file_upload_title"/>
   </xsl:with-param>
   <xsl:with-param name="formaction">upload.xsl</xsl:with-param>
   <xsl:with-param name="formname">specialwindow</xsl:with-param>
   <xsl:with-param name="formenctype">multipart/form-data</xsl:with-param>
   <xsl:with-param name="onload">document.forms[0].fileupload.focus();</xsl:with-param>
   <xsl:with-param name="feedback" select="$feedback" />
   <xsl:with-param name="selected_navandcontent" select="x"/>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

    <xsl:if test="/cp/form/action = 'ok'">
     <script>
      window.opener.location = 'index.xsl?currentDir=<xsl:value-of select="/cp/form/currentDir"/>&amp;currentUser=<xsl:value-of select="/cp/form/currentUser"/>';
     </script>
    </xsl:if>
    <xsl:if test="/cp/form/action != ''">
     <script>
      window.close();
     </script>
    </xsl:if>

    <input type="hidden" name="sessionID" value="{$sessionID}"/>
    <input type="hidden" name="currentDir" value="{$currentDir}"/>
    <input type="hidden" name="currentUser" value="{$currentUser}"/>
    <input type="hidden" name="action" value=""/>
    <xsl:for-each select="/cp/vsap/vsap[@type='files:upload:list']/upload">
     <xsl:if test="(string-length(./size) > 0) and (./filename != string(/cp/form/remove))">
      <input type="hidden" name="filename" value="{filename}"/>
     </xsl:if>
    </xsl:for-each> 

    <!-- Generate the path used to remove all files -->
    <xsl:variable name="removeAllPath">
     <xsl:value-of select="concat('upload.xsl?sessionID=',$sessionID)"/>
     <xsl:for-each select="/cp/vsap/vsap[@type='files:upload:list']/upload">
      <xsl:value-of select="concat('&amp;remove=',filename)"/>
     </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="inst4_help">
      <xsl:call-template name="transliterate">
        <xsl:with-param name="string"><xsl:value-of select="/cp/strings/file_upload_step2_inst4"/></xsl:with-param>
        <xsl:with-param name="search">__TOTAL__</xsl:with-param>
        <xsl:with-param name="replace" select="$uploadCount"/>
      </xsl:call-template>
    </xsl:variable>

    <xsl:if test="$uploadCount &lt; 5">
     <table class="uploadpopup" border="0" cellspacing="0" cellpadding="0">
      <tr class="columnhead">
       <td colspan="2">
        <xsl:value-of select="/cp/strings/file_upload_title"/>
       </td>
      </tr>
      <tr class="rowodd">
       <td class="label">
        <xsl:value-of select="/cp/strings/file_upload_step1_title"/>
       </td>
       <td>
        <xsl:value-of select="/cp/strings/file_upload_step1_click"/>
        <strong>
         <xsl:value-of select="/cp/strings/file_upload_step1_browse"/>
        </strong>
        <xsl:value-of select="/cp/strings/file3_upload_step1_instr"/>
        <br/>
        <input type="file" name="fileupload" size="23"/>
        <br/>
        <span class="parenthetichelp">
         <xsl:value-of select="/cp/strings/file_upload_step1_help"/>
        </span>
        <br/>
       </td>
      </tr>
      <tr class="roweven">
       <td class="label">
        <xsl:value-of select="/cp/strings/file_upload_step2_title"/>
       </td>
       <td>
        <xsl:value-of select="/cp/strings/file_upload_step2_click"/>
        <strong>
         <xsl:value-of select="/cp/strings/file_upload_step2_uploadfile"/>
        </strong>
        <xsl:value-of select="/cp/strings/file_upload_step2_period"/>
        <xsl:choose>
         <xsl:when test="/cp/vsap/vsap[@type='auth']/platform = 'freebsd4'">
          <input type="submit" name="attachFile" onClick="window.open('upload_progress.xsl?sessionID={$sessionID}','UploadProgress','scrollbars=yes,resizable=yes,width=540,height=210,screenX=30,screenY=260,top=260,left=30');" value="{/cp/strings/file_upload_step2_bt_uploadfile}"/>&#160;<br/>
         </xsl:when>
         <xsl:otherwise>
          <!-- progress bar does not work yet for Apache2 because hook_data not implemented -->
          <input type="submit" name="attachFile" value="{/cp/strings/file_upload_step2_bt_uploadfile}"/>&#160;<br/>
         </xsl:otherwise>
        </xsl:choose>
       </td>
      </tr>
      <tr class="instructionrow">
       <td colspan="2">
        <xsl:value-of select="/cp/strings/file_upload_step2_inst1"/>
        <br/>
        <xsl:value-of select="/cp/strings/file_upload_step2_inst2"/>
        <br/>
        <hr/>
        <xsl:value-of select="/cp/strings/file_upload_step2_inst3"/>
        <xsl:value-of select="$inst4_help"/>&#160;<xsl:value-of select="/cp/strings/file_upload_step2_inst5"/>
        <br/>
       </td>
      </tr>
     </table>
    </xsl:if>

    <xsl:if test="$uploadCount = 5">
     <table class="uploadpopup" border="0" cellspacing="0" cellpadding="0">
      <tr class="columnhead">
       <td colspan="2">
        <xsl:value-of select="/cp/strings/file_upload_title"/>
       </td>
      </tr>
      <tr class="instructionrow">
       <td>
        <xsl:value-of select="$inst4_help"/> 
        <br/>
       </td>
      </tr>
     </table>
    </xsl:if>

    <!--table of uploaded files goes here-->
    <xsl:if test="$uploadCount &gt; 0">
     <table class="uploadpopup" border="0" cellspacing="1" cellpadding="2" width="100%">
      <tr height="1">
       <td colspan="3" bgcolor="black" height="1"/>
      </tr>
      <tr class="columnhead">
       <td class="attachedfilecolumnpopup" align="left">
        <span class="tableHeaderLabel">
         <heading_attachedfile>
          <xsl:value-of select="/cp/strings/file_upload_uploadedfile"/>
         </heading_attachedfile>
        </span>
       </td>
       <td class="sizecolumnpopup" width="90">
        <span class="tableHeaderLabel">
         <heading_size>
          <xsl:value-of select="/cp/strings/file_upload_size"/>
         </heading_size>
        </span>
       </td>
       <td class="actioncolumnpopup" width="90">
        <span class="tableHeaderLabel">
         <heading_actions>
          <xsl:value-of select="/cp/strings/file_upload_actions"/>
         </heading_actions>
        </span>
       </td>
      </tr>
      <xsl:for-each select="/cp/vsap/vsap[@type='files:upload:list']/upload">
       <xsl:variable name="removeFile">
        <xsl:value-of select="concat('upload.xsl?sessionID=',$sessionID,'&amp;remove=',filename,'&amp;currentDir=',$currentDir,'&amp;currentUser=',$currentUser)"/>
       </xsl:variable>
       <tr class="rowodd">
        <td width="60%">
         <xsl:call-template name="truncate">
          <xsl:with-param name="string">
           <xsl:value-of select="filename"/>
          </xsl:with-param>
          <xsl:with-param name="fieldlength">
           <xsl:copy-of select="/cp/strings/file_upload_name_fieldlength"/>
          </xsl:with-param>
         </xsl:call-template>
        </td>
        <td class="rightalign">
         <xsl:call-template name="format_bytes">
          <xsl:with-param name="bytes" select="size"/>
         </xsl:call-template>
        </td>
        <td>
         <a onClick="removeSingleFileUpload('{$removeFile}'); return false" href="{$removeFile}">
          <xsl:copy-of select="/cp/strings/file_upload_remove"/>
         </a>
        </td>
       </tr>
      </xsl:for-each>
      <tr class="roweven">
       <td>
        <strong>
         <xsl:copy-of select="/cp/strings/file_upload_total"/>
        </strong>
        <br/>
       </td>
       <td class="rightalign">
        <xsl:call-template name="format_bytes">
         <xsl:with-param name="bytes" select="$totalSize"/>
        </xsl:call-template>
       </td>
       <td>
        <a href="{$removeAllPath}">
         <xsl:value-of select="/cp/strings/file_upload_removeall"/>
        </a>
       </td>
      </tr>
      <tr height="1">
       <td colspan="3" bgcolor="black" height="1"/>
      </tr>
     </table>
    </xsl:if>
    <table class="uploadpopup" border="0" cellspacing="0" cellpadding="0">
     <tr class="roweven">
      <td class="label">
       <xsl:value-of select="/cp/strings/file_upload_step3_title"/>
      </td>
      <td>
       <xsl:value-of select="/cp/strings/file_upload_step3_click"/>
       <strong>
        <xsl:value-of select="/cp/strings/file_upload_step3_done"/>
       </strong>
       <xsl:value-of select="/cp/strings/file_upload_step3_inst"/>
       <br/>
      </td>
     </tr>
     <tr class="controlrow">
      <td>
        <table cellspacing="1" cellpadding="0" border="0">
         <tr>
          <td>
           <input type="checkbox" id="overwrite" name="overwrite" value="true">
            <xsl:choose>
              <xsl:when test="/cp/form/overwrite='true'"><xsl:attribute name="checked"/></xsl:when>
              <xsl:when test="$uploadCount=0"><xsl:attribute name="checked"/></xsl:when>
            </xsl:choose>
           </input></td>
          <td><label for="overwrite"><xsl:value-of select="/cp/strings/file_upload_replace_checkbox"/></label></td>
         </tr>
        </table>
      </td>
      <td>
       <input class="floatright" type="button" onClick="document.forms[0].elements['action'].value = 'cancel';document.forms[0].encoding='application/x-www-form-urlencoded';document.forms[0].submit()" name="cancel" value="{/cp/strings/file_upload_bt_cancel}"/>
       <input class="floatright" type="button" onClick="document.forms[0].elements['action'].value = 'ok';document.forms[0].encoding='application/x-www-form-urlencoded';document.forms[0].submit()" name="ok" value="{/cp/strings/file_upload_bt_done}"/>
      </td>
     </tr>
    </table>

 </xsl:template>
</xsl:stylesheet>
