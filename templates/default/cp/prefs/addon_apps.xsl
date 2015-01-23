<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
  xmlns:exslt="http://exslt.org/common"
  exclude-result-prefixes="exslt">

<xsl:import href="../cp_global.xsl" />

<xsl:template name="oneclick_app">
  <xsl:for-each select="/cp/vsap/vsap[@type='oneclick_app']/app">
    <xsl:variable name="link_text">
      <xsl:choose>
        <xsl:when test="./linktext != ''"><xsl:value-of select="./linktext" /></xsl:when>
        <xsl:otherwise><xsl:value-of select="/cp/strings/oneclick_install_text" /></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name='confirm_install_text'>
      <xsl:value-of select="/cp/strings/oneclick_confirm_text" />
    </xsl:variable>
    <xsl:if test="./app_key != ''">
      <div class="oneclick_obj">
        <xsl:choose>
          <xsl:when test="./checkfile = 'false'">
            <a class="oneclick_icon" href="{$base_url}/cp/prefs/addon_apps_result.xsl?app_key={./app_key}&amp;domain=" onclick="javascript: setDomain( $(this) ); return confirm('{$confirm_install_text}');"><img src="/clientimages/{./icon}" /></a>
          </xsl:when>
          <xsl:otherwise>
            <xsl:choose>
              <xsl:when test="./icon_inactive" >
                <span class="oneclick_icon"><img src="/clientimages/{./icon_inactive}" /></span>
              </xsl:when>
              <xsl:otherwise>
                <span class="oneclick_icon"><img src="/clientimages/{./icon}" /></span>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:choose>
          <xsl:when test="./checkfile = 'false'">
            <a class="oneclick_text" href="{$base_url}/cp/prefs/addon_apps_result.xsl?app_key={./app_key}&amp;domain=" onclick="javascript: setDomain( $(this) ); return confirm('{$confirm_install_text}');"><xsl:value-of select="$link_text" /></a>
          </xsl:when>
          <xsl:otherwise>
            <span class="oneclick_text_off"><xsl:value-of select="$link_text" /></span>
          </xsl:otherwise>
        </xsl:choose>
      </div>
    </xsl:if>
  </xsl:for-each>
</xsl:template>

<xsl:template match="/">

<xsl:call-template name="bodywrapper">

  <xsl:with-param name="title">
    <xsl:copy-of select="/cp/strings/cp_title" /> : <xsl:copy-of select="/cp/strings/oneclick_title" />
  </xsl:with-param>

  <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_one_click" />
  <xsl:with-param name="breadcrumb">
    <breadcrumb>
      <section>
        <name><xsl:copy-of select="/cp/strings/bc_oneclick" /></name>
        <url>#</url>
        <image>Preferences</image>
      </section>
    </breadcrumb>
  </xsl:with-param>

</xsl:call-template>
</xsl:template>

<xsl:template name="content">

    <script language="javascript">
      function setDomain( link ) {
        var dom;
        var newHref;
        
        if ( $( '#endUserDomain' ).length ) {
          dom = $( '#endUserDomain' ).val();
        }
        else {
          dom = $( '#domainSelect :selected' ).val();
        }
        
        newHref = link.attr( 'href' ).replace( /domain=.?/, 'domain=' + dom );
        link.attr( 'href', newHref );
      }
    </script>
    
    <table class="formview" border="0" cellspacing="0" cellpadding="0">
      <tr class="title">
        <td colspan="2"><xsl:copy-of select="/cp/strings/oneclick_title" /></td>
      </tr>
      <tr class="instructionrow">
        <td colspan="2">
          <xsl:value-of select="/cp/strings/oneclick_instr"/>
          <br />
          
          <xsl:choose>
            <xsl:when test="/cp/vsap/vsap[@type='auth']/server_admin or /cp/vsap/vsap[@type='auth']/domain_admin">
              <select id="domainSelect" name="domain" style="margin: 5px 0px;" onclick="">
                <option value=""><xsl:value-of select="/cp/strings/oneclick_select_domain"/></option>
                <xsl:for-each select="/cp/vsap/vsap[@type='domain:list']/domain">
                  <option value="{name}"><xsl:if test="/cp/form/domain=name"><xsl:attribute name="selected"/></xsl:if>
                  <xsl:value-of select="name"/></option>
                </xsl:for-each>
              </select>
            </xsl:when>
            <xsl:otherwise>
              <xsl:variable name="userDom">
                <xsl:value-of select="/cp/vsap/vsap[@type='user:list']/user/domain" />
              </xsl:variable>
              <input id="endUserDomain" type="hidden" value="{$userDom}" />
            </xsl:otherwise>
          </xsl:choose>
          
        </td>
      </tr>
      <tr class="roweven">
        <td colspan="2" class="contentwidth">
          <xsl:call-template name="oneclick_app" />
        </td>
      </tr>
    </table>


</xsl:template>
</xsl:stylesheet>

