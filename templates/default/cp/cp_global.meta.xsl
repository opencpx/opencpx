<?xml version='1.0' encoding='UTF-8' ?>
<xsl:stylesheet version='1.0'
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exslt="http://exslt.org/common"
  xmlns:func="http://exslt.org/functions"
  xmlns:cp="vsap:cp"
  extension-element-prefixes="func"
  exclude-result-prefixes="exslt">

<xsl:template name="cp_global">
  <!-- add vsap calls that are to appear on _every_ cp page here -->
   <xsl:call-template name="dovsap">
     <xsl:with-param name="vsap">
       <vsap>
         <!-- domain admin's need domain:list for 'add end user' nav item -->
         <xsl:if test="/cp/vsap/vsap[@type='auth']/domain_admin and not(/cp/vsap/vsap[@type='auth']/server_admin)">
           <vsap type="domain:admin_list" />
         </xsl:if>
         <!-- check system for messages about jobs running in background -->
         <vsap type="user:messages:list" />
         <!-- is ssh protocol 1 enabled? -->
         <vsap type="sys:ssh:status" />
       </vsap>
     </xsl:with-param>
   </xsl:call-template>
</xsl:template>

</xsl:stylesheet>

