<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" xmlns:exslt="http://exslt.org/common">
 <xsl:import href="../cp_global.xsl"/>
 <xsl:import href="file_global.xsl"/>

 <xsl:variable name="message">
   <xsl:choose>
     <xsl:when test="/cp/msgs/msg[@name='not_authorized']">
       <xsl:copy-of select="/cp/strings/cp_msg_file_add_file_fail" /> &gt;
       <xsl:copy-of select="/cp/strings/error_not_authorized" />
     </xsl:when>
     <xsl:when test="/cp/msgs/msg[@name='invalid_path']">
       <xsl:copy-of select="/cp/strings/cp_msg_file_add_file_fail" /> &gt;
       <xsl:copy-of select="/cp/strings/error_invalid_path" />
     </xsl:when>
     <xsl:when test="/cp/msgs/msg[@name='path_exists']">
       <xsl:copy-of select="/cp/strings/cp_msg_file_add_file_fail" /> &gt;
       <xsl:copy-of select="/cp/strings/error_path_exists" />
     </xsl:when>
     <xsl:when test="/cp/msgs/msg[@name='create_failed']">
       <xsl:copy-of select="/cp/strings/cp_msg_file_add_file_fail" />
     </xsl:when>
     <xsl:when test="/cp/msgs/msg[@name='quota_exceeded']">
       <xsl:copy-of select="/cp/strings/cp_msg_file_add_file_fail" /> &gt;
       <xsl:copy-of select="/cp/strings/error_quota_exceeded" />
     </xsl:when>
     <xsl:when test="/cp/msgs/msg[@name='invalid_user']">
       <xsl:copy-of select="/cp/strings/cp_msg_file_add_file_fail" /> &gt;
       <xsl:copy-of select="/cp/strings/error_invalid_user" />
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
    <xsl:value-of select="/cp/strings/cp_title"/> : <xsl:value-of select="/cp/strings/nv_menu_filemanager"/> : <xsl:value-of select="/cp/strings/bc_file_add"/>
   </xsl:with-param>
   <xsl:with-param name="formaction">add_file.xsl</xsl:with-param>
   <xsl:with-param name="onsubmit">return validateField('<xsl:value-of select="cp:js-escape(/cp/strings/file_valid_file_name)"/>', newFileName)</xsl:with-param>
   <xsl:with-param name="onload">document.forms[0].newFileName.focus();</xsl:with-param>
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
      <name><xsl:value-of select="/cp/strings/bc_file_add"/></name>
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
       <xsl:value-of select="/cp/strings/file_action_file_add"/>
      </td>
     </tr>
     <tr class="instructionrow">
      <td colspan="2">
       <xsl:value-of select="/cp/strings/file_file_add_title"/>
       &#160;<b><xsl:value-of select="/cp/form/currentDir"/></b>
      </td>
     </tr>
     <tr class="roweven">
      <td class="label">
       <xsl:value-of select="/cp/strings/file_add_file_name"/>
      </td>
      <td class="contentwidth">
       <input name="newFileName" value="" size="35">
         <xsl:if test="/cp/form/newFileName">
           <xsl:attribute name="value">
             <xsl:value-of select="/cp/form/newFileName" />
           </xsl:attribute>
         </xsl:if>
       </input>
      </td>
     </tr>
     <tr class="rowodd">
      <td class="label">
       <xsl:value-of select="/cp/strings/file_destination_directory"/>
      </td>
      <td class="contentwidth">
       <xsl:if test="$userType = 'da'">
        <xsl:if test="$currentUser != /cp/vsap/vsap[@type='auth']/username">
         <xsl:value-of select="$currentUser"/>:
        </xsl:if>
       </xsl:if>
       <xsl:value-of select="/cp/form/currentDir"/>
      </td>
     </tr>
     <tr class="roweven">
      <td class="label">
       <xsl:value-of select="/cp/strings/file_properties_template"/>
      </td>
      <td class="contentwidth">
       <select name="selectTemplate" onchange="setTemplate(this, editedFile, '{/cp/strings/file_template_instruction}', '{/cp/strings/file_template_reset}')">
        <option value=""><xsl:value-of select="/cp/strings/file_properties_template_none"/></option>
        <option value="{/cp/strings/html_template}"><xsl:value-of select="/cp/strings/file_properties_template_html"/></option>
        <option value="{/cp/strings/xhtml_template}"><xsl:value-of select="/cp/strings/file_properties_template_xhtml"/></option>
       </select>
      </td>
     </tr>

     <tr class="rowodd">
      <td class="label"><xsl:value-of select="/cp/strings/file_properties_word_wrap_options"/></td>
      <td class="contentwidth">
       <select name="selectWrap" onchange="setTextAreaWrap(this, editedFile)">
        <option value="off"><xsl:value-of select="/cp/strings/file_properties_word_wrap_none"/></option>
        <option value="soft"><xsl:value-of select="/cp/strings/file_properties_word_wrap_soft"/></option>
        <option value="hard"><xsl:value-of select="/cp/strings/file_properties_word_wrap_hard"/></option>
       </select>
      </td>
     </tr>

     <tr class="roweven">
      <td class="label">
       <xsl:value-of select="/cp/strings/file_properties_file_contents"/>
      </td>
      <td class="contentwidth">
       <textarea name="editedFile" rows="12" cols="60" wrap="off">
        <xsl:if test="/cp/form/editedFile">
          <xsl:value-of select="/cp/form/editedFile" />
        </xsl:if>
       </textarea>
      </td>
     </tr>

     <tr class="controlrow">
      <td colspan="2">
       <input class="floatright" type="button" name="cmd_cancel" value="{/cp/strings/file_btn_cancel}" onClick="javascript:doSubmit('_cancel')"/>
       <input class="floatright" type="reset" name="reset" value="{/cp/strings/file_btn_reset}"/>
       <input class="floatright" type="submit" name="ok" value="{/cp/strings/file_btn_ok}" onClick="actionType.value='_addFile'"/>
      </td>
     </tr>
    </table>

 </xsl:template>
</xsl:stylesheet>
