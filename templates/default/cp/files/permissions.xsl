<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" xmlns:exslt="http://exslt.org/common">
 <xsl:import href="../cp_global.xsl"/>
 <xsl:import href="file_global.xsl"/>

 <xsl:variable name="message">
   <xsl:choose>
     <xsl:when test="/cp/msgs/msg[@name='not_authorized']">
       <xsl:copy-of select="/cp/strings/cp_msg_file_permissions_fail" /> &gt;
       <xsl:copy-of select="/cp/strings/error_not_authorized" />
     </xsl:when>
     <xsl:when test="/cp/msgs/msg[@name='invalid_path']">
       <xsl:copy-of select="/cp/strings/cp_msg_file_permissions_fail" /> &gt;
       <xsl:copy-of select="/cp/strings/error_invalid_path" />
     </xsl:when>
     <xsl:when test="/cp/msgs/msg[@name='chmod_failed']">
       <xsl:copy-of select="/cp/strings/cp_msg_file_permissions_fail" />
     </xsl:when>
     <xsl:when test="/cp/msgs/msg[@name='recursion_failed']">
       <xsl:copy-of select="/cp/strings/cp_msg_file_permissions_fail" /> &gt;
       <xsl:copy-of select="/cp/strings/error_recursion_failed" />
     </xsl:when>
     <xsl:when test="/cp/msgs/msg[@name='invalid_user']">
       <xsl:copy-of select="/cp/strings/cp_msg_file_permissions_fail" /> &gt;
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
    <xsl:value-of select="/cp/strings/cp_title"/>
    v<xsl:value-of select="/cp/vsap/vsap[@type='auth']/version" /> :
    <xsl:value-of select="/cp/strings/nv_menu_filemanager"/> : 
    <xsl:value-of select="/cp/strings/bc_permissions"/>
   </xsl:with-param>
   <xsl:with-param name="formaction">permissions.xsl</xsl:with-param>
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
      <name>
       <xsl:value-of select="/cp/strings/bc_permissions"/>: 
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

    <script src="{concat($base_url, '/cp/cp.js')}" language="JavaScript"></script>
    <xsl:variable name="ownedByValidUser">
     <xsl:if test="$userType = 'da'">
      <xsl:for-each select="/cp/vsap/vsap[@type='user:list:eu']/user">
       <xsl:if test=". = /cp/vsap/vsap[@type='files:chmod']/owner">yes</xsl:if>
      </xsl:for-each>
     </xsl:if>
    </xsl:variable>
    <xsl:variable name="rw">
     <xsl:choose>
      <xsl:when test="$userType = 'da' and $ownedByValidUser != 'yes'">false</xsl:when>
      <xsl:when test="/cp/form/currentDir = '/' and $userType = 'sa'">false</xsl:when>
      <xsl:otherwise>true</xsl:otherwise>
     </xsl:choose>
    </xsl:variable>
    <xsl:call-template name="hiddenFields"/>
    <table class="formview" border="0" cellspacing="0" cellpadding="0">
     <tr class="title">
      <td colspan="2">
       <xsl:value-of select="/cp/strings/file_action_permissions"/>
      </td>
     </tr>
     <tr class="instructionrow">
      <td colspan="2">
       <xsl:value-of select="/cp/strings/file_permissions_title"/>&#160;
       <xsl:if test="$userType = 'da'">
        <xsl:if test="$currentUser != /cp/vsap/vsap[@type='auth']/username">
         <b><xsl:value-of select="$currentUser"/>:</b>
        </xsl:if>
       </xsl:if>
       <b><xsl:value-of select="/cp/form/currentItem"/></b>
      </td>
     </tr>
       <tr class="roweven">
        <td class="label">
         <xsl:value-of select="/cp/strings/file_properties_owner"/>
        </td>
        <td class="contentwidth">
         <input class="indent" type="checkbox" id="owner_read" name="chkOwnerRead"  value="1"><xsl:if test="$rw='false'"><xsl:attribute name="disabled"/></xsl:if><xsl:if test="/cp/vsap/vsap[@type='files:chmod']/mode/owner/read = '1' or /cp/form/chkOwnerRead = '1'"><xsl:attribute name="checked"/></xsl:if></input> <label for="owner_read"><xsl:value-of select="/cp/strings/file_mode_read"/></label>
         <input class="indent" type="checkbox" id="owner_write" name="chkOwnerWrite" value="1"><xsl:if test="$rw='false'"><xsl:attribute name="disabled"/></xsl:if><xsl:if test="/cp/vsap/vsap[@type='files:chmod']/mode/owner/write = '1' or /cp/form/chkOwnerWrite = '1'"><xsl:attribute name="checked"/></xsl:if></input> <label for="owner_write"><xsl:value-of select="/cp/strings/file_mode_write"/></label>
         <input class="indent" type="checkbox" id="owner_exec" name="chkOwnerExec"  value="1"><xsl:if test="$rw='false'"><xsl:attribute name="disabled"/></xsl:if><xsl:if test="/cp/vsap/vsap[@type='files:chmod']/mode/owner/execute = '1' or /cp/form/chkOwnerExec = '1'"><xsl:attribute name="checked"/></xsl:if></input> <label for="owner_exec"><xsl:value-of select="/cp/strings/file_mode_exec"/></label>
        </td>
       </tr>
       <tr class="rowodd">
        <td class="label">
         <xsl:value-of select="/cp/strings/file_properties_group"/>
        </td>
        <td class="contentwidth">
         <input class="indent" type="checkbox" id="group_read" name="chkGroupRead"  value="1"><xsl:if test="$rw='false'"><xsl:attribute name="disabled"/></xsl:if><xsl:if test="/cp/vsap/vsap[@type='files:chmod']/mode/group/read = '1' or /cp/form/chkGroupRead = '1'"><xsl:attribute name="checked"/></xsl:if></input> <label for="group_read"><xsl:value-of select="/cp/strings/file_mode_read"/></label>
         <input class="indent" type="checkbox" id="group_write" name="chkGroupWrite" value="1"><xsl:if test="$rw='false'"><xsl:attribute name="disabled"/></xsl:if><xsl:if test="/cp/vsap/vsap[@type='files:chmod']/mode/group/write = '1' or /cp/form/chkGroupWrite = '1'"><xsl:attribute name="checked"/></xsl:if></input> <label for="group_write"><xsl:value-of select="/cp/strings/file_mode_write"/></label>
         <input class="indent" type="checkbox" id="group_exec" name="chkGroupExec"  value="1"><xsl:if test="$rw='false'"><xsl:attribute name="disabled"/></xsl:if><xsl:if test="/cp/vsap/vsap[@type='files:chmod']/mode/group/execute = '1' or /cp/form/chkGroupExec = '1'"><xsl:attribute name="checked"/></xsl:if></input> <label for="group_exec"><xsl:value-of select="/cp/strings/file_mode_exec"/></label>
        </td>
       </tr>
       <tr class="roweven">
        <td class="label">
         <xsl:value-of select="/cp/strings/file_properties_world"/>
        </td>
        <td class="contentwidth">
         <input class="indent" type="checkbox" id="world_read" name="chkWorldRead"  value="1"><xsl:if test="$rw='false'"><xsl:attribute name="disabled"/></xsl:if><xsl:if test="/cp/vsap/vsap[@type='files:chmod']/mode/world/read = '1' or /cp/form/chkWorldRead = '1'"><xsl:attribute name="checked"/></xsl:if></input> <label for="world_read"><xsl:value-of select="/cp/strings/file_mode_read"/></label>
         <input class="indent" type="checkbox" id="world_write" name="chkWorldWrite" value="1"><xsl:if test="$rw='false'"><xsl:attribute name="disabled"/></xsl:if><xsl:if test="/cp/vsap/vsap[@type='files:chmod']/mode/world/write = '1' or /cp/form/chkWorldWrite = '1'"><xsl:attribute name="checked"/></xsl:if></input> <label for="world_write"><xsl:value-of select="/cp/strings/file_mode_write"/></label>
         <input class="indent" type="checkbox" id="world_exec" name="chkWorldExec"  value="1"><xsl:if test="$rw='false'"><xsl:attribute name="disabled"/></xsl:if><xsl:if test="/cp/vsap/vsap[@type='files:chmod']/mode/world/execute = '1' or /cp/form/chkWorldExec = '1'"><xsl:attribute name="checked"/></xsl:if></input> <label for="world_exec"><xsl:value-of select="/cp/strings/file_mode_exec"/></label>
        </td>
       </tr>

     <xsl:if test="/cp/vsap/vsap[@type='files:chmod']/recurse_option_valid = 'yes'">
      <tr class="rowodd">
       <td class="label">
        <xsl:value-of select="/cp/strings/file_command_options"/>
       </td>
       <td class="contentwidth">
        <input type="checkbox" id="recurse" name="recurse" onClick="disenableRecurseX(this);" value="1"><xsl:if test="$rw='false'"><xsl:attribute name="disabled"/></xsl:if></input> <label for="recurse"><xsl:value-of select="/cp/strings/file_command_recurse"/></label><br/>
        <p>
        <ul>
        <xsl:value-of disable-output-escaping="yes" select="/cp/strings/file_command_recurse_X_note"/><br/>
        <input type="radio" id="rxno" name="recurse_X" value="yes" checked="true"><xsl:attribute name="disabled"/></input><label for="rxno"><xsl:value-of select="/cp/strings/file_command_recurse_X_option_1"/></label><br/>
        <input type="radio" id="rxyes" name="recurse_X" value="no"><xsl:attribute name="disabled"/></input><label for="rxyes"><xsl:value-of select="/cp/strings/file_command_recurse_X_option_2"/></label><br/>
        </ul>
        </p>
       </td>
      </tr>
     </xsl:if>


     <tr class="controlrow">
      <td colspan="2">
       <input class="floatright" type="button" name="cmd_cancel" value="{/cp/strings/file_btn_cancel}" onClick="doSubmit('_cancel')"/>
       <input class="floatright" type="submit" name="ok" value="{/cp/strings/file_btn_ok}" onClick="actionType.value='_permissions'"><xsl:if test="$rw='false'"><xsl:attribute name="disabled"/></xsl:if></input>
      </td>
     </tr>
    </table>

</xsl:template>
</xsl:stylesheet>
