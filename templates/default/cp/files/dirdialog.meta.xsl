<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
 <xsl:import href="../../global.meta.xsl"/>
 <xsl:import href="../cp_global.meta.xsl"/>

 <xsl:template match="/">
  <meta>

   <!-- run auth code -->
   <xsl:call-template name="auth">
    <xsl:with-param name="require_fileman">1</xsl:with-param>
   </xsl:call-template>

   <xsl:call-template name="cp_global"/>

   <xsl:call-template name="dovsap">
    <xsl:with-param name="vsap">
     <vsap>
      <vsap type='user:prefs:load' />
       <vsap type="files:list">
        <path>
         <xsl:value-of select="/cp/form/path"/>
        </path>
        <xsl:if test="/cp/form/targetUser">
         <user>
          <xsl:value-of select="/cp/form/targetUser"/>
         </user>
       </xsl:if>
      </vsap>
     </vsap>
    </xsl:with-param>
   </xsl:call-template>

   <xsl:if test="/cp/vsap/vsap[@type='error' and  @caller='files:list']">
     <xsl:call-template name="dovsap">
      <xsl:with-param name="force_call">yes</xsl:with-param>
      <xsl:with-param name="vsap">
       <vsap>
        <vsap type="files:list">
         <path></path>
        </vsap>
       </vsap>
      </xsl:with-param>
     </xsl:call-template>
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
