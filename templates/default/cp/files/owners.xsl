<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" xmlns:exslt="http://exslt.org/common">
 <xsl:import href="../cp_global.xsl"/>
 <xsl:import href="file_global.xsl"/>

 <xsl:variable name="message">
   <xsl:choose>
     <xsl:when test="/cp/msgs/msg[@name='not_authorized']">
       <xsl:copy-of select="/cp/strings/cp_msg_file_owners_fail" /> &gt;
       <xsl:copy-of select="/cp/strings/error_not_authorized" />
     </xsl:when>
     <xsl:when test="/cp/msgs/msg[@name='invalid_path']">
       <xsl:copy-of select="/cp/strings/cp_msg_file_owners_fail" /> &gt;
       <xsl:copy-of select="/cp/strings/error_invalid_path" />
     </xsl:when>
     <xsl:when test="/cp/msgs/msg[@name='chown_failed']">
       <xsl:copy-of select="/cp/strings/cp_msg_file_owners_fail" />
     </xsl:when>
     <xsl:when test="/cp/msgs/msg[@name='recursion_failed']">
       <xsl:copy-of select="/cp/strings/cp_msg_file_owners_fail" /> &gt;
       <xsl:copy-of select="/cp/strings/error_recursion_failed" />
     </xsl:when>
     <xsl:when test="/cp/msgs/msg[@name='invalid_user']">
       <xsl:copy-of select="/cp/strings/cp_msg_file_owners_fail" /> &gt;
       <xsl:copy-of select="/cp/strings/error_invalid_user" />
     </xsl:when>
     <xsl:when test="/cp/msgs/msg[@name='invalid_owner']">
       <xsl:copy-of select="/cp/strings/cp_msg_file_owners_fail" /> &gt;
       <xsl:copy-of select="/cp/strings/error_invalid_owner" />
     </xsl:when>
     <xsl:when test="/cp/msgs/msg[@name='invalid_group']">
       <xsl:copy-of select="/cp/strings/cp_msg_file_owners_fail" /> &gt;
       <xsl:copy-of select="/cp/strings/error_invalid_group" />
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
    <xsl:value-of select="/cp/strings/bc_owners"/>
   </xsl:with-param>
   <xsl:with-param name="formaction">owners.xsl</xsl:with-param>
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
       <xsl:value-of select="/cp/strings/bc_owners"/>: 
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

    <xsl:variable name="ownedByValidUser">
     <xsl:if test="$userType = 'da'">
      <xsl:for-each select="/cp/vsap/vsap[@type='user:list:eu']/user">
       <xsl:if test=". = /cp/vsap/vsap[@type='files:chown']/owner">yes</xsl:if>
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
    <xsl:call-template name="hiddenFields" />
    <table class="formview" border="0" cellspacing="0" cellpadding="0">
     <tr class="title">
      <td colspan="2">
       <xsl:value-of select="/cp/strings/file_action_owners"/>
      </td>
     </tr>
     <tr class="instructionrow">
      <td colspan="2">
       <xsl:value-of select="/cp/strings/file_owners_title"/>&#160;
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
       <xsl:value-of select="/cp/strings/file_properties_user_id"/>
      </td>
      <td class="contentwidth">
       <xsl:variable name="selectedUser" select="/cp/vsap/vsap[@type='files:chown']/owner"/>
       <select name="lstUser"><xsl:if test="$rw='false'"><xsl:attribute name="disabled"/></xsl:if>
       <xsl:for-each select="/cp/vsap/vsap[@type='files:chown']/ownership_options/ownernames/owner">
        <xsl:sort select="."/>
        <option value="{.}"><xsl:if test=".=$selectedUser or .=/cp/form/selectedUser"><xsl:attribute name="selected"/></xsl:if><xsl:value-of select="."/></option>
       </xsl:for-each>
       </select>
      </td>
     </tr>
     <tr class="rowodd">
      <td class="label">
       <xsl:value-of select="/cp/strings/file_properties_group_id"/>
      </td>
      <td class="contentwidth">
       <xsl:variable name="selectedGroup" select="/cp/vsap/vsap[@type='files:chown']/group"/>
       <select name="lstGroup"><xsl:if test="$rw='false'"><xsl:attribute name="disabled"/></xsl:if>
       <xsl:for-each select="/cp/vsap/vsap[@type='files:chown']/ownership_options/groupnames/group">
        <xsl:sort select="."/>
        <option value="{.}"><xsl:if test=".=$selectedGroup or .=/cp/form/selectedGroup"><xsl:attribute name="selected"/></xsl:if><xsl:value-of select="."/></option>
       </xsl:for-each>
       </select>
      </td>
     </tr>
     <xsl:if test="/cp/vsap/vsap[@type='files:chown']/recurse_option_valid = 'yes'">
      <tr class="roweven">
       <td class="label">
        <xsl:value-of select="/cp/strings/file_command_options"/>
       </td>
       <td class="contentwidth">
        <input type="checkbox" id="recurse" name="recurse" value="1">
          <xsl:if test="$rw='false'">
            <xsl:attribute name="disabled"/>
          </xsl:if>
        </input>
        <label for="recurse">
          <xsl:value-of select="/cp/strings/file_command_recurse"/>
        </label>
       </td>
      </tr>
     </xsl:if>

     <tr class="controlrow">
      <td colspan="2">
       <input class="floatright" type="button" name="cmd_cancel" value="{/cp/strings/file_btn_cancel}" onClick="doSubmit('_cancel')"/>
       <input class="floatright" type="submit" name="ok" value="{/cp/strings/file_btn_ok}" onClick="actionType.value='_owners'" ><xsl:if test="$rw='false'"><xsl:attribute name="disabled"/></xsl:if></input>
      </td>
     </tr>

    </table>

</xsl:template>
</xsl:stylesheet>
