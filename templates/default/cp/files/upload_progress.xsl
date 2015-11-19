<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
 <xsl:import href="../cp_global.xsl"/>

 <xsl:variable name="sessionID">
  <xsl:choose>
   <xsl:when test="/cp/form/sessionID"><xsl:value-of select="/cp/form/sessionID"/></xsl:when>
   <xsl:otherwise><xsl:value-of select="/cp/vsap/vsap[@type='files:upload:list']/sessionid"/></xsl:otherwise>
  </xsl:choose>
 </xsl:variable>

 <xsl:variable name="total_size">
  <xsl:choose>
   <xsl:when test="/cp/vsap/vsap[@type='files:upload:status']/total_size &gt; 1048576">
    <xsl:value-of select="concat(format-number((/cp/vsap/vsap[@type='files:upload:status']/total_size) div (1048576), '#.##'),' ')"/>
   </xsl:when>
   <xsl:when test="/cp/vsap/vsap[@type='files:upload:status']/total_size &gt; 1024">
    <xsl:value-of select="concat(format-number((/cp/vsap/vsap[@type='files:upload:status']/total_size) div (1024), '#.##'),' ')"/>
   </xsl:when>
   <xsl:otherwise>
    <xsl:value-of select="/cp/vsap/vsap[@type='files:upload:status']/total_size"/>
   </xsl:otherwise>
  </xsl:choose>
 </xsl:variable>

 <xsl:variable name="size_units">
  <xsl:choose>
   <xsl:when test="/cp/vsap/vsap[@type='files:upload:status']/total_size &gt; 1048576"><xsl:value-of select="/cp/strings/mb"/></xsl:when>
   <xsl:when test="/cp/vsap/vsap[@type='files:upload:status']/total_size &gt; 1024"><xsl:value-of select="/cp/strings/kb"/></xsl:when>
   <xsl:otherwise>bytes</xsl:otherwise>
  </xsl:choose>
 </xsl:variable>

 <xsl:variable name="amt_xferred">
  <xsl:choose>
   <xsl:when test="/cp/vsap/vsap[@type='files:upload:status']/bytes_transferred &gt; 1048576">
    <xsl:value-of select="concat(format-number((/cp/vsap/vsap[@type='files:upload:status']/bytes_transferred) div (1048576), '#.##'),' ')"/>
   </xsl:when>
   <xsl:when test="/cp/vsap/vsap[@type='files:upload:status']/bytes_transferred &gt; 1024">
    <xsl:value-of select="concat(format-number((/cp/vsap/vsap[@type='files:upload:status']/bytes_transferred) div (1024), '#.##'),' ')"/>
   </xsl:when>
   <xsl:otherwise>
    <xsl:value-of select="/cp/vsap/vsap[@type='files:upload:status']/bytes_transferred"/>
   </xsl:otherwise>
  </xsl:choose>
 </xsl:variable>

 <xsl:variable name="amt_units">
  <xsl:choose>
   <xsl:when test="/cp/vsap/vsap[@type='files:upload:status']/bytes_transferred &gt; 1048576"><xsl:value-of select="/cp/strings/mb"/></xsl:when>
   <xsl:when test="/cp/vsap/vsap[@type='files:upload:status']/bytes_transferred &gt; 1024"><xsl:value-of select="/cp/strings/kb"/></xsl:when>
   <xsl:otherwise>bytes</xsl:otherwise>
  </xsl:choose>
 </xsl:variable>

 <xsl:variable name="xfer_rate">
  <xsl:choose>
   <xsl:when test="/cp/vsap/vsap[@type='files:upload:status']/average_transfer_rate &gt; 1048576">
    <xsl:value-of select="concat(format-number((/cp/vsap/vsap[@type='files:upload:status']/average_transfer_rate) div (1048576), '#.##'),' ')"/>
   </xsl:when>
   <xsl:when test="/cp/vsap/vsap[@type='files:upload:status']/average_transfer_rate &gt; 1024">
    <xsl:value-of select="concat(format-number((/cp/vsap/vsap[@type='files:upload:status']/average_transfer_rate) div (1024), '#.##'),' ')"/>
   </xsl:when>
   <xsl:otherwise>
    <xsl:value-of select="/cp/vsap/vsap[@type='files:upload:status']/average_transfer_rate"/>
   </xsl:otherwise>
  </xsl:choose>
 </xsl:variable>

 <xsl:variable name="rate_units">
  <xsl:choose>
   <xsl:when test="/cp/vsap/vsap[@type='files:upload:status']/average_transfer_rate &gt; 1048576"><xsl:value-of select="/cp/strings/mbps"/></xsl:when>
   <xsl:when test="/cp/vsap/vsap[@type='files:upload:status']/average_transfer_rate &gt; 1024"><xsl:value-of select="/cp/strings/kbps"/></xsl:when>
   <xsl:otherwise>bytes/s</xsl:otherwise>
  </xsl:choose>
 </xsl:variable>

 <xsl:variable name="onload_action">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='error']/code = 102">self.close();</xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='files:upload:status']/percent_complete=100"></xsl:when>
    <xsl:otherwise>initProgressRefreshTimeout()</xsl:otherwise>
  </xsl:choose>
 </xsl:variable>

 <xsl:template match="/">
  <xsl:call-template name="blankbodywrapper">
   <xsl:with-param name="title">
    <xsl:value-of select="/cp/strings/cp_title"/>
    v<xsl:value-of select="/cp/vsap/vsap[@type='auth']/version" /> :
    <xsl:value-of select="/cp/strings/nv_menu_filemanager"/> : 
    <xsl:value-of select="/cp/strings/file_upload_title"/>
   </xsl:with-param>
   <xsl:with-param name="formaction">upload_progress.xsl</xsl:with-param>
   <xsl:with-param name="formname">specialwindow</xsl:with-param>
   <xsl:with-param name="formenctype">multipart/form-data</xsl:with-param>
   <xsl:with-param name="selected_navandcontent" select="x"/>
   <xsl:with-param name="onload"><xsl:value-of select="$onload_action"/></xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

    <script src="{concat($base_url, '/cp/cp.js')}" language="JavaScript"></script>

    <input type="hidden" name="sessionID" value="{$sessionID}"/>
    <input type="hidden" name="action" value=""/>

    <xsl:if test="/cp/form/action = 'ok'">
     <script>
      window.close();
     </script>
    </xsl:if>

     <table class="uploadpopup" border="0" cellspacing="0" cellpadding="0" with="100%">
      <tr class="columnhead">
       <td colspan="2"><xsl:value-of select="/cp/strings/file_upload_progress_title"/></td>
      </tr>
      <tr class="roweven">
       <td class="label">
        <xsl:value-of select="/cp/strings/file_upload_progress_filename"/><br/>
        <xsl:value-of select="/cp/strings/file_upload_progress_total_size"/><br/>
        <xsl:value-of select="/cp/strings/file_upload_progress_bytes_transferred"/><br/>
        <xsl:value-of select="/cp/strings/file_upload_progress_transfer_rate"/><br/>
       </td>
       <td>
        <xsl:value-of select="/cp/vsap/vsap[@type='files:upload:status']/filename"/><br/>
        <xsl:value-of select="$total_size"/> <xsl:value-of select="$size_units"/><br/>
        <xsl:value-of select="$amt_xferred"/> <xsl:value-of select="$amt_units"/> (<xsl:value-of select="/cp/vsap/vsap[@type='files:upload:status']/percent_complete"/>%)<br/>
        <xsl:value-of select="$xfer_rate"/> <xsl:value-of select="$rate_units"/><br/>
       </td>
      </tr>
      <tr class="instructionrow">
       <td colspan="2">
        <table style="margin: 0 0 0 0; padding: 0;" border="0" cellspacing="0" cellpadding="0" width="100%">
          <tr>
            <td style="margin: 0;
                       padding: 0; border-style: solid;
                       border-width: 1px 0px 1px 1px;
                       border-color: #333;
                       background-color : #E45A06;" align="right" width="{/cp/vsap/vsap[@type='files:upload:status']/percent_complete}%"><img src="{/cp/strings/guage_img_guagemarker}" alt="" height="10" width="1" border="0" /></td>
            <xsl:choose>
             <xsl:when test="/cp/vsap/vsap[@type='files:upload:status']/percent_complete=100">
              <td style="margin: 0;
                         padding: 0; border-style: solid;
                         border-width: 1px 1px 1px 0px;
                         border-color: #333;
                         background-color : #FFFFFF" width="{100 - /cp/vsap/vsap[@type='files:upload:status']/percent_complete}%"><img src="{/cp/strings/guage_img_guagemarker}" alt="" height="10" width="1" border="0" /></td>
             </xsl:when>
             <xsl:otherwise>
              <td style="margin: 0;
                         padding: 0; border-style: solid;
                         border-width: 1px 1px 1px 0px;
                         border-color: #333;
                         background-color : #FFFFFF" width="{100 - /cp/vsap/vsap[@type='files:upload:status']/percent_complete}%"><img src="{/cp/strings/guage_img_guagemarkerright}" alt="" height="10" width="1" border="0" /></td>
             </xsl:otherwise>
            </xsl:choose>
          </tr>
        </table>
       </td>
      </tr>
      <tr class="controlrow">
       <td>
       </td>
       <td>
        <xsl:choose>
         <xsl:when test="/cp/vsap/vsap[@type='files:upload:status']/percent_complete=100">
           <input class="floatright" type="button" onClick="document.forms[0].elements['action'].value = 'ok';document.forms[0].encoding='application/x-www-form-urlencoded';document.forms[0].submit()" name="ok" value="{/cp/strings/file_upload_progress_dismiss}"/>
         </xsl:when>
         <xsl:otherwise>&#160;</xsl:otherwise>
        </xsl:choose>
       </td>
      </tr>
     </table>

 </xsl:template>
</xsl:stylesheet>
