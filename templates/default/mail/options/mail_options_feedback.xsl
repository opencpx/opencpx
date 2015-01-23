<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exslt="http://exslt.org/common"
  xmlns:cp="vsap:cp"
  exclude-result-prefixes="cp exslt">
<xsl:import href="../../global.xsl" />

<!-- we handle all of the user feedback here -->
<xsl:template name="status_message">
  <xsl:choose>
    <!-- handle all errors -->
    <xsl:when test="/cp/vsap/vsap[@type='error']">
      <xsl:for-each select="/cp/vsap/vsap[@type='error']">
        <xsl:if test="position() &gt; 1">
          <br /><xsl:text />
        </xsl:if>
        
        <xsl:variable name="code" select="/cp/vsap/vsap[@type='error']/code" />
        <xsl:variable name="caller" select="/cp/vsap/vsap[@type='error']/@caller" />
        <xsl:variable name="message" select="/cp/vsap/vsap[@type='error']/message" />
        <xsl:choose>
          <xsl:when test="$code &lt; 550">
            <xsl:choose> <xsl:when test="$code = '500'">  <xsl:copy-of select="/cp/strings/wm_helper_error_mail_procmail_not_found" /> </xsl:when> <xsl:when test="$code = '501'">  <xsl:copy-of select="/cp/strings/wm_helper_error_mail_procmail_not_lda" /> </xsl:when> <xsl:when test="$code = '510'">  
                <xsl:copy-of select="/cp/strings/wm_helper_error_mail_open_failed" />
              </xsl:when>
              <xsl:when test="$code = '511'">  
                <xsl:copy-of select="/cp/strings/wm_helper_error_mail_write_failed" />
              </xsl:when>
              <xsl:when test="$code = '512'">  
                <xsl:copy-of select="/cp/strings/wm_helper_error_mail_mkdir_failed" />
              </xsl:when>
              <xsl:when test="$code = '513'">  
                <xsl:copy-of select="/cp/strings/wm_helper_error_mail_rename_failed" />
              </xsl:when>
            </xsl:choose>
          </xsl:when>
          
          <xsl:when test="$caller = 'mail:spamassassin:enable' or $caller = 'mail:spamassassin:disable'">
            <xsl:choose>
              <xsl:when test="$code = '550'">  
                <xsl:copy-of select="/cp/strings/wm_spamfilter_error_spamassassin_not_found" />
              </xsl:when>
            </xsl:choose>
          </xsl:when>

          <xsl:when test="$caller = 'mail:spamassassin:set_user_prefs'">
            <xsl:choose>
              <xsl:when test="$code = '555'">  
                <xsl:copy-of select="/cp/strings/wm_spamfilter_custom_score_invalid_format" />
              </xsl:when>
            </xsl:choose>
          </xsl:when>

          <xsl:when test="$caller = 'mail:clamav:enable' or $caller = 'mail:clamav:disable'">
            <xsl:choose>
              <xsl:when test="$code = '550'">  
                <xsl:copy-of select="/cp/strings/wm_virusscan_error_clamav_not_found" />
              </xsl:when>
            </xsl:choose>
          </xsl:when>

          <xsl:when test="$caller = 'mail:forward:enable' or $caller = 'mail:forward:disable'">
            <xsl:choose>
              <xsl:when test="$code = '550'">  
                <xsl:copy-of select="/cp/strings/wm_mailfwd_error_forward_email_empty" />
              </xsl:when>
              <xsl:when test="$code = '551'">  
                <xsl:copy-of select="/cp/strings/wm_mailfwd_error_forward_email_invalid" />
              </xsl:when>
              <xsl:when test="$code = '552'">  
                <xsl:copy-of select="/cp/strings/wm_mailfwd_error_forward_user_not_found" />
              </xsl:when>
            </xsl:choose>
          </xsl:when>

          <xsl:when test="$caller = 'mail:autoreply:enable' or $caller = 'mail:autoreply:disable'">
            <xsl:choose>
              <xsl:when test="$code = '550'">  
                <xsl:copy-of select="/cp/strings/wm_autoreply_error_autoreply_not_found" />
              </xsl:when>
              <xsl:when test="$code = '551'">  
                <xsl:copy-of select="/cp/strings/wm_autoreply_error_vacation_not_found" />
              </xsl:when>
              <xsl:when test="$code = '555'">  
                <xsl:copy-of select="/cp/strings/wm_autoreply_error_autoreply_message_empty" />
              </xsl:when>
            </xsl:choose>
          </xsl:when>

        </xsl:choose>
        
      </xsl:for-each>
    </xsl:when>
    <xsl:otherwise>
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='mail:spamassassin:enable'] or /cp/vsap/vsap[@type='mail:spamassassin:disable']">
          <xsl:value-of select="/cp/strings/wm_spamfilter_success" />
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='mail:spamassassin:set_user_prefs']">
          <xsl:value-of select="/cp/strings/wm_spamfilter_success" />
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='mail:spamassassin:add_patterns'] or /cp/vsap/vsap[@type='mail:spamassassin:remove_patterns']">
          <xsl:value-of select="/cp/strings/wm_spamfilter_success" />
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='mail:clamav:enable'] or /cp/vsap/vsap[@type='mail:clamav:disable']">
          <xsl:value-of select="/cp/strings/wm_virusscan_success" />
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='mail:forward:enable'] or /cp/vsap/vsap[@type='mail:forward:disable']">
          <xsl:value-of select="/cp/strings/wm_mailfwd_success" />
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='mail:autoreply:enable'] or /cp/vsap/vsap[@type='mail:autoreply:disable']">
          <xsl:value-of select="/cp/strings/wm_autoreply_success" />
        </xsl:when>
      </xsl:choose>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>
</xsl:stylesheet>

