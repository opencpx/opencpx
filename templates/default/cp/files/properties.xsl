<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" xmlns:exslt="http://exslt.org/common">
 <xsl:import href="../cp_global.xsl" />
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
       <xsl:when test="/cp/msgs/msg[@name='fail']!='0'">
        <xsl:value-of select="/cp/strings/cp_msg_file_copy_fail"/>&#160;<xsl:value-of select="/cp/msgs/msg[@name='fail']"/>&#160;<xsl:value-of select="/cp/strings/cp_msg_file_copy_suffix"/>
       </xsl:when>
       <xsl:otherwise>
        <xsl:value-of select="/cp/strings/cp_msg_file_copy_success"/>&#160;<xsl:value-of select="/cp/msgs/msg[@name='success']"/>&#160;<xsl:value-of select="/cp/strings/cp_msg_file_copy_suffix"/>
       </xsl:otherwise>
      </xsl:choose>
     </xsl:with-param>
    </xsl:call-template>
   </xsl:when>

   <!--xsl:when test="/cp/msgs/msg[@name='move_action']">
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
        <xsl:value-of select="/cp/strings/cp_msg_file_move_fail"/>&#160;<xsl:value-of select="/cp/msgs/msg[@name='fail']"/>&#160;<xsl:value-of select="/cp/strings/cp_msg_file_move_suffix"/>
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
   </xsl:when-->
 
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

   <!--xsl:when test="/cp/msgs/msg[@name='rename_action']">
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
   </xsl:when-->

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

  
 <!-- Preview Text File -->
 <xsl:template name="file_preview_text">
  <table class="formview" border="0" cellspacing="0" cellpadding="0">
   <tr class="columnhead">
    <td colspan="2" class="title">
     <xsl:value-of select="/cp/strings/file_properties_file_preview"/>
    </td>
   </tr>
   <xsl:choose>
   <xsl:when test="/cp/vsap/vsap[@type='files:properties']/contents[@large='yes']">
    <tr class="roweven">
     <td colspan="2" class="contentwidth">
      <xsl:value-of select="/cp/strings/file_properties_file_contents_too_large"/>
     </td>
    </tr>
   </xsl:when>
   <xsl:otherwise>
    <xsl:variable name="wrapMode">
     <xsl:choose>
      <xsl:when test="/cp/form/selectWrap"><xsl:value-of select="/cp/form/selectWrap"/></xsl:when>
      <xsl:otherwise>off</xsl:otherwise>
     </xsl:choose>
    </xsl:variable>
    <tr class="roweven">
     <td class="label"><xsl:value-of select="/cp/strings/file_properties_word_wrap_options"/></td>
     <td class="contentwidth"><select name="selectWrap" onchange="setTextAreaWrap(this, editedFile)">
     <option value="off"><xsl:value-of select="/cp/strings/file_properties_word_wrap_none"/></option>
     <option value="soft"><xsl:if test="$wrapMode='soft'"><xsl:attribute name="selected"/></xsl:if><xsl:value-of select="/cp/strings/file_properties_word_wrap_soft"/></option>
     <option value="hard"><xsl:if test="$wrapMode='hard'"><xsl:attribute name="selected"/></xsl:if><xsl:value-of select="/cp/strings/file_properties_word_wrap_hard"/></option>
     </select></td>
    </tr>
    <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='files:properties']/is_writable = 'yes'">
     <tr class="rowodd">
      <td class="label" valign="top"><xsl:value-of select="/cp/strings/file_properties_file_contents"/></td>
      <td class="contentwidth"><textarea name="editedFile" rows="12" cols="60" wrap="{$wrapMode}">
       <xsl:value-of select="/cp/vsap/vsap[@type='files:properties']/contents"/>
      </textarea><br/><br/></td>
     </tr>
     <tr class="controlrow">
      <td colspan="2">
       <input class="floatright" type="button" name="cmd_cancel" value="{/cp/strings/file_btn_cancel}" onClick="doSubmit('listFiles')"/>
       <input class="floatright" type="submit" name="save" value="{/cp/strings/file_btn_save}" onClick="actionType.value = '_save'"/>
      </td>
     </tr>
    </xsl:when>
    <xsl:otherwise> 
     <tr class="rowodd">
      <td class="label" valign="top"><xsl:value-of select="/cp/strings/file_properties_file_contents"/></td>
      <td class="contentwidth">
       <xsl:value-of select="/cp/vsap/vsap[@type='files:properties']/contents"/>
      <br/><br/></td>
     </tr>
    </xsl:otherwise>
    </xsl:choose>
   </xsl:otherwise>
   </xsl:choose>
  </table>
 </xsl:template>


 <!-- Preview Image File -->
 <xsl:template name="file_preview_image">
  <table class="formview" border="0" cellspacing="0" cellpadding="0">
   <tr class="columnhead">
    <td colspan="2" class="title">
     <xsl:value-of select="/cp/strings/file_properties_file_preview"/>
    </td>
   </tr>
   <tr class="roweven">
    <td class="label"><xsl:value-of select="/cp/strings/file_properties_file_preview"/></td>
    <td class="contentwidth">
     <a onClick="window.location.href='properties.xsl/VSAPDOWNLOAD/?currentItem={/cp/vsap/vsap[@type='files:properties']/url_encoded_path}&amp;currentUser={$currentUser}&amp;format=print&amp;download=yes'; return false" href="properties.xsl/VSAPDOWNLOAD/?currentItem={/cp/vsap/vsap[@type='files:properties']/url_encoded_path}&amp;currentUser={$currentUser}&amp;format=print&amp;download=yes"><img src="properties.xsl/VSAPDOWNLOAD/?currentItem={/cp/vsap/vsap[@type='files:properties']/thumb_path}&amp;format=print&amp;download=yes" style="border-color: #000000; border-width: 1px"/></a><br/>
    </td>
   </tr>
   <tr class="rowodd">
    <td class="label"><xsl:value-of select="/cp/strings/file_properties_preview_size"/></td>
    <td class="contentwidth"><xsl:value-of select="/cp/vsap/vsap[@type='files:properties']/thumb_width"/> X <xsl:value-of select="/cp/vsap/vsap[@type='files:properties']/thumb_height"/></td>
   </tr>
   <tr class="roweven">
    <td class="label" valign="top"><xsl:value-of select="/cp/strings/file_properties_actual_size"/></td>
    <td class="contentwidth"><xsl:value-of select="/cp/vsap/vsap[@type='files:properties']/image_width"/> X <xsl:value-of select="/cp/vsap/vsap[@type='files:properties']/image_height"/></td>
   </tr>
   <tr class="controlrow">
    <td colspan="2">
     <input class="floatright" type="button" name="cmd_cancel" value="{/cp/strings/file_btn_back}" onClick="doSubmit('listFiles');"/>
    </td>
   </tr>
  </table>
 </xsl:template>

 <!-- Preview Compressed (zip) File -->
 <xsl:template name="file_preview_compressed">
  <table class="formview" border="0" cellspacing="0" cellpadding="0">
   <tr class="columnhead">
    <td colspan="2" class="title">
     <xsl:value-of select="/cp/strings/file_properties_file_preview"/>
    </td>
   </tr>
   <tr class="roweven">
    <td class="label"><xsl:value-of select="/cp/strings/file_properties_file_preview"/></td>
    <td class="contentwidth">
     <xsl:value-of select="/cp/strings/file_properties_contents"/>&#160;
     <xsl:value-of select="/cp/vsap/vsap[@type='files:properties']/path"/><br/><br/>
     <input name="archive" type="hidden" value="{/cp/vsap/vsap[@type='files:properties']/path}"/>

     <table class="displaylist" border="0" cellspacing="0" cellpadding="0">
      <tr>
       <td class="ckboxcolumn"><input type="checkbox" id="all_files" name="files" onClick="check2(this.form.file, this.checked)" value=""/></td>
       <td class="label"><label for="all_files"><xsl:value-of select="/cp/strings/file_list_file"/></label></td>
       <td class="label"><xsl:value-of select="/cp/strings/file_list_size"/></td>
       <td class="label"><xsl:value-of select="/cp/strings/file_list_path"/></td>
       <td class="label"><xsl:value-of select="/cp/strings/file_list_action"/></td>
      </tr>

      <xsl:call-template name="archive_contents">
       <xsl:with-param name="archiveItems" select="/cp/vsap/vsap[@type='files:properties']/archive_contents"/>
      </xsl:call-template>   
      <tr class="controlrow">
       <td colspan="5"><input type="button" name="Extract_Selected" value="{/cp/strings/file_action_extract_selected}" onClick="submitFiles('{cp:js-escape(/cp/strings/file_select_prompt)}','file','','uncompress')"/></td>
      </tr>
     </table>


    </td>
   </tr>
   <tr class="controlrow">
    <td colspan="2">
     <input class="floatright" type="button" name="cmd_cancel" value="{/cp/strings/file_btn_cancel}" onClick="doSubmit('listFiles');"/>
     <input class="floatright" type="button" name="uncompress" value="{/cp/strings/file_btn_uncompress}" onClick="doSubmit('uncompress',null,null,null,'properties.xsl',null,null,null,'/')" />
    </td>
   </tr>
  </table>
 </xsl:template>

 <xsl:template name="archive_contents">
  <xsl:param name="archiveItems"/>
  <xsl:for-each select="$archiveItems/*">
    <xsl:variable name="row_id">row<xsl:value-of select="position()"/></xsl:variable>
    <xsl:variable name="path_length">
     <xsl:choose>
      <xsl:when test="path = './'">0</xsl:when>
      <xsl:otherwise><xsl:value-of select="string-length(./path)+1"/></xsl:otherwise>
     </xsl:choose>
    </xsl:variable> 
    <tr>
     <td><input type="checkbox" id="{$row_id}" name="file" value="{name}" /></td>
     <td><label for="{$row_id}"><xsl:value-of select="substring(name, $path_length)"/></label></td>
     <td><xsl:call-template name="format_bytes"><xsl:with-param name="bytes" select="size"/></xsl:call-template></td>
     <td><xsl:value-of select="path"/></td>
     <td><a href="#" onClick="doSubmit('uncompress',null,null,null,'properties.xsl',null,null,null,'{url_escaped_name}')"><xsl:value-of select="/cp/strings/file_action_extract"/></a></td>
    </tr>
  </xsl:for-each>
 </xsl:template>


 <!-- Unsupported File Types-->
 <xsl:template name="file_preview_unsuported">
  <table class="formview" border="0" cellspacing="0" cellpadding="0">
   <tr class="columnhead">
    <td colspan="2" class="title">
     <xsl:value-of select="/cp/strings/file_properties_file_preview"/>
    </td>
   </tr>
   <tr class="roweven">
    <td class="label"><xsl:value-of select="/cp/strings/file_properties_file_preview"/></td>
    <td class="contentwidth">
     <b><xsl:value-of select="/cp/strings/file_preview_unsupported_type"/></b>
    </td>
   </tr>
   <tr class="controlrow">
    <td colspan="2">
     <input class="floatright" type="button" name="cmd_cancel" value="{/cp/strings/file_btn_back}" onClick="doSubmit('listFiles');"/></td>
   </tr>
  </table>
 </xsl:template>


 <!-- Read Access Denied; Preview Unavailable-->
 <xsl:template name="file_preview_no_access">
  <table class="formview" border="0" cellspacing="0" cellpadding="0">
   <tr class="columnhead">
    <td colspan="2" class="title">
     <xsl:value-of select="/cp/strings/file_properties_file_preview"/>
    </td>
   </tr>
   <tr class="roweven">
    <td class="label"><xsl:value-of select="/cp/strings/file_properties_file_preview"/></td>
    <td class="contentwidth">
     <b><xsl:value-of select="/cp/strings/file_preview_no_access"/></b>
    </td>
   </tr>
   <tr class="controlrow">
    <td colspan="2">
     <input class="floatright" type="button" name="cmd_cancel" value="{/cp/strings/file_btn_back}" onClick="doSubmit('listFiles');"/></td>
   </tr>
  </table>
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

 <xsl:template match="/">
  <xsl:call-template name="bodywrapper">
   <xsl:with-param name="title"><xsl:value-of select="/cp/strings/cp_title"/> : <xsl:value-of select="/cp/strings/nv_menu_filemanager"/> : <xsl:value-of select="/cp/strings/bc_file_properties"/> : <xsl:value-of select="/cp/vsap/vsap[@type='files:properties']/path"/></xsl:with-param>
   <xsl:with-param name="formaction">properties.xsl</xsl:with-param>
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
      <name>
       <xsl:value-of select="/cp/strings/bc_file_properties"/>:
       <xsl:value-of select="/cp/vsap/vsap[@type='files:properties']/name"/>
      </name>
      <url>#</url>
      <image>FileManagement</image>
     </section>
    </breadcrumb>
   </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

    <xsl:choose>
     <xsl:when test="/cp/form/actionType = 'jump'">
      <xsl:call-template name="hiddenFields">
       <xsl:with-param name="refPage"></xsl:with-param>
       <xsl:with-param name="senderData"></xsl:with-param>
       <xsl:with-param name="currentItem" select="/cp/form/locationJump" />
      </xsl:call-template>    
     </xsl:when>
     <xsl:otherwise>
      <xsl:call-template name="hiddenFields">
       <xsl:with-param name="refPage"></xsl:with-param>
       <xsl:with-param name="senderData"></xsl:with-param>
      </xsl:call-template>    
     </xsl:otherwise>
    </xsl:choose>

   
    <xsl:call-template name="file_properties"/>
    <xsl:choose>
     <xsl:when test="/cp/vsap/vsap[@type='files:properties']/contents">
      <xsl:call-template name="file_preview_text"/>
     </xsl:when>
     <xsl:when test="/cp/vsap/vsap[@type='files:properties']/image_width">
      <xsl:call-template name="file_preview_image"/>
     </xsl:when>
     <xsl:when test="/cp/vsap/vsap[@type='files:properties']/archive_contents">
      <xsl:call-template name="file_preview_compressed"/>
     </xsl:when>
     <xsl:when test="substring(/cp/vsap/vsap[@type='files:properties']/symbolic_mode,1,3)='---'">
      <xsl:call-template name="file_preview_no_access"/>
     </xsl:when>
     <xsl:otherwise>
      <xsl:call-template name="file_preview_unsuported"/>
     </xsl:otherwise>
    </xsl:choose>

</xsl:template>
</xsl:stylesheet>

