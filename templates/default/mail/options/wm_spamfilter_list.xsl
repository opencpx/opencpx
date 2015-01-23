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

<xsl:variable name="listType">
  <xsl:choose>
    <xsl:when test="/cp/form/listType='black'">black</xsl:when>
    <xsl:otherwise>white</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="listCount">
  <xsl:choose>
    <xsl:when test="$listType='black'">
      <xsl:value-of select="count(/cp/vsap/vsap[@type='mail:spamassassin:status']/blacklist_from)"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="count(/cp/vsap/vsap[@type='mail:spamassassin:status']/whitelist_from)"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>
  
<xsl:variable name="subTitle">
  <xsl:choose>
    <xsl:when test="$listType='black'">
      <xsl:copy-of select="/cp/strings/wm_spamfilter_blacklist_manage" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:copy-of select="/cp/strings/wm_spamfilter_whitelist_manage" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:template match="/">
  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title">
      <xsl:copy-of select="/cp/strings/wm_title" /> : <xsl:copy-of select="/cp/strings/nv_menu_mailboxoptions" /> : <xsl:copy-of select="/cp/strings/bc_wm_spamfilter" /> : <xsl:copy-of select="$subTitle" />
    </xsl:with-param>
    <xsl:with-param name="formaction">wm_spamfilter_list.xsl</xsl:with-param>
    <xsl:with-param name="feedback" select="$message" />
    <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_spam" />
    <xsl:with-param name="breadcrumb">
      <breadcrumb>
       <section>
         <name><xsl:copy-of select="/cp/strings/bc_wm_spamfilter" /></name>
         <url>wm_spamfilter.xsl</url>
       </section>
       <section>
         <name><xsl:copy-of select="$subTitle" /></name>
         <url>#</url>
         <image>MailFilters</image>
       </section>
      </breadcrumb>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

      <input type="hidden" name="listType" value="{$listType}" />
      <table class="formview" border="0" cellspacing="0" cellpadding="0">
        <tr class="title">
          <td colspan="2"><xsl:value-of select="/cp/strings/wm_spamfilter_title" /></td>
        </tr>
        <tr class="roweven">
          <td class="label">
            <xsl:choose>
              <xsl:when test="$listType='black'">
                <xsl:value-of select="/cp/strings/wm_spamfilter_blacklist" />
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="/cp/strings/wm_spamfilter_whitelist" />
              </xsl:otherwise>
            </xsl:choose>
          </td>
          <td class="contentwidth">
            <xsl:choose>
              <xsl:when test="$listType='black'">
                <select name="blacklist_from" size="12" multiple="multiple">
                  <xsl:for-each select="/cp/vsap/vsap[@type='mail:spamassassin:status']/blacklist_from">
                   <option><xsl:value-of select="."/></option>
                  </xsl:for-each>
                  <xsl:if test="$listCount='0'">
                   <option value="__EMPTY"><xsl:value-of select="/cp/strings/wm_spamfilter_list_empty"/></option>
                  </xsl:if>
                </select>
              </xsl:when>
              <xsl:otherwise>
                <select name="whitelist_from" size="12" multiple="multiple">
                  <xsl:for-each select="/cp/vsap/vsap[@type='mail:spamassassin:status']/whitelist_from">
                   <option><xsl:value-of select="."/></option>
                  </xsl:for-each>
                  <xsl:if test="$listCount='0'">
                   <option value="__EMPTY"><xsl:value-of select="/cp/strings/wm_spamfilter_list_empty"/></option>
                  </xsl:if>
                </select>
              </xsl:otherwise>
            </xsl:choose>
            <br/>
            <input type="submit" id="submitRemove" name="remove" value="{/cp/strings/wm_spamfilter_list_remove}" />
            <p>
            <input type="text" name="pattern" size="30" onkeydown="if (event.keyCode == 13) document.getElementById('submitAdd').click()"/><br/>
            <input type="submit" id="submitAdd" name="add" value="{/cp/strings/wm_spamfilter_list_add}" />
            </p>
            <xsl:choose>
              <xsl:when test="$listType='black'">
                <p><xsl:value-of select="/cp/strings/wm_spamfilter_blacklist_help" /></p>
              </xsl:when>
              <xsl:otherwise>
                <p><xsl:value-of select="/cp/strings/wm_spamfilter_whitelist_help" /></p>
              </xsl:otherwise>
            </xsl:choose>
            <p><xsl:value-of select="/cp/strings/wm_spamfilter_list_instruction" /></p>
          </td>
        </tr>
      </table>
    <br />
         
</xsl:template>      
</xsl:stylesheet>

