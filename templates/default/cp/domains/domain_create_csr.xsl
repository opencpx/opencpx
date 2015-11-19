<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
  xmlns:exslt="http://exslt.org/common"
  exclude-result-prefixes="exslt">

<xsl:import href="../cp_global.xsl" />

<xsl:variable name="message">
  <xsl:choose>
    <xsl:when test="/cp/msgs/msg[@name='domain_csr_create_error']">
      <xsl:copy-of select="/cp/strings/domain_csr_create_error" />
    </xsl:when>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="feedback">
  <xsl:if test="$message != ''">
    <xsl:call-template name="feedback_table">
      <xsl:with-param name="image">
        <xsl:choose>
          <xsl:when test="/cp/vsap/vsap[@type='error']">error</xsl:when>
          <xsl:when test="/cp/vsap/vsap[@type='sys:ssl:csr_create']/status != 'ok'">error</xsl:when>
          <xsl:otherwise>success</xsl:otherwise>
        </xsl:choose>
      </xsl:with-param>
      <xsl:with-param name="message">
        <xsl:copy-of select="$message" />
      </xsl:with-param>
    </xsl:call-template>
  </xsl:if>
</xsl:variable>

<xsl:template match="/">
<xsl:call-template name="bodywrapper">

  <xsl:with-param name="title">
    <xsl:copy-of select="/cp/strings/cp_title" />
    v<xsl:value-of select="/cp/vsap/vsap[@type='auth']/version" /> :
    <xsl:copy-of select="/cp/strings/cp_title_domain_create_csr" />
  </xsl:with-param>

  <xsl:with-param name="formaction">domain_create_csr.xsl</xsl:with-param>
  <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_create_csr" />
  <xsl:with-param name="help_short" select="/cp/strings/domain_csr_help_short" />
  <xsl:with-param name="help_long" select="/cp/strings/domain_csr_help_long" />
  <xsl:with-param name="feedback" select="$feedback" />
  <xsl:with-param name="breadcrumb">
    <breadcrumb>
      <section>
        <name><xsl:copy-of select="/cp/strings/bc_domain_csr" /></name>
        <url><xsl:value-of select="$base_url" />/cp/domains/domain_create_csr.xsl</url>
        <image>DomainManagement</image>
      </section>
      <section>
        <name><xsl:copy-of select="/cp/strings/bc_domain_csr" /></name>
        <url>#</url>
        <image>DomainManagement</image>
      </section>
    </breadcrumb>
  </xsl:with-param>

</xsl:call-template>
</xsl:template>

