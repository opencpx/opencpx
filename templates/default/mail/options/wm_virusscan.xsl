<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../mail_global.xsl" />
<xsl:import href="mail_options_feedback.xsl" />

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

<xsl:variable name="clamav_mail">
  <xsl:choose>
    <xsl:when test="string(/cp/form/checkboxName) and not(string(/cp/form/btnCancel))">on</xsl:when>
    <xsl:when test="string(cp/vsap/vsap[@type='mail:clamav:status']/status)">
      <xsl:value-of select="/cp/vsap/vsap[@type='mail:clamav:status']/status"/>
    </xsl:when>
    <xsl:otherwise>off</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:template match="/">
  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title">
      <xsl:copy-of select="/cp/strings/wm_title" /> : <xsl:copy-of select="/cp/strings/nv_menu_mailboxoptions" /> : <xsl:copy-of select="/cp/strings/bc_wm_virusscan" />
    </xsl:with-param>
    <xsl:with-param name="formaction">wm_virusscan.xsl</xsl:with-param>
    <xsl:with-param name="feedback" select="$message" />
    <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_virus" />
    <xsl:with-param name="help_short" select="/cp/strings/wm_virusscan_hlp_short" />
    <xsl:with-param name="help_long" select="/cp/strings/wm_virusscan_hlp_long" />
    <xsl:with-param name="breadcrumb">
      <breadcrumb>
       <section>
         <name><xsl:copy-of select="/cp/strings/bc_wm_virusscan" /></name>
         <url>#</url>
         <image>MailFilters</image>
       </section>
      </breadcrumb>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

      <input type="hidden" name="clamav_mail" value="{$clamav_mail}" />
      <table class="formview" border="0" cellspacing="0" cellpadding="0">
        <tr class="title">
          <td colspan="2"><xsl:value-of select="/cp/strings/wm_virusscan_title" /></td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:value-of select="/cp/strings/wm_virusscan_name" /><br />
          <img src="{/cp/strings/wm_virusscan_img_clam}" alt="" height="99" width="100" border="0" /></td>
          <td class="contentwidth"><xsl:value-of select="/cp/strings/wm_virusscan_content" />
            <xsl:choose>
              <xsl:when test="/cp/vsap/vsap[@type='mail:clamav:milter_installed']/installed='yes'">
                <p><input type="checkbox" id="clamav_subscribe" name="checkboxName" value="checkboxValue" checked="check" disabled="true" /><label for="clamav_subscribe"><xsl:value-of select="/cp/strings/wm_virusscan_ck_subscribe" /></label>*</p>
              </xsl:when>
              <xsl:when test="$clamav_mail='on'">
                <p><input type="checkbox" id="clamav_subscribe" name="checkboxName" value="checkboxValue" checked="check" /><label for="clamav_subscribe"><xsl:value-of select="/cp/strings/wm_virusscan_ck_subscribe" /></label></p>
              </xsl:when>
              <xsl:otherwise>
                <p><input type="checkbox" id="clamav_subscribe" name="checkboxName" value="checkboxValue" /><label for="clamav_subscribe"><xsl:value-of select="/cp/strings/wm_virusscan_ck_subscribe" /></label></p>
              </xsl:otherwise>
            </xsl:choose>
            <p><xsl:value-of select="/cp/strings/wm_virusscan_reminder" /><br />
            </p>
          </td>
        </tr>
        <tr class="controlrow">
          <td colspan="2"><span class="floatright"><input type="submit" name="save" value="{/cp/strings/wm_virusscan_btn_save}" /><input type="submit" name="btnCancel" value="{/cp/strings/wm_virusscan_btn_cancel}" /></span></td>
        </tr>
      </table>

      <xsl:if test="/cp/vsap/vsap[@type='mail:clamav:milter_installed']/installed='yes'">
        <table class="formview" border="0" cellspacing="0" cellpadding="0">
          <tr class="noterow">
            <td><xsl:copy-of select="/cp/strings/wm_virusscan_installed_as_milter" /></td>
          </tr>
        </table>
      </xsl:if>

    <br />
         
</xsl:template>  
</xsl:stylesheet>  

