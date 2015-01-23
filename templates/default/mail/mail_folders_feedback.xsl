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
          <br />&#160;&#160;&#160;&#160;&#160;&#160;<xsl:text />
        </xsl:if>
        
        <xsl:variable name="code" select="/cp/vsap/vsap[@type='error']/code" />
        <xsl:variable name="caller" select="/cp/vsap/vsap[@type='error']/@caller" />
        <xsl:variable name="message" select="/cp/vsap/vsap[@type='error']/message" />
        <xsl:choose>
          <xsl:when test="$caller = 'webmail:folders:list'">
            <xsl:choose>
              <xsl:when test="$code = '101'">  
                <xsl:copy-of select="/cp/strings/wm_folders_error_cclient" />
              </xsl:when>
            </xsl:choose>
          </xsl:when>
          
          <xsl:when test="$caller = 'webmail:folders:create'">
            <xsl:variable name="newfolder">
              <xsl:call-template name="truncate">
                <xsl:with-param name="string"><xsl:value-of select="/cp/form/newfolder" /></xsl:with-param>
                <xsl:with-param name="fieldlength"><xsl:copy-of select="/cp/strings/wm_folders_name_fieldlength" /></xsl:with-param>
              </xsl:call-template>
            </xsl:variable>
            <xsl:choose>
              <xsl:when test="$code = '100'">  
                <xsl:copy-of select="/cp/strings/wm_folders_error_bad_characters" />
              </xsl:when>
              <xsl:when test="$code = '101'">  
                <xsl:copy-of select="/cp/strings/wm_folders_error_cclient" />
              </xsl:when>
              <xsl:when test="$code = '102'">  
                <xsl:copy-of select="/cp/strings/wm_folders_error_folder_missing" />
              </xsl:when>
              <xsl:when test="$code = '109'">  
                &apos;<xsl:value-of select="$newfolder" />&apos;<xsl:copy-of select="/cp/strings/wm_folders_error_folder_exists" />
              </xsl:when>
              <xsl:when test="$code = '110'">  
                &apos;<xsl:value-of select="$newfolder" />&apos;<xsl:copy-of select="/cp/strings/wm_folders_error_folder_create" />
              </xsl:when>
            </xsl:choose>
          </xsl:when>

          <xsl:when test="$caller = 'webmail:folders:subscribe'">
            <xsl:choose>
              <xsl:when test="$code = '100'">  
                <xsl:copy-of select="/cp/strings/wm_folders_error_bad_characters" />
              </xsl:when>
              <xsl:when test="$code = '101'">  
                <xsl:copy-of select="/cp/strings/wm_folders_error_cclient" />
              </xsl:when>
              <xsl:when test="$code = '102'">  
                <xsl:copy-of select="/cp/strings/wm_folders_error_folder_missing" />
              </xsl:when>
              <xsl:when test="$code = '111'">  
                <xsl:copy-of select="/cp/strings/wm_folders_error_folder_subscribe" />
              </xsl:when>
              <xsl:when test="$code = '117'">  
                &apos;<xsl:value-of select="$newfolder" />&apos;<xsl:copy-of select="/cp/strings/wm_folders_error_folder_not_found" />
              </xsl:when>
            </xsl:choose>
          </xsl:when>

          <xsl:when test="$caller = 'webmail:folders:clear'">
            <xsl:choose>
              <xsl:when test="$code = '101'">  
                <xsl:copy-of select="/cp/strings/wm_folders_error_cclient" />
              </xsl:when>
              <xsl:when test="$code = '107'">  
                <xsl:copy-of select="/cp/strings/wm_folders_error_move_failed" />
              </xsl:when>
              <xsl:when test="$code = '108'">  
                <xsl:copy-of select="/cp/strings/wm_folders_error_folder_delete_clear" />
              </xsl:when>
              <xsl:when test="$code = '110'">  
                <xsl:copy-of select="/cp/strings/wm_folders_error_folder_create_clear" />
              </xsl:when>
            </xsl:choose>
          </xsl:when>

          <xsl:when test="$caller = 'webmail:folders:delete'">
            <xsl:choose>
              <xsl:when test="$code = '101'">  
                <xsl:copy-of select="/cp/strings/wm_folders_error_cclient" />
              </xsl:when>
              <xsl:when test="$code = '103'">  
                <xsl:copy-of select="/cp/strings/wm_folders_error_delete_inbox" />
              </xsl:when>
              <xsl:when test="$code = '108'">  
                <xsl:copy-of select="/cp/strings/wm_folders_error_folder_delete" />
              </xsl:when>
            </xsl:choose>
          </xsl:when>

          <xsl:when test="$caller = 'webmail:folders:unsubscribe'">
            <xsl:choose>
              <xsl:when test="$code = '101'">  
                <xsl:copy-of select="/cp/strings/wm_folders_error_cclient" />
              </xsl:when>
              <xsl:when test="$code = '112'">  
                <xsl:copy-of select="/cp/strings/wm_folders_error_folder_unsubscribe" />
              </xsl:when>
              <xsl:when test="$code = '113'">  
                <xsl:copy-of select="/cp/strings/wm_folders_error_unsubscribe_inbox" />
              </xsl:when>
            </xsl:choose>
          </xsl:when>

          <xsl:when test="$caller = 'webmail:folders:rename'">
            <xsl:choose>
              <xsl:when test="$code = '100'">  
                <xsl:copy-of select="/cp/strings/wm_folders_error_bad_characters" />
              </xsl:when>
              <xsl:when test="$code = '101'">  
                <xsl:copy-of select="/cp/strings/wm_folders_error_cclient" />
              </xsl:when>
              <xsl:when test="$code = '104'">  
                <xsl:copy-of select="/cp/strings/wm_folders_error_folder_rename" />
              </xsl:when>
              <xsl:when test="$code = '105'">  
                <xsl:copy-of select="/cp/strings/wm_folders_error_system_rename" />
              </xsl:when>
              <xsl:when test="$code = '106'">  
                <xsl:copy-of select="/cp/strings/wm_folders_error_rename" />
              </xsl:when>
              <xsl:when test="$code = '109'">  
                &apos;<xsl:value-of select="$newfolder" />&apos;<xsl:copy-of select="/cp/strings/wm_folders_error_folder_exists" />
              </xsl:when>
            </xsl:choose>
          </xsl:when>

        </xsl:choose>
        
      </xsl:for-each>
    </xsl:when>
 
    <xsl:otherwise>
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='webmail:folders:create']">
          <xsl:variable name="newfolder">
            <xsl:call-template name="truncate">
              <xsl:with-param name="string"><xsl:value-of select="/cp/form/newfolder" /></xsl:with-param>
              <xsl:with-param name="fieldlength"><xsl:copy-of select="/cp/strings/wm_folders_name_fieldlength" /></xsl:with-param>
            </xsl:call-template>
          </xsl:variable>
          <xsl:copy-of select="/cp/strings/wm_addfolder_success_1" />
          &apos;<xsl:value-of select="$newfolder" />&apos;
          <xsl:copy-of select="/cp/strings/wm_addfolder_success_2" />
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='webmail:folders:subscribe']">
          <xsl:variable name="newfolder">
            <xsl:call-template name="truncate">
              <xsl:with-param name="string"><xsl:value-of select="/cp/form/newfolder" /></xsl:with-param>
              <xsl:with-param name="fieldlength"><xsl:copy-of select="/cp/strings/wm_folders_name_fieldlength" /></xsl:with-param>
            </xsl:call-template>
          </xsl:variable>
          <xsl:copy-of select="/cp/strings/wm_subscribefolder_success_1" />
          &apos;<xsl:value-of select="$newfolder" />&apos;
          <xsl:copy-of select="/cp/strings/wm_subscribefolder_success_2" />
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='webmail:folders:clear']">
          <xsl:copy-of select="/cp/strings/wm_clearfolder_success_1" />
          &apos;<xsl:value-of select="/cp/form/clear" />&apos;
          <xsl:copy-of select="/cp/strings/wm_clearfolder_success_2" />
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='webmail:folders:delete']">
          <xsl:choose>
            <xsl:when test="count(/cp/form/cbUserID) = 1">
              <xsl:copy-of select="/cp/strings/wm_deletefolder_success_1" />
              &apos;<xsl:call-template name="truncate">
                <xsl:with-param name="string"><xsl:value-of select="/cp/form/cbUserID" /></xsl:with-param>
                <xsl:with-param name="fieldlength"><xsl:copy-of select="/cp/strings/wm_folders_name_fieldlength" /></xsl:with-param>
              </xsl:call-template>&apos;
              <xsl:copy-of select="/cp/strings/wm_deletefolder_success_2" />
            </xsl:when>
            <xsl:when test="count(/cp/form/cbUserID) > 1">
              <xsl:copy-of select="/cp/strings/wm_multi_deletefolder_success_1" />
              <xsl:for-each select="/cp/form/cbUserID">
                &apos;<xsl:value-of select="." />&apos;
                <xsl:if test="position() != last()">,</xsl:if>
              </xsl:for-each>
              <xsl:copy-of select="/cp/strings/wm_multi_deletefolder_success_2" />
            </xsl:when>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='webmail:folders:unsubscribe']">
          <xsl:choose>
            <xsl:when test="count(/cp/form/cbUserID) = 1">
              <xsl:copy-of select="/cp/strings/wm_unsubscribefolder_success_1" />
              &apos;<xsl:call-template name="truncate">
                <xsl:with-param name="string"><xsl:value-of select="/cp/form/cbUserID" /></xsl:with-param>
                <xsl:with-param name="fieldlength"><xsl:copy-of select="/cp/strings/wm_folders_name_fieldlength" /></xsl:with-param>
              </xsl:call-template>&apos;
              <xsl:copy-of select="/cp/strings/wm_unsubscribefolder_success_2" />
            </xsl:when>
            <xsl:when test="count(/cp/form/cbUserID) > 1">
              <xsl:copy-of select="/cp/strings/wm_multi_unsubscribefolder_success_1" />
              <xsl:for-each select="/cp/form/cbUserID">
                &apos;<xsl:value-of select="." />&apos;
                <xsl:if test="position() != last()">,</xsl:if>
              </xsl:for-each>
              <xsl:copy-of select="/cp/strings/wm_multi_unsubscribefolder_success_2" />
            </xsl:when>
          </xsl:choose>
        </xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='webmail:folders:rename']">
          <xsl:variable name="oldfolder">
            <xsl:call-template name="truncate">
              <xsl:with-param name="string"><xsl:value-of select="/cp/form/oldfolder" /></xsl:with-param>
              <xsl:with-param name="fieldlength"><xsl:copy-of select="/cp/strings/wm_folders_name_fieldlength" /></xsl:with-param>
            </xsl:call-template>
          </xsl:variable>
          <xsl:variable name="newfolder">
            <xsl:call-template name="truncate">
              <xsl:with-param name="string"><xsl:value-of select="/cp/form/newfolder" /></xsl:with-param>
              <xsl:with-param name="fieldlength"><xsl:copy-of select="/cp/strings/wm_folders_name_fieldlength" /></xsl:with-param>
            </xsl:call-template>
          </xsl:variable>
          <xsl:copy-of select="/cp/strings/wm_renamefolder_success_1" />
          &apos;<xsl:value-of select="$oldfolder" />&apos;
          <xsl:copy-of select="/cp/strings/wm_renamefolder_success_2" />
          &apos;<xsl:value-of select="$newfolder" />&apos;
        </xsl:when>
      </xsl:choose>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>
</xsl:stylesheet>

