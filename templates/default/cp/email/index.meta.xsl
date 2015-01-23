<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../../global.meta.xsl" />
<xsl:import href="../cp_global.meta.xsl" />
<xsl:template match="/">
<meta>

<xsl:call-template name="auth">
  <xsl:with-param name="require_class">ma</xsl:with-param>
  <xsl:with-param name="require_mail">1</xsl:with-param>
</xsl:call-template>

<xsl:call-template name="cp_global"/>

<xsl:choose>

  <xsl:when test="/cp/form/AddEmail">
    <redirect><path>cp/email/add-edit.xsl</path></redirect>
  </xsl:when>

  <xsl:when test="/cp/form/Delete='yes'">
    <xsl:call-template name="dovsap">
       <xsl:with-param name="vsap">
         <vsap>
           <vsap type="mail:addresses:delete">
             <xsl:for-each select="/cp/form/address">
               <source><xsl:value-of select="."/></source>
             </xsl:for-each>
           </vsap>
           <vsap type="mail:addresses:list">
            <xsl:if test="/cp/form/select_domain != ''">
              <domain><xsl:value-of select="/cp/form/select_domain" /></domain>
            </xsl:if>
           </vsap>
           <vsap type="domain:list"/>
         </vsap>
       </xsl:with-param>
     </xsl:call-template>
  </xsl:when>

  <xsl:otherwise>
    <xsl:call-template name="dovsap">
      <xsl:with-param name="vsap">
        <vsap>
          <vsap type="mail:addresses:list">
            <xsl:if test="/cp/form/select_domain != ''">
              <domain><xsl:value-of select="/cp/form/select_domain" /></domain>
            </xsl:if>
          </vsap>
          <vsap type="domain:list"/>
        </vsap>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:otherwise>

</xsl:choose>

<!--
  This page has the following events defined:

  email_delete_failure
  email_delete_successful

  email_add_failure
  email_add_successful

  email_edit_failure
  email_edit_successful
-->
<xsl:if test="(/cp/form/Delete='ok' or /cp/form/Delete='yes') and (count (/cp/form/address) > 0)"> 
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='mail:addresses:delete']/status='not ok'">
      <xsl:variable name="msg_error_val">
        <xsl:choose>
          <xsl:when test="count(/cp/form/address)=1">email_delete_failure</xsl:when>
          <xsl:otherwise>email_delete_failure_multi</xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:call-template name="set_message">
        <xsl:with-param name="name"><xsl:value-of select="$msg_error_val" /></xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <xsl:variable name="msg_success_val">
        <xsl:choose>
          <xsl:when test="count(/cp/form/address)=1">email_delete_successful</xsl:when>
          <xsl:otherwise>email_delete_successful_multi</xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <xsl:call-template name="set_message">
        <xsl:with-param name="name"><xsl:value-of select="$msg_success_val" /></xsl:with-param>
      </xsl:call-template>
    </xsl:otherwise>
  </xsl:choose>
</xsl:if>

<showpage />

</meta>
</xsl:template>
</xsl:stylesheet>

