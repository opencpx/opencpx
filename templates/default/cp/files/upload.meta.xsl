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

   <!-- run vsap code -->
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

   <xsl:if test="string(/cp/form/action)='ok'">
    <xsl:call-template name="dovsap">
     <xsl:with-param name="vsap">
      <vsap>
       <vsap type="files:upload:confirm">
        <sessionid><xsl:value-of select="/cp/form/sessionID"/> </sessionid>
        <path><xsl:value-of select="/cp/form/currentDir"/></path>
        <xsl:if test="/cp/form/currentUser">
         <user><xsl:value-of select="/cp/form/currentUser"/></user>
        </xsl:if>
        <xsl:if test="/cp/form/overwrite">
         <overwrite/>
        </xsl:if>
       </vsap>       
      </vsap>
     </xsl:with-param>
    </xsl:call-template>
   </xsl:if>

   <xsl:if test="string(/cp/form/action)='cancel'">
    <xsl:call-template name="dovsap">
     <xsl:with-param name="vsap">
      <vsap>
       <vsap type="files:upload:cancel">
        <sessionid><xsl:value-of select="/cp/form/sessionID"/> </sessionid>
       </vsap>      
      </vsap>
     </xsl:with-param>
    </xsl:call-template>
   </xsl:if>

   <xsl:if test="string(/cp/form/attachFile)">
    <xsl:if test="/cp/form/fileupload != ''">
     <xsl:call-template name="dovsap">
      <xsl:with-param name="vsap">
       <vsap>
        <vsap type="files:upload:add">
         <sessionid><xsl:value-of select="/cp/form/sessionID"/></sessionid>
         <filename><xsl:value-of select="/cp/form/fileupload"/></filename>
        </vsap>
       </vsap> 
      </xsl:with-param>
     </xsl:call-template>
    </xsl:if>
   </xsl:if>

   <xsl:if test="string(/cp/form/remove)">
    <xsl:call-template name="dovsap">
     <xsl:with-param name="vsap">
      <vsap>
       <vsap type="files:upload:delete">
        <sessionid><xsl:value-of select="/cp/form/sessionID"/></sessionid>
        <xsl:for-each select="/cp/form/remove">
         <filename><xsl:value-of select="."/></filename>
        </xsl:for-each>
       </vsap>      
      </vsap>
     </xsl:with-param>
    </xsl:call-template>
   </xsl:if>
 
   <xsl:call-template name="dovsap">
    <xsl:with-param name="vsap">
     <vsap>
      <vsap type="files:upload:list">
       <sessionid><xsl:value-of select="/cp/form/sessionID"/></sessionid>
      </vsap>
     </vsap>
    </xsl:with-param>
   </xsl:call-template>

   <xsl:if test="not(boolean(/cp/request/setcookies/CP-uploadkey))">
    <cp>
      <request>
        <setcookies>
          <CP-uploadkey><xsl:value-of select="/cp/form/sessionID" /></CP-uploadkey>
        </setcookies>
      </request>
    </cp>
   </xsl:if>

   <!-- if that's all done, we just show the page -->
   <showpage/>

  </meta>
 </xsl:template>
</xsl:stylesheet>
