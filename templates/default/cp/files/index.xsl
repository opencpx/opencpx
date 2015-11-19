<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" xmlns:exslt="http://exslt.org/common">
 <xsl:import href="../cp_global.xsl"/>
 <xsl:import href="file_global.xsl"/>

 <xsl:variable name="feedback">
  <xsl:choose>

   <xsl:when test="/cp/msgs/msg[@name='request_queued']">
    <xsl:call-template name="feedback_table">
     <xsl:with-param name="image">success</xsl:with-param>
     <xsl:with-param name="message">
      <xsl:choose>
       <xsl:when test="/cp/vsap/vsap[@type='error']/@caller='files:compress'">
         <xsl:value-of select="/cp/strings/cp_msg_file_compress_in_progress" /> &gt; <xsl:value-of select="/cp/strings/cp_background_job_started"/>
       </xsl:when>
       <xsl:when test="/cp/vsap/vsap[@type='error']/@caller='files:uncompress'">
         <xsl:value-of select="/cp/strings/cp_msg_file_uncompress_in_progress" /> &gt; <xsl:value-of select="/cp/strings/cp_background_job_started"/>
       </xsl:when>
      </xsl:choose>
     </xsl:with-param>
    </xsl:call-template>
   </xsl:when>

   <xsl:when test="/cp/msgs/msg[@name='list_action']">
    <xsl:call-template name="feedback_table">
     <xsl:with-param name="image">error</xsl:with-param>
     <xsl:with-param name="message"><xsl:value-of select="/cp/strings/cp_msg_file_list_fail"/></xsl:with-param>
    </xsl:call-template>
   </xsl:when>

   <xsl:when test="/cp/msgs/msg[@name='copy_action']">
    <xsl:call-template name="feedback_table">
     <xsl:with-param name="image">
      <xsl:choose>
       <xsl:when test="/cp/msgs/msg[@name='fail']!='0' or /cp/msgs/msg[@name='success']='0'">error</xsl:when>
       <xsl:otherwise>success</xsl:otherwise>
      </xsl:choose>
     </xsl:with-param>
     <xsl:with-param name="message"> 
      <xsl:choose>
       <xsl:when test="/cp/msgs/msg[@name='success']!='0' and /cp/msgs/msg[@name='fail']!='0'">
        <xsl:value-of select="/cp/strings/cp_msg_file_copy_mixed"/>&#160;
        <xsl:value-of select="/cp/strings/cp_msg_file_copy_fail"/>&#160;<xsl:value-of select="/cp/msgs/msg[@name='fail']"/>&#160;<xsl:value-of select="/cp/strings/cp_msg_file_copy_suffix"/>&#160;
        <xsl:value-of select="/cp/strings/cp_msg_file_copy_success"/>&#160;<xsl:value-of select="/cp/msgs/msg[@name='success']"/>&#160;<xsl:value-of select="/cp/strings/cp_msg_file_copy_suffix"/>
       </xsl:when>
 
       <xsl:when test="/cp/msgs/msg[@name='success']='0' and /cp/msgs/msg[@name='fail']!='0'">
        <xsl:value-of select="/cp/strings/cp_msg_file_copy_fail"/>&#160;<xsl:value-of select="/cp/msgs/msg[@name='fail']"/>&#160;<xsl:value-of select="/cp/strings/cp_msg_file_copy_suffix"/>&#160;
        <xsl:choose>
         <xsl:when test="/cp/msgs/msg[@name='failcode'] = 'not_authorized'">
           <xsl:copy-of select="/cp/strings/error_not_authorized" />
         </xsl:when>
         <xsl:when test="/cp/msgs/msg[@name='failcode'] = 'invalid_path'">
           <xsl:copy-of select="/cp/strings/error_invalid_path" />
         </xsl:when>
         <xsl:when test="/cp/msgs/msg[@name='failcode'] = 'copy_failed'">
           <xsl:copy-of select="/cp/strings/cp_msg_file_copy_command_failed" />
         </xsl:when>
         <xsl:when test="/cp/msgs/msg[@name='failcode'] = 'quota_exceeded'">
           <xsl:copy-of select="/cp/strings/error_quota_exceeded" />
         </xsl:when>
         <xsl:when test="/cp/msgs/msg[@name='failcode'] = 'invalid_user'">
           <xsl:copy-of select="/cp/strings/error_invalid_user" />
         </xsl:when>
         <xsl:when test="/cp/msgs/msg[@name='failcode'] = 'invalid_name'">
           <xsl:copy-of select="/cp/strings/error_invalid_name" />
         </xsl:when>
         <xsl:when test="/cp/msgs/msg[@name='failcode'] = 'invalid_target'">
           <xsl:copy-of select="/cp/strings/error_invalid_target" />
         </xsl:when>
         <xsl:when test="/cp/msgs/msg[@name='failcode'] = 'target_exists'">
           <xsl:copy-of select="/cp/strings/error_path_exists" />
         </xsl:when>
         <xsl:when test="/cp/msgs/msg[@name='failcode'] = 'copy_loop'">
           <xsl:copy-of select="/cp/strings/cp_msg_file_copy_loop" />
         </xsl:when>
         <xsl:when test="/cp/msgs/msg[@name='failcode'] = 'mkdir_failed'">
           <xsl:copy-of select="/cp/strings/error_mkdir_failed" />
         </xsl:when>
        </xsl:choose>
       </xsl:when>
        <xsl:when test="/cp/msgs/msg[@name='success']!='0' and /cp/msgs/msg[@name='fail']='0'">
        <xsl:value-of select="/cp/strings/cp_msg_file_copy_success"/>&#160;<xsl:value-of select="/cp/msgs/msg[@name='success']"/>&#160;<xsl:value-of select="/cp/strings/cp_msg_file_copy_suffix"/>
       </xsl:when>
        <xsl:otherwise>
        <xsl:value-of select="/cp/strings/cp_msg_file_copy_fail"/>&#160;<xsl:value-of select="/cp/strings/cp_msg_file_copy_suffix"/>
       </xsl:otherwise>
      </xsl:choose>
     </xsl:with-param>
    </xsl:call-template>
   </xsl:when>

   <xsl:when test="/cp/msgs/msg[@name='move_action']">
    <xsl:call-template name="feedback_table">
     <xsl:with-param name="image">
      <xsl:choose>
       <xsl:when test="/cp/msgs/msg[@name='fail']!='0' or /cp/msgs/msg[@name='success']='0'">error</xsl:when>
       <xsl:otherwise>success</xsl:otherwise>
      </xsl:choose>
     </xsl:with-param>
      <xsl:with-param name="message">
      <xsl:choose>
       <xsl:when test="/cp/msgs/msg[@name='success']!='0' and /cp/msgs/msg[@name='fail']!='0'">
        <xsl:value-of select="/cp/strings/cp_msg_file_move_mixed"/>&#160;
        <xsl:value-of select="/cp/strings/cp_msg_file_move_fail"/>&#160;<xsl:value-of select="/cp/msgs/msg[@name='fail']"/>&#160;<xsl:value-of select="/cp/strings/cp_msg_file_move_suffix"/>&#160;
        <xsl:value-of select="/cp/strings/cp_msg_file_move_success"/>&#160;<xsl:value-of select="/cp/msgs/msg[@name='success']"/>&#160;<xsl:value-of select="/cp/strings/cp_msg_file_move_suffix"/>
       </xsl:when>
       <xsl:when test="/cp/msgs/msg[@name='success']='0' and /cp/msgs/msg[@name='fail']!='0'">
        <xsl:value-of select="/cp/strings/cp_msg_file_move_fail"/>&#160;<xsl:value-of select="/cp/msgs/msg[@name='fail']"/>&#160;<xsl:value-of select="/cp/strings/cp_msg_file_move_suffix"/>&#160;
        <xsl:choose>
         <xsl:when test="/cp/msgs/msg[@name='failcode'] = 'not_authorized'">
           <xsl:copy-of select="/cp/strings/error_not_authorized" />
         </xsl:when>
         <xsl:when test="/cp/msgs/msg[@name='failcode'] = 'invalid_path'">
           <xsl:copy-of select="/cp/strings/error_invalid_path" />
         </xsl:when>
         <xsl:when test="/cp/msgs/msg[@name='failcode'] = 'move_failed'">
           <xsl:copy-of select="/cp/strings/cp_msg_file_move_command_failed" />
         </xsl:when>
         <xsl:when test="/cp/msgs/msg[@name='failcode'] = 'quota_exceeded'">
           <xsl:copy-of select="/cp/strings/error_quota_exceeded" />
         </xsl:when>
         <xsl:when test="/cp/msgs/msg[@name='failcode'] = 'invalid_user'">
           <xsl:copy-of select="/cp/strings/error_invalid_user" />
         </xsl:when>
         <xsl:when test="/cp/msgs/msg[@name='failcode'] = 'invalid_target'">
           <xsl:copy-of select="/cp/strings/error_invalid_target" />
         </xsl:when>
         <xsl:when test="/cp/msgs/msg[@name='failcode'] = 'target_exists'">
           <xsl:copy-of select="/cp/strings/error_path_exists" />
         </xsl:when>
         <xsl:when test="/cp/msgs/msg[@name='failcode'] = 'move_loop'">
           <xsl:copy-of select="/cp/strings/cp_msg_file_move_loop" />
         </xsl:when>
         <xsl:when test="/cp/msgs/msg[@name='failcode'] = 'mkdir_failed'">
           <xsl:copy-of select="/cp/strings/error_mkdir_failed" />
         </xsl:when>
        </xsl:choose>
       </xsl:when>
       <xsl:when test="/cp/msgs/msg[@name='success']!='0' and /cp/msgs/msg[@name='fail']='0'">
        <xsl:value-of select="/cp/strings/cp_msg_file_move_success"/>&#160;<xsl:value-of select="/cp/msgs/msg[@name='success']"/>&#160;<xsl:value-of select="/cp/strings/cp_msg_file_move_suffix"/>
       </xsl:when>
       <xsl:otherwise>
        <xsl:value-of select="/cp/strings/cp_msg_file_move_fail"/>&#160;<xsl:value-of select="/cp/strings/cp_msg_file_move_suffix"/>
       </xsl:otherwise>
      </xsl:choose>
     </xsl:with-param>
    </xsl:call-template>
   </xsl:when>

   <xsl:when test="/cp/msgs/msg[@name='delete_action']">
    <xsl:call-template name="feedback_table">
     <xsl:with-param name="image">
      <xsl:choose>
       <xsl:when test="/cp/msgs/msg[@name='fail']!='0' or /cp/msgs/msg[@name='success']='0'">error</xsl:when>
       <xsl:otherwise>success</xsl:otherwise>
      </xsl:choose>
     </xsl:with-param>
     <xsl:with-param name="message">
      <xsl:choose>
       <xsl:when test="/cp/msgs/msg[@name='success']!='0' and /cp/msgs/msg[@name='fail']!='0'">
        <xsl:value-of select="/cp/strings/cp_msg_file_delete_mixed"/>&#160;
        <xsl:value-of select="/cp/strings/cp_msg_file_delete_fail"/>&#160;<xsl:value-of select="/cp/msgs/msg[@name='fail']"/>&#160;<xsl:value-of select="/cp/strings/cp_msg_file_delete_suffix"/>&#160;
        <xsl:value-of select="/cp/strings/cp_msg_file_delete_success"/>&#160;<xsl:value-of select="/cp/msgs/msg[@name='success']"/>&#160;<xsl:value-of select="/cp/strings/cp_msg_file_delete_suffix"/>
       </xsl:when>
       <xsl:when test="/cp/msgs/msg[@name='success']='0' and /cp/msgs/msg[@name='fail']!='0'">
        <xsl:value-of select="/cp/strings/cp_msg_file_delete_fail"/>&#160;<xsl:value-of select="/cp/msgs/msg[@name='fail']"/>&#160;<xsl:value-of select="/cp/strings/cp_msg_file_delete_suffix"/>
       </xsl:when>
       <xsl:when test="/cp/msgs/msg[@name='success']!='0' and /cp/msgs/msg[@name='fail']='0'">
        <xsl:value-of select="/cp/strings/cp_msg_file_delete_success"/>&#160;<xsl:value-of select="/cp/msgs/msg[@name='success']"/>&#160;<xsl:value-of select="/cp/strings/cp_msg_file_delete_suffix"/>
       </xsl:when>
        <xsl:otherwise>
        <xsl:value-of select="/cp/strings/cp_msg_file_delete_fail"/>&#160;<xsl:value-of select="/cp/strings/cp_msg_file_delete_suffix"/>
       </xsl:otherwise>
      </xsl:choose>
     </xsl:with-param>
    </xsl:call-template>
   </xsl:when>

   <xsl:when test="/cp/msgs/msg[@name='link_action']">
    <xsl:call-template name="feedback_table">
     <xsl:with-param name="image">
      <xsl:choose>
       <xsl:when test="/cp/msgs/msg[@name='success']='no'">error</xsl:when>
       <xsl:otherwise>success</xsl:otherwise>
      </xsl:choose>
     </xsl:with-param>
     <xsl:with-param name="message">
      <xsl:choose>
       <xsl:when test="/cp/msgs/msg[@name='success']='no'">
        <xsl:value-of select="/cp/strings/cp_msg_file_link_fail"/>
       </xsl:when>
       <xsl:otherwise>
        <xsl:value-of select="/cp/strings/cp_msg_file_link_success"/>
       </xsl:otherwise>
      </xsl:choose>
     </xsl:with-param>
    </xsl:call-template>
   </xsl:when>

   <xsl:when test="/cp/msgs/msg[@name='compress_action']">
    <xsl:call-template name="feedback_table">
     <xsl:with-param name="image">
      <xsl:choose>
       <xsl:when test="/cp/msgs/msg[@name='success']='no'">error</xsl:when>
       <xsl:otherwise>success</xsl:otherwise>
      </xsl:choose>
     </xsl:with-param>
     <xsl:with-param name="message">
      <xsl:choose>
       <xsl:when test="/cp/msgs/msg[@name='success']='no'">
        <xsl:value-of select="/cp/strings/cp_msg_file_compress_fail"/>
       </xsl:when>
       <xsl:otherwise>
        <xsl:value-of select="/cp/strings/cp_msg_file_compress_success"/>
       </xsl:otherwise>
      </xsl:choose>
     </xsl:with-param>
    </xsl:call-template>
   </xsl:when>

   <xsl:when test="/cp/msgs/msg[@name='uncompress_action']">
    <xsl:call-template name="feedback_table">
     <xsl:with-param name="image">
      <xsl:choose>
      <xsl:when test="/cp/msgs/msg[@name='success']='no'">error</xsl:when>
       <xsl:otherwise>success</xsl:otherwise>
      </xsl:choose>
     </xsl:with-param>
     <xsl:with-param name="message">
      <xsl:choose>
       <xsl:when test="/cp/msgs/msg[@name='success']='no'">
       <xsl:value-of select="/cp/strings/cp_msg_file_uncompress_fail"/>
       </xsl:when>
       <xsl:otherwise>
        <xsl:value-of select="/cp/strings/cp_msg_file_uncompress_success"/>
       </xsl:otherwise>
      </xsl:choose>
     </xsl:with-param>
    </xsl:call-template>
   </xsl:when>

   <xsl:when test="/cp/msgs/msg[@name='rename_action']">
    <xsl:call-template name="feedback_table">
     <xsl:with-param name="image">
      <xsl:choose>
       <xsl:when test="/cp/msgs/msg[@name='success']='no'">error</xsl:when>
       <xsl:otherwise>success</xsl:otherwise>
      </xsl:choose>
     </xsl:with-param>
     <xsl:with-param name="message">
      <xsl:choose>
       <xsl:when test="/cp/msgs/msg[@name='success']='no'">
        <xsl:value-of select="/cp/strings/cp_msg_file_rename_fail"/>
       </xsl:when>
       <xsl:otherwise>
        <xsl:value-of select="/cp/strings/cp_msg_file_rename_success"/>
       </xsl:otherwise>
      </xsl:choose>
     </xsl:with-param>
    </xsl:call-template>
   </xsl:when>

   <xsl:when test="/cp/msgs/msg[@name='permissions_action']">
    <xsl:call-template name="feedback_table">
     <xsl:with-param name="image">
      <xsl:choose>
       <xsl:when test="/cp/msgs/msg[@name='success']='no'">error</xsl:when>
       <xsl:otherwise>success</xsl:otherwise>
      </xsl:choose>
     </xsl:with-param>
     <xsl:with-param name="message">
      <xsl:choose>
       <xsl:when test="/cp/msgs/msg[@name='success']='no'">
        <xsl:value-of select="/cp/strings/cp_msg_file_permissions_fail"/>
       </xsl:when>
       <xsl:otherwise>
        <xsl:value-of select="/cp/strings/cp_msg_file_permissions_success"/>
       </xsl:otherwise>
      </xsl:choose>
     </xsl:with-param>
    </xsl:call-template>
   </xsl:when>

   <xsl:when test="/cp/msgs/msg[@name='owners_action']">
    <xsl:call-template name="feedback_table">
     <xsl:with-param name="image">
      <xsl:choose>
       <xsl:when test="/cp/msgs/msg[@name='success']='no'">error</xsl:when>
       <xsl:otherwise>success</xsl:otherwise>
      </xsl:choose>
     </xsl:with-param>
     <xsl:with-param name="message">
      <xsl:choose>
       <xsl:when test="/cp/msgs/msg[@name='success']='no'">
        <xsl:value-of select="/cp/strings/cp_msg_file_owners_fail"/>
       </xsl:when>
       <xsl:otherwise>
        <xsl:value-of select="/cp/strings/cp_msg_file_owners_success"/>
       </xsl:otherwise>
      </xsl:choose>
     </xsl:with-param>
    </xsl:call-template>
   </xsl:when>

   <xsl:when test="/cp/msgs/msg[@name='add_dir_action']">
    <xsl:call-template name="feedback_table">
     <xsl:with-param name="image">
      <xsl:choose>
       <xsl:when test="/cp/msgs/msg[@name='success']='no'">error</xsl:when>
       <xsl:otherwise>success</xsl:otherwise>
      </xsl:choose>
     </xsl:with-param>
     <xsl:with-param name="message">
      <xsl:choose>
       <xsl:when test="/cp/msgs/msg[@name='success']='no'">
        <xsl:value-of select="/cp/strings/cp_msg_file_add_dir_fail"/>
       </xsl:when>
       <xsl:otherwise>
        <xsl:value-of select="/cp/strings/cp_msg_file_add_dir_success"/>
       </xsl:otherwise>
      </xsl:choose>
     </xsl:with-param>
    </xsl:call-template>
   </xsl:when>

   <xsl:when test="/cp/msgs/msg[@name='add_file_action']">
    <xsl:call-template name="feedback_table">
     <xsl:with-param name="image">
      <xsl:choose>
       <xsl:when test="/cp/msgs/msg[@name='success']='no'">error</xsl:when>
       <xsl:otherwise>success</xsl:otherwise>
      </xsl:choose>
     </xsl:with-param>
     <xsl:with-param name="message">
      <xsl:choose>
       <xsl:when test="/cp/msgs/msg[@name='success']='no'">
        <xsl:value-of select="/cp/strings/cp_msg_file_add_file_fail"/>
       </xsl:when>
       <xsl:otherwise>
        <xsl:value-of select="/cp/strings/cp_msg_file_add_file_success"/>
       </xsl:otherwise>
      </xsl:choose>
     </xsl:with-param>
    </xsl:call-template>
   </xsl:when>

   <xsl:when test="/cp/msgs/msg[@name='edit_file_action']">
    <xsl:call-template name="feedback_table">
     <xsl:with-param name="image">
      <xsl:choose>
       <xsl:when test="/cp/msgs/msg[@name='success']='no'">error</xsl:when>
       <xsl:otherwise>success</xsl:otherwise>
      </xsl:choose>
     </xsl:with-param>
     <xsl:with-param name="message">
      <xsl:choose>
       <xsl:when test="/cp/msgs/msg[@name='success']='no'">
        <xsl:value-of select="/cp/strings/cp_msg_file_edit_file_fail"/>
       </xsl:when>
       <xsl:otherwise>
        <xsl:value-of select="/cp/strings/cp_msg_file_edit_file_success"/>
       </xsl:otherwise>
      </xsl:choose>
     </xsl:with-param>
    </xsl:call-template>
   </xsl:when>

   <xsl:when test="/cp/msgs/msg[@name='general_error']">
    <xsl:call-template name="feedback_table">
     <xsl:with-param name="image">error</xsl:with-param>
     <xsl:with-param name="message">
      <xsl:choose>
       <xsl:when test="/cp/msgs/msg[@name='general_error']='file_access'">
        <xsl:value-of select="/cp/strings/error_file_access"/>
       </xsl:when>
       <xsl:otherwise>
        <xsl:value-of select="/cp/strings/error_unexpected"/>
       </xsl:otherwise>
      </xsl:choose>
     </xsl:with-param>
    </xsl:call-template>
   </xsl:when>
 
  </xsl:choose>
 </xsl:variable>
 
 <xsl:variable name="sortBy">
  <xsl:choose>
   <xsl:when test="string(/cp/form/sortBy)"><xsl:value-of select="/cp/form/sortBy"/></xsl:when>
   <xsl:otherwise>filename</xsl:otherwise>
  </xsl:choose>
 </xsl:variable>

 <xsl:variable name="sortType">
  <xsl:choose>
   <xsl:when test="string(/cp/form/sortType)"><xsl:value-of select="/cp/form/sortType"/></xsl:when>
   <xsl:otherwise>ascending</xsl:otherwise>
  </xsl:choose>
 </xsl:variable>

 <xsl:variable name="showHidden">
  <xsl:choose>
   <xsl:when test="/cp/form/showHidden"><xsl:value-of select="/cp/form/showHidden"/></xsl:when>
   <xsl:when test="/cp/vsap/vsap[@type='user:prefs:load']/user_preferences/fm_hidden_file_default = 'show'">true</xsl:when>
   <xsl:otherwise>false</xsl:otherwise>
  </xsl:choose>
 </xsl:variable>

 <xsl:variable name="sessionID">
  <xsl:choose>
   <xsl:when test="string(/cp/form/sessionID)"><xsl:value-of select="/cp/form/sessionID"/></xsl:when>
   <xsl:otherwise><xsl:value-of select="/cp/vsap/vsap[@type='files:upload:init']/sessionid"/></xsl:otherwise>
  </xsl:choose>
 </xsl:variable>

 <xsl:variable name="parentDir"><xsl:value-of select="/cp/vsap/vsap[@type='files:list']/parent_dir"/></xsl:variable>
 <xsl:variable name="parentDirEncoded"><xsl:value-of select="/cp/vsap/vsap[@type='files:list']/url_encoded_parent_dir"/></xsl:variable>
 <xsl:variable name="parentDirEscaped"><xsl:value-of select="/cp/vsap/vsap[@type='files:list']/url_escaped_parent_dir"/></xsl:variable>

 <xsl:variable name="currentDir"><xsl:value-of select="/cp/vsap/vsap[@type='files:list']/path"/></xsl:variable>
 <xsl:variable name="currentDirEncoded"><xsl:value-of select="/cp/vsap/vsap[@type='files:list']/url_encoded_path"/></xsl:variable>
 <xsl:variable name="currentDirEscaped"><xsl:value-of select="/cp/vsap/vsap[@type='files:list']/url_escaped_path"/></xsl:variable>

 <xsl:template match="/cp/vsap/vsap[@type='files:list']/file">
  <xsl:variable name="rowStyle">
   <xsl:choose>
    <xsl:when test="position() mod 2 = 1">rowodd</xsl:when>
    <xsl:otherwise>roweven</xsl:otherwise>
   </xsl:choose>
  </xsl:variable>

  <xsl:variable name="fileFullName">
   <xsl:value-of select="$currentDir"/><xsl:if test="$currentDir != '/'">/</xsl:if>
   <xsl:value-of select="name"/>
  </xsl:variable>
  <xsl:variable name="fileFullNameEncoded">
   <xsl:value-of select="$currentDirEncoded"/><xsl:if test="$currentDir != '/'">/</xsl:if>
   <xsl:value-of select="url_encoded_name"/>
  </xsl:variable>
  <xsl:variable name="fileFullNameEscaped">
   <xsl:value-of select="$currentDirEscaped"/><xsl:if test="$currentDir != '/'">/</xsl:if>
   <xsl:value-of select="url_escaped_name"/>
  </xsl:variable>

  <tr class="{$rowStyle}">
   <xsl:choose>
    <!-- Self directory: go to parent -->
    <xsl:when test="name = '..'">
     <td class="ckboxcolumn">&#160;</td>
     <td class="imagecolumn"><a href="#" onClick="doSubmit('listFiles','{$parentDirEscaped}')"><img src="{/cp/strings/img_folder_up}" border="0"/></a></td>
     <td class="filecolumn"><a href="#" onClick="doSubmit('listFiles','{$parentDirEscaped}')">[..]</a></td>
     <td class="lastmodcolumn">
      <xsl:call-template name="display_date">
       <xsl:with-param name="date" select="date"/>
      </xsl:call-template>
     </td>
     <td class="cpsizecolumn">&#160;</td>
     <td class="cpactionscolumn">&#160;</td>
    </xsl:when>

    <!-- Sub directory -->
    <xsl:when test="type='dir'">
     <td class="ckboxcolumn"><input type="checkbox" name="file" value="{name}"/></td>
     <td class="imagecolumn"><a href="#" onClick="doSubmit('listFiles','{$fileFullNameEscaped}')"><img src="{/cp/strings/icons_folder}{cp_icon}.gif" border="0" /></a></td>
     <td class="filecolumn"><a href="#" onClick="doSubmit('listFiles','{$fileFullNameEscaped}')"><xsl:value-of select="name"/></a></td>
     <td class="lastmodcolumn">
      <xsl:call-template name="display_date">
       <xsl:with-param name="date" select="date"/>
      </xsl:call-template>
     </td>
     <td class="cpsizecolumn">&#160;</td>
     <td class="cpactionscolumn">
      <a href="#" onClick="doSubmit('listFiles','{$fileFullNameEscaped}')"><xsl:value-of select="/cp/strings/file_action_view"/></a> | 
      <a href="#" onClick="doSubmit('rename',null,null,'{$fileFullNameEscaped}')"><xsl:value-of select="/cp/strings/file_action_rename"/></a>
     </td>
    </xsl:when>

    <!-- Directory shortcut-->
    <xsl:when test="type='dirlink'">
     <xsl:if test="target">
      <td class="ckboxcolumn"><input type="checkbox" name="file" value="{name}"/></td>
      <td class="imagecolumn"><a href="#" onClick="doSubmit('listFiles','{url_escaped_target}')"><img src="{/cp/strings/icons_folder}{cp_icon}.gif" border="0" /></a></td>
      <td class="filecolumn"><a href="#" onClick="doSubmit('listFiles','{url_escaped_target}')"><xsl:value-of select="name"/></a></td>
      <td class="lastmodcolumn">
       <xsl:call-template name="display_date">
        <xsl:with-param name="date" select="date"/>
       </xsl:call-template>
      </td>
      <td class="cpsizecolumn">&#160;</td>
      <td class="cpactionscolumn">
       <a href="#" onClick="doSubmit('listFiles','{url_escaped_target}')"><xsl:value-of select="/cp/strings/file_action_view"/></a> | 
       <a href="#" onClick="doSubmit('rename',null,null,'{$fileFullNameEscaped}')"><xsl:value-of select="/cp/strings/file_action_rename"/></a>
      </td>
     </xsl:if>
    </xsl:when>

    <!-- File shortcut-->
    <xsl:when test="type='symlink'">
     <xsl:if test="target">
      <td class="ckboxcolumn"><input type="checkbox" name="file" value="{name}"/></td>
      <td class="imagecolumn"><a href="#" onClick="doSubmit('properties',null,null,'{url_escaped_target}')"><img src="{/cp/strings/icons_folder}{cp_icon}.gif" border="0" /></a></td>
      <td class="filecolumn"><a href="#" onClick="doSubmit('properties',null,null,'{url_escaped_target}')"><xsl:value-of select="name"/></a></td>
      <td class="lastmodcolumn">
       <xsl:call-template name="display_date">
        <xsl:with-param name="date" select="date"/>
       </xsl:call-template>
      </td>
      <td class="cpsizecolumn">
       <xsl:call-template name="format_bytes">
        <xsl:with-param name="bytes" select="size"/>
       </xsl:call-template>
      </td>
      <td class="cpactionscolumn">
       <a target="_blank" onClick="window.location.href='properties.xsl/VSAPDOWNLOAD/?currentItem={url_encoded_target}&amp;currentUser={$currentUser}&amp;download=yes&amp;format=print'; return false" href="properties.xsl/VSAPDOWNLOAD/?currentItem={url_encoded_target}&amp;currentUser={$currentUser}&amp;download=yes&amp;format=print"><xsl:value-of select="/cp/strings/file_action_view"/></a> | 
       <a href="#" onClick="doSubmit('rename',null,null,'{$fileFullNameEscaped}')"><xsl:value-of select="/cp/strings/file_action_rename"/></a> |
       <a onClick="window.location.href='properties.xsl/VSAPDOWNLOAD/?currentItem={url_encoded_target}&amp;currentUser={$currentUser}&amp;download=yes'; return false" href="properties.xsl/VSAPDOWNLOAD/?currentItem={url_encoded_target}&amp;currentUser={$currentUser}&amp;download=yes"><xsl:value-of select="/cp/strings/file_action_download"/></a>
      </td>
     </xsl:if>
    </xsl:when>

    <!-- All other -->
    <xsl:otherwise>
     <td class="ckboxcolumn"><input type="checkbox" name="file" value="{name}"/></td>
     <td class="imagecolumn"><a href="#" onClick="doSubmit('properties','{$currentDirEscaped}',null,'{$fileFullNameEscaped}')"><img src="{/cp/strings/icons_folder}{cp_icon}.gif" border="0" /></a></td>
     <td class="filecolumn"><a href="#" onClick="doSubmit('properties','{$currentDirEscaped}',null,'{$fileFullNameEscaped}')"><xsl:value-of select="name"/></a>
     </td>
     <td class="lastmodcolumn">
      <xsl:call-template name="display_date">
       <xsl:with-param name="date" select="date"/>
      </xsl:call-template>
     </td>
     <td class="cpsizecolumn">
      <xsl:call-template name="format_bytes">
       <xsl:with-param name="bytes" select="size"/>
      </xsl:call-template>
     </td>
     <td class="cpactionscolumn">
      <a target="_blank" onClick="window.location.href='properties.xsl/VSAPDOWNLOAD/?currentItem={$fileFullNameEncoded}&amp;currentUser={$currentUser}&amp;download=yes&amp;format=print'; return false" href="properties.xsl/VSAPDOWNLOAD/?currentItem={$fileFullNameEncoded}&amp;currentUser={$currentUser}&amp;download=yes&amp;format=print"><xsl:value-of select="/cp/strings/file_action_view"/></a> | 
      <a href="#" onClick="doSubmit('rename',null,null,'{$fileFullNameEscaped}')"><xsl:value-of select="/cp/strings/file_action_rename"/></a> | 
      <a onClick="window.location.href='properties.xsl/VSAPDOWNLOAD/?currentItem={$fileFullNameEncoded}&amp;currentUser={$currentUser}&amp;download=yes'; return false" href="properties.xsl/VSAPDOWNLOAD/?currentItem={$fileFullNameEncoded}&amp;currentUser={$currentUser}&amp;download=yes"><xsl:value-of select="/cp/strings/file_action_download"/></a>
     </td>
    </xsl:otherwise>
   </xsl:choose>
  </tr>
 </xsl:template>

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
 
  <xsl:variable name="bcHeaderType">
    <xsl:choose>
      <xsl:when test="$currentUser = 'apache'">
        <xsl:value-of select="/cp/strings/bc_root_web_folder"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="/cp/strings/bc_file_list"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

 <xsl:template match="/">
  <xsl:call-template name="bodywrapper">
   <xsl:with-param name="title">
     <xsl:value-of select="/cp/strings/cp_title"/> : 
     v<xsl:value-of select="/cp/vsap/vsap[@type='auth']/version" /> :
     <xsl:value-of select="/cp/strings/nv_menu_filemanager"/> : 
     <xsl:value-of select="/cp/strings/nv_file_list"/> : 
     <xsl:value-of select="/cp/vsap/vsap[@type='files:list']/path"/>
   </xsl:with-param>
   <xsl:with-param name="formaction">index.xsl</xsl:with-param>
   <xsl:with-param name="onload">document.forms[0].locationJump.focus();</xsl:with-param>
   <xsl:with-param name="feedback" select="$feedback"/>
   <xsl:with-param name="selected_navandcontent" select="$selectedNavAndContent"/>
   <xsl:with-param name="help_short" select="/cp/strings/file_list_hlp_short"/>
   <xsl:with-param name="help_long"><xsl:value-of select="/cp/strings/file_list_hlp_long_eu"/></xsl:with-param>
   <xsl:with-param name="breadcrumb">
    <breadcrumb>
     <section>
      <name><xsl:value-of select="$bcHeaderType"/></name>
      <url>#</url>
      <image>FileManagement</image>
     </section>
    </breadcrumb>
   </xsl:with-param>

  </xsl:call-template>
 </xsl:template>

 <xsl:template name="content">

    <xsl:call-template name="cp_titlenavbar">
     <xsl:with-param name="active_tab">files</xsl:with-param>
    </xsl:call-template>

    <xsl:call-template name="hiddenFields">
     <xsl:with-param name="currentDir" select="$currentDir"/>
     <xsl:with-param name="refPage"/>
     <xsl:with-param name="actionType">jump</xsl:with-param>
     <xsl:with-param name="sortBy" select="$sortBy"/>
     <xsl:with-param name="sortType" select="$sortType"/>
     <xsl:with-param name="showHidden" select="$showHidden"/>
    </xsl:call-template>

    <xsl:call-template name="dir_properties"/>

    <table class="listview" border="0" cellspacing="0" cellpadding="0">
     <xsl:call-template name="control_row"/>
      <tr class="columnhead">
       <td class="ckboxcolumn">
        <input type="checkbox" name="files" onClick="check(this.form.file)" value=""/>
       </td>
       <td class="imagecolumn"><br/></td>

       <!-- File Name -->
       <td class="filecolumn">
        <xsl:variable name="newSortOrder">
         <xsl:choose>
          <xsl:when test="($sortBy = 'filename') and ($sortType = 'ascending')">descending</xsl:when>
          <xsl:otherwise>ascending</xsl:otherwise>
         </xsl:choose>
        </xsl:variable>
        <a href="#" onClick="doSubmit('listFiles',null,null,null,null,'filename','{$newSortOrder}')">
         <xsl:value-of select="/cp/strings/file_list_filename"/>
        </a>&#160;
        <a href="#" onClick="doSubmit('listFiles',null,null,null,null,'filename','{$newSortOrder}')">
         <xsl:if test="$sortBy = 'filename'">
          <xsl:choose>
           <xsl:when test="$sortType = 'ascending'">
            <img src="{/cp/strings/img_sortarrowup}" border="0"/>
           </xsl:when>
           <xsl:when test="$sortType = 'descending'">
            <img src="{/cp/strings/img_sortarrowdown}" border="0"/>
           </xsl:when>
          </xsl:choose>
         </xsl:if>
        </a>
       </td>

       <!-- Last Mod -->
       <td class="lastmodcolumn">
        <xsl:variable name="newSortOrder">
         <xsl:choose>
          <xsl:when test="($sortBy = 'lastmod') and ($sortType = 'ascending')">descending</xsl:when>
          <xsl:otherwise>ascending</xsl:otherwise>
         </xsl:choose>
        </xsl:variable>
        <a href="#" onClick="doSubmit('listFiles',null,null,null,null,'lastmod','{$newSortOrder}')">
         <xsl:value-of select="/cp/strings/file_list_lastmod"/>
        </a>&#160;
        <a href="#" onClick="doSubmit('listFiles',null,null,null,null,'lastmod','{$newSortOrder}')">
         <xsl:if test="$sortBy = 'lastmod'">
          <xsl:choose>
           <xsl:when test="$sortType = 'ascending'">
            <img src="{/cp/strings/img_sortarrowup}" border="0"/>
           </xsl:when>
           <xsl:when test="$sortType = 'descending'">
            <img src="{/cp/strings/img_sortarrowdown}" border="0"/>
           </xsl:when>
          </xsl:choose>
         </xsl:if>
        </a>
       </td>

       <!-- Size -->
       <td class="cpsizecolumn">
        <xsl:variable name="newSortOrder">
         <xsl:choose>
          <xsl:when test="($sortBy = 'size') and ($sortType = 'ascending')">descending</xsl:when>
          <xsl:otherwise>ascending</xsl:otherwise>
         </xsl:choose>
        </xsl:variable>
        <a href="#" onClick="doSubmit('listFiles',null,null,null,null,'size','{$newSortOrder}')">
         <xsl:value-of select="/cp/strings/file_list_size"/>
        </a>&#160;
        <a href="#" onClick="doSubmit('listFiles',null,null,null,null,'size','{$newSortOrder}')">
         <xsl:if test="$sortBy = 'size'">
          <xsl:choose>
           <xsl:when test="$sortType = 'ascending'">
            <img src="{/cp/strings/img_sortarrowup}" border="0"/>
           </xsl:when>
           <xsl:when test="$sortType = 'descending'">
            <img src="{/cp/strings/img_sortarrowdown}" border="0"/>
           </xsl:when>
          </xsl:choose>
         </xsl:if>
        </a>
       </td>

       <!-- Actions -->
       <td class="cpactionscolumn">
        <xsl:value-of select="/cp/strings/file_list_actions"/>
       </td>
      </tr>

      <xsl:choose>
       <xsl:when test="$sortBy = 'filename'">
        <xsl:apply-templates select="/cp/vsap/vsap[@type='files:list']/file[name != ''  and name != '.' and (starts-with(name, '.') = false or name = '.' or name = '..' or $showHidden = 'true')]">
         <xsl:sort select="name != '..'" order="ascending"/>
         <xsl:sort select="type = 'dir' or type = 'dirlink'" order="descending"/>    
         <xsl:sort select="translate(name, 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')" order="{$sortType}"/>
        </xsl:apply-templates>
       </xsl:when>
       <xsl:when test="$sortBy = 'lastmod'">
        <xsl:apply-templates select="/cp/vsap/vsap[@type='files:list']/file[name != ''  and name != '.' and (starts-with(name, '.') = false or name = '.' or name = '..' or $showHidden = 'true')]">
         <xsl:sort select="name != '..'" order="ascending"/>
         <xsl:sort select="type = 'dir' or type = 'dirlink'" order="descending"/>    
         <xsl:sort select="mtime/epoch" order="{$sortType}" data-type="number"/>
         <xsl:sort select="translate(name, 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')" order="ascending"/>
        </xsl:apply-templates>
       </xsl:when>
       <xsl:when test="$sortBy = 'size'">
       <xsl:apply-templates select="/cp/vsap/vsap[@type='files:list']/file[name != ''  and name != '.' and (starts-with(name, '.') = false or name = '.' or name = '..' or $showHidden = 'true')]">
        <xsl:sort select="name != '..'" order="ascending"/>
         <xsl:sort select="type = 'dir' or type = 'dirlink'" order="descending"/>    
         <xsl:sort select="size" order="{$sortType}" data-type="number"/>
         <xsl:sort select="translate(name, 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')" order="ascending"/>
        </xsl:apply-templates>
       </xsl:when>
      </xsl:choose>
     <xsl:call-template name="control_row"/>
    </table>

 </xsl:template>

 <xsl:template name="control_row">
  <tr class="controlrow">
   <td colspan="6">
    <input class="floatright" type="button" name="addFile" value="{/cp/strings/file_btn_addFile}" onClick="doSubmit('add_file')"/>
    <input class="floatright" type="button" name="addDir" value="{/cp/strings/file_btn_addDir}" onClick="doSubmit('add_dir')"/>
    <input class="floatright" type="button" name="upload" value="{/cp/strings/file_btn_upload}" onClick="window.open('upload.xsl?currentDir={$currentDir}&amp;currentUser={$currentUser}&amp;sessionID={$sessionID}','UploadFiles','scrollbars=yes,resizable=yes,width=540,height=440,screenX=30,screenY=30,top=30,left=30');"/>
    <input type="button" name="delete_file" value="{/cp/strings/file_btn_delete}" onClick="submitFiles('{cp:js-escape(/cp/strings/file_select_prompt)}','file','{/cp/strings/file_verify_files_delete}','delete')"/>
    <input type="button" name="compress_file" value="{/cp/strings/file_btn_compress}" onClick="submitFiles('{cp:js-escape(/cp/strings/file_select_prompt)}','file',null,'compress');"/>
    <input type="button" name="copy_file" value="{/cp/strings/file_btn_copy}" onClick="submitFiles('{cp:js-escape(/cp/strings/file_select_prompt)}','file',null,'copy');"/>
    <input type="button" name="move_file" value="{/cp/strings/file_btn_move}" onClick="submitFiles('{cp:js-escape(/cp/strings/file_select_prompt)}','file',null,'move');"/>
   </td>
  </tr>
 </xsl:template>

</xsl:stylesheet>
