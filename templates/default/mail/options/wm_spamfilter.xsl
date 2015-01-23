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

<xsl:variable name="spamassassin_mail">
  <xsl:choose>
    <xsl:when test="string(/cp/form/checkboxName) and not(string(/cp/form/btnCancel))">on</xsl:when>
    <xsl:when test="string(cp/vsap/vsap[@type='mail:spamassassin:status']/status)">
      <xsl:value-of select="/cp/vsap/vsap[@type='mail:spamassassin:status']/status"/>
    </xsl:when>
    <xsl:otherwise>off</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="level">
  <xsl:choose>
    <xsl:when test="string(/cp/form/level) and not(string(/cp/form/btnCancel))">
      <xsl:value-of select="/cp/form/level" />
    </xsl:when>
    <xsl:when test="string(cp/vsap/vsap[@type='mail:spamassassin:status']/required_score)">
      <xsl:value-of select="/cp/vsap/vsap[@type='mail:spamassassin:status']/required_score"/>
    </xsl:when>
    <xsl:otherwise>5</xsl:otherwise>
  </xsl:choose>
</xsl:variable>
  
<xsl:variable name="custom_score">
  <xsl:choose>
    <xsl:when test="string(/cp/form/custom_score) and not(string(/cp/form/btnCancel))">
      <xsl:value-of select="/cp/form/custom_score" />
    </xsl:when>
    <xsl:when test="string(cp/vsap/vsap[@type='mail:spamassassin:status']/required_score)">
      <xsl:value-of select="/cp/vsap/vsap[@type='mail:spamassassin:status']/required_score"/>
    </xsl:when>
    <xsl:otherwise>3.5</xsl:otherwise>
  </xsl:choose>
</xsl:variable>
  
