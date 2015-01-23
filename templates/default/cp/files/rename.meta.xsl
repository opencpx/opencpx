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

   <xsl:if test="/cp/form/actionType = '_rename'">

    <xsl:call-template name="dovsap">
     <xsl:with-param name="vsap">
      <vsap>
       <vsap type="files:rename">
        <source><xsl:value-of select="/cp/form/currentItem"/></source>
        <xsl:if test="/cp/form/currentUser"><source_user><xsl:value-of select="/cp/form/currentUser"/></source_user></xsl:if>
        <target><xsl:value-of select="/cp/form/target"/></target>
        <xsl:if test="/cp/form/currentUser"><target_user><xsl:value-of select="/cp/form/currentUser"/></target_user></xsl:if>
        <target_name><xsl:value-of select="/cp/form/targetName"/></target_name>
       </vsap>
      </vsap>
     </xsl:with-param>
    </xsl:call-template>

    <xsl:choose>
     <xsl:when test="/cp/vsap/vsap[@type='error']/@caller='files:rename'">
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='files:rename']/code = 100">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">not_authorized</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='files:rename']/code = 101">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">invalid_path</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='files:rename']/code = 102">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">invalid_path</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='files:rename']/code = 103">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">rename_failed</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='files:rename']/code = 104">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">quota_exceeded</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='files:rename']/code = 105">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">invalid_user</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='files:rename']/code = 106">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">invalid_name</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='files:rename']/code = 107">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">invalid_target</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='files:rename']/code = 108">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">target_exists</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
      </xsl:choose>
     </xsl:when>
     <xsl:otherwise>
      <!-- redirect on success -->
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

   </xsl:if>

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
