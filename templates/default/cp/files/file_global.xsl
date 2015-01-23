<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" xmlns:exslt="http://exslt.org/common">
  
 <xsl:template name="hiddenFields"> 
  <xsl:param name="actionType"/>
  <xsl:param name="currentDir" select="/cp/form/currentDir"/>
  <xsl:param name="currentUser" select="/cp/form/currentUser"/>
  <xsl:param name="currentItem" select="/cp/form/currentItem"/>
  <xsl:param name="refPage" select="/cp/form/refPage"/>
  <xsl:param name="sortBy" select="/cp/form/sortBy"/>
  <xsl:param name="sortType" select="/cp/form/sortType"/>
  <xsl:param name="showHidden" select="/cp/form/showHidden"/>
  <xsl:param name="senderData" select="/cp/form/senderData"/>

  <script src="{$base_url}/cp/files/files.js" language="javascript"/>
  <input type="hidden" name="actionType" value="{$actionType}"/>
  <input type="hidden" name="currentDir" value="{$currentDir}"/>
  <input type="hidden" name="originalDir" value="{$currentDir}"/>
  <input type="hidden" name="refPage" value="{$refPage}"/>
  <input type="hidden" name="currentUser" value="{$currentUser}"/>
  <input type="hidden" name="originalCurrentUser" value="{$currentUser}"/>
  <input type="hidden" name="sortBy" value="{$sortBy}"/>
  <input type="hidden" name="sortType" value="{$sortType}"/>
  <input type="hidden" name="showHidden" value="{$showHidden}"/>
  <input type="hidden" name="currentItem" value="{$currentItem}"/>
  <input type="hidden" name="senderData" value="{$senderData}"/>
 </xsl:template>

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
   <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='error' and @caller='files:list']/code = '101'"><xsl:value-of select="/cp/form/originalCurrentUser"/></xsl:when>
    <xsl:when test="string(/cp/form/currentUser)"><xsl:value-of select="/cp/form/currentUser"/></xsl:when>
    <xsl:otherwise><xsl:value-of select="/cp/vsap/vsap[@type='auth']/username"/></xsl:otherwise>
   </xsl:choose>
 </xsl:variable>

 <xsl:template name="display_date">
  <xsl:param name="date"/>

  <xsl:variable name="format_date">
   <xsl:call-template name="format-date">
    <xsl:with-param name="date" select="$date"/>
    <xsl:with-param name="type">short</xsl:with-param>
   </xsl:call-template>
  </xsl:variable>
  <xsl:variable name="format_time">
   <xsl:call-template name="format-time">
    <xsl:with-param name="date" select="$date"/>
    <xsl:with-param name="type">short</xsl:with-param>
   </xsl:call-template>
  </xsl:variable>

  <xsl:choose>
   <xsl:when test="/cp/vsap/vsap[@type='user:prefs:load']/user_preferences/dt_order='date'">
    <xsl:value-of select="concat($format_date,' ',$format_time)" />
   </xsl:when>
   <xsl:otherwise>
    <xsl:value-of select="concat($format_time,' ',$format_date)" />
   </xsl:otherwise>
  </xsl:choose>
 </xsl:template>

 <xsl:template name="path_list">
  <xsl:param name="path"/>
  <xsl:param name="escaped_path"/>
  <xsl:param name="parent_path"/>
  <xsl:param name="escaped_parent_path"/>
  /
  <xsl:choose>
   <xsl:when test="contains($path, '/')">
    <a href="#" onClick="doSubmit('listFiles','{$escaped_parent_path}/{substring-before($escaped_path , '/')}')">
     <xsl:value-of select="substring-before($path , '/')"/>
    </a>
    <xsl:call-template name="path_list">
     <xsl:with-param name="path" select="substring-after($path , '/')"/>
     <xsl:with-param name="escaped_path" select="substring-after($escaped_path , '/')"/>
     <xsl:with-param name="parent_path">
      <xsl:value-of select="$parent_path"/>/<xsl:value-of select="substring-before($path ,  '/')"/>
     </xsl:with-param>
     <xsl:with-param name="escaped_parent_path">
      <xsl:value-of select="$escaped_parent_path"/>/<xsl:value-of select="substring-before($escaped_path ,  '/')"/>
     </xsl:with-param>
    </xsl:call-template>
   </xsl:when>
   <xsl:otherwise>
    <xsl:value-of select="$path"/>
   </xsl:otherwise>
  </xsl:choose>
 </xsl:template>

 <xsl:template name="permissions">
  <xsl:param name="attrib">---------</xsl:param>
  <xsl:param name="attribOct"/>
  <xsl:param name="url"/>

  <xsl:choose>
   <xsl:when test="$userType='sa'">
    <xsl:choose>
      <xsl:when test="$url=''">
        <xsl:value-of select="substring($attrib,1,3)"/> | 
        <xsl:value-of select="substring($attrib,4,3)"/> | 
        <xsl:value-of select="substring($attrib,7,3)"/>
        &#160;&#160;
        (<xsl:value-of select="$attribOct"/>)
      </xsl:when>
      <xsl:otherwise>
       <a href="#" onClick="{$url}">
        <xsl:value-of select="substring($attrib,1,3)"/> | 
        <xsl:value-of select="substring($attrib,4,3)"/> | 
        <xsl:value-of select="substring($attrib,7,3)"/>
       </a>&#160;&#160;
       <a href="#" onClick="{$url}">
        (<xsl:value-of select="$attribOct"/>)
       </a>
      </xsl:otherwise>
    </xsl:choose>
   </xsl:when>
   <xsl:otherwise>
    <xsl:value-of select="/cp/strings/file_properties_owner"/>&#160;
    <xsl:call-template name="permissionsSet">
     <xsl:with-param name="attrib" select="substring($attrib,1,3)"/>
     <xsl:with-param name="url" select="$url"/>
    </xsl:call-template><br/>
    <xsl:value-of select="/cp/strings/file_properties_group"/>&#160;
    <xsl:call-template name="permissionsSet">
     <xsl:with-param name="attrib" select="substring($attrib,4,3)"/>
     <xsl:with-param name="url" select="$url"/>
    </xsl:call-template><br/>
    <xsl:value-of select="/cp/strings/file_properties_world"/>&#160;
    <xsl:call-template name="permissionsSet">
     <xsl:with-param name="attrib" select="substring($attrib,7,3)"/>
     <xsl:with-param name="url" select="$url"/>
    </xsl:call-template> 
   </xsl:otherwise>
  </xsl:choose>
 </xsl:template>

 <xsl:template name="permissionsSet">
  <xsl:param name="attrib"/>
  <xsl:param name="url"/>

  <xsl:variable name="attribDesc">
   <xsl:choose>
    <xsl:when test="$attrib='---'"><xsl:value-of select="/cp/strings/file_properties_000"/></xsl:when>
    <xsl:when test="$attrib='--x'"><xsl:value-of select="/cp/strings/file_properties_00x"/></xsl:when>
    <xsl:when test="$attrib='--s'"><xsl:value-of select="/cp/strings/file_properties_00x"/></xsl:when>
    <xsl:when test="$attrib='-w-'"><xsl:value-of select="/cp/strings/file_properties_0w0"/></xsl:when>
    <xsl:when test="$attrib='-wx'"><xsl:value-of select="/cp/strings/file_properties_0wx"/></xsl:when>
    <xsl:when test="$attrib='-ws'"><xsl:value-of select="/cp/strings/file_properties_0wx"/></xsl:when>
    <xsl:when test="$attrib='r--'"><xsl:value-of select="/cp/strings/file_properties_r00"/></xsl:when>
    <xsl:when test="$attrib='r-x'"><xsl:value-of select="/cp/strings/file_properties_r0x"/></xsl:when>
    <xsl:when test="$attrib='r-s'"><xsl:value-of select="/cp/strings/file_properties_r0x"/></xsl:when>
    <xsl:when test="$attrib='rw-'"><xsl:value-of select="/cp/strings/file_properties_rw0"/></xsl:when>
    <xsl:when test="$attrib='rwx'"><xsl:value-of select="/cp/strings/file_properties_rwx"/></xsl:when>
    <xsl:when test="$attrib='rws'"><xsl:value-of select="/cp/strings/file_properties_rwx"/></xsl:when>
   </xsl:choose>
  </xsl:variable>
 
  <xsl:choose>
   <xsl:when test="$url=''"><xsl:value-of select="$attribDesc"/></xsl:when>
   <xsl:otherwise><a href="#" onClick="{$url}"><xsl:value-of select="$attribDesc"/></a></xsl:otherwise>
  </xsl:choose>
 </xsl:template>  





 <xsl:template name="dir_properties">
  <xsl:variable name="currentDirName" select="/cp/vsap/vsap[@type='files:list']/path"/>
  <xsl:variable name="ownedByValidUser">
   <xsl:if test="$userType = 'da'">
    <xsl:for-each select="/cp/vsap/vsap[@type='user:list:eu']/user">
     <xsl:if test=". = /cp/vsap/vsap[@type='files:list']/owner">yes</xsl:if>
    </xsl:for-each>
   </xsl:if>
  </xsl:variable>

  <table class="formview" border="0" cellspacing="0" cellpadding="0">
   <tr class="instructionrow">
    <td colspan="2">
     <xsl:choose>
      <xsl:when test="$userType = 'sa'">
       <input class="floatright" type="button" name="openLocation" value="{/cp/strings/file_list_btn_go}" onClick="doSubmit('jump')"/>
       <input class="floatright" size="40" name="locationJump" value="{$currentDir}"/>
       <xsl:value-of select="/cp/strings/file_list_title_serveradmin"/>
      </xsl:when>
      <xsl:when test="$userType = 'da'">
       <xsl:choose>

        <xsl:when test="$numEndUsers > 1">
         <xsl:value-of select="/cp/strings/file_list_title_domainadmin"/>&#160;
         <select name="lstcurrentUser" size="1" onChange="this.form.locationJump.value='/'">
          <xsl:for-each select="/cp/vsap/vsap[@type='user:list:eu']/user">
           <option value="{.}">
            <xsl:if test=". = $currentUser">
             <xsl:attribute name="selected">true</xsl:attribute>
            </xsl:if><xsl:value-of select="." />
           </option>
          </xsl:for-each>
         </select>&#160;
         <input size="40" name="locationJump" value="{$currentDir}"/>
         <input type="button" name="openLocation" value="{/cp/strings/file_list_btn_go}" onClick="doSubmit('jump',null,document.forms[0].lstcurrentUser.value)"/>
        </xsl:when>

        <xsl:otherwise>
         <input class="floatright" type="button" name="openLocation" value="{/cp/strings/file_list_btn_go}" onClick="doSubmit('jump')"/>
         <input class="floatright" size="40" name="locationJump" value="{$currentDir}"/>
         <xsl:value-of select="/cp/strings/file_list_title_enduser"/>
        </xsl:otherwise>
       </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
       <input class="floatright" type="button" name="openLocation" value="{/cp/strings/file_list_btn_go}" onClick="doSubmit('jump')"/>
       <input class="floatright" size="40" name="locationJump" value="{$currentDir}"/>
       <xsl:value-of select="/cp/strings/file_list_title_enduser"/>
      </xsl:otherwise>
     </xsl:choose>
     <!--input type="hidden" name="originalPath" value="{$currentDir}"/-->
    </td>
   </tr>
    
   <xsl:choose>
    <xsl:when test="$parentDir != ''">
     <tr class="title">
      <td colspan="2">
       <xsl:value-of select="/cp/strings/file_properties_directory"/>&#160;<xsl:value-of select="translate(substring-after($currentDir, $parentDir), '/', '')"/>
      </td>
     </tr>
     <tr class="roweven">
      <td class="label">
       <xsl:value-of select="/cp/strings/file_properties_name_path"/>
      </td>
      <td class="contentwidth">
       <xsl:if test="$userType = 'da'">
        <xsl:if test="$currentUser != /cp/vsap/vsap[@type='auth']/username">
         <xsl:value-of select="$currentUser"/>:
        </xsl:if>
       </xsl:if>
       <a href="#" onClick="doSubmit('listFiles','/')"><xsl:value-of select="/cp/strings/file_list_all_files"/></a>
       <xsl:call-template name="path_list">
        <xsl:with-param name="path" select="substring($currentDir, 2)"/>
        <xsl:with-param name="escaped_path" select="substring($currentDirEscaped, 2)"/>
        <xsl:with-param name="parent_path" select="''"/>
        <xsl:with-param name="escaped_parent_path" select="''"/>
       </xsl:call-template>
      </td>
     </tr>
    </xsl:when>
    <xsl:otherwise>
     <tr class="title">
      <td colspan="2">
       <xsl:value-of select="/cp/strings/file_properties_directory"/>&#160;<xsl:value-of select="/cp/strings/file_list_all_files"/>
      </td>
     </tr>
     <tr class="roweven">
      <td class="label">
       <xsl:value-of select="/cp/strings/file_properties_name_path"/>
      </td>
      <td class="contentwidth">
       <xsl:if test="$userType = 'da'">
        <xsl:if test="$currentUser != /cp/vsap/vsap[@type='auth']/username">
         <xsl:value-of select="$currentUser"/>:
        </xsl:if>
       </xsl:if>
       <xsl:value-of select="/cp/strings/file_list_all_files"/>
      </td>
     </tr>
    </xsl:otherwise>
   </xsl:choose>
    <tr class="rowodd">
    <td class="label">
     <xsl:value-of select="/cp/strings/file_properties_contents"/>
    </td>
    <td class="contentwidth">
     <xsl:variable name="fileCount">
      <xsl:value-of select="count(/cp/vsap/vsap[@type='files:list']/file[cp_category='folder' and name != '' and name != '..' and name != '.'])"/>
     </xsl:variable>
     <xsl:variable name="dirCount">
      <xsl:value-of select="count(/cp/vsap/vsap[@type='files:list']/file[type != 'dir' and name != ''])"/>
     </xsl:variable>
     <xsl:variable name="linkCount">
      <xsl:value-of select="count(/cp/vsap/vsap[@type='files:list']/file[(type = 'dirlink' or type = 'symlink') and name != ''])"/>
     </xsl:variable>
     <xsl:variable name="hiddenCount">
      <xsl:value-of select="count(/cp/vsap/vsap[@type='files:list']/file[starts-with(name, '.') and name != '.' and name != '..'])"/>
     </xsl:variable>
     <xsl:value-of select="$fileCount"/>&#160;<xsl:value-of select="/cp/strings/file_properties_directories"/>, 
     <xsl:value-of select="$dirCount"/>&#160;<xsl:value-of select="/cp/strings/file_properties_files"/>, 
       (<xsl:value-of select="$linkCount"/>&#160;<xsl:value-of select="/cp/strings/file_properties_shortcuts"/>), 
     <xsl:choose>
      <xsl:when test="$hiddenCount = 0">
       0&#160;<xsl:value-of select="/cp/strings/file_properties_hidden_files"/>
      </xsl:when>
      <xsl:otherwise>
       <a href="#" onClick="doSubmit('listFiles',null,null,null,null,null,null,'{$showHidden='false'}')">
        <xsl:value-of select="$hiddenCount"/>&#160;<xsl:value-of select="/cp/strings/file_properties_hidden_files"/>
       </a>
      </xsl:otherwise>
     </xsl:choose>
    </td>
   </tr>
   <tr class="roweven">
    <td class="label">
     <xsl:value-of select="/cp/strings/file_properties_last_modified"/>
    </td>
    <td class="contentwidth">
     <xsl:call-template name="display_date">
      <xsl:with-param name="date" select="/cp/vsap/vsap[@type='files:list']/date"/>
     </xsl:call-template>
    </td>
   </tr>
   <tr class="rowodd">
    <td class="label">
     <xsl:value-of select="/cp/strings/file_properties_actions"/>
    </td>
    <td class="contentwidth">
      <xsl:variable name="parentDir"><xsl:value-of select="/cp/vsap/vsap[@type='files:list']/parent_dir"/></xsl:variable>
     <xsl:choose>
      <xsl:when test="$currentDir != '/'">
       <a href="#" onClick="uncheckFiles(document.forms[0].file); if (confirm('{cp:js-escape(/cp/strings/file_verify_dir_delete)}')) doSubmit('delete','{$parentDirEscaped}',null,'{$currentDirEscaped}')"><xsl:value-of select="/cp/strings/file_action_delete"/></a> |              
       <a href="#" onClick="uncheckFiles(document.forms[0].file); doSubmit('compress','{$parentDirEscaped}',null,'{$currentDirEscaped}')"><xsl:value-of select="/cp/strings/file_action_compress"/></a> | 
       <a href="#" onClick="uncheckFiles(document.forms[0].file); doSubmit('copy',null,null,'{$currentDirEscaped}')"><xsl:value-of select="/cp/strings/file_action_copy"/></a> | 
       <a href="#" onClick="uncheckFiles(document.forms[0].file); doSubmit('move','{$parentDirEscaped}',null,'{$currentDirEscaped}')"><xsl:value-of select="/cp/strings/file_action_move"/></a> | 
       <a href="#" onClick="doSubmit('rename','{$parentDirEscaped}',null,'{$currentDirEscaped}')"><xsl:value-of select="/cp/strings/file_action_rename"/></a>
      </xsl:when>
       <xsl:otherwise>
       <a href="#" onClick="uncheckFiles(document.forms[0].file); doSubmit('compress','{$parentDirEscaped}',null,'{$currentDirEscaped}')"><xsl:value-of select="/cp/strings/file_action_compress"/></a> | 
       <a href="#" onClick="uncheckFiles(document.forms[0].file); doSubmit('copy','{$parentDirEscaped}',null,'{$currentDirEscaped}')"><xsl:value-of select="/cp/strings/file_action_copy"/></a>
      </xsl:otherwise>
     </xsl:choose>
    </td>
   </tr>
    <tr class="roweven">
    <td class="label">
     <xsl:value-of select="/cp/strings/file_properties_permissions"/>
    </td>
    <td class="contentwidth">
     <!-- show dir  permissions -->
     <xsl:call-template name="permissions">
      <xsl:with-param name="attrib" select="/cp/vsap/vsap[@type='files:list']/symbolic_mode"/>
      <xsl:with-param name="attribOct" select="/cp/vsap/vsap[@type='files:list']/octal_mode"/>
      <xsl:with-param name="url">
       <xsl:if test="not(($currentDir = '/') or ($userType = 'da' and $ownedByValidUser != 'yes') or ($userType = 'eu' and /cp/vsap/vsap[@type='files:list']/owner != /cp/vsap/vsap[@type='auth']/username))">
        javascript:doSubmit('permissions',null,null,'<xsl:value-of select="$currentDirEscaped"/>')</xsl:if>
      </xsl:with-param>
     </xsl:call-template>
    </td>
   </tr>
  
   <tr class="rowodd">
    <td class="label">
     <xsl:value-of select="/cp/strings/file_properties_ownership"/>
    </td>
    <td class="contentwidth">
     <xsl:choose>
      <xsl:when test="($userType = 'da' and $ownedByValidUser != 'yes') or ($currentDir = '/' or $userType = 'eu')">
       <!-- hide link: domain admin not allowed to chown on files not owned by self or enduser, chmod on /. not allowed, endusers not allowed to chown -->
       <xsl:value-of select="/cp/strings/file_properties_user_id"/>&#160;<xsl:value-of select="/cp/vsap/vsap[@type='files:list']/owner"/><br/>
       <xsl:value-of select="/cp/strings/file_properties_group_id"/>&#160;<xsl:value-of select="/cp/vsap/vsap[@type='files:list']/group"/>
      </xsl:when>
      <xsl:otherwise>
       <xsl:value-of select="/cp/strings/file_properties_user_id"/>&#160;<a href="#" onClick="doSubmit('owners',null,null,'{$currentDirEscaped}')">
       <xsl:value-of select="/cp/vsap/vsap[@type='files:list']/owner"/></a>
       <br/>
       <xsl:value-of select="/cp/strings/file_properties_group_id"/>&#160;<a href="#" onClick="doSubmit('owners',null,null,'{$currentDirEscaped}')">
       <xsl:value-of select="/cp/vsap/vsap[@type='files:list']/group"/></a>
      </xsl:otherwise>
     </xsl:choose>
    </td>
   </tr>
  </table>
 </xsl:template>





 <xsl:template name="file_properties">
  <xsl:variable name="currentFileName" select="/cp/vsap/vsap[@type='files:properties']/path"/>
  <xsl:variable name="currentFileNameEncoded" select="/cp/vsap/vsap[@type='files:properties']/url_encoded_name"/>
  <xsl:variable name="currentFilePathEncoded" select="/cp/vsap/vsap[@type='files:properties']/url_encoded_path"/>
  <xsl:variable name="currentFilePathEscaped" select="/cp/vsap/vsap[@type='files:properties']/url_escaped_path"/>
  <xsl:variable name="ownedByValidUser">
   <xsl:if test="$userType = 'da'">
    <xsl:for-each select="/cp/vsap/vsap[@type='user:list:eu']/user">
     <xsl:if test=". = /cp/vsap/vsap[@type='files:properties']/owner">yes</xsl:if>
    </xsl:for-each>
   </xsl:if>
  </xsl:variable>

  <table class="formview" border="0" cellspacing="0" cellpadding="0">
   <tr class="title">
    <td colspan="2">
     <xsl:value-of select="/cp/strings/file_properties_file"/>&#160;<xsl:value-of select="/cp/vsap/vsap[@type='files:properties']/name"/>
    </td>
   </tr>
   <tr class="roweven">
    <td class="label">
     <xsl:value-of select="/cp/strings/file_properties_name_path"/>
    </td>
    <td class="contentwidth">
     <xsl:if test="$userType = 'da'">
      <xsl:if test="$currentUser != /cp/vsap/vsap[@type='auth']/username">
       <xsl:value-of select="$currentUser"/>:
      </xsl:if>
     </xsl:if>
     <a href="#" onClick="doSubmit('listFiles','/')"><xsl:value-of select="/cp/strings/file_list_all_files"/></a>
     <xsl:call-template name="path_list">
      <xsl:with-param name="path" select="substring($currentFileName, 2)"/>
      <xsl:with-param name="escaped_path" select="substring($currentFilePathEscaped, 2)"/>
      <xsl:with-param name="parent_path" select="''"/>
      <xsl:with-param name="escaped_parent_path" select="''"/>
     </xsl:call-template>
     <xsl:if test="/cp/vsap/vsap[@type='files:properties']/documentroot">
       <xsl:variable name="domainName" select="/cp/vsap/vsap[@type='files:properties']/documentroot_domain"/>
       <xsl:variable name="relativePath" select="/cp/vsap/vsap[@type='files:properties']/documentroot_relativepath"/>
       <a target="_blank" onClick="window.location.href='http://{$domainName}{$relativePath}{$currentFileNameEncoded}'; return false" href="http://{$domainName}{$relativePath}{$currentFileNameEncoded}"><img src="{/cp/strings/img_hypertext_link}" border="0" align="right" /></a>
     </xsl:if>
    </td>
   </tr>
   <tr class="roweven">
    <td class="label">
     <xsl:value-of select="/cp/strings/file_properties_type"/>
    </td>
    <td class="contentwidth">
     <xsl:choose>
      <xsl:when test="/cp/vsap/vsap[@type='files:properties']/cp_category = 'text'">
       <xsl:value-of select="/cp/strings/file_properties_type_text"/>
      </xsl:when>
      <xsl:when test="/cp/vsap/vsap[@type='files:properties']/cp_category = 'image'">
       <xsl:value-of select="/cp/strings/file_properties_type_image"/>
      </xsl:when>
      <xsl:when test="/cp/vsap/vsap[@type='files:properties']/cp_category = 'media'">
       <xsl:value-of select="/cp/strings/file_properties_type_media"/>
      </xsl:when>
      <xsl:when test="/cp/vsap/vsap[@type='files:properties']/cp_category = 'compressed'">
       <xsl:value-of select="/cp/strings/file_properties_type_compressed"/>
      </xsl:when>
      <xsl:when test="/cp/vsap/vsap[@type='files:properties']/cp_category = 'binary'">
       <xsl:value-of select="/cp/strings/file_properties_type_binary"/>
      </xsl:when>
      <xsl:otherwise>
       <xsl:value-of select="/cp/strings/file_properties_type_other"/>
      </xsl:otherwise>
     </xsl:choose>
    </td>
   </tr>
   <tr class="rowodd">
    <td class="label">
     <xsl:value-of select="/cp/strings/file_properties_size"/>
    </td>
    <td class="contentwidth">
     <xsl:call-template name="format_bytes">
      <xsl:with-param name="bytes" select="/cp/vsap/vsap[@type='files:properties']/size"/>
     </xsl:call-template>
    </td>
   </tr>
   <tr class="rowodd">
    <td class="label">
     <xsl:value-of select="/cp/strings/file_properties_last_modified"/>
    </td>
    <td class="contentwidth">
     <xsl:call-template name="display_date">
      <xsl:with-param name="date" select="/cp/vsap/vsap[@type='files:properties']/date"/>
     </xsl:call-template>
    </td>
   </tr>
   <tr class="roweven">
    <td class="label">
     <xsl:value-of select="/cp/strings/file_properties_actions"/>
    </td>
    <td class="contentwidth">
     <a href="#" onClick="if (confirm('{cp:js-escape(/cp/strings/file_verify_file_delete)}')) doSubmit('delete',null,null,'{$currentFilePathEscaped}')"><xsl:value-of select="/cp/strings/file_action_delete"/></a> |
     <xsl:choose>
      <xsl:when test="/cp/vsap/vsap[@type='files:properties']/archive_contents">
       <a href="#" onClick="doSubmit('uncompress',null,null,'{$currentFilePathEscaped}','properties.xsl',null,null,null,'/')"><xsl:value-of select="/cp/strings/file_action_uncompress"/></a> | 
      </xsl:when>
      <xsl:otherwise>
       <a href="#" onClick="doSubmit('compress',null,null,'{$currentFilePathEscaped}','properties.xsl')"><xsl:value-of select="/cp/strings/file_action_compress"/></a> | 
      </xsl:otherwise>
     </xsl:choose>
     <a href="#" onClick="doSubmit('copy',null,null,'{$currentFilePathEscaped}','properties.xsl')"><xsl:value-of select="/cp/strings/file_action_copy"/></a> | 
     <a href="#" onClick="doSubmit('move',null,null,'{$currentFilePathEscaped}','properties.xsl')"><xsl:value-of select="/cp/strings/file_action_move"/></a> | 
     <a href="#" onClick="doSubmit('rename',null,null,'{$currentFilePathEscaped}','properties.xsl')"><xsl:value-of select="/cp/strings/file_action_rename"/></a> |  <!-- &amp;targetPath={/cp/form/currentPath}&amp;currentPath={/cp/form/currentPath -->
     <a target="_blank" onClick="window.location.href='properties.xsl/VSAPDOWNLOAD/?currentItem={$currentFilePathEncoded}&amp;currentUser={$currentUser}&amp;format=print&amp;download=yes'; return false" href="properties.xsl/VSAPDOWNLOAD/?currentItem={$currentFilePathEncoded}&amp;currentUser={$currentUser}&amp;format=print&amp;download=yes"><xsl:value-of select="/cp/strings/file_action_print_view"/></a> | 
     <a onClick="window.location.href='properties.xsl/VSAPDOWNLOAD/?currentItem={$currentFilePathEncoded}&amp;currentUser={$currentUser}&amp;download=yes'; return false" href="properties.xsl/VSAPDOWNLOAD/?currentItem={$currentFilePathEncoded}&amp;currentUser={$currentUser}&amp;download=yes"><xsl:value-of select="/cp/strings/file_action_download"/></a>
    </td>
   </tr>
   <tr class="roweven">
    <td class="label">
     <xsl:value-of select="/cp/strings/file_properties_permissions"/>
    </td>
    <td class="contentwidth">
     <!-- show file permissions -->
     <xsl:call-template name="permissions">
      <xsl:with-param name="attrib" select="/cp/vsap/vsap[@type='files:properties']/symbolic_mode"/>
      <xsl:with-param name="attribOct" select="/cp/vsap/vsap[@type='files:properties']/octal_mode"/>
      <xsl:with-param name="url">
       <xsl:if test="not(($userType = 'da' and $ownedByValidUser != 'yes') or ($userType = 'eu' and /cp/vsap/vsap[@type='files:properties']/owner != /cp/vsap/vsap[@type='auth']/username))">
        javascript:doSubmit('permissions',null,null,'<xsl:value-of select="$currentFilePathEscaped"/>','properties.xsl')</xsl:if>
      </xsl:with-param>
     </xsl:call-template>
    </td>
   </tr>
   <tr class="rowodd">
    <td class="label">
     <xsl:value-of select="/cp/strings/file_properties_ownership"/>
    </td>
    <td class="contentwidth">
     <xsl:choose>
      <xsl:when test="($userType = 'da' and $ownedByValidUser != 'yes') or ($userType = 'eu')">
       <xsl:value-of select="/cp/strings/file_properties_user_id"/>&#160;<xsl:value-of select="/cp/vsap/vsap[@type='files:properties']/owner"/><br/>
       <xsl:value-of select="/cp/strings/file_properties_group_id"/>&#160;<xsl:value-of select="/cp/vsap/vsap[@type='files:properties']/group"/>
      </xsl:when>
      <xsl:otherwise>
       <xsl:value-of select="/cp/strings/file_properties_user_id"/>&#160;
       <a href="#" onClick="doSubmit('owners',null,null,'{$currentFilePathEscaped}','properties.xsl')">
        <xsl:value-of select="/cp/vsap/vsap[@type='files:properties']/owner"/>
       </a>
       <br/>
       <xsl:value-of select="/cp/strings/file_properties_group_id"/>&#160;
        <a href="#" onClick="doSubmit('owners',null,null,'{$currentFilePathEscaped}','properties.xsl')">
         <xsl:value-of select="/cp/vsap/vsap[@type='files:properties']/group"/>
        </a>
       </xsl:otherwise>
      </xsl:choose>
    </td>
   </tr>
  </table>
 </xsl:template>

 <xsl:template name='extract-filename'>
  <xsl:param name='pathName'/>
  <xsl:choose>
   <xsl:when test='contains($pathName, "/")'> 
    <xsl:call-template name='extract-filename'>
     <xsl:with-param name='pathName'
      select='substring-after($pathName, "/")'/>
    </xsl:call-template>
   </xsl:when>
   <xsl:otherwise>
    <xsl:copy-of select='$pathName'/>
   </xsl:otherwise>
  </xsl:choose>
 </xsl:template>

 <xsl:template name='extract-extension'>
  <xsl:param name='fileName'/>
  <xsl:choose>
   <xsl:when test='contains($fileName, ".")'> 
    <xsl:call-template name='extract-extension'>
     <xsl:with-param name='fileName'
      select='substring-after($fileName, ".")'/>
    </xsl:call-template>
   </xsl:when>
   <xsl:otherwise>
    <xsl:copy-of select='$fileName'/>
   </xsl:otherwise>
  </xsl:choose>
 </xsl:template>

</xsl:stylesheet>



