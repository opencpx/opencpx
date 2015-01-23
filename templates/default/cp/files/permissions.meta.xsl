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

   <xsl:if test="/cp/form/actionType ='_permissions'">
    <xsl:call-template name="dovsap">
     <xsl:with-param name="vsap">
      <vsap>
       <vsap type="files:chmod">
        <path><xsl:value-of select="/cp/form/currentItem"/></path>
        <xsl:if test="/cp/form/recurse">
          <recurse>1</recurse>
          <xsl:choose>
            <xsl:when test="/cp/form/recurse_X = 'yes'"><recurse_X>1</recurse_X></xsl:when>
            <xsl:otherwise><recurse_X>0</recurse_X></xsl:otherwise>
          </xsl:choose>
        </xsl:if>
          <mode>
           <owner>
            <xsl:if test="/cp/form/chkOwnerRead"><read>1</read></xsl:if>
            <xsl:if test="/cp/form/chkOwnerWrite"><write>1</write></xsl:if>
            <xsl:if test="/cp/form/chkOwnerExec"><execute>1</execute></xsl:if>
           </owner>
           <group>
            <xsl:if test="/cp/form/chkGroupRead"><read>1</read></xsl:if>
            <xsl:if test="/cp/form/chkGroupWrite"><write>1</write></xsl:if>
            <xsl:if test="/cp/form/chkGroupExec"><execute>1</execute></xsl:if>
           </group>
           <world>
            <xsl:if test="/cp/form/chkWorldRead"><read>1</read></xsl:if>
            <xsl:if test="/cp/form/chkWorldWrite"><write>1</write></xsl:if>
            <xsl:if test="/cp/form/chkWorldExec"><execute>1</execute></xsl:if>
           </world>
          </mode>
         <xsl:if test="/cp/form/currentUser">
         <user>
          <xsl:value-of select="/cp/form/currentUser"/>
         </user>
        </xsl:if>
       </vsap>
      </vsap>
     </xsl:with-param>
    </xsl:call-template>

    <xsl:choose>
     <xsl:when test="/cp/vsap/vsap[@type='error']/@caller='files:chmod'">
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='files:chmod']/code = 100">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">not_authorized</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='files:chmod']/code = 101">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">invalid_path</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='files:chmod']/code = 102">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">invalid_path</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='files:chmod']/code = 103">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">chmod_failed</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='files:chmod']/code = 104">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">recursion_failed</xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='files:chmod']/code = 105">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name">invalid_user</xsl:with-param>
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

   <xsl:call-template name="dovsap">
    <xsl:with-param name="vsap">
     <vsap>
      <vsap type='user:prefs:load' />
      <vsap type="files:chmod">
       <path><xsl:value-of select="/cp/form/currentItem"/></path>
       <xsl:if test="/cp/form/currentUser">
        <user>
         <xsl:value-of select="/cp/form/currentUser"/>
        </user>
       </xsl:if>
      </vsap>
     </vsap>
    </xsl:with-param>
   </xsl:call-template>

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