<xsl:template match="/">
  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title">
      <xsl:copy-of select="/cp/strings/wm_title" /> : <xsl:copy-of select="/cp/strings/nv_menu_mailboxoptions" /> : <xsl:copy-of select="/cp/strings/bc_wm_spamfilter" />
    </xsl:with-param>
    <xsl:with-param name="formaction">wm_spamfilter.xsl</xsl:with-param>
    <xsl:with-param name="feedback" select="$message" />
    <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_spam" />
    <xsl:with-param name="help_short" select="/cp/strings/wm_spamfilter_hlp_short" />
    <xsl:with-param name="help_long" select="/cp/strings/wm_spamfilter_hlp_long" />
    <xsl:with-param name="breadcrumb">
      <breadcrumb>
       <section>
         <name><xsl:copy-of select="/cp/strings/bc_wm_spamfilter" /></name>
         <url>#</url>
         <image>MailFilters</image>
       </section>
      </breadcrumb>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

      <input type="hidden" name="spamassassin_mail" value="{$spamassassin_mail}" />
      <table class="formview" border="0" cellspacing="0" cellpadding="0">
        <tr class="title">
          <td colspan="2"><xsl:value-of select="/cp/strings/wm_spamfilter_title" /></td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:value-of select="/cp/strings/wm_spamfilter_name" /><br />
          <img src="{/cp/strings/wm_spamfilter_img_spamassassin}" alt="" height="60" width="135" border="0" /></td>
          <td class="contentwidth"><xsl:value-of select="/cp/strings/wm_spamfilter_content" /><xsl:value-of select="/cp/strings/wm_folders_junk" /><xsl:value-of select="/cp/strings/wm_spamfilter_folder" />
            <xsl:choose>
              <xsl:when test="/cp/vsap/vsap[@type='mail:spamassassin:globally_installed']/global='yes'">
                <p><input type="checkbox" id="sa_subscribe" name="checkboxName" value="checkBoxValue" checked="check" disabled="true" /><label for="sa_subscribe"><xsl:value-of select="/cp/strings/wm_spamfilter_ck_subscribe" /></label>*</p>
              </xsl:when>
              <xsl:when test="$spamassassin_mail='on'">
                <p><input type="checkbox" id="sa_subscribe" name="checkboxName" value="checkBoxValue" checked="check" /><label for="sa_subscribe"><xsl:value-of select="/cp/strings/wm_spamfilter_ck_subscribe" /></label></p>
              </xsl:when>
              <xsl:otherwise>
                <p><input type="checkbox" id="sa_subscribe" name="checkboxName" value="checkboxValue" /><label for="sa_subscribe"><xsl:value-of select="/cp/strings/wm_spamfilter_ck_subscribe" /></label></p>
              </xsl:otherwise>
            </xsl:choose>
            <p><xsl:value-of select="/cp/strings/wm_spamfilter_reminder_1" /><xsl:value-of select="/cp/strings/wm_folders_junk" /><xsl:value-of select="/cp/strings/wm_spamfilter_reminder_2" /></p>
          </td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:value-of select="/cp/strings/wm_spamfilter_sensitivity_level" /></td>
          <td class="contentwidth"><xsl:value-of select="/cp/strings/wm_spamfilter_sensitivity_level_help" />
            <p>
            <xsl:choose>
              <xsl:when test="$level='0'">
                <input type="radio" id="level_strict" name="level" value="0" checked="checked" border="0" /><label for="level_strict"><xsl:value-of select="/cp/strings/wm_spamfilter_sensitivity_level_strict" /></label><br />
              </xsl:when>
              <xsl:otherwise>
                <input type="radio" id="level_strict" name="level" value="0" border="0" /><label for="level_strict"><xsl:value-of select="/cp/strings/wm_spamfilter_sensitivity_level_strict" /></label><br />
              </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
              <xsl:when test="$level='5'">
                <input type="radio" id="level_high" name="level" value="5" checked="checked" border="0" /><label for="level_high"><xsl:value-of select="/cp/strings/wm_spamfilter_sensitivity_level_high" /></label><br />
              </xsl:when>
              <xsl:otherwise>
                <input type="radio" id="level_high" name="level" value="5" border="0" /><label for="level_high"><xsl:value-of select="/cp/strings/wm_spamfilter_sensitivity_level_high" /></label><br />
              </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
              <xsl:when test="$level='10'">
                <input type="radio" id="level_medium" name="level" value="10" checked="checked" border="0" /><label for="level_medium"><xsl:value-of select="/cp/strings/wm_spamfilter_sensitivity_level_medium" /></label><br />
              </xsl:when>
              <xsl:otherwise>
                <input type="radio" id="level_medium" name="level" value="10" border="0" /><label for="level_medium"><xsl:value-of select="/cp/strings/wm_spamfilter_sensitivity_level_medium" /></label><br />
              </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
              <xsl:when test="$level='20'">
                <input type="radio" id="level_low" name="level" value="20" checked="checked" border="0" /><label for="level_low"><xsl:value-of select="/cp/strings/wm_spamfilter_sensitivity_level_low" /></label><br />
              </xsl:when>
              <xsl:otherwise>
                <input type="radio" id="level_low" name="level" value="20" border="0" /><label for="level_low"><xsl:value-of select="/cp/strings/wm_spamfilter_sensitivity_level_low" /></label><br />
              </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
              <xsl:when test="$level='100'">
                <input type="radio" id="level_permissive" name="level" value="100" checked="checked" border="0" /><label for="level_permissive"><xsl:value-of select="/cp/strings/wm_spamfilter_sensitivity_level_permissive" /></label><br />
              </xsl:when>
              <xsl:otherwise>
                <input type="radio" id="level_permissive" name="level" value="100" border="0" /><label for="level_permissive"><xsl:value-of select="/cp/strings/wm_spamfilter_sensitivity_level_permissive" /></label><br />
              </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
              <xsl:when test="$level='0' or $level='5' or $level='10' or $level='20' or $level='100'">
                <input type="radio" id="level_custom" name="level" value="CUSTOM" border="0" /><label for="level_custom"><xsl:value-of select="/cp/strings/wm_spamfilter_sensitivity_level_custom" /></label><input type="text" name="custom_score" size="5" value="{$custom_score}"/><br />
              </xsl:when>
              <xsl:otherwise>
                <input type="radio" id="level_custom" name="level" value="CUSTOM" checked="checked" border="0" /><label for="level_custom"><xsl:value-of select="/cp/strings/wm_spamfilter_sensitivity_level_custom" /></label><input type="text" name="custom_score" size="5" value="{$custom_score}"/><br />
              </xsl:otherwise>
            </xsl:choose>
            </p>
          </td>
        </tr>
        <tr class="roweven">
          <td class="label"><xsl:value-of select="/cp/strings/wm_spamfilter_whitelist" /></td>
          <td class="contentwidth"><xsl:value-of select="/cp/strings/wm_spamfilter_whitelist_help" /> (<a href="wm_spamfilter_list.xsl?listType=white"><xsl:value-of select="/cp/strings/wm_spamfilter_whitelist_manage" /></a>)
          </td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:value-of select="/cp/strings/wm_spamfilter_blacklist" /></td>
          <td class="contentwidth"><xsl:value-of select="/cp/strings/wm_spamfilter_blacklist_help" /> (<a href="wm_spamfilter_list.xsl?listType=black"><xsl:value-of select="/cp/strings/wm_spamfilter_blacklist_manage" /></a>)
          </td>
        </tr>
        <tr class="controlrow">
          <td colspan="2"><span class="floatright"><input type="submit" name="save" value="{/cp/strings/wm_spamfilter_btn_save}" /><input type="submit" name="btnCancel" value="{/cp/strings/wm_spamfilter_btn_cancel}" /></span></td>
        </tr>
      </table>

      <xsl:if test="/cp/vsap/vsap[@type='mail:spamassassin:globally_installed']/global='yes'">
        <table class="formview" border="0" cellspacing="0" cellpadding="0">
          <tr class="noterow">
            <td><xsl:copy-of select="/cp/strings/wm_spamfilter_installed_globally" /></td>
          </tr>
        </table>
      </xsl:if>

    <br />
         
</xsl:template>      
</xsl:stylesheet>

