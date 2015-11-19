<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" xmlns:exslt="http://exslt.org/common">
 <xsl:import href="../cp_global.xsl"/>
 <xsl:import href="file_global.xsl"/>

 <xsl:variable name="message">
   <xsl:choose>
     <xsl:when test="/cp/msgs/msg[@name='not_authorized']">
       <xsl:copy-of select="/cp/strings/cp_msg_file_rename_fail" /> &gt;
       <xsl:copy-of select="/cp/strings/error_not_authorized" />
     </xsl:when>
     <xsl:when test="/cp/msgs/msg[@name='invalid_path']">
       <xsl:copy-of select="/cp/strings/cp_msg_file_rename_fail" /> &gt;
       <xsl:copy-of select="/cp/strings/error_invalid_path" />
     </xsl:when>
     <xsl:when test="/cp/msgs/msg[@name='rename_failed']">
       <xsl:copy-of select="/cp/strings/cp_msg_file_rename_fail" />
     </xsl:when>
     <xsl:when test="/cp/msgs/msg[@name='quota_exceeded']">
       <xsl:copy-of select="/cp/strings/cp_msg_file_rename_fail" /> &gt;
       <xsl:copy-of select="/cp/strings/error_quota_exceeded" />
     </xsl:when>
     <xsl:when test="/cp/msgs/msg[@name='invalid_user']">
       <xsl:copy-of select="/cp/strings/cp_msg_file_rename_fail" /> &gt;
       <xsl:copy-of select="/cp/strings/error_invalid_user" />
     </xsl:when>
     <xsl:when test="/cp/msgs/msg[@name='invalid_name']">
       <xsl:copy-of select="/cp/strings/cp_msg_file_rename_fail" /> &gt;
       <xsl:copy-of select="/cp/strings/error_invalid_name" />
     </xsl:when>
     <xsl:when test="/cp/msgs/msg[@name='invalid_target']">
       <xsl:copy-of select="/cp/strings/cp_msg_file_rename_fail" /> &gt;
       <xsl:copy-of select="/cp/strings/error_invalid_target" />
     </xsl:when>
     <xsl:when test="/cp/msgs/msg[@name='target_exists']">
       <xsl:copy-of select="/cp/strings/cp_msg_file_rename_fail" /> &gt;
       <xsl:copy-of select="/cp/strings/error_path_exists" />
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
     <xsl:value-of select="/cp/strings/cp_title"/>
     v<xsl:value-of select="/cp/vsap/vsap[@type='auth']/version" /> :
     <xsl:value-of select="/cp/strings/nv_menu_filemanager"/> : 
     <xsl:value-of select="/cp/strings/bc_file_rename"/>
   </xsl:with-param>
   <xsl:with-param name="formaction">rename.xsl</xsl:with-param>
   <xsl:with-param name="onsubmit">return validateField('<xsl:value-of select="cp:js-escape(/cp/strings/file_valid_file_name)"/>', targetName) &amp;&amp; validateRenameNewNameField('<xsl:value-of select="cp:js-escape(/cp/strings/file_rename_instructions)"/>', targetName)</xsl:with-param>
   <xsl:with-param name="onload">document.forms[0].targetName.focus();</xsl:with-param>
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
       <xsl:value-of select="/cp/strings/bc_file_rename"/>: 
       <xsl:if test="$userType = 'da'">
        <xsl:if test="$currentUser != /cp/vsap/vsap[@type='auth']/username">
         <b><xsl:value-of select="$currentUser"/>:</b>
        </xsl:if>
       </xsl:if>
       <xsl:value-of select="/cp/form/currentItem"/>
      </name>
      <url>#</url>
      <image>FileManagement</image>
     </section>
    </breadcrumb>
   </xsl:with-param>
   
  </xsl:call-template>
 </xsl:template>

 <xsl:template name="content">

    <xsl:call-template name="hiddenFields" />
    <table class="formview" border="0" cellspacing="0" cellpadding="0">
     <tr class="title">
      <td colspan="2">
       <xsl:value-of select="/cp/strings/file_action_rename"/>
      </td>
     </tr>
     <tr class="instructionrow">
      <td colspan="2">
       <xsl:value-of select="/cp/strings/file_rename_title"/>
       <br/>
       <xsl:value-of select="/cp/strings/file_rename_instructions"/>
      </td>
     </tr>
     <tr class="rowodd">
      <td class="label">
       <xsl:value-of select="/cp/strings/file_old_name"/>
      </td>
      <td class="contentwidth">
       <xsl:if test="$userType = 'da'">
        <xsl:if test="$currentUser != /cp/vsap/vsap[@type='auth']/username">
         <xsl:value-of select="$currentUser"/>:
        </xsl:if>
       </xsl:if>
       <xsl:value-of select="/cp/form/currentItem"/>
      </td>
     </tr>
     <tr class="roweven">
      <td class="label">
       <xsl:value-of select="/cp/strings/file_new_name"/>
      </td>
      <td class="contentwidth">
       <input name="targetName" value="" size="35">
         <xsl:if test="/cp/form/targetName">
           <xsl:attribute name="value">
             <xsl:value-of select="/cp/form/targetName" />
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
       <input type="hidden" name="target" value="{/cp/form/currentDir}" />
       <xsl:if test="$userType = 'da'">
        <xsl:if test="$currentUser != /cp/vsap/vsap[@type='auth']/username">
         <xsl:value-of select="$currentUser"/>:
        </xsl:if>
       </xsl:if>
       <xsl:value-of select="/cp/form/currentDir"/>
      </td>
     </tr>

     <tr class="controlrow">
      <td colspan="2">
       <input class="floatright" type="button" name="cmd_cancel" value="{/cp/strings/file_btn_cancel}" onClick="doSubmit('_cancel')"/>
       <input class="floatright" type="submit" name="ok" value="{/cp/strings/file_btn_ok}" onClick="actionType.value='_rename'" />
      </td>
     </tr>

    </table>

 </xsl:template>
</xsl:stylesheet>
