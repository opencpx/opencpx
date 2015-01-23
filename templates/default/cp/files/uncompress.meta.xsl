<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
 <xsl:import href="../../global.meta.xsl"/>
 <xsl:import href="../cp_global.meta.xsl"/>

 <xsl:template match="/">
  <meta>

   <xsl:if test="/cp/form/actionType = '_cancel'">
    <redirect>
     <path>
      <xsl:choose>
       <xsl:when test="/cp/form/refPage != ''">/cp/files/<xsl:value-of select="/cp/form/refPage"/></xsl:when>
       <xsl:otherwise>/cp/files/index.xsl</xsl:otherwise>
       </xsl:choose>
      </path>
     </redirect>
   </xsl:if>

   <!-- run auth code -->
   <xsl:call-template name="auth">
    <xsl:with-param name="require_fileman">1</xsl:with-param>
   </xsl:call-template>

   <xsl:call-template name="cp_global"/>

   <xsl:choose>
   <xsl:when test="/cp/form/actionType = '_uncompress'">
    <xsl:call-template name="dovsap">
     <xsl:with-param name="vsap">
      <vsap>
       <vsap type="files:uncompress">
        <source><xsl:value-of select="/cp/form/currentItem"/></source>
        <xsl:if test="/cp/form/currentUser">
         <source_user><xsl:value-of select="/cp/form/currentUser"/></source_user>
        </xsl:if>
        <xsl:copy-of select="/cp/form/target"/>
        <xsl:if test="/cp/form/targetUser">
         <target_user><xsl:value-of select="/cp/form/targetUser"/></target_user>
        </xsl:if>
        <xsl:copy-of select="/cp/form/file"/>
        <uncompress_option><xsl:value-of select="/cp/form/uncompress_option"/></uncompress_option>
       </vsap>
      </vsap>
     </xsl:with-param>
    </xsl:call-template>
    <xsl:choose>
     <xsl:when test="/cp/vsap/vsap[@type='error']/@caller='files:uncompress' and 
                     not(/cp/vsap/vsap[@type='error'][@caller='files:uncompress']/code = 250)">
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='files:uncompress']/code = 100">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">not_authorized</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='files:uncompress']/code = 101">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">invalid_path</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='files:uncompress']/code = 102">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">invalid_path</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='files:uncompress']/code = 103">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">uncompress_failed</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='files:uncompress']/code = 104">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">quota_exceeded</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='files:uncompress']/code = 105">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">invalid_user</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='files:uncompress']/code = 106">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">invalid_target</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
      </xsl:choose>
     </xsl:when>
     <xsl:otherwise>
      <!-- redirect on success or if request was queued -->
      <xsl:if test="/cp/vsap/vsap[@type='error'][@caller='files:uncompress']/code = 250">
        <xsl:call-template name="set_message">
          <xsl:with-param name="name">request_queued</xsl:with-param>
        </xsl:call-template>
      </xsl:if>
      <redirect>
       <path>
        <xsl:choose>
         <xsl:when test="/cp/form/refPage != ''">/cp/files/<xsl:value-of select="/cp/form/refPage"/></xsl:when>
         <xsl:otherwise>/cp/files/index.xsl</xsl:otherwise>
        </xsl:choose>
       </path>
      </redirect>
     </xsl:otherwise>
    </xsl:choose>
   </xsl:when>

   <!-- on loading, call files:properties so we can tell when to display options -->
   <xsl:otherwise>
     <xsl:call-template name="dovsap">
     <xsl:with-param name="vsap">
     <vsap>
     <vsap type="files:properties">
       <path><xsl:value-of select="/cp/form/currentItem"/></path>
       <xsl:if test="/cp/form/currentUser">
        <user><xsl:value-of select="/cp/form/currentUser"/></user>
       </xsl:if>
     </vsap>
     </vsap>
     </xsl:with-param>
     </xsl:call-template>
   </xsl:otherwise>
   </xsl:choose>

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

   <showpage/>

  </meta>
 </xsl:template>
</xsl:stylesheet>
