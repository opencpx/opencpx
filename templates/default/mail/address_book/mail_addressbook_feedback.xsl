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
          <br />&#160;&#160;&#160;&#160;&#160;&#160;<xsl:text />
        </xsl:if>
        
        <xsl:variable name="code" select="/cp/vsap/vsap[@type='error']/code" />
        <xsl:variable name="caller" select="/cp/vsap/vsap[@type='error']/@caller" />
        <xsl:variable name="message" select="/cp/vsap/vsap[@type='error']/message" />
        <xsl:choose>
          <!-- addressbook errors -->
          <xsl:when test="$caller = 'webmail:addressbook:load'">
            <xsl:choose>
              <xsl:when test="$code = '100'">  
                &apos;<xsl:value-of select="/cp/form/txtEmail" />&apos;<xsl:copy-of select="/cp/strings/wm_addressbook_error_address_required" />
              </xsl:when>
              <xsl:when test="$code = '103'">  
                <xsl:copy-of select="/cp/strings/wm_addressbook_error_xml_error" />
              </xsl:when>
            </xsl:choose>
          </xsl:when>

          <xsl:when test="$caller = 'webmail:addressbook:add'">
            <xsl:choose>
              <xsl:when test="$code = '101'"> 
                <xsl:copy-of select="/cp/strings/wm_addressbook_error_address_required" />
              </xsl:when>
              <xsl:when test="$code = '103'"> 
                <xsl:copy-of select="/cp/strings/wm_addressbook_error_xml_error" />
              </xsl:when>
              <xsl:when test="$code = '109'"> 
                <xsl:copy-of select="/cp/strings/wm_addressbook_error_file_parse" />
              </xsl:when>
              <xsl:when test="$code = '110'"> 
                <xsl:copy-of select="/cp/strings/wm_addressbook_error_file_write" />
              </xsl:when>
              <xsl:when test="$code = '500'"> 
                <xsl:copy-of select="/cp/strings/wm_addressbook_error_limit_exceeded" />
              </xsl:when>
            </xsl:choose>
          </xsl:when>
          <xsl:when test="$caller = 'webmail:addressbook:delete'">
            <xsl:choose>
              <xsl:when test="$code = '100'">  
                <xsl:copy-of select="/cp/strings/wm_addressbook_error_notfound_delete" />
              </xsl:when>
              <xsl:when test="$code = '103'">
                <xsl:copy-of select="/cp/strings/wm_addressbook_error_xml_error" />
              </xsl:when>
              <xsl:when test="$code = '110'"> 
                <xsl:copy-of select="/cp/strings/wm_addressbook_error_file_write" />
              </xsl:when>
            </xsl:choose>
          </xsl:when>

          <!-- distlist errors -->
          <xsl:when test="$caller = 'webmail:distlist:list'">
            <xsl:choose>
              <xsl:when test="$code = '100'">  
                <xsl:copy-of select="/cp/strings/wm_distlist_error_bad_list_list_list" />
              </xsl:when>
              <xsl:when test="$code = '101'">  
                &apos;<xsl:value-of select="/cp/form/listid" />&apos;<xsl:copy-of select="/cp/strings/wm_distlist_error_bad_listid" />
              </xsl:when>
              <xsl:when test="$code = '105'">  
                <xsl:copy-of select="/cp/strings/wm_distlist_error_list_gone" />&apos;<xsl:value-of select="/cp/form/listid" />&apos;<xsl:copy-of select="/cp/strings/wm_distlist_error_list_gone_2" />
              </xsl:when>
              <xsl:when test="$code = '107'"> 
                <xsl:copy-of select="/cp/strings/wm_distlist_error_list_parse" />
              </xsl:when>
            </xsl:choose>
          </xsl:when>

          <xsl:when test="$caller = 'webmail:distlist:add'">
            <xsl:choose>
              <xsl:when test="$code = '100'">
                <xsl:copy-of select="/cp/strings/wm_distlist_error_bad_list_add" />
              </xsl:when>
              <xsl:when test="$code = '101'">  
                &apos;<xsl:value-of select="/cp/form/listid" />&apos;<xsl:copy-of select="/cp/strings/wm_distlist_error_bad_listid" />
              </xsl:when>
              
              <xsl:when test="$code = '102'">
                &apos;<xsl:value-of select="/cp/form/name" />&apos;<xsl:copy-of select="/cp/strings/wm_distlist_error_unique_listid" />
              </xsl:when>

              <xsl:when test="$code = '103'">
                <xsl:copy-of select="/cp/strings/wm_distlist_error_fs_error" />
              </xsl:when>
            
              <xsl:when test="$code = '104'">
                <xsl:copy-of select="/cp/strings/wm_distlist_error_listname_1" /> &apos;<xsl:value-of select="/cp/form/txtListName" />&apos;
                <xsl:copy-of select="/cp/strings/wm_distlist_error_listname_2" />
              </xsl:when>

              <xsl:when test="$code = '106'">
                <xsl:copy-of select="/cp/strings/wm_distlist_error_address" />
              </xsl:when>

              <xsl:when test="$code = '108'">
                <xsl:copy-of select="/cp/strings/wm_distlist_error_fs_create_path" />
              </xsl:when>

            </xsl:choose>
          </xsl:when>
          <xsl:when test="$caller = 'webmail:distlist:delete'">
          <!-- no errors returned on this vsap call -->
          </xsl:when>

          <!-- import errors -->
          <xsl:when test="$caller = 'webmail:addressbook:import'">
            <xsl:choose>
              <xsl:when test="/cp/vsap/vsap[@type='webmail:addressbook:import']/imported = 0">
                <xsl:copy-of select="/cp/strings/wm_addressbook_error_import" />
              </xsl:when>
              <xsl:when test="$code = '105'">  
                <!-- changing 'invalid file' to 'quota exceeded' (which is the likely culprit, BUG23465) -->
                <!-- xsl:copy-of select="/cp/strings/wm_addressbook_error_invalid_file" / -->
                <xsl:copy-of select="/cp/strings/wm_addressbook_error_file_write" />
              </xsl:when>
              <xsl:when test="$code = '106'">  
                <xsl:copy-of select="/cp/strings/wm_addressbook_error_invalid_format" />
              </xsl:when>
              <xsl:when test="$code = '107'">  
                <xsl:copy-of select="/cp/strings/wm_addressbook_error_empty_type" />
              </xsl:when>
              <xsl:when test="$code = '108'">  
                <xsl:copy-of select="/cp/strings/wm_addressbook_error_invalid_type" />
              </xsl:when>
              <xsl:when test="$code = '109'">  
                <xsl:copy-of select="/cp/strings/wm_addressbook_error_file_parse" />
              </xsl:when>
              <xsl:when test="$code = '110'"> 
                <xsl:copy-of select="/cp/strings/wm_addressbook_error_file_write" />
              </xsl:when>
              <xsl:when test="$code = '500'"> 
                <xsl:copy-of select="/cp/strings/wm_addressbook_error_limit_exceeded" />
              </xsl:when>
            </xsl:choose>
          </xsl:when>

          <!-- export errors -->
          <xsl:when test="$caller = 'webmail:addressbook:export'">
            <xsl:choose>
              <xsl:when test="$code = '107'">  
                <xsl:copy-of select="/cp/strings/wm_addressbook_error_empty_type" />
              </xsl:when>
              <xsl:when test="$code = '108'">  
                <xsl:copy-of select="/cp/strings/wm_addressbook_error_invalid_type" />
              </xsl:when>
              <xsl:when test="$code = '109'">  
                <xsl:copy-of select="/cp/strings/wm_addressbook_error_file_parse" />
              </xsl:when>
            </xsl:choose>
          </xsl:when>

          <!-- compose errors -->
          <xsl:when test="$caller = 'webmail:messages:save'">
            <xsl:value-of select="/cp/strings/wm_addresses_compose_successful" /><br />
            <xsl:value-of select="/cp/strings/wm_addresses_compose_sent_items_failure_1" />
            <a href="{concat($base_url,'/mail/wm_folders.xsl?folder=Sent Items')}"><xsl:value-of select="/cp/strings/wm_folders_sent_items" /></a>
            <xsl:value-of select="/cp/strings/wm_addresses_compose_sent_items_failure_2" />
          </xsl:when>
          
        </xsl:choose>
        
      </xsl:for-each>
    </xsl:when>
 
    <xsl:otherwise>
      <xsl:choose>
 
          <xsl:when test="/cp/vsap/vsap[@type='webmail:addressbook:add']">
            <xsl:choose>
              <xsl:when test="string(/cp/form/edit)">
                <xsl:copy-of select="/cp/strings/wm_addcontact_edit_success" />
              </xsl:when>
              <xsl:otherwise>
                &apos;<xsl:value-of select="/cp/form/txtEmail" />&apos;
                <xsl:copy-of select="/cp/strings/wm_addcontact_add_success" />
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:when test="/cp/vsap/vsap[@type='vsap:webmail:addressbook:delete']">
                <xsl:copy-of select="/cp/strings/wm_addressbook_delete_success" />
          </xsl:when>
          <xsl:when test="/cp/vsap/vsap[@type='vsap:webmail:distlist:add']">
            <xsl:choose>
              <xsl:when test="string(/cp/form/edit)">
                <xsl:copy-of select="/cp/strings/wm_distlist_edit_success" />
              </xsl:when>
              <xsl:otherwise>
                &apos;<xsl:value-of select="/cp/form/txtListName" />&apos;
                <xsl:copy-of select="/cp/strings/wm_distlist_add_success" />
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:when test="/cp/vsap/vsap[@type='vsap:webmail:distlist:delete']">
          </xsl:when>
          <xsl:when test="/cp/vsap/vsap[@type='webmail:addressbook:import']">
            <xsl:call-template name="transliterate">
              <xsl:with-param name="string"><xsl:value-of select="/cp/strings/wm_import_success"/></xsl:with-param>
              <xsl:with-param name="search">__TOTAL__</xsl:with-param>
              <xsl:with-param name="replace" select="/cp/vsap/vsap[@type='webmail:addressbook:import']/imported"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:when test="/cp/vsap/vsap[@type='webmail:addressbook:export']">
            <xsl:copy-of select="/cp/strings/wm_export_success" />
          </xsl:when>
          <xsl:when test="/cp/msgs/msg[@name='compose_successful']">
            <xsl:copy-of select="/cp/strings/wm_addresses_compose_successful" />
          </xsl:when>

      </xsl:choose>
    </xsl:otherwise>
  </xsl:choose>
  </xsl:template>
</xsl:stylesheet>