<xsl:template name="content">

  <xsl:choose>
    <xsl:when test="/cp/form/save">
      <xsl:if test="/cp/vsap/vsap[@type='sys:ssl:csr_create']/status = 'ok'">
          <table class="formview" border="0" cellspacing="0" cellpadding="0">
            <tr class="title">
              <td colspan="2"><xsl:copy-of select="/cp/strings/domain_csr_title" /></td>
            </tr>
            <tr class="roweven">
              <td colspan="2" class="contentwidth">
                <textarea name="csr_text" rows="17" cols="70">
                  <xsl:value-of select="/cp/vsap/vsap[@type='sys:ssl:csr_create']/csr" />
                </textarea>
              </td>
            </tr>
            <tr class="controlrow">
              <td colspan="2">
                <span class="floatright">
                  <input type="button" name="btn_copy" value="{/cp/strings/domain_csr_btn_selectall}" 
                    onClick="document.forms[0].csr_text.select();" />
                </span>
              </td>
            </tr>
          </table>
      </xsl:if>
    </xsl:when>
    <xsl:otherwise>

        <script src="{concat($base_url, '/cp/cp.js')}" language="JavaScript"></script>

        <input type="hidden" name="save" value="" />     
        <input type="hidden" name="cancel" value="" />     

        <table class="formview" border="0" cellspacing="0" cellpadding="0">
          <tr class="title">
            <td colspan="2"><xsl:copy-of select="/cp/strings/domain_csr_title" /></td>
          </tr>
          <tr class="instructionrow">
            <td colspan="2"><xsl:value-of select="/cp/strings/domain_csr_instr"/></td>
          </tr>
          <tr class="roweven">
            <td class="label"><xsl:value-of select="/cp/strings/domain_csr_domain"/></td>
            <td class="contentwidth">
              <select name="domain">
                <xsl:if test="string(/cp/form/domain)=''">
                  <option value=""><xsl:value-of select="/cp/strings/domain_csr_select"/></option>
                </xsl:if>
                <xsl:for-each select="/cp/vsap/vsap[@type='domain:list']/domain">
                  <option value="{name}"><xsl:if test="/cp/form/domain=name"><xsl:attribute name="selected"/></xsl:if>
                  <xsl:value-of select="name"/></option>
                </xsl:for-each>
              </select>
            </td>
          </tr>
          <tr class="rowodd">
            <td class="label"><xsl:value-of select="/cp/strings/domain_csr_country"/></td>
            <td class="contentwidth">
                <input type="test" name="country" size="2" maxlength="2" value="" autocomplete="off" />
                &#160;<span class="parenthetichelp"><xsl:value-of select="/cp/strings/domain_csr_country_instr"/></span>
            </td>
          </tr>
          <tr class="roweven">
            <td class="label"><xsl:value-of select="/cp/strings/domain_csr_state"/></td>
            <td class="contentwidth">
                <input type="text" name="state" size="42" maxlength="64" value="" autocomplete="off" />
                &#160;<span class="parenthetichelp"><xsl:value-of select="/cp/strings/domain_csr_state_instr"/></span>
            </td>
          </tr>
          <tr class="rowodd">
            <td class="label"><xsl:value-of select="/cp/strings/domain_csr_city"/></td>
            <td class="contentwidth">
                <input type="test" name="city" size="42" maxlength="64" value="" autocomplete="off" />
                &#160;<span class="parenthetichelp"><xsl:value-of select="/cp/strings/domain_csr_city_instr"/></span>
            </td>
          </tr>
          <tr class="roweven">
            <td class="label"><xsl:value-of select="/cp/strings/domain_csr_company"/></td>
            <td class="contentwidth">
                <input type="text" name="company" size="42" maxlength="64" value="" autocomplete="off" />
                &#160;<span class="parenthetichelp"><xsl:value-of select="/cp/strings/domain_csr_company_instr"/></span>
            </td>
          </tr>
          <tr class="rowodd">
            <td class="label"><xsl:value-of select="/cp/strings/domain_csr_company_division"/></td>
            <td class="contentwidth">
                <input type="test" name="company_division" size="42" maxlength="64" value="" autocomplete="off" />
                &#160;<span class="parenthetichelp"><xsl:value-of select="/cp/strings/domain_csr_company_division_instr"/></span>
            </td>
          </tr>
          <tr class="roweven">
            <td class="label"><xsl:value-of select="/cp/strings/domain_csr_email"/></td>
            <td class="contentwidth">
                <input type="text" name="email" size="42" maxlength="64" value="" autocomplete="off" />
                &#160;<span class="parenthetichelp"><xsl:value-of select="/cp/strings/domain_csr_email_instr"/></span>
            </td>
          </tr>
          <tr class="controlrow">
            <td colspan="2">
              <span class="floatright">
                <input type="submit" name="btn_save" value="{/cp/strings/domain_csr_btn_save}"
                  onClick="return validateAddCSR(
                    '{cp:js-escape(/cp/strings/domain_csr_js_error_domain)}',
                    '{cp:js-escape(/cp/strings/domain_csr_js_error_country)}',
                    '{cp:js-escape(/cp/strings/domain_csr_js_error_state)}',
                    '{cp:js-escape(/cp/strings/domain_csr_js_error_city)}',
                    '{cp:js-escape(/cp/strings/domain_csr_js_error_company)}',
                    '{cp:js-escape(/cp/strings/domain_csr_js_error_company_division)}',
                    '{cp:js-escape(/cp/strings/domain_csr_js_error_email)}'
                );"/>       
                <input type="button" name="btn_cancel" value="{/cp/strings/domain_csr_btn_cancel}" 
                  onClick="document.forms[0].cancel.value='yes';document.forms[0].submit();" /></span></td>
          </tr>
        </table>
    
    </xsl:otherwise>
  </xsl:choose>
    
  
</xsl:template>
</xsl:stylesheet>

