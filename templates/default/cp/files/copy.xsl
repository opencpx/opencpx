<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" xmlns:exslt="http://exslt.org/common">
 <xsl:import href="../cp_global.xsl"/>
 <xsl:import href="file_global.xsl"/>

 <xsl:variable name="message">
   <xsl:choose>
     <xsl:when test="/cp/msgs/msg[@name='not_authorized']">
       <xsl:copy-of select="/cp/strings/cp_msg_file_copy_fail" /> &gt;
       <xsl:copy-of select="/cp/strings/error_not_authorized" />
     </xsl:when>
     <xsl:when test="/cp/msgs/msg[@name='invalid_path']">
       <xsl:copy-of select="/cp/strings/cp_msg_file_copy_fail" /> &gt;
       <xsl:copy-of select="/cp/strings/error_invalid_path" />
     </xsl:when>
     <xsl:when test="/cp/msgs/msg[@name='copy_failed']">
       <xsl:copy-of select="/cp/strings/cp_msg_file_copy_fail" /> &gt;
       <xsl:copy-of select="/cp/strings/cp_msg_file_copy_command_failed" />
     </xsl:when>
     <xsl:when test="/cp/msgs/msg[@name='quota_exceeded']">
       <xsl:copy-of select="/cp/strings/cp_msg_file_copy_fail" /> &gt;
       <xsl:copy-of select="/cp/strings/error_quota_exceeded" />
     </xsl:when>
     <xsl:when test="/cp/msgs/msg[@name='invalid_user']">
       <xsl:copy-of select="/cp/strings/cp_msg_file_copy_fail" /> &gt;
       <xsl:copy-of select="/cp/strings/error_invalid_user" />
     </xsl:when>
     <xsl:when test="/cp/msgs/msg[@name='invalid_name']">
       <xsl:copy-of select="/cp/strings/cp_msg_file_copy_fail" /> &gt;
       <xsl:copy-of select="/cp/strings/error_invalid_name" />
     </xsl:when>
     <xsl:when test="/cp/msgs/msg[@name='invalid_target']">
       <xsl:copy-of select="/cp/strings/cp_msg_file_copy_fail" /> &gt;
       <xsl:copy-of select="/cp/strings/error_invalid_target" />
     </xsl:when>
     <xsl:when test="/cp/msgs/msg[@name='target_exists']">
       <xsl:copy-of select="/cp/strings/cp_msg_file_copy_fail" /> &gt;
       <xsl:copy-of select="/cp/strings/error_path_exists" />
     </xsl:when>
     <xsl:when test="/cp/msgs/msg[@name='copy_loop']">
       <xsl:copy-of select="/cp/strings/cp_msg_file_copy_fail" /> &gt;
       <xsl:copy-of select="/cp/strings/cp_msg_file_copy_loop" />
     </xsl:when>
     <xsl:when test="/cp/msgs/msg[@name='mkdir_failed']">
       <xsl:copy-of select="/cp/strings/cp_msg_file_copy_fail" /> &gt;
       <xsl:copy-of select="/cp/strings/error_mkdir_failed" />
     </xsl:when>
   </xsl:choose>
 </xsl:variable>
 
 <xsl:variable name="feedback">
   <xsl:if test="$message != ''">
     <xsl:call-template name="feedback_table">
       <xsl:with-param name="image">
         <xsl:choose>
           <xsl:when test="/cp/vsap/vsap[@type='error']">error</xsl:when>
           <xsl:otherwise>success</xsl:otherwise>
         </xsl:choose>
       </xsl:with-param>
       <xsl:with-param name="message">
         <xsl:copy-of select="$message" />
       </xsl:with-param>
     </xsl:call-template>
   </xsl:if>
 </xsl:variable>

 <xsl:variable name="selectedNavAndContent">
   <xsl:choose>
     <xsl:when test="($currentUser = 'apache') or ($currentUser = 'webadmin')">
       <xsl:value-of select="/cp/strings/nv_file_web_root"/>
     </xsl:when>
     <xsl:otherwise>
       <xsl:value-of select="/cp/strings/nv_file_list"/>
     </xsl:otherwise>
   </xsl:choose>
 </xsl:variable>

 <xsl:template match="/">
  <xsl:call-template name="bodywrapper">
   <xsl:with-param name="title">
    <xsl:value-of select="/cp/strings/cp_title"/> : <xsl:value-of select="/cp/strings/nv_menu_filemanager"/> : <xsl:value-of select="/cp/strings/bc_file_copy"/>
   </xsl:with-param>
   <xsl:with-param name="formaction">copy.xsl</xsl:with-param>
   <xsl:with-param name="onsubmit">return validateField('<xsl:value-of select="cp:js-escape(/cp/strings/file_valid_dest_dir_name)"/>', target);</xsl:with-param>
   <xsl:with-param name="onload">document.forms[0].target.focus();  if(document.forms[0].target_name!=null){document.forms[0].target_name.focus();}</xsl:with-param>
   <xsl:with-param name="feedback" select="$feedback"/>
   <xsl:with-param name="selected_navandcontent" select="$selectedNavAndContent"/>
   <xsl:with-param name="help_short" select="/cp/strings/file_list_hlp_short"/>
   <xsl:with-param name="help_long">
    <xsl:value-of select="/cp/strings/file_list_hlp_long_eu"/>
   </xsl:with-param>
   <xsl:with-param name="breadcrumb">
    <breadcrumb>
     <section>
      <name><xsl:value-of select="/cp/strings/bc_file_list"/></name>
      <url><xsl:value-of select="$base_url"/>/cp/files/index.xsl</url>
     </section>
     <section>
      <name><xsl:value-of select="/cp/strings/bc_file_copy"/></name>
      <url>#</url>
      <image>FileManagement</image>
     </section>
    </breadcrumb>
   </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

    <xsl:call-template name="hiddenFields"/>
    <table class="formview" border="0" cellspacing="0" cellpadding="0">
     <tr class="title">
      <td colspan="2">
       <xsl:value-of select="/cp/strings/file_action_copy"/>
      </td>
     </tr>

     <tr class="instructionrow">
      <td colspan="2">
       <xsl:value-of select="/cp/strings/file_copy_title"/>
      </td>
     </tr>

     <xsl:variable name="itemsCount">
      <xsl:choose>
       <xsl:when test="/cp/form/file">
        <xsl:value-of select="count(/cp/form/file)"/>
       </xsl:when>
       <xsl:otherwise>1</xsl:otherwise>
      </xsl:choose>
     </xsl:variable>
     <input type="hidden" name="itemsCount" select="{$itemsCount}"/>

     <xsl:for-each select="cp/form/file">
      <tr class="roweven">
       <td class="label">
        <xsl:choose>
         <xsl:when test="$itemsCount = '1'">
          <xsl:value-of select="/cp/strings/file_copy_name"/>:
         </xsl:when>
         <xsl:otherwise>
          <xsl:value-of select="/cp/strings/file_copy_name"/>&#160;<xsl:value-of select="position()"/>:
         </xsl:otherwise>
        </xsl:choose>
       </td>
       <td class="contentwidth">
        <xsl:if test="$userType = 'da'">
         <xsl:if test="$currentUser != /cp/vsap/vsap[@type='auth']/username">
          <xsl:value-of select="$currentUser"/>:
         </xsl:if>
        </xsl:if>
        <xsl:variable name="source">
         <xsl:value-of select="/cp/form/currentDir"/>
         <xsl:if test="/cp/form/currentDir != '' and /cp/form/currentDir != '/'">/</xsl:if>
         <xsl:value-of select="."/>
        </xsl:variable>
        <xsl:value-of select="$source"/><input type="hidden" name="source" value="{$source}"/><input type="hidden" name="file" value="{.}"/>
       </td>
      </tr>
     </xsl:for-each>

     <xsl:if test="not(cp/form/file)">
      <tr class="roweven">
       <td class="label">
        <xsl:value-of select="/cp/strings/file_copy_name"/>:
       </td>
       <td class="contentwidth">
        <xsl:if test="$userType = 'da'">
         <xsl:if test="$currentUser != /cp/vsap/vsap[@type='auth']/username">
          <xsl:value-of select="$currentUser"/>:
         </xsl:if>
        </xsl:if>
        <xsl:variable name="source">
         <xsl:value-of select="/cp/form/currentItem"/>
        </xsl:variable>
        <xsl:value-of select="$source"/><input type="hidden" name="source" value="{$source}"/>
       </td>
      </tr>
     </xsl:if>

     <tr class="rowodd">
      <td class="label">
       <xsl:value-of select="/cp/strings/file_destination_directory"/>
      </td>
      <td class="contentwidth">
       <xsl:if test="$userType = 'da'">
        <xsl:if test="$numEndUsers > 1">
         <xsl:variable name="targetUser">
          <xsl:choose>
           <xsl:when test="string(/cp/form/targetUser)">
            <xsl:value-of select="/cp/form/targetUser"/>
           </xsl:when>
           <xsl:when test="string(/cp/form/currentUser)">
            <xsl:value-of select="/cp/form/currentUser"/>
           </xsl:when>
           <xsl:otherwise>
            <xsl:value-of select="/cp/vsap/vsap[@type='auth']/username"/>
           </xsl:otherwise>
          </xsl:choose>
         </xsl:variable>
         <select name="targetUser" size="1" onChange="this.form.target.value='/'">
          <xsl:for-each select="/cp/vsap/vsap[@type='user:list:eu']/user">
           <option value="{.}">
           <xsl:if test=". = $targetUser">
            <xsl:attribute name="selected">true</xsl:attribute>
           </xsl:if><xsl:value-of select="." /></option>
          </xsl:for-each>
         </select>&#160;
        </xsl:if>
       </xsl:if>
       <input name="target" value="{/cp/form/currentDir}" size="35">
         <xsl:attribute name="value">
          <xsl:choose>
           <xsl:when test="/cp/form/target">
            <xsl:value-of select="/cp/form/target" />
           </xsl:when>
           <xsl:otherwise>
            <xsl:value-of select="/cp/form/currentDir" />
           </xsl:otherwise>
          </xsl:choose>
         </xsl:attribute>
       </input>&#160;<a href="OpenDirectoryDialog" target="_blank" onClick="showDirectoryDialog(); return false;"><img src="{/cp/strings/img_folder}" border="0" align="middle" /></a>
      </td>
     </tr>

     <xsl:if test="$itemsCount = '1'">
      <tr class="roweven">
       <td class="label">
        <xsl:value-of select="/cp/strings/file_destination_filename"/>
       </td>
       <td class="contentwidth">
        <xsl:variable name="targetPath">
         <xsl:choose>
           <xsl:when test="/cp/form/file">
          <xsl:value-of select="/cp/form/file"/>
           </xsl:when>
           <xsl:otherwise>
          <xsl:value-of select="/cp/form/currentItem"/>
           </xsl:otherwise>
         </xsl:choose>
        </xsl:variable>
        <xsl:variable name="targetName">
         <xsl:call-template name='extract-filename'>
          <xsl:with-param name='pathName' select="$targetPath"/>
         </xsl:call-template>
        </xsl:variable>
        <!--xsl:variable name="suggestedTargetName">
         <xsl:choose>
          <xsl:when test='contains($targetName, ".")'> 
           <xsl:variable name="targetExt">
            <xsl:call-template name='extract-extension'>
             <xsl:with-param name='fileName' select="$targetName"/>
            </xsl:call-template>
           </xsl:variable>
           <xsl:variable name="targetExtWithPeriod">.<xsl:value-of select="$targetExt"/></xsl:variable>
           <xsl:variable name="targetBase">
            <xsl:value-of select='substring-before($targetName, $targetExtWithPeriod)'/>
           </xsl:variable>
           <xsl:value-of select="$targetBase"/>
           <xsl:value-of select="/cp/strings/file_copy_name_suggestion"/>.<xsl:value-of select="$targetExt"/>
          </xsl:when>
          <xsl:otherwise>
           <xsl:value-of select="$targetName"/>
           <xsl:value-of select="/cp/strings/file_copy_name_suggestion"/>
          </xsl:otherwise>
         </xsl:choose>
        </xsl:variable>
        <input name="targetName" value="{$suggestedTargetName}"/-->
        <input name="targetName" value="{$targetName}"/>
       </td>
      </tr>
     </xsl:if>

     <tr class="controlrow">
      <td colspan="2">
       <input class="floatright" type="button" name="cmd_cancel" value="{/cp/strings/file_btn_cancel}" onClick="javascript:doSubmit('_cancel')"/>
       <input class="floatright" type="submit" name="ok" value="{/cp/strings/file_btn_ok}" onClick="actionType.value='_copy'" />
      </td>
     </tr>

    </table>

 </xsl:template>
</xsl:stylesheet>
