<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:import href="../global.xsl" />

  <!-- This will tell the global template which app we are in -->
  <xsl:variable name="app_name">error</xsl:variable>

  <!-- This will build the "navandcontent" menu for the error section -->
  <xsl:variable name="navandcontent_items">
    <menu_items>
      <menu id="errornav" name="{/cp/strings/nv_menu_error}">
        <item href="{$base_url}/cp/"><xsl:value-of select="/cp/strings/gn_bt_controlpanel" /></item>
        <xsl:if test="$mail_ok='1'">
          <item href="{$base_url}/mail/"><xsl:value-of select="/cp/strings/gn_bt_mail" /></item>
        </xsl:if>
      </menu>
    </menu_items>
  </xsl:variable>

</xsl:stylesheet>
