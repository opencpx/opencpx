<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exslt="http://exslt.org/common"
  xmlns:cp="vsap:cp"
  exclude-result-prefixes="cp exslt">
<xsl:import href="../global.xsl" />

<!-- we handle all of the user feedback here -->
<xsl:template name="status_message">
  <xsl:choose>
    <!-- handle all errors -->
    <xsl:when test="/cp/vsap/vsap[@type='error']">
      <xsl:for-each select="/cp/vsap/vsap[@type='error']">
        <xsl:if test="position() &gt; 1">
          <br />
        </xsl:if>
        <xsl:variable name="code" select="./code" />
        <xsl:variable name="caller" select="./@caller" />
        <xsl:variable name="message" select="./@message" />
        <xsl:choose>
          <xsl:when test="$caller = 'webmail:send'">
            <xsl:choose>
              <xsl:when test="$code = '100'">  
                <xsl:copy-of select="/cp/strings/wm_compose_error_missing_to" />
              </xsl:when>
              <xsl:when test="$code = '101'">  
                <xsl:copy-of select="/cp/strings/wm_compose_error_bad_to" />
              </xsl:when>
              <xsl:when test="$code = '102'">  
                <xsl:copy-of select="/cp/strings/wm_compose_error_bad_replyto" />
              </xsl:when>
              <xsl:when test="$code = '103'">  
                <xsl:copy-of select="/cp/strings/wm_compose_error_bad_cc" />
              </xsl:when>
              <xsl:when test="$code = '104'">  
                <xsl:copy-of select="/cp/strings/wm_compose_error_bad_bcc" />
              </xsl:when>
              <xsl:when test="$code = '105'">  
                <xsl:copy-of select="/cp/strings/wm_compose_error_bad_subject" />
              </xsl:when>
              <xsl:when test="$code = '106'">  
                <xsl:copy-of select="/cp/strings/wm_compose_error_bad_text" />
              </xsl:when>
              <xsl:when test="$code = '107'">  
                <xsl:copy-of select="/cp/strings/wm_compose_error_missing_attach" />
              </xsl:when>
              <xsl:when test="$code = '108'">  
                <xsl:copy-of select="/cp/strings/wm_compose_error_send_failed" />
              </xsl:when>
              <xsl:when test="$code = '109'">  
                <xsl:copy-of select="/cp/strings/wm_compose_error_invalid_addr" />
              </xsl:when>
              <xsl:when test="$code = '110'">  
                <xsl:copy-of select="/cp/strings/wm_compose_error_bad_from" />
              </xsl:when>
              <xsl:when test="$code = '111'">  
                <xsl:copy-of select="/cp/strings/wm_compose_error_attach_dir" />
              </xsl:when>
              <xsl:when test="$code = '112'">  
                <xsl:copy-of select="/cp/strings/wm_compose_error_attach_copy" />
              </xsl:when>
            </xsl:choose>
          </xsl:when>
          
        </xsl:choose>
        
      </xsl:for-each>
    </xsl:when>
 
    <xsl:otherwise>
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='webmail:send'] and not(string(/cp/form/savedraft))">
          <xsl:copy-of select="/cp/strings/wm_compose_success_send" />
        </xsl:when>
        <xsl:when test="string(cp/form/savedraft)">
          <xsl:copy-of select="/cp/strings/wm_compose_success_save_drafts" />
        </xsl:when>
      </xsl:choose>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>
</xsl:stylesheet>

