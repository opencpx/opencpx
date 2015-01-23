<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
  xmlns:exslt="http://exslt.org/common"
  exclude-result-prefixes="exslt">

<xsl:import href="../cp_global.xsl" />

<xsl:variable name="message">
  <xsl:choose>
    <xsl:when test="/cp/msgs/msg[@name='domain_self_signed_cert_success']">
      <xsl:copy-of select="/cp/strings/domain_self_signed_cert_success" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='domain_cert_error_permission_denied']">
      <xsl:copy-of select="/cp/strings/domain_cert_error_permission_denied" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='domain_cert_error_domain_missing']">
      <xsl:copy-of select="/cp/strings/domain_cert_error_domain_missing" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='domain_cert_error_openssl_failed']">
      <xsl:copy-of select="/cp/strings/domain_cert_error_openssl_failed" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='domain_cert_error_csr_file']">
      <xsl:copy-of select="/cp/strings/domain_cert_error_csr_file" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='domain_cert_error_cert_file']">
      <xsl:copy-of select="/cp/strings/domain_cert_error_cert_file" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='domain_cert_error_docroot_missing']">
      <xsl:copy-of select="/cp/strings/domain_cert_error_docroot_missing" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='domain_cert_error_validation_url']">
      <xsl:copy-of select="/cp/strings/domain_cert_error_validation_url" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='domain_cert_error_restart_service_failed']">
      <xsl:copy-of select="/cp/strings/domain_cert_error_restart_service_failed" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='domain_cert_error_uninstall_inuse']">
      <xsl:copy-of select="/cp/strings/domain_cert_error_uninstall_inuse" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='domain_cert_error_unknown_error']">
      <xsl:copy-of select="/cp/strings/domain_cert_error_unknown_error" />
    </xsl:when>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="feedback">
  <xsl:if test="$message != ''">
    <xsl:call-template name="feedback_table">
      <xsl:with-param name="image">
        <xsl:choose>
          <xsl:when test="/cp/vsap/vsap[@type='error']">error</xsl:when>
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
    <xsl:copy-of select="/cp/strings/cp_title" /> : <xsl:copy-of select="/cp/strings/cp_title_domain_create_selfcert" />
  </xsl:with-param>

  <xsl:with-param name="formaction">domain_self_signed_cert.xsl</xsl:with-param>
  <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_self_signed_cert" />
  <xsl:with-param name="help_short" select="/cp/strings/domains_selfcert_help_short" />
  <xsl:with-param name="help_long" select="/cp/strings/domains_selfcert_help_long" />
  <xsl:with-param name="feedback" select="$feedback" />
  <xsl:with-param name="breadcrumb">
    <breadcrumb>
      <section>
        <name><xsl:copy-of select="/cp/strings/bc_domain_selfcert" /></name>
        <url><xsl:value-of select="$base_url" />/cp/domains/domain_self_signed_cert.xsl</url>
        <image>Profile</image>
      </section>
      <section>
        <name><xsl:copy-of select="/cp/strings/bc_domain_selfcert" /></name>
        <url>#</url>
        <image>DomainManagement</image>
      </section>
    </breadcrumb>
  </xsl:with-param>

</xsl:call-template>
</xsl:template>

<xsl:template name="content">

        <script src="{concat($base_url, '/cp/cp.js')}" language="JavaScript"></script>

        <input type="hidden" name="save" value="" />     
        <input type="hidden" name="cancel" value="" />
        <input type="hidden" name="self" value="1" />          

        <table class="formview" border="0" cellspacing="0" cellpadding="0">
          <tr class="title">
            <td colspan="2"><xsl:copy-of select="/cp/strings/domain_selfcert_title" /></td>
          </tr>
          <tr class="instructionrow">
            <td colspan="2"><xsl:value-of select="/cp/strings/domain_selfcert_instr"/></td>
          </tr>
          <tr class="roweven">
            <td class="label"><xsl:value-of select="/cp/strings/domain_selfcert_domain"/></td>
            <td class="contentwidth">
              <select name="domain">
                <xsl:if test="string(/cp/form/domain)=''">
                  <option value=""><xsl:value-of select="/cp/strings/domain_selfcert_select"/></option>
                </xsl:if>
                <xsl:for-each select="/cp/vsap/vsap[@type='domain:list']/domain">
                  <option value="{name}"><xsl:if test="/cp/form/domain=name"><xsl:attribute name="selected"/></xsl:if>
                  <xsl:value-of select="name"/></option>
                </xsl:for-each>
              </select>
            </td>
          </tr>
          <tr class="rowodd">
            <td class="label"><xsl:value-of select="/cp/strings/domain_selfcert_applyto"/></td>
            <td class="contentwidth">
                <input type="checkbox" name="applyto_apache" value="apache" id="applyto_postfix" checked="checked"/>&#160;<xsl:value-of select="/cp/strings/domain_selfcert_applyto_apache"/>
                <br/>
                <input type="checkbox" name="applyto_dovecot" value="dovecot" id="applyto_postfix" checked="checked" />&#160;<xsl:value-of select="/cp/strings/domain_selfcert_applyto_dovecot"/>
                <br/>
                <input type="checkbox" name="applyto_postfix" value="applyto_postfix" id="applyto_postfix" checked="checked" />&#160;<xsl:value-of select="/cp/strings/domain_selfcert_applyto_postfix"/>
                <br/>
                <input type="checkbox" name="applyto_vsftpd" value="applyto_vsftpd" id="applyto_postfix" checked="checked" />&#160;<xsl:value-of select="/cp/strings/domain_selfcert_applyto_vsftpd"/>
            </td>
          </tr>
          <tr class="roweven">
            <td class="label" style="text-align:right;"><input type="checkbox" name="understand" /></td>
            <td class="contentwidth">
                &#160;<xsl:value-of select="/cp/strings/domain_selfcert_understand"/>
            </td>
          </tr>
          <tr class="controlrow">
            <td colspan="2">
              <span class="floatright">
                <input type="submit" name="btn_save" value="{/cp/strings/domain_selfcert_btn_save}" 
                  onClick="return validateCertForm(
                    '{cp:js-escape(/cp/strings/domain_selfcert_js_error_domain)}',
                    '{cp:js-escape(/cp/strings/domain_selfcert_js_error_applied)}',
                    '{cp:js-escape(/cp/strings/domain_selfcert_js_error_understand)}',
                    '{cp:js-escape(/cp/strings/domain_selfcert_js_confirmation)}'
                );"/>       
                <input type="button" name="btn_cancel" value="{/cp/strings/domain_selfcert_btn_cancel}" 
                  onClick="document.forms[0].cancel.value='yes';document.forms[0].submit();" /></span></td>
          </tr>
        </table>

</xsl:template>
</xsl:stylesheet>

