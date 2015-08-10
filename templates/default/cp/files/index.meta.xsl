<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
 <xsl:import href="../../global.meta.xsl"/>
 <xsl:import href="../cp_global.meta.xsl"/>

 <xsl:template match="/">
  <meta>
   <!-- run auth code -->
   <xsl:call-template name="auth">
    <xsl:with-param name="require_fileman">1</xsl:with-param>
    <xsl:with-param name="check_diskspace">0</xsl:with-param>
   </xsl:call-template>

   <xsl:call-template name="cp_global"/>

   <xsl:if test="(/cp/vsap/vsap[@type='auth']/domain_admin and not(/cp/vsap/vsap[@type='auth']/server_admin)) or
                 (/cp/vsap/vsap[@type='auth']/server_admin and /cp/vsap/vsap[@type='auth']/siteprefs/limited-file-manager)">
    <xsl:call-template name="dovsap">
     <xsl:with-param name="vsap">
      <vsap>
       <vsap type="user:list:eu"/>
      </vsap>
     </xsl:with-param>
    </xsl:call-template>
   </xsl:if>

   <!-- get an upload id for this session -->
   <xsl:if test="not(/cp/form/sessionID)">
    <xsl:call-template name="dovsap">
     <xsl:with-param name="vsap">
      <vsap>
       <vsap type="files:upload:init"/>
      </vsap>
     </xsl:with-param>
    </xsl:call-template>
   </xsl:if>

   <xsl:choose>
    <xsl:when test="/cp/form/actionType='listFiles' or /cp/form/actionType='jump' or /cp/form/looping='1'">
     <!-- Do Nothing -->
    </xsl:when>

    <xsl:when test="starts-with(/cp/form/actionType, '_')">
     <!-- Do Nothing -->
    </xsl:when>

    <xsl:when test="/cp/form/actionType='delete'">
     <xsl:call-template name="dovsap">
      <xsl:with-param name="vsap">
       <vsap>
        <vsap type="files:delete">
         <xsl:choose>
          <xsl:when test="/cp/form/file">
           <xsl:for-each select="cp/form/file">
            <path>
             <xsl:value-of select="/cp/form/currentDir"/>
             <xsl:if test="/cp/form/currentDir != '' and /cp/form/currentDir != '/'">/</xsl:if>
             <xsl:value-of select="."/>
            </path>
           </xsl:for-each>
          </xsl:when>
          <xsl:otherwise>
           <path>
            <xsl:value-of select="/cp/form/currentItem"/>
           </path>
          </xsl:otherwise>
         </xsl:choose>
         <user><xsl:value-of select="/cp/form/currentUser"/></user>
        </vsap>
       </vsap>
      </xsl:with-param>
     </xsl:call-template>

     <xsl:call-template name="set_message">
      <xsl:with-param name="name" select="'delete_action'"/>
     </xsl:call-template>
     <xsl:call-template name="set_message">
      <xsl:with-param name="name" select="'success'"/>
      <xsl:with-param name="value" select="count(/cp/vsap/vsap[@type='files:delete']/success/path)"/>
     </xsl:call-template>
     <xsl:call-template name="set_message">
      <xsl:with-param name="name" select="'fail'"/>
      <xsl:with-param name="value" select="count(/cp/vsap/vsap[@type='files:delete']/failure/path)"/>
     </xsl:call-template>
    </xsl:when>

    <xsl:when test="/cp/form/actionType != ''">
     <redirect>
      <path>/cp/files/<xsl:value-of select="/cp/form/actionType"/>.xsl</path>
     </redirect>
    </xsl:when>
   </xsl:choose>

   <xsl:if test="/cp/form/actionType='jump'">
    <xsl:choose>
     <xsl:when test="/cp/form/locationJump='tabasco'">
      <redirect>
       <path>/cp/files/dirspace.xsl</path>
      </redirect>
     </xsl:when>
     <xsl:otherwise>
      <xsl:call-template name="dovsap">
       <xsl:with-param name="vsap">
        <vsap>
         <vsap type="files:properties:type">
          <path><xsl:value-of select="/cp/form/locationJump"/></path>
          <user><xsl:value-of select="/cp/form/currentUser"/></user>
         </vsap>
        </vsap>
       </xsl:with-param>
      </xsl:call-template>
      <xsl:if test="/cp/vsap/vsap[@type='files:properties:type']/type='file'">
       <redirect>
        <path>/cp/files/properties.xsl</path>
       </redirect>
      </xsl:if>
     </xsl:otherwise>
    </xsl:choose>
   </xsl:if>

    <!--xsl:if test="/cp/vsap/vsap[@type='error'][@caller='files:properties:type']">
     <redirect>
      <path>/</path>
     </redirect>
    </xsl:if-->
 
   <xsl:call-template name="dovsap">
    <xsl:with-param name="vsap">
     <vsap>
      <vsap type='user:prefs:load' />
      <vsap type="files:list">
       <xsl:choose>
        <xsl:when test="/cp/form/actionType='jump'">
         <path><xsl:value-of select="/cp/vsap/vsap[@type='files:properties:type']/path"/></path>
        </xsl:when>
        <xsl:otherwise>
         <path><xsl:value-of select="/cp/form/currentDir"/></path>
        </xsl:otherwise>
       </xsl:choose>
       <user><xsl:value-of select="/cp/form/currentUser"/></user>
      </vsap>
     </vsap>
    </xsl:with-param>
   </xsl:call-template>
   <xsl:if test="/cp/vsap/vsap[@type='error' and  @caller='files:list']"><!-- or not(/cp/vsap/vsap[@type='files:list'])"-->

    <xsl:call-template name="set_message">
     <xsl:with-param name="name" select="'list_action'"/>
    </xsl:call-template>

    <xsl:call-template name="set_message">
     <xsl:with-param name="name" select="'code'"/>
     <xsl:with-param name="value" select="/cp/vsap/vsap[@type='error'][@caller='files:list']/code"/>
    </xsl:call-template>

     <xsl:call-template name="dovsap">
      <xsl:with-param name="force_call">yes</xsl:with-param>
      <xsl:with-param name="vsap">
       <vsap>
        <vsap type="files:list">
         <path><xsl:value-of select="/cp/form/originalDir"/></path>
         <user><xsl:value-of select="/cp/form/originalCurrentUser"/></user>
        </vsap>
       </vsap>
      </xsl:with-param>     
     </xsl:call-template>
    </xsl:if>

    <xsl:choose>
     <xsl:when test="(/cp/form/actionType='_copy')">
        <xsl:call-template name="set_message">
         <xsl:with-param name="name" select="'copy_action'"/>
        </xsl:call-template>
        <xsl:call-template name="set_message">
          <xsl:with-param name="name" select="'success'"/>
          <xsl:with-param name="value" select="count(/cp/vsap/vsap[@type='files:copy']/success/path)"/>
        </xsl:call-template>
        <xsl:call-template name="set_message">
          <xsl:with-param name="name" select="'fail'"/>
          <xsl:with-param name="value" select="count(/cp/vsap/vsap[@type='files:copy']/failure/path)"/>
        </xsl:call-template>
        <xsl:variable name="failcode">
           <xsl:value-of select="/cp/vsap/vsap[@type='files:copy']/failure/path[1]/code"/>
        </xsl:variable>
        <xsl:variable name="failtype">
          <xsl:choose>
            <xsl:when test="$failcode = 100">not_authorized</xsl:when>
            <xsl:when test="$failcode = 101">invalid_path</xsl:when>
            <xsl:when test="$failcode = 102">invalid_path</xsl:when>
            <xsl:when test="$failcode = 103">copy_failed</xsl:when>
            <xsl:when test="$failcode = 104">quota_exceeded</xsl:when>
            <xsl:when test="$failcode = 105">invalid_user</xsl:when>
            <xsl:when test="$failcode = 106">invalid_name</xsl:when>
            <xsl:when test="$failcode = 107">invalid_target</xsl:when>
            <xsl:when test="$failcode = 108">target_exists</xsl:when>
            <xsl:when test="$failcode = 109">copy_loop</xsl:when>
            <xsl:when test="$failcode = 110">mkdir_failed</xsl:when>
          </xsl:choose>
        </xsl:variable>
        <xsl:call-template name="set_message">
          <xsl:with-param name="name" select="'failcode'"/>
          <xsl:with-param name="value" select="$failtype"/>
        </xsl:call-template>
      </xsl:when>

      <xsl:when test="(/cp/form/actionType='_move')">
        <xsl:call-template name="set_message">
          <xsl:with-param name="name" select="'move_action'"/>
        </xsl:call-template>
        <xsl:call-template name="set_message">
          <xsl:with-param name="name" select="'success'"/>
          <xsl:with-param name="value" select="count(/cp/vsap/vsap[@type='files:move']/success/path)"/>
        </xsl:call-template>
        <xsl:call-template name="set_message">
          <xsl:with-param name="name" select="'fail'"/>
          <xsl:with-param name="value" select="count(/cp/vsap/vsap[@type='files:move']/failure/path)"/>
        </xsl:call-template>
        <xsl:variable name="failcode">
           <xsl:value-of select="/cp/vsap/vsap[@type='files:move']/failure/path[1]/code"/>
        </xsl:variable>
        <xsl:variable name="failtype">
          <xsl:choose>
            <xsl:when test="$failcode = 100">not_authorized</xsl:when>
            <xsl:when test="$failcode = 101">invalid_path</xsl:when>
            <xsl:when test="$failcode = 102">invalid_path</xsl:when>
            <xsl:when test="$failcode = 103">move_failed</xsl:when>
            <xsl:when test="$failcode = 104">quota_exceeded</xsl:when>
            <xsl:when test="$failcode = 105">invalid_user</xsl:when>
            <xsl:when test="$failcode = 106">invalid_target</xsl:when>
            <xsl:when test="$failcode = 107">target_exists</xsl:when>
            <xsl:when test="$failcode = 108">move_loop</xsl:when>
            <xsl:when test="$failcode = 109">mkdir_failed</xsl:when>
          </xsl:choose>
        </xsl:variable>
        <xsl:call-template name="set_message">
          <xsl:with-param name="name" select="'failcode'"/>
          <xsl:with-param name="value" select="$failtype"/>
        </xsl:call-template>
      </xsl:when>

      <xsl:when test="(/cp/form/actionType='_link')">
        <xsl:call-template name="set_message">
          <xsl:with-param name="name" select="'link_action'"/>
        </xsl:call-template>

        <xsl:call-template name="set_message">
          <xsl:with-param name="name" select="'success'"/>
          <xsl:with-param name="value">
            <xsl:choose>
              <xsl:when test="/cp/vsap/vsap[@type='files:link']/path">yes</xsl:when>
              <xsl:otherwise>no</xsl:otherwise>
            </xsl:choose>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>

      <xsl:when test="(/cp/form/actionType='_compress')">
        <xsl:call-template name="set_message">
          <xsl:with-param name="name" select="'compress_action'"/>
        </xsl:call-template>

        <xsl:call-template name="set_message">
          <xsl:with-param name="name" select="'success'"/>
          <xsl:with-param name="value">
            <xsl:choose>
              <xsl:when test="/cp/vsap/vsap[@type='files:compress']/target">yes</xsl:when>
              <xsl:otherwise>no</xsl:otherwise>
            </xsl:choose>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>

      <xsl:when test="(/cp/form/actionType='_uncompress')">
        <xsl:call-template name="set_message">
          <xsl:with-param name="name" select="'uncompress_action'"/>
        </xsl:call-template>

        <xsl:call-template name="set_message">
          <xsl:with-param name="name" select="'success'"/>
          <xsl:with-param name="value">
            <xsl:choose>
              <xsl:when test="/cp/vsap/vsap[@type='files:uncompress']/target">yes</xsl:when>
              <xsl:otherwise>no</xsl:otherwise>
            </xsl:choose>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>

      <xsl:when test="(/cp/form/actionType='_rename')">
        <xsl:call-template name="set_message">
          <xsl:with-param name="name" select="'rename_action'"/>
        </xsl:call-template>

        <xsl:call-template name="set_message">
          <xsl:with-param name="name" select="'success'"/>
          <xsl:with-param name="value">
            <xsl:choose>
              <xsl:when test="/cp/vsap/vsap[@type='files:rename']/status='ok'">yes</xsl:when>
              <xsl:otherwise>no</xsl:otherwise>
            </xsl:choose>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>

      <xsl:when test="(/cp/form/actionType='_permissions')">
        <xsl:call-template name="set_message">
          <xsl:with-param name="name" select="'permissions_action'"/>
        </xsl:call-template>

        <xsl:call-template name="set_message">
          <xsl:with-param name="name" select="'success'"/>
          <xsl:with-param name="value">
            <xsl:choose>
              <xsl:when test="/cp/vsap/vsap[@type='files:chmod']/path">yes</xsl:when>
              <xsl:otherwise>no</xsl:otherwise>
            </xsl:choose>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>

      <xsl:when test="(/cp/form/actionType='_owners')">
        <xsl:call-template name="set_message">
          <xsl:with-param name="name" select="'owners_action'"/>
        </xsl:call-template>

        <xsl:call-template name="set_message">
          <xsl:with-param name="name" select="'success'"/>
          <xsl:with-param name="value">
            <xsl:choose>
              <xsl:when test="/cp/vsap/vsap[@type='files:chown']/path">yes</xsl:when>
              <xsl:otherwise>no</xsl:otherwise>
            </xsl:choose>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>

      <xsl:when test="(/cp/form/actionType='_addDir')">
        <xsl:call-template name="set_message">
          <xsl:with-param name="name" select="'add_dir_action'"/>
        </xsl:call-template>

        <xsl:call-template name="set_message">
          <xsl:with-param name="name" select="'success'"/>
          <xsl:with-param name="value">
            <xsl:choose>
              <xsl:when test="/cp/vsap/vsap[@type='files:mkdir']/path">yes</xsl:when>
              <xsl:otherwise>no</xsl:otherwise>
            </xsl:choose>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>

      <xsl:when test="(/cp/form/actionType='_addFile')">
        <xsl:call-template name="set_message">
          <xsl:with-param name="name" select="'add_file_action'"/>
        </xsl:call-template>

        <xsl:call-template name="set_message">
          <xsl:with-param name="name" select="'success'"/>
          <xsl:with-param name="value">
            <xsl:choose>
              <xsl:when test="/cp/vsap/vsap[@type='files:create']/path">yes</xsl:when>
              <xsl:otherwise>no</xsl:otherwise>
            </xsl:choose>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>

      <xsl:when test="(/cp/form/actionType='_save')">
        <xsl:call-template name="set_message">
          <xsl:with-param name="name" select="'edit_file_action'"/>
        </xsl:call-template>

        <xsl:call-template name="set_message">
          <xsl:with-param name="name" select="'success'"/>
          <xsl:with-param name="value">
            <xsl:choose>
              <xsl:when test="/cp/vsap/vsap[@type='error']">no</xsl:when>
              <xsl:otherwise>yes</xsl:otherwise>
            </xsl:choose>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>

      <xsl:otherwise>
        <xsl:if test="/cp/vsap/vsap[@type='error' and @caller='files:properties']">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name" select="'general_error'"/>
            <xsl:with-param name="value">file_access</xsl:with-param>
          </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>

      </xsl:choose>

      <xsl:call-template name="dovsap">
        <xsl:with-param name="vsap">
          <vsap>  
            <vsap type="diskspace" />
          </vsap>
        </xsl:with-param>
      </xsl:call-template>

      <showpage/>
    </meta>
  </xsl:template>
</xsl:stylesheet>




