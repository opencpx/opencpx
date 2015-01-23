<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" xmlns:exslt="http://exslt.org/common">
 <xsl:import href="../cp_global.xsl"/>
 <xsl:import href="file_global.xsl"/>

 <xsl:variable name="message">
   <xsl:choose>
     <xsl:when test="/cp/msgs/msg[@name='not_authorized']">
       <xsl:copy-of select="/cp/strings/cp_msg_file_uncompress_fail" /> &gt;
       <xsl:copy-of select="/cp/strings/error_not_authorized" />
     </xsl:when>
     <xsl:when test="/cp/msgs/msg[@name='invalid_path']">
       <xsl:copy-of select="/cp/strings/cp_msg_file_uncompress_fail" /> &gt;
       <xsl:copy-of select="/cp/strings/error_invalid_path" />
     </xsl:when>
     <xsl:when test="/cp/msgs/msg[@name='uncompress_failed']">
       <xsl:copy-of select="/cp/strings/cp_msg_file_uncompress_fail" />
     </xsl:when>
     <xsl:when test="/cp/msgs/msg[@name='quota_exceeded']">
       <xsl:copy-of select="/cp/strings/cp_msg_file_uncompress_fail" /> &gt;
       <xsl:copy-of select="/cp/strings/error_quota_exceeded" />
     </xsl:when>
     <xsl:when test="/cp/msgs/msg[@name='invalid_user']">
       <xsl:copy-of select="/cp/strings/cp_msg_file_uncompress_fail" /> &gt;
       <xsl:copy-of select="/cp/strings/error_invalid_user" />
     </xsl:when>
     <xsl:when test="/cp/msgs/msg[@name='invalid_name']">
       <xsl:copy-of select="/cp/strings/cp_msg_file_uncompress_fail" /> &gt;
       <xsl:copy-of select="/cp/strings/error_invalid_name" />
     </xsl:when>
     <xsl:when test="/cp/msgs/msg[@name='invalid_target']">
       <xsl:copy-of select="/cp/strings/cp_msg_file_uncompress_fail" /> &gt;
       <xsl:copy-of select="/cp/strings/error_invalid_target" />
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
   <xsl:with-param name="title"><xsl:value-of select="/cp/strings/cp_title"/> : <xsl:value-of select="/cp/strings/nv_menu_filemanager"/> : <xsl:value-of select="/cp/strings/bc_file_uncompress"/></xsl:with-param>
   <xsl:with-param name="formaction">uncompress.xsl</xsl:with-param>
   <xsl:with-param name="onsubmit">return validateField('<xsl:value-of select="cp:js-escape(/cp/strings/file_valid_dest_dir_name)"/>', target);</xsl:with-param>
   <xsl:with-param name="onload">document.forms[0].target.focus();</xsl:with-param>
   <xsl:with-param name="feedback" select="$feedback"/>
   <xsl:with-param name="selected_navandcontent" select="$selectedNavAndContent"/>
   <xsl:with-param name="help_short" select="/cp/strings/file_list_hlp_short"/>
   <xsl:with-param name="help_long"><xsl:value-of select="/cp/strings/file_list_hlp_long_eu"/></xsl:with-param>
   <xsl:with-param name="breadcrumb">
    <breadcrumb>
     <section>
      <name><xsl:value-of select="/cp/strings/bc_file_list"/></name>
      <url><xsl:value-of select="$base_url"/>/cp/files/index.xsl</url>
     </section>
     <section>
      <name><xsl:value-of select="/cp/strings/bc_file_uncompress"/></name>
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
       <xsl:value-of select="/cp/strings/file_action_uncompress"/>
      </td>
     </tr>

     <!-- 
      use of cp/form/senderData: 
       '' (empty string): use data from cp/form/file for uncompress list
       '/'              : uncompress the entire archive
       anything else    : path of single file in archive
     -->
      


     <tr class="instructionrow">
      <td colspan="2">
       <xsl:choose>
        <xsl:when test="cp/form/senderData != '/'">
         <xsl:value-of select="/cp/strings/file_uncompress_title"/>
        </xsl:when>
        <xsl:otherwise>
         <xsl:value-of select="/cp/strings/file_uncompress_title2"/>
        </xsl:otherwise>
       </xsl:choose>
      </td>
     </tr>

     <xsl:choose>
      <xsl:when test="cp/form/senderData = '/'" />
      <xsl:when test="cp/form/senderData = ''">
       <xsl:for-each select="cp/form/file">
        <tr class="roweven">
         <td class="label">
          <xsl:value-of select="/cp/strings/file_move_name"/>&#160;<xsl:value-of select="position()"/>:
         </td>
         <td class="contentwidth">
          <xsl:value-of select="."/><input type="hidden" name="file" value="{.}"/>
         </td>
        </tr>
       </xsl:for-each>
      </xsl:when>
      <xsl:otherwise>
       <tr class="roweven">
        <td class="label">
         <xsl:value-of select="/cp/strings/file_move_name"/>:
        </td>
        <td class="contentwidth">
         <xsl:value-of select="cp/form/senderData"/><input type="hidden" name="file" value="{cp/form/senderData}"/>
        </td>
       </tr>
      </xsl:otherwise>
     </xsl:choose>

     <!-- get extension -->
     <xsl:variable name="targetExt">
       <xsl:choose>
         <xsl:when test="/cp/vsap/vsap[@type='files:properties']/archive_ext != ''">
           <xsl:value-of select="/cp/vsap/vsap[@type='files:properties']/archive_ext" />
         </xsl:when>
         <xsl:otherwise>
           <xsl:call-template name="extract-extension">
             <xsl:with-param name="fileName" select="/cp/form/currentItem" />
           </xsl:call-template>
         </xsl:otherwise>
       </xsl:choose>
     </xsl:variable>

     <!-- debug: show file extension returned by vsap -->
     <!--
     <tr class="roweven">
       <td class="label">Extension:</td>
       <td class="contentwidth"><xsl:value-of select="$targetExt"/></td>
     </tr>
     -->

     <!-- variants of tar/zip may select the destination directory, others cannot -->
     <xsl:if test="$targetExt = 'tar' or $targetExt = 'taz' or $targetExt = 'tbz' or $targetExt = 'tbz2' or $targetExt = 'tgz' or $targetExt = 'tar.gz' or $targetExt = 'tar.bz' or $targetExt = 'tar.bz2' or $targetExt = 'tar.Z' or $targetExt = 'tgz' or $targetExt = 'zip' or $targetExt = 'gz'">
     <tr class="roweven">
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
       <input name="target" value="{/cp/form/currentDir}" size="35" />&#160;<a href="OpenDirectoryDialog" target="_blank" onClick="showDirectoryDialog(); return false;"><img src="{/cp/strings/img_folder}" border="0" align="middle" /></a>
      </td>
     </tr>
     </xsl:if>

     <tr class="roweven">
       <td class="label">
         <xsl:value-of select="/cp/strings/file_uncompress_options"/>
       </td>
       <td class="contentwidth">

        <!-- show options for this extension -->
        <xsl:choose>
          <xsl:when test="$targetExt = 'tar' or $targetExt = 'taz' or $targetExt = 'tbz' or $targetExt = 'tbz2' or $targetExt = 'tgz' or $targetExt = 'tar.gz' or $targetExt = 'tar.bz' or $targetExt = 'tar.bz2' or $targetExt = 'tar.Z'">
            <input type="radio" id="overwrite_existing" name="uncompress_option" value="default" checked="true"></input>
            <label for="overwrite_existing"><xsl:value-of select="/cp/strings/file_uncompress_option_gz1" /></label><br />
            <input type="radio" id="skip_existing" name="uncompress_option" value="skip"></input>
            <label for="skip_existing"><xsl:value-of select="/cp/strings/file_uncompress_option_gz2" /></label><br />
          </xsl:when>
          <xsl:when test="$targetExt = 'zip'">
            <input type="radio" id="overwrite_existing" name="uncompress_option" value="default" checked="true"></input>
            <label for="overwrite_existing"><xsl:value-of select="/cp/strings/file_uncompress_option_zip2" /></label><br />
            <input type="radio" id="skip_existing" name="uncompress_option" value="skip"></input>
            <label for="skip_existing"><xsl:value-of select="/cp/strings/file_uncompress_option_zip3" /></label><br />
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="/cp/strings/file_uncompress_option_none" />
          </xsl:otherwise>
        </xsl:choose>
       </td>
     </tr>

     <tr class="controlrow">
      <td colspan="2">
       <input class="floatright" type="button" name="cmd_cancel" value="{/cp/strings/file_btn_cancel}" onClick="doSubmit('_cancel')"/>
       <input class="floatright" type="submit" name="ok" value="{/cp/strings/file_btn_uncompress}" onClick="actionType.value='_uncompress'"/>
      </td>
     </tr>

    </table>

 </xsl:template>
</xsl:stylesheet>
