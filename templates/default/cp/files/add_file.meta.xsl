<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
 <xsl:import href="../../global.meta.xsl"/>
 <xsl:import href="../cp_global.meta.xsl"/>

 <xsl:template match="/">
  <meta>

   <xsl:if test="/cp/form/actionType = '_cancel'">
    <redirect>
     <path>/cp/files/index.xsl</path>
    </redirect>
   </xsl:if>

   <!-- run auth code -->
   <xsl:call-template name="auth">
    <xsl:with-param name="require_fileman">1</xsl:with-param>
   </xsl:call-template>

   <xsl:call-template name="cp_global"/>

   <xsl:if test="/cp/form/actionType='_addFile'">

    <xsl:call-template name="dovsap">
     <xsl:with-param name="vsap">
      <vsap>
       <vsap type="files:create">
        <path><xsl:value-of select="/cp/form/currentDir"/><xsl:if test="/cp/form/currentDir != '/'">/</xsl:if><xsl:value-of select="/cp/form/newFileName"/></path>
        <xsl:if test="/cp/form/currentUser">
         <user>
          <xsl:value-of select="/cp/form/currentUser"/>
         </user>
        </xsl:if>
        <contents><xsl:value-of select="/cp/form/editedFile"/></contents>
       </vsap>
      </vsap>
     </xsl:with-param>
    </xsl:call-template>

    <xsl:choose>
     <xsl:when test="/cp/vsap/vsap[@type='error']/@caller='files:create'">
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='files:create']/code = 100">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">not_authorized</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='files:create']/code = 101">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">invalid_path</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='files:create']/code = 102">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">path_exists</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='files:create']/code = 103">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">create_failed</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='files:create']/code = 104">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">quota_exceeded</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='files:create']/code = 105">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">invalid_user</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
      </xsl:choose>
     </xsl:when>
     <xsl:otherwise>
      <!-- redirect on success -->
      <redirect>
       <path>/cp/files/index.xsl</path>
      </redirect>
     </xsl:otherwise>
    </xsl:choose>

   </xsl:if>

   <showpage/>

  </meta>
 </xsl:template>
</xsl:stylesheet>
