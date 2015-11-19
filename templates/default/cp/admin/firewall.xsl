<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../cp_global.xsl" />

<xsl:variable name="message">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='error'] and string(/cp/form/btnSave)">
      <xsl:value-of select="/cp/strings/firewall_update_failure"/>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='error']">
      <xsl:value-of select="/cp/strings/firewall_get_failure"/>
    </xsl:when>
    <xsl:when test="string(/cp/form/btnSave)">
      <xsl:value-of select="/cp/strings/firewall_update_successful"/>
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

<xsl:variable name="firewall_level" select="/cp/vsap/vsap[@type='sys:firewall:get']/level"/>
<xsl:variable name="firewall_type" select="/cp/vsap/vsap[@type='sys:firewall:get']/type"/>
<xsl:variable name="firewall_rule_limit" select="/cp/vsap/vsap[@type='sys:firewall:get']/rules/limit"/>
<xsl:variable name="firewall_rule_count_low" select="/cp/vsap/vsap[@type='sys:firewall:get']/rules/low"/>
<xsl:variable name="firewall_rule_count_medium" select="/cp/vsap/vsap[@type='sys:firewall:get']/rules/medium"/>
<xsl:variable name="firewall_rule_count_high" select="/cp/vsap/vsap[@type='sys:firewall:get']/rules/high"/>

<xsl:template match="/">
  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title">
      <xsl:copy-of select="/cp/strings/cp_title" />
      v<xsl:value-of select="/cp/vsap/vsap[@type='auth']/version" /> :
      <xsl:copy-of select="/cp/strings/bc_system_admin_firewall" />
    </xsl:with-param>
    <xsl:with-param name="formaction">firewall.xsl</xsl:with-param>
    <xsl:with-param name="feedback" select="$feedback" />
    <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_admin_set_firewall" />
    <xsl:with-param name="help_short" select="/cp/strings/system_admin_hlp_short" />
    <xsl:with-param name="help_long"><xsl:copy-of select="/cp/strings/system_admin_hlp_long" /></xsl:with-param>
    <xsl:with-param name="breadcrumb">
      <breadcrumb>
        <section>
          <name><xsl:copy-of select="/cp/strings/bc_system_admin_firewall" /></name>
          <url>#</url>
          <image>SystemAdministration</image>
        </section>
      </breadcrumb>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

  <script src="{concat($base_url, '/cp/cp.js')}" language="JavaScript"></script>

  <table class="formview" border="0" cellspacing="0" cellpadding="0">
    <tr class="title">
      <td colspan="2"><xsl:copy-of select="/cp/strings/server_firewall_set" /></td>
    </tr>
    <tr class="instructionrow">
      <td colspan="2"><xsl:copy-of select="/cp/strings/server_firewall_info" /></td>
    </tr>
    <tr class="rowodd">
      <td class="label"><xsl:copy-of select="/cp/strings/server_firewall_level" /></td>
      <td class="contentwidth">

        <input type="radio" id="firewall_level_off" name="firewall_level" value="0" onClick="setFirewallSwitches(this);" border="0">
          <xsl:if test="$firewall_level = '0'">
            <xsl:attribute name="checked" value="checked"/>
          </xsl:if>
        </input><label for="firewall_level_off"><xsl:value-of select="/cp/strings/server_firewall_level_off"/></label><br />

        <xsl:if test="$firewall_rule_limit='0' or $firewall_rule_limit >= $firewall_rule_count_low">
          <input type="radio" id="firewall_level_low" name="firewall_level" value="1" onClick="setFirewallSwitches(this);" border="0">
            <xsl:if test="$firewall_level = '1'">
              <xsl:attribute name="checked" value="checked"/>
            </xsl:if>
          </input><label for="firewall_level_low"><xsl:value-of select="/cp/strings/server_firewall_level_low"/></label><br />
        </xsl:if>

        <xsl:if test="$firewall_rule_limit='0' or $firewall_rule_limit >= $firewall_rule_count_medium">
          <input type="radio" id="firewall_level_medium" name="firewall_level" value="2" onClick="setFirewallSwitches(this);" border="0">
            <xsl:if test="$firewall_level = '2'">
              <xsl:attribute name="checked" value="checked"/>
            </xsl:if>
          </input><label for="firewall_level_medium"><xsl:value-of select="/cp/strings/server_firewall_level_medium"/></label><br />
        </xsl:if>

        <xsl:if test="$firewall_rule_limit='0' or $firewall_rule_limit >= $firewall_rule_count_high">
          <input type="radio" id="firewall_level_high" name="firewall_level" value="3" onClick="setFirewallSwitches(this);" border="0">
            <xsl:if test="$firewall_level = '3'">
              <xsl:attribute name="checked" value="checked"/>
            </xsl:if>
          </input><label for="firewall_level_high"><xsl:value-of select="/cp/strings/server_firewall_level_high"/></label><br />
        </xsl:if>

      </td>
    </tr>

    <xsl:if test="$firewall_rule_limit='0' or $firewall_rule_limit >= $firewall_rule_count_medium or $firewall_rule_limit >= $firewall_rule_count_high">
      <tr class="roweven">
        <td class="label"><xsl:copy-of select="/cp/strings/server_firewall_type" /></td>
        <td class="contentwidth"><xsl:value-of select="/cp/strings/server_firewall_type_desc"/><br />

          <input type="radio" id="allow_mail_and_web" name="firewall_type" value="" border="0">
            <xsl:if test="$firewall_type = ''">
              <xsl:attribute name="checked" value="checked"/>
            </xsl:if>
            <xsl:if test="$firewall_level &lt; '2'">
              <xsl:attribute name="disabled" value="disabled"/>
            </xsl:if>
          </input><label for="allow_mail_and_web"><xsl:value-of select="/cp/strings/server_firewall_type_none"/></label><br />
<!--
          <input type="radio" id="mail_only" name="firewall_type" value="m" border="0">
            <xsl:if test="$firewall_type = 'm'">
              <xsl:attribute name="checked" value="checked"/>
            </xsl:if>
            <xsl:if test="$firewall_level &lt; '2'">
              <xsl:attribute name="disabled" value="disabled"/>
            </xsl:if>
          </input><label for="mail_only"><xsl:value-of select="/cp/strings/server_firewall_type_mail"/></label><br />
-->
          <input type="radio" id="web_only" name="firewall_type" value="w" border="0">
            <xsl:if test="$firewall_type = 'w'">
              <xsl:attribute name="checked" value="checked"/>
            </xsl:if>
            <xsl:if test="$firewall_level &lt; '2'">
              <xsl:attribute name="disabled" value="disabled"/>
            </xsl:if>
          </input><label for="web_only"><xsl:value-of select="/cp/strings/server_firewall_type_web"/></label><br />

        </td>
      </tr>
    </xsl:if>

    <tr class="controlrow">
      <td colspan="2"><input class="floatright" type="submit" name="btnCancel" value="{/cp/strings/server_firewall_btn_cancel}"/><input class="floatright" type="submit" name="btnSave" value="{/cp/strings/server_firewall_btn_save}" /></td>
    </tr>
  </table>

  <xsl:if test="/cp/vsap/vsap[@type='auth']/siteprefs/disable-firewall">
    <script type="text/javascript" language="javascript">
        for (i=0; i&lt;document.forms[0].elements.length; i++) {
            document.forms[0].elements[i].disabled = true; 
        }
    </script>
  </xsl:if>


</xsl:template>

</xsl:stylesheet>
