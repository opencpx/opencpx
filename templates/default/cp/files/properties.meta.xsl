<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
 <xsl:import href="../../global.meta.xsl"/>
 <xsl:import href="../cp_global.meta.xsl"/>

 <xsl:template match="/">
  <meta>

  <xsl:choose>
   <xsl:when test="/cp/form/actionType = 'delete' or /cp/form/actionType = 'listFiles'">
    <redirect>    
     <path>/cp/files/index.xsl</path>
    </redirect>
   </xsl:when>

   <xsl:when test="/cp/form/actionType = 'properties' or /cp/form/actionType = 'jump' or starts-with(/cp/form/actionType, '_')">
    <!-- Do Nothing -->
   </xsl:when>

   <xsl:when test="/cp/form/actionType != ''">
    <redirect>
     <path>/cp/files/<xsl:value-of select="/cp/form/actionType"/>.xsl</path>
    </redirect>
   </xsl:when>
  </xsl:choose>

   <!-- run auth code -->
   <xsl:call-template name="auth">
    <xsl:with-param name="require_fileman">1</xsl:with-param>
    <xsl:with-param name="check_diskspace">0</xsl:with-param>
   </xsl:call-template>

   <xsl:call-template name="cp_global"/>

   <xsl:call-template name="dovsap">
    <xsl:with-param name="vsap">
     <vsap>
      <xsl:choose>
       <xsl:when test="string(/cp/form/download) = 'yes'">
        <vsap type="files:download">
         <path>
          <xsl:value-of select="/cp/form/currentItem"/>
         </path>
         <xsl:if test="/cp/form/currentUser">
          <user><xsl:value-of select="/cp/form/currentUser"/></user>
         </xsl:if>
         <format>
          <xsl:value-of select="/cp/form/format"/>
         </format>
         <user_agent>
          <xsl:value-of select="/cp/request/user_agent"/>
         </user_agent>
        </vsap>
       </xsl:when>
       <xsl:otherwise>
        <vsap type='user:prefs:load' />
        <vsap type="files:properties">
         <xsl:choose>
          <xsl:when test="/cp/form/actionType = 'jump'">
           <path><xsl:value-of select="/cp/vsap/vsap[@type='files:properties:type']/path"/></path>
          </xsl:when>
          <xsl:otherwise>
           <path><xsl:value-of select="/cp/form/currentItem"/></path>
          </xsl:otherwise>
         </xsl:choose>
         <xsl:if test="/cp/form/currentUser">
          <user><xsl:value-of select="/cp/form/currentUser"/></user>
         </xsl:if>
         <xsl:if test="/cp/form/actionType = '_save'">
          <set_contents>
           <xsl:value-of select="/cp/form/editedFile"/>
          </set_contents>
         </xsl:if>
        </vsap>
       </xsl:otherwise>
      </xsl:choose>
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

   <xsl:if test="/cp/form/actionType = '_save' or (/cp/vsap/vsap[@type='error'] and /cp/vsap/vsap[@caller='files:properties'])">

    <xsl:if test="not(/cp/form/looping)">
     <cp><form><looping>1</looping></form></cp>
    </xsl:if>

    <redirect>
     <path>/cp/files/index.xsl</path>
    </redirect>
   </xsl:if>

      <xsl:choose>
      <xsl:when test="(/cp/form/actionType = '_copy')">
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
      </xsl:when>

      <!--xsl:when test="(/cp/form/actionType = '_move')">
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
      </xsl:when-->

      <xsl:when test="(/cp/form/actionType = '_link')">
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

      <xsl:when test="(/cp/form/actionType = '_compress')">
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

      <xsl:when test="(/cp/form/actionType = '_uncompress')">
        <xsl:call-template name="set_message">
          <xsl:with-param name="name" select="'uncompress_action'"/>
        </xsl:call-template>

        <xsl:call-template name="set_message">
          <xsl:with-param name="name" select="'success'"/>
          <xsl:with-param name="value">
            <xsl:choose>
              <xsl:when test="/cp/vsap/vsap[@type='files:uncompress']/status = 'ok'">yes</xsl:when>
              <xsl:otherwise>no</xsl:otherwise>
            </xsl:choose>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>

      <!--xsl:when test="(/cp/form/action='doRename')">
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
      </xsl:when-->

      <xsl:when test="(/cp/form/actionType = '_permissions')">
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

      <xsl:when test="(/cp/form/actionType = '_owners')">
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
