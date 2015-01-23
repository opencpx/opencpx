<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../mail_global.xsl" />
<xsl:import href="mail_addressbook_feedback.xsl" />

<xsl:variable name="status">
  <xsl:call-template name="status_message" />
</xsl:variable>

<xsl:variable name="status_image">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='error']">error</xsl:when>
    <xsl:otherwise>success</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="message">
  <xsl:if test="string($status)">
    <xsl:call-template name="feedback_table">
      <xsl:with-param name="image"><xsl:value-of select="$status_image" /></xsl:with-param>
      <xsl:with-param name="message"><xsl:copy-of select="$status" /> </xsl:with-param>
    </xsl:call-template>
  </xsl:if>
</xsl:variable>

<xsl:variable name="fileupload">
  <xsl:value-of select="/cp/form/fileupload" />
</xsl:variable>

<xsl:variable name="enc_setting">
  <xsl:value-of select="/cp/form/import_encoding" />
</xsl:variable>

<xsl:variable name="subtitle">
  <xsl:copy-of select="/cp/strings/bc_import_export" />
</xsl:variable>

<xsl:template match="/">
  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title">
      <xsl:copy-of select="/cp/strings/wm_title" /> : <xsl:copy-of select="/cp/strings/nv_menu_addressbook" /> : <xsl:copy-of select="$subtitle" />
    </xsl:with-param>
    <xsl:with-param name="formaction">wm_import_export.xsl</xsl:with-param>
    <xsl:with-param name="formenctype">multipart/form-data</xsl:with-param>
    <xsl:with-param name="feedback" select="$message" />
    <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_import_export" />
    <xsl:with-param name="help_short" select="/cp/strings/wm_addcontact_hlp_short" />
    <xsl:with-param name="help_long" select="/cp/strings/wm_addcontact_hlp_long" />
    <xsl:with-param name="breadcrumb">
      <breadcrumb>
        <section>
          <name><xsl:copy-of select="/cp/strings/bc_import_export" /></name>
          <url>#</url>
          <image>AddressBook</image>
        </section>
      </breadcrumb>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

      <script src="{concat($base_url, '/mail/address_book/address_book.js')}" language="JavaScript"></script>      
      <table class="formview" border="0" cellspacing="0" cellpadding="0">
        <tr class="title">
          <td colspan="2"><xsl:copy-of select="/cp/strings/wm_import_title" /></td>
        </tr>
        <tr class="instructionrow">
          <td colspan="2"><xsl:value-of select="/cp/strings/wm_import_instruction" /></td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:value-of select="/cp/strings/wm_import_file" /></td>
          <td class="contentwidth"><input type="file" name="fileupload" id="fileupload" size="60" value="{$fileupload}" /></td>
        </tr>
        <tr class="roweven">
          <td class="label"><xsl:value-of select="/cp/strings/wm_import_format" /></td>
          <td class="contentwidth">
            <select name="import_format">
              <option value="csv"><xsl:value-of select="/cp/strings/wm_import_csv_format"/></option>
              <option value="vcf"><xsl:value-of select="/cp/strings/wm_import_vcf_format"/></option>
            </select>
          </td>
        </tr>

            <!-- optional specification of source file encoding -->
            <tr class="rowodd">
              <td class="label"><xsl:value-of select="/cp/strings/wm_import_encoding"/></td>
              <td class="contentwidth"><select name="import_encoding">

                  <option value="UTF-8">
                    <xsl:if test="$enc_setting = 'UTF-8'">
                      <xsl:attribute name="selected" value="selected"/>
                    </xsl:if>
                    <xsl:value-of select="/cp/strings/wm_import_encoding_utf8"/>
                  </option>

                  <option value="US-ASCII">
                    <xsl:if test="$enc_setting = 'US_ASCII'">
                      <xsl:attribute name="selected" value="selected"/>
                    </xsl:if>
                    <xsl:value-of select="/cp/strings/wm_import_encoding_usascii"/>
                  </option>

                  <option value="ISO-2022-JP">
                    <xsl:if test="$enc_setting = 'ISO-2022-JP'">
                      <xsl:attribute name="selected" value="selected"/>
                    </xsl:if>
                    <xsl:value-of select="/cp/strings/wm_import_encoding_iso2022jp"/>
                  </option>

                  <option value="ISO-8859-1">
                    <xsl:if test="$enc_setting = 'ISO-8859-1'">
                      <xsl:attribute name="selected" value="selected"/>
                    </xsl:if>
                    <xsl:value-of select="/cp/strings/wm_import_encoding_iso88591"/>
                  </option>

                </select></td>
             </tr>

        <tr class="controlrow">
          <td colspan="2">
            <span class="floatright">
              <input type="submit" name="import" value="{/cp/strings/wm_import_bt_import}" onClick="return verifyImportFile('{cp:js-escape(/cp/strings/wm_import_alert_file)}');" />
              <input type="submit" name="cancel" value="{/cp/strings/wm_import_bt_cancel}" onClick="var elem=document.getElementById('fileupload'); elem.parentNode.removeChild(elem);" />
            </span>
          </td>
        </tr>
      </table>
      <br />
      <table class="formview" border="0" cellspacing="0" cellpadding="0">
        <tr class="title">
          <td colspan="2"><xsl:copy-of select="/cp/strings/wm_export_title" /></td>
        </tr>
        <tr class="instructionrow">
          <td colspan="2"><xsl:value-of select="/cp/strings/wm_export_instruction" /></td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:value-of select="/cp/strings/wm_export_format" /></td>
          <td class="contentwidth">
            <select name="export_format">
              <option value="csv"><xsl:value-of select="/cp/strings/wm_export_csv_format"/></option>
              <option value="vcf"><xsl:value-of select="/cp/strings/wm_export_vcf_format"/></option>
            </select>
          </td>
        </tr>
        <tr class="controlrow">
          <td colspan="2">
            <span class="floatright">
              <input type="submit" name="export" value="{/cp/strings/wm_export_bt_export}" onClick="var elem=document.getElementById('fileupload'); elem.parentNode.removeChild(elem);" />
              <input type="submit" name="cancel" value="{/cp/strings/wm_export_bt_cancel}" onClick="var elem=document.getElementById('fileupload'); elem.parentNode.removeChild(elem);" />
            </span>
          </td>
        </tr>
      </table>

</xsl:template>
</xsl:stylesheet>
