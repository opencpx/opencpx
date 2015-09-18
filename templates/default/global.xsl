<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exslt="http://exslt.org/common"
  xmlns:func="http://exslt.org/functions"
  xmlns:cp="vsap:cp"
  xmlns:str="http://exslt.org/strings"
  extension-element-prefixes="func str"
  exclude-result-prefixes="exslt cp">

  <xsl:output
    method="html"
    indent="yes"
    encoding="utf-8"
    doctype-public="-//W3C//DTD XHTML 1.0 Transitional//EN"
    doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"
    omit-xml-declaration="no"
  />

  <!-- global variables -->
    <xsl:variable name="base_url">/ControlPanel</xsl:variable>

    <xsl:variable name="user_type">
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='auth']/server_admin">sa</xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='auth']/domain_admin">da</xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='auth']/mail_admin">ma</xsl:when>
        <xsl:otherwise>eu</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="fileman_ok">
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='auth']/services/fileman">1</xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="shell_ok">
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='auth']/siteprefs/disable-shell">0</xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='auth']/services/shell">1</xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="mail_ok">
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='auth']/services/mail">1</xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="podcast_ok">
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='auth']/siteprefs/disable-podcast">0</xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='auth']/services/podcast">1</xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="clamav_package">
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='auth']/siteprefs/disable-clamav">0</xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='auth']/packages/mail-clamav">1</xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="spamassassin_package">
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='auth']/siteprefs/disable-spamassassin">0</xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='auth']/packages/mail-spamassassin">1</xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="webmail_package">
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='auth']/siteprefs/disable-webmail">0</xsl:when>
        <xsl:otherwise>1</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="enhanced_webmail_installed">
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='domain:enhanced_webmail']/installed = 1">1</xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="disable_enhanced_webmail">
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='auth']/siteprefs/disable-enhanced-webmail">1</xsl:when>
        <xsl:otherwise>0</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    
    <!-- 
      Look to see if a Default category or topic has been specified for this pages
      Help link.
    -->
    <xsl:variable name="suggested_help_topic">
          <xsl:value-of select="/cp/strings/help_defaults/entry/page[.=/cp/request/filename]/preceding-sibling::topic" />
    </xsl:variable>

    <xsl:variable name="suggested_help_category">
        <xsl:value-of select="/cp/strings/help_defaults/entry/page[.=/cp/request/filename]/preceding-sibling::category" />
    </xsl:variable>

    <!-- 
      A redirect after login usually will produce a blank topic and blank category
      because the path doesn't match, so we set an appropriate default value here.
      Note: other redirects create similar problems.  :|
    -->
    <xsl:variable name="help_default_topic">
      <xsl:choose>
          <xsl:when test="$suggested_help_topic='' and $suggested_help_category=''">
              <xsl:choose>
                  <xsl:when test="$user_type = 'sa'">h_sa_managing_your_services</xsl:when>
                  <xsl:when test="$user_type = 'da'">h_um_view_user_list</xsl:when>
                  <xsl:when test="$user_type = 'ma'">h_mm_email_addresses</xsl:when>
                  <xsl:otherwise>h_pro_view_profile</xsl:otherwise>
              </xsl:choose>
          </xsl:when>
          <xsl:when test="$suggested_help_topic='h_um_add_USER_TYPE'">
              <xsl:choose>
                  <xsl:when test="/cp/form/type = 'da'">h_um_add_domain_admin</xsl:when>
                  <xsl:when test="/cp/form/type = 'ma'">h_um_add_mail_admin</xsl:when>
                  <xsl:when test="/cp/form/type = 'eu'">h_um_add_end_user</xsl:when>
                  <xsl:otherwise>h_pro_view_profile</xsl:otherwise>
              </xsl:choose>
          </xsl:when>
          <xsl:otherwise>
              <xsl:value-of select="$suggested_help_topic" />
          </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="help_default_category">
      <xsl:choose>
          <xsl:when test="$suggested_help_category='' and $suggested_help_topic=''">
              <xsl:choose>
                  <xsl:when test="$user_type = 'sa'">system_administration</xsl:when>
                  <xsl:when test="$user_type = 'da'">user_management</xsl:when>
                  <xsl:when test="$user_type = 'ma'">mail_management</xsl:when>
                  <xsl:otherwise>my_profile</xsl:otherwise>
              </xsl:choose>
          </xsl:when>
          <xsl:otherwise>
              <xsl:value-of select="$suggested_help_category" />
          </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- set the NEW user help link -->
    <xsl:variable name="help_link">javascript:new_help_window( "<xsl:value-of select='$help_default_category'/>", "<xsl:value-of select='$help_default_topic'/>" )</xsl:variable> 



  <!-- templates start here -->

  <xsl:template name="feedback_table">
    <xsl:param name="image" />
    <xsl:param name="message" />
    <xsl:param name="message2" />
    <xsl:param name="message3" />

    <xsl:variable name="image_src">
      <xsl:choose>
        <xsl:when test="$image = 'success'">
          <xsl:value-of select="/cp/strings/img_success" />
        </xsl:when>
        <xsl:when test="$image = 'error'">
          <xsl:value-of select="/cp/strings/img_error" />
        </xsl:when>
        <xsl:when test="$image = 'alert'">
          <xsl:value-of select="/cp/strings/img_alert" />
        </xsl:when>
        <xsl:when test="$image = 'message'">
          <xsl:value-of select="/cp/strings/img_message" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="/cp/strings/img_error" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <table id="feedback" border="0" cellspacing="0" cellpadding="0">
      <tr>
        <td width="40"><img align="right" src="{$image_src}" alt="" border="0" /></td>
        <td><xsl:copy-of select="$message" /></td>
      </tr>
      <xsl:if test="string-length($message2)">
        <tr>
          <td width="40"> </td>
          <td><xsl:copy-of select="$message2" /></td>
        </tr>
      </xsl:if>
      <xsl:if test="string-length($message3)">
        <tr>
          <td width="40"> </td>
          <td><xsl:copy-of select="$message3" /></td>
        </tr>
      </xsl:if>
    </table>
  </xsl:template>

  <xsl:template name="help_table">
    <xsl:param name="help_short" />
    <xsl:param name="help_long" />

    <table border="0" cellspacing="0" cellpadding="0">
      <xsl:attribute name="class">
        <xsl:choose>
          <!-- If there is no help for a page help_short should be blank, and the
               help table will be hidden  -->
          <xsl:when test="$help_short = ''">hide</xsl:when>
          <xsl:otherwise>help</xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <tr>
        <td class="icon"><br /></td>
        <!-- The &#160; makes sure there is something inside the td. If it is blank, IE will not be able to find the text node -->
        <td id="addl_help_text"><xsl:copy-of select="$help_short" />&#160;</td>
        <td class="arrow"
          onClick="help_info('{cp:js-escape(/cp/strings/img_hlp_up)}','{cp:js-escape(/cp/strings/img_hlp_down)}')">
          <img id="addl_help_image" src="{/cp/strings/img_hlp_down}" alt="" border="0" />
        </td>
      </tr>
    </table>
    <div class="hide" id="help_short"><xsl:copy-of select="$help_short" />&#160;</div>
    <div class="hide" id="help_long"><xsl:copy-of select="$help_long" />&#160;</div>
  </xsl:template>

  <!-- ###### Custom Navigation Template ##########  -->
  <xsl:template name="customnav">
    <xsl:for-each select="/cp/vsap/vsap[@type='customnav']/url">
      <xsl:variable name="custom_query">
        <xsl:for-each select="./parameter"><xsl:if test="position() != 1">&amp;</xsl:if><xsl:value-of select="@name" />=<xsl:value-of select="@value" /></xsl:for-each>
      </xsl:variable>
      <span>
        <a class="customnavlink" href="javascript:customNav('{$base_url}','{./url_key}','{./location}','{$custom_query}');"><xsl:value-of select="./label" /></a>
      </span>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="customFrameLabels">
<script language="JavaScript">
var customFrameLabels = {
    <xsl:for-each select="/cp/vsap/vsap[@type='customnav']/url">
      <xsl:variable name="custom_query_string">
        <xsl:for-each select="./parameter"><xsl:if test="position() != 1">&amp;</xsl:if><xsl:value-of select="@name" />=<xsl:value-of select="@value" /></xsl:for-each>
      </xsl:variable>
      <xsl:value-of select="./url_key" />:'<xsl:value-of select="./location" /><xsl:if test="$custom_query_string != ''">?</xsl:if><xsl:copy-of select="$custom_query_string" />'<xsl:if test="position() != last()">,</xsl:if>
    </xsl:for-each>
};
</script>
  </xsl:template>
  <!-- ###### Custom Navigation Template End #####  -->

  <xsl:template name="navandcontent">
    <xsl:param name="menu_items" />
    <xsl:param name="current_page" />

    <!-- convert the menu_items param into a node set -->
    <xsl:variable name="xmenu_items" select="exslt:node-set($menu_items)" />

    <xsl:for-each select="$xmenu_items/menu_items/menu">
      <table id="{@id}" border="0" cellspacing="0" cellpadding="0">
        <tr>
          <xsl:attribute name="class">
            <xsl:choose>
              <xsl:when test="./item = $current_page">title active</xsl:when>
              <xsl:otherwise>title</xsl:otherwise>
            </xsl:choose>
          </xsl:attribute>
          <xsl:if test="@id = 'custom_side_nav'">
            <xsl:attribute name="id">titleCustomSideNavTR</xsl:attribute>
          </xsl:if>
          <td>
            <xsl:choose>
              <xsl:when test="@id = 'custom_side_nav'">
                <span id="titleCustomSideNav"><xsl:value-of select="@name" /></span>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="@name" />
              </xsl:otherwise>
            </xsl:choose>
          </td>
        </tr>

        <xsl:for-each select="./item">

          <xsl:variable name="customNavType">
            <xsl:choose>
              <xsl:when test="contains(@href,'javascript:customNav')">customSideNavLink</xsl:when>
              <xsl:otherwise></xsl:otherwise>
            </xsl:choose>
          </xsl:variable>

          <xsl:variable name="customNavId">
            <xsl:choose>
              <xsl:when test="$customNavType = 'customSideNavLink'">custNav_<xsl:value-of select="@customNavLabel" /></xsl:when>
              <xsl:otherwise></xsl:otherwise>
            </xsl:choose>
          </xsl:variable>

          <tr>
            <td>
              <a href="{@href}">
                <xsl:attribute name="class">
                  <xsl:choose>
                    <xsl:when test="$customNavType = 'customSideNavLink'">custSideNavLabelOff</xsl:when>
                    <xsl:otherwise>
                      <xsl:choose>
                        <xsl:when test=". = $current_page">on</xsl:when>
                        <xsl:otherwise>off</xsl:otherwise>
                      </xsl:choose>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:attribute>
                <xsl:if test="$customNavId != ''">
                  <xsl:attribute name="id">
                    <xsl:value-of select="$customNavId" />
                  </xsl:attribute>
                </xsl:if>
                <xsl:value-of select="." />
              </a>
            </td>
          </tr>
        </xsl:for-each>
      </table>
    </xsl:for-each>
  </xsl:template>

  <!-- this is the new and improved breadcrumb builder -->
  <!-- <breadcrumb>
       <section>
         <name>Section Name</name>
         <url>/ControlPanel/section/index.xsl</url>
         <image>Image Name</image>
       </section>
       ...
     </breadcrumb>
  -->
  <xsl:template name="breadcrumb">
    <xsl:param name="breadcrumb" />

    <xsl:variable name="xtabs" select="exslt:node-set($breadcrumb)" />

    <xsl:for-each select="$xtabs/breadcrumb/section">
    
        <xsl:variable name="sectSpaceName">
                 <xsl:value-of select="../section[1]/name" />
        </xsl:variable>
        
        <xsl:variable name="sectSlashName">
                 <xsl:value-of select="translate(normalize-space($sectSpaceName),'/','')"/>
        </xsl:variable>
        
        <xsl:variable name="sectPreName">
                 <xsl:value-of select="translate(normalize-space($sectSlashName),':','')"/>
        </xsl:variable>
        
        <xsl:variable name="sectName">
                 <xsl:value-of select="translate(normalize-space($sectPreName),' ','')"/>
        </xsl:variable>
        
      <xsl:choose>
        <xsl:when test="position() = last()">
          <xsl:choose>
            <xsl:when test="./image">
              <xsl:variable name="sectImage"><xsl:value-of select="./image" /></xsl:variable>
              <img src="/cpimages/{$sectImage}.png" alt="{$sectSpaceName}" id="{$sectName}Img" />
              <strong><xsl:value-of select="./name" /></strong>
            </xsl:when>
            <xsl:otherwise>
              <img src="/cpimages/{$sectName}.png" alt="{$sectSpaceName}" id="{$sectName}Img" />
              <strong><xsl:value-of select="./name" /></strong>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:when>
        <xsl:otherwise>
        </xsl:otherwise>
      </xsl:choose>

    </xsl:for-each>
  </xsl:template>

  <xsl:template name="bodywrapper">
    <xsl:param name="title" />
    <xsl:param name="formaction" />
    <xsl:param name="formenctype">application/x-www-form-urlencoded</xsl:param>
    <xsl:param name="script" />
    <xsl:param name="formname">globalnav</xsl:param>
    <xsl:param name="onload" />
    <xsl:param name="onunload" />
    <xsl:param name="onsubmit" />
    <xsl:param name="feedback" />
    <xsl:param name="help_short" />
    <xsl:param name="help_long" />
    <xsl:param name="selected_navandcontent" />
    <xsl:param name="breadcrumb" />

    <!-- css style names -->
    <xsl:variable name="navbg">navbg<xsl:value-of select="$app_name" /></xsl:variable>
    <xsl:variable name="contentbg">contentbg<xsl:value-of select="$app_name" /></xsl:variable>
    <xsl:variable name="header">header<xsl:value-of select="$app_name" /></xsl:variable>

    <!-- restart apache required? -->
    <xsl:variable name="restartapache">
      <xsl:if test="/cp/vsap/vsap/need_apache_restart">
        <xsl:if test="string($onload)">; </xsl:if>
        <script language="JavaScript">restartApache('<xsl:value-of select="/cp/strings/restart_apache_required"/>', '<xsl:value-of select="$base_url"/>/restart_apache.xsl')</script>
      </xsl:if>
    </xsl:variable>

    <!-- here's the actual page -->
    <html xmlns="http://www.w3.org/1999/xhtml">
      <head>
        <meta http-equiv="content-type" content="text/html;charset=UTF-8" />
        <title><xsl:value-of select="$title" /> v<xsl:value-of select="/cp/vsap/vsap[@type='auth']/release" /></title>
        <link href="{/cp/strings/stylesheet}" type="text/css" rel="stylesheet" media="screen" />
      </head>

      <body onBeforeUnload="{$onunload}" onLoad="{$onload}{$restartapache}">
        <script src="{concat($base_url, '/jquery-1.9.1.min.js')}" language="JavaScript" type="text/javascript" ></script>
        <script src="{concat($base_url, '/allfunctions.js')}" language="JavaScript"></script>
        <script src="{concat($base_url, '/cp/custom_frame.js')}" language="JavaScript"></script>
        <xsl:call-template name="customFrameLabels" />
        
        <xsl:if test="string-length($script)">
          <script language="JavaScript">
            <xsl:value-of select="$script" />
          </script>
        </xsl:if>

        <form name="{$formname}" action="{$formaction}" method="post" enctype="{$formenctype}" onSubmit="{$onsubmit}">

          <xsl:if test="/cp/vsap/vsap[@type='auth']/siteprefs/enable-debug">
            <!-- Header table for build info -->
            <table id="headerdebug" width="100%" border="0" cellspacing="0" cellpadding="0">
              <tr>
                 <td>
                   ####
                   <xsl:value-of select="/cp/strings/cp_title"/>
                   v<xsl:value-of select="/cp/vsap/vsap[@type='auth']/release" />, 
                   build <xsl:value-of select="/cp/vsap/vsap[@type='auth']/build" />
                   ####
                 </td>
              </tr>
            </table>
          </xsl:if>

          <!-- Header table for logo -->
          <table id="{$header}" width="100%" border="0" cellspacing="0" cellpadding="0">
            <tr>
               <td><a href="{$base_url}/cp/" title="Home"><img src="/cpimages/61logo.gif" alt="Control Panel" id="logoImg"/></a></td>
            </tr>
          </table>

            <!-- note: preserving mispelled 'gauge' (guage) for historical reasons -->
            <xsl:variable name="guage_help_raw">
              <xsl:choose>
                <xsl:when test="$user_type = 'sa'">
                  <xsl:value-of select="/cp/strings/guage_help_sa"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="/cp/strings/guage_help_other"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <xsl:variable name="allocated">
                <xsl:value-of select="/cp/vsap/vsap[@type='diskspace']/allocated" />
                <xsl:choose>
                  <xsl:when test="/cp/vsap/vsap[@type='diskspace']/units = 'GB'">
                    <xsl:value-of select="/cp/strings/gb" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="/cp/strings/mb" />
                  </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="usage">
                <xsl:value-of select="/cp/vsap/vsap[@type='diskspace']/percent" />
                <xsl:value-of select="/cp/strings/guage_percent" />
            </xsl:variable>
            <xsl:variable name="guage_help_temp">
              <xsl:call-template name="transliterate">
                <xsl:with-param name="string" select="$guage_help_raw"/>
                <xsl:with-param name="search">__TOTAL__</xsl:with-param>
                <xsl:with-param name="replace" select="$allocated"/>
              </xsl:call-template>
            </xsl:variable>
            <xsl:variable name="guage_help">
              <xsl:call-template name="transliterate">
                <xsl:with-param name="string" select="$guage_help_temp"/>
                <xsl:with-param name="search">__USAGE__</xsl:with-param>
                <xsl:with-param name="replace" select="$usage"/>
              </xsl:call-template>
            </xsl:variable>          
        <xsl:if test="/cp/vsap/vsap[@type='diskspace']/allocated != 0">
          <div id="userInfo">
                <table id="gauge">
                        <tr>
                          <td id="gaugeLeft" align="right" style="width:{/cp/vsap/vsap[@type='diskspace']/percent}px"><a onClick="return false" onMouseOver="window.status='{$guage_help}'; return true" onMouseOut="window.status=''; return true" title="{$guage_help}" href="#">.</a></td>
                          <td id="gaugeRight" style="width:{100 - /cp/vsap/vsap[@type='diskspace']/percent}px"><a onClick="return false" onMouseOver="window.status='{$guage_help}'; return true" onMouseOut="window.status=''; return true" title="{$guage_help}" href="#">.</a></td>
                        </tr>
                </table>                      
                <!-- xx% of [xxMB|xx.xGB] Used -->
                      <a onClick="return false" onMouseOver="window.status='{$guage_help}'; return true" onMouseOut="window.status=''; return true" title="{$guage_help}" href="#">
                      <strong>
                        <xsl:copy-of select="$usage"/>
                      </strong>
                      <xsl:value-of select="/cp/strings/guage_of" />
                      <strong>
                        <xsl:copy-of select="$allocated"/>
                      </strong>
                      <xsl:value-of select="/cp/strings/guage_used" /></a>
          </div> 
        </xsl:if>
          <!-- Global navigation table -->
          <table id="globalnav" border="0" cellspacing="0" cellpadding="0">
            <tr>
              <td>

              </td>
              <td>
                <xsl:choose>
                  <xsl:when test="$app_name = 'help' or $app_name = 'error'">
                  </xsl:when>
                  <xsl:otherwise>
                                <table border="0" cellspacing="0" cellpadding="0">
                                  <tr>
                                    <td id="controlpanel">
                                      <a href="{$base_url}/cp/index.xsl">
                                        <xsl:attribute name="class">
                                          <xsl:choose>
                                            <xsl:when test="$app_name = 'controlpanel'">on</xsl:when>
                                            <xsl:otherwise>off</xsl:otherwise>
                                          </xsl:choose>
                                        </xsl:attribute>
                                        <xsl:value-of select="/cp/strings/gn_bt_controlpanel" />
                                      </a>
                                    </td>
                                    <xsl:if test="$mail_ok='1'">
                                      <td id="mail">
                                        <a href="{$base_url}/mail/index.xsl">
                                          <xsl:attribute name="class">
                                            <xsl:choose>
                                              <xsl:when test="$app_name = 'mail'">on</xsl:when>
                                              <xsl:otherwise>off</xsl:otherwise>
                                            </xsl:choose>
                                          </xsl:attribute>
                                          <xsl:value-of select="/cp/strings/gn_bt_mail" />
                                        </a>
                                      </td>
                                    </xsl:if>
                                  </tr>
                                </table>
                  </xsl:otherwise>
                </xsl:choose>
              </td>
              <td>
                <xsl:choose>
                  <xsl:when test="$app_name = 'help' or $app_name = 'error'">
                  </xsl:when>
                  <xsl:otherwise>
                                <table class="floatright" border="0" cellspacing="0" cellpadding="0">
                                  <tr>
                                    <xsl:if test="not(/cp/vsap/vsap[@type='auth']/siteprefs/disable-help)">
                                      <td id="help"><a class="off" href="{$help_link}"><xsl:value-of select="/cp/strings/gn_bt_help" /></a></td>
                                    </xsl:if>
                                    <td id="logout"><a class="off" href="{concat($base_url, '/index.xsl?logout=true')}"><xsl:value-of select="/cp/strings/gn_bt_logout" /></a></td>
                                  </tr>
                                </table>
                  </xsl:otherwise>
                </xsl:choose>

              </td>
            </tr>
          </table>
          
          <!-- ################ Custom Navigation Links #################### -->
          <xsl:if test="/cp/vsap/vsap[@type='auth']/product = 'cloud' and /cp/vsap/vsap[@type='auth']/siteprefs/custom-topnav">
            <xsl:variable name="customnav_links">
              <xsl:choose>
                <xsl:when test="/cp/vsap/vsap[@type='customnav']/url">1</xsl:when>
                <xsl:otherwise>0</xsl:otherwise>
              </xsl:choose>
            </xsl:variable>

            <xsl:choose>
              <xsl:when test="$app_name = 'help' or $app_name = 'error' or $customnav_links = 0">
              </xsl:when>
              <xsl:otherwise>
                <table id="customnav">
                  <tr>
                    <td width="939">
                      <xsl:call-template name="customnav" />
                    </td>
                    <td></td>
                  </tr>
                </table>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:if>
          <!-- ################ Custom Navigation Links END ################ -->


          <!-- Navigation and content table -->
          <table id="navandcontent" border="0" cellspacing="0" cellpadding="0">
            <tr>
              <td id="{$navbg}" class="navbgwidth">

                <xsl:call-template name="navandcontent">
                  <xsl:with-param name="menu_items" select="$navandcontent_items" />
                  <xsl:with-param name="current_page" select="$selected_navandcontent" />
                </xsl:call-template>

                <br />
              </td>

              <td id="{$contentbg}" class="contentbgwidth">
                <table id="breadcrumb" border="0" cellspacing="0" cellpadding="0">
                  <tr>
                    <td>
                      <span class="floatright">
                        <xsl:choose>
                          <xsl:when test="$user_type = 'sa'">
                            <xsl:value-of select="/cp/strings/bc_server_admin" />
                          </xsl:when>
                          <xsl:when test="$user_type = 'da'">
                            <xsl:value-of select="/cp/strings/bc_domain_admin" />
                          </xsl:when>
                          <xsl:when test="$user_type = 'ma'">
                            <xsl:value-of select="/cp/strings/bc_mail_admin" />
                          </xsl:when>
                          <xsl:otherwise>
                            <!-- default to end user view -->
                            <xsl:value-of select="/cp/strings/bc_end_user" />
                          </xsl:otherwise>
                        </xsl:choose>
                        <b><xsl:value-of select="/cp/vsap/vsap[@type='auth']/username" /></b>
                      </span>
                      <xsl:call-template name="breadcrumb">
                        <xsl:with-param name="breadcrumb" select="$breadcrumb" />
                      </xsl:call-template>
                    </td>
                  </tr>
                </table>

                <!-- feedback table gets inserted here -->
                <xsl:copy-of select="$feedback" />

                <div id="workarea">

                  <!-- user messages -->
                  <xsl:if test="/cp/vsap/vsap[@type='user:messages:list']/numjobs > 0">
                    <table class="listview" border="0" cellspacing="0" cellpadding="0">
                      <tr class="jobstatusrow">
                        <td><xsl:value-of select="/cp/strings/cp_background_job_title" /></td>
                        <td><xsl:value-of select="/cp/strings/cp_background_job_time_started" /></td>
                        <td><xsl:value-of select="/cp/strings/cp_background_job_last_updated" /></td>
                        <td><xsl:value-of select="/cp/strings/cp_background_job_status" /></td>
                      </tr>
                      <xsl:for-each select="/cp/vsap/vsap[@type='user:messages:list']/job">
                        <xsl:variable name="row_style">
                          <xsl:choose>
                            <xsl:when test="position() mod 2 = 1">roweven</xsl:when>
                            <xsl:otherwise>rowodd</xsl:otherwise>
                          </xsl:choose>
                        </xsl:variable>
                        <tr class="{$row_style}">
                          <td>
                            <xsl:choose>
                              <xsl:when test="./task = 'USER_REMOVE'"><xsl:value-of select="/cp/strings/cp_background_job_user_remove_title" /></xsl:when>
                              <xsl:when test="./task = 'FILE_COMPRESS'"><xsl:value-of select="/cp/strings/cp_background_job_file_compress_title" /> → <xsl:value-of select="./target_filename" /></xsl:when>
                              <xsl:when test="./task = 'FILE_UNCOMPRESS'"><xsl:value-of select="/cp/strings/cp_background_job_file_uncompress_title" /> →  <xsl:value-of select="./source_filename" /></xsl:when>
                              <xsl:otherwise>
                                <xsl:variable name="remove_user_status_temp">
                                  <xsl:call-template name="transliterate">
                                    <xsl:with-param name="string"><xsl:value-of select="/cp/strings/cp_background_job_title_unknown"/></xsl:with-param>
                                    <xsl:with-param name="search">__PID__</xsl:with-param>
                                    <xsl:with-param name="replace" select="./pid"/>
                                  </xsl:call-template>
                                </xsl:variable>
                              </xsl:otherwise>
                            </xsl:choose>
                          </td>
                          <td>
                            <xsl:call-template name="format-time">
                              <xsl:with-param name="date" select="./epoch_date"/>
                            </xsl:call-template>
                            <xsl:call-template name="format-date">
                              <xsl:with-param name="date" select="./epoch_date"/>
                            </xsl:call-template>
                          </td>
                          <td>
                            <xsl:call-template name="format-time">
                              <xsl:with-param name="date" select="./mtime_date"/>
                            </xsl:call-template>
                            <xsl:call-template name="format-date">
                              <xsl:with-param name="date" select="./mtime_date"/>
                            </xsl:call-template>
                          </td>
                          <td>
                            <xsl:choose>
                              <xsl:when test="./status = 'complete'">
                                <xsl:value-of select="/cp/strings/cp_background_job_completed" />
                              </xsl:when>
                              <xsl:when test="./task = 'USER_REMOVE'"> 
                                <xsl:variable name="remove_user_status_temp">
                                  <xsl:call-template name="transliterate">
                                    <xsl:with-param name="string"><xsl:value-of select="/cp/strings/cp_background_job_user_remove_status"/></xsl:with-param>
                                    <xsl:with-param name="search">__COMPLETED__</xsl:with-param>
                                    <xsl:with-param name="replace" select="./completed"/>
                                  </xsl:call-template>
                                </xsl:variable>
                                <xsl:variable name="remove_user_status">
                                  <xsl:call-template name="transliterate">
                                    <xsl:with-param name="string"><xsl:value-of select="$remove_user_status_temp"/></xsl:with-param>
                                    <xsl:with-param name="search">__TOTAL__</xsl:with-param>
                                    <xsl:with-param name="replace" select="./total"/>
                                  </xsl:call-template>
                                </xsl:variable>
                                <xsl:value-of select="$remove_user_status" />
                              </xsl:when>
                              <xsl:when test="./task = 'FILE_COMPRESS'"> 
                                <xsl:value-of select="/cp/strings/cp_background_job_file_compress_status" />
                              </xsl:when>
                              <xsl:when test="./task = 'FILE_UNCOMPRESS'"> 
                                <xsl:value-of select="/cp/strings/cp_background_job_file_uncompress_status" />
                              </xsl:when>
                              <xsl:otherwise><xsl:value-of select="/cp/strings/cp_background_job_status_unknown" /></xsl:otherwise>
                            </xsl:choose>
                          </td>
                        </tr>
                      </xsl:for-each>
                    </table>
                    <br />
                  </xsl:if>

                  <!-- work area content goes here -->
                  <xsl:call-template name="content" />
                  <br />

                  <!-- call help table template -->
                  <!--
                  <xsl:call-template name="help_table">
                    <xsl:with-param name="help_short"><xsl:copy-of select="$help_short" /></xsl:with-param>
                    <xsl:with-param name="help_long"><xsl:copy-of select="$help_long" /></xsl:with-param>
                  </xsl:call-template>
                  <br />
                  -->
                </div>
              </td>
            </tr>
          </table>
          <table id="footers" border="0" cellspacing="0" cellpadding="0">
            <tr>
              <td><xsl:copy-of select="/cp/strings/global_footer" /></td>
            </tr>
          </table>
          <p />
        </form>
        <xsl:if test="/cp/vsap/vsap[@type='auth']/siteprefs/enable-debug">
          <!-- begin debug -->
          <hr/>
          &#160; <b>DEBUGGING and DOCUMENTATION</b>
          <hr/>
          &#160; <b>Calls made to VSAP</b><p/>
          <pre><xsl:apply-templates select="/cp/completed/vsap" mode="escape-xml"/></pre>
          <hr/>
          &#160; <b>Returned from VSAP</b><p/>
          <pre><xsl:apply-templates select="/cp/vsap" mode="escape-xml-no-nl"/></pre>
          <hr/>
          <!-- end debug -->
        </xsl:if>
      </body>
    </html>
  </xsl:template>

  <xsl:template name="blankbodywrapper">
    <xsl:param name="title" />
    <xsl:param name="formaction" />
    <xsl:param name="formname">globalnav</xsl:param>
    <xsl:param name="onload"/>
    <xsl:param name="onunload" />
    <xsl:param name="formenctype">application/x-www-form-urlencoded</xsl:param>
    <xsl:param name="feedback" />

    <!-- css style names -->
    <xsl:variable name="contentbg">contentbg<xsl:value-of select="$app_name" /></xsl:variable>

    <html xmlns="http://www.w3.org/1999/xhtml">
      <head>
        <meta http-equiv="content-type" content="text/html;charset=UTF-8" />
        <title><xsl:value-of select="$title" /></title>
        <link href="{/cp/strings/stylesheet}" type="text/css" rel="stylesheet" media="screen" />
      </head>
      <body>
        <xsl:if test="string($onload)">
          <xsl:attribute name="onLoad"><xsl:value-of select="$onload"/></xsl:attribute>
        </xsl:if>
        <xsl:if test="string($onunload)">
          <xsl:attribute name="onUnload"><xsl:value-of select="$onunload"/></xsl:attribute>
        </xsl:if>
        <script src="{concat($base_url, '/allfunctions.js')}" language="JavaScript"></script>
        <div id="{$contentbg}" class="contentbgpopupwidth">
          <!-- feedback table gets inserted here -->
          <xsl:copy-of select="$feedback" />
          <div id="workarea">
            <form name="{$formname}" action="{$formaction}" method="post" enctype="{$formenctype}">
              <xsl:call-template name="content" />
              <br />
            </form>
          </div>
        </div>
      </body>
    </html>
  </xsl:template>

  <xsl:template name="printbodywrapper">
    <xsl:param name="title" />

    <html xmlns="http://www.w3.org/1999/xhtml">
      <head>
        <meta http-equiv="content-type" content="text/html;charset=UTF-8" />
        <title><xsl:value-of select="$title" /></title>
        <link href="{/cp/strings/stylesheet}" type="text/css" rel="stylesheet" media="screen" />
        <style type="text/css">
          @media print {
            table.controlbar {display: none;}
          }
        </style>
      </head>
      <body>
        <form action="#" method="get" name="printform">
          <table class="controlbar" border="0" cellspacing="0" cellpadding="0">
            <tr>
              <td><input class="floatright" onClick="window.close()" type="button" name="close_window" value="{cp/strings/print_btn_close}" /></td>
            </tr>
          </table>

          <xsl:call-template name="content" />
        </form>
      </body>
    </html>
  </xsl:template>

  <xsl:template name="format-date">
    <xsl:param name="date" />
    <xsl:param name="type" />

    <xsl:choose>
      <xsl:when test="(/cp/vsap/vsap[@type='user:prefs:load']/user_preferences/messageTimeOption = 'myzone') or $type = 'short'">
        <xsl:choose>
          <xsl:when test="/cp/vsap/vsap[@type='user:prefs:load']/user_preferences/date_format = '%Y-%m-%d'">
            <xsl:value-of select="$date/year" /><xsl:copy-of select="/cp/strings/dateformat_afteryear" />
            <xsl:if test="string-length($date/month) = 1">0</xsl:if>
            <xsl:value-of select="$date/month" /><xsl:copy-of select="/cp/strings/dateformat_aftermonth" />
            <xsl:if test="string-length($date/day) = 1">0</xsl:if>
            <xsl:value-of select="$date/day" /><xsl:copy-of select="/cp/strings/dateformat_afterdayend" />
          </xsl:when>
          <xsl:when test="/cp/vsap/vsap[@type='user:prefs:load']/user_preferences/date_format = '%d-%m-%Y'">
            <xsl:if test="string-length($date/day) = 1">0</xsl:if>
            <xsl:value-of select="$date/day" /><xsl:copy-of select="/cp/strings/dateformat_afterday" />
            <xsl:if test="string-length($date/month) = 1">0</xsl:if>
            <xsl:value-of select="$date/month" /><xsl:copy-of select="/cp/strings/dateformat_aftermonth" />
            <xsl:value-of select="$date/year" /><xsl:copy-of select="/cp/strings/dateformat_afteryearend" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:if test="string-length($date/month) = 1">0</xsl:if>
            <xsl:value-of select="$date/month" /><xsl:copy-of select="/cp/strings/dateformat_aftermonth" />
            <xsl:if test="string-length($date/day) = 1">0</xsl:if>
            <xsl:value-of select="$date/day" /><xsl:copy-of select="/cp/strings/dateformat_afterday" />
            <xsl:value-of select="$date/year" /><xsl:copy-of select="/cp/strings/dateformat_afteryearend" />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>

      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="/cp/vsap/vsap[@type='user:prefs:load']/user_preferences/date_format = '%Y-%m-%d'">
            <xsl:value-of select="$date/o_year" /><xsl:copy-of select="/cp/strings/dateformat_afteryear" />
            <xsl:if test="string-length($date/o_month) = 1">0</xsl:if>
            <xsl:value-of select="$date/o_month" /><xsl:copy-of select="/cp/strings/dateformat_aftermonth" />
            <xsl:if test="string-length($date/o_day) = 1">0</xsl:if>
            <xsl:value-of select="$date/o_day" /><xsl:copy-of select="/cp/strings/dateformat_afterdayend" />
          </xsl:when>
          <xsl:when test="/cp/vsap/vsap[@type='user:prefs:load']/user_preference/date_format = '%d-%m-%Y'">
            <xsl:if test="string-length($date/o_day) = 1">0</xsl:if>
            <xsl:value-of select="$date/o_day" /><xsl:copy-of select="/cp/strings/dateformat_afterday" />
            <xsl:if test="string-length($date/o_month) = 1">0</xsl:if>
            <xsl:value-of select="$date/o_month" /><xsl:copy-of select="/cp/strings/dateformat_aftermonth" />
            <xsl:value-of select="$date/o_year" /><xsl:copy-of select="/cp/strings/dateformat_afteryearend" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:if test="string-length($date/o_month) = 1">0</xsl:if>
            <xsl:value-of select="$date/o_month" /><xsl:copy-of select="/cp/strings/dateformat_aftermonth" />
            <xsl:if test="string-length($date/o_day) = 1">0</xsl:if>
            <xsl:value-of select="$date/o_day" /><xsl:copy-of select="/cp/strings/dateformat_afterday" />
            <xsl:value-of select="$date/o_year" /><xsl:copy-of select="/cp/strings/dateformat_afteryearend" />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="format-time">
    <xsl:param name="date" />
    <xsl:param name="type" />

    <xsl:choose>
      <xsl:when test="(/cp/vsap/vsap[@type='user:prefs:load']/user_preferences/messageTimeOption = 'myzone') or ($type = 'short')">
        <xsl:choose>
          <xsl:when test="/cp/vsap/vsap[@type='user:prefs:load']/user_preferences/time_format = '%H:%M'">
            <xsl:if test="string-length($date/hour) = 1">0</xsl:if>
            <xsl:value-of select="$date/hour" />
            <xsl:text>:</xsl:text>
            <xsl:if test="string-length($date/minute) = 1">0</xsl:if>
            <xsl:value-of select="$date/minute" />
          </xsl:when>
          <xsl:when test="(($date/hour != $date/hour12) or ($date/hour = '12')) and ($date/hour != '24')">
            <xsl:copy-of select="/cp/strings/timeformat_beforePM" />
            <xsl:if test="string-length($date/hour12) = 1">0</xsl:if>
            <xsl:value-of select="$date/hour12" />
            <xsl:text>:</xsl:text>
            <xsl:if test="string-length($date/minute) = 1">0</xsl:if>
            <xsl:value-of select="$date/minute" />
            <xsl:copy-of select="/cp/strings/timeformat_afterPM" />
          </xsl:when>
          <xsl:when test="$date/hour = '0'">
            <xsl:copy-of select="/cp/strings/timeformat_beforeAM" />
            <xsl:text>12:</xsl:text>
            <xsl:if test="string-length(string(number($date/minute))) = 1">0</xsl:if>
            <xsl:value-of select="$date/minute" />
            <xsl:copy-of select="/cp/strings/timeformat_afterAM" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:copy-of select="/cp/strings/timeformat_beforeAM" />
            <xsl:if test="string-length($date/hour) = 1">0</xsl:if>
            <xsl:value-of select="$date/hour" />
            <xsl:text>:</xsl:text>
            <xsl:if test="string-length($date/minute) = 1">0</xsl:if>
            <xsl:value-of select="$date/minute" />
            <xsl:copy-of select="/cp/strings/timeformat_afterAM" />
          </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="$type != 'short'">
          <xsl:value-of select="concat('  ',/cp/vsap/vsap[@type='user:prefs:load']/user_preferences/timeZoneCode)" />
        </xsl:if>
      </xsl:when>

      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="/cp/vsap/vsap[@type='user:prefs:load']/user_preferences/time_format = '%H:%M'">
            <xsl:if test="string-length($date/o_hour) = 1">0</xsl:if>
            <xsl:value-of select="$date/o_hour" />
            <xsl:text>:</xsl:text>
            <xsl:if test="string-length($date/o_minute) = 1">0</xsl:if>
            <xsl:value-of select="$date/o_minute" />
          </xsl:when>
          <xsl:when test="$date/o_hour != $date/o_hour12">
            <xsl:copy-of select="/cp/strings/timeformat_beforePM" />
            <xsl:if test="string-length($date/o_hour12) = 1">0</xsl:if>
            <xsl:value-of select="$date/o_hour12" />
            <xsl:text>:</xsl:text>
            <xsl:if test="string-length($date/o_minute) = 1">0</xsl:if>
            <xsl:value-of select="$date/o_minute" />
            <xsl:copy-of select="/cp/strings/timeformat_afterPM" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:copy-of select="/cp/strings/timeformat_beforeAM" />
            <xsl:if test="string-length($date/o_hour) = 1">0</xsl:if>
            <xsl:value-of select="$date/o_hour" />
            <xsl:text>:</xsl:text>
            <xsl:if test="string-length($date/o_minute) = 1">0</xsl:if>
            <xsl:value-of select="$date/o_minute" />
            <xsl:copy-of select="/cp/strings/timeformat_afterAM" />
          </xsl:otherwise>
        </xsl:choose>

        <xsl:choose>
          <xsl:when test="$date/o_off = /cp/vsap/vsap[@type='user:prefs:load']/user_preferences/timeZone">
            <xsl:value-of select="concat('  ',/cp/vsap/vsap[@type='user:prefs:load']/user_preferences/timeZoneCode)" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="concat('  ',$date/o_off,/cp/strings/offset_tz)" />
          </xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- this template formats raw bytes for display in a consistent manner -->
  <!--
    Params:
      bytes - bytes to be formatted

    Returns:
      string containing formatted size with appropriate units (KB, MB or GB)
  -->
  <xsl:template name="format_bytes">
    <xsl:param name="bytes" />

    <xsl:choose>
      <xsl:when test="$bytes &lt; 1048576"><!-- 1024^2 -->
        <xsl:value-of select="format-number($bytes div (1024), '#.##')" />
        &#160;<xsl:value-of select="/cp/strings/kb" />
      </xsl:when>
      <xsl:when test="$bytes &lt; 1073741824"><!-- 1024^3 -->
        <xsl:value-of select="format-number($bytes div (1048576), '###.#')" />
        &#160;<xsl:value-of select="/cp/strings/mb" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="format-number($bytes div (1073741824), '###.#')" />
        &#160;<xsl:value-of select="/cp/strings/gb" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="truncate">
    <xsl:param name="string" />
    <xsl:param name="fieldlength" />
    <xsl:choose>
      <xsl:when test="string-length($string) &lt; $fieldlength"><xsl:value-of select="$string" /></xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="substring($string, 0, $fieldlength - 3)" /><xsl:value-of select="/cp/strings/truncate_string" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="transliterate">
    <xsl:param name="string"/>
    <xsl:param name="search"/>
    <xsl:param name="replace"/>
    <xsl:choose>
      <xsl:when test="contains($string, $search)">
        <xsl:value-of select="substring-before($string, $search)"/>
        <xsl:copy-of select="$replace"/>
        <xsl:call-template name="transliterate">
          <xsl:with-param name="string" select="substring-after($string, $search)"/>
          <xsl:with-param name="search" select="$search"/>
          <xsl:with-param name="replace" select="$replace"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:copy-of select="$string"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

<func:function name="cp:js-escape">
  <xsl:param name="text"/>
  <xsl:variable name="apos">'</xsl:variable>
  <xsl:variable name="esc_apos">\'</xsl:variable>
  <!-- add others here, like double-quotes? -->

  <xsl:variable name="apos_done" select="str:replace($text, $apos, $esc_apos)"/>
  <!-- add other escape calls here, using the previous variable, i.e.:
    <xsl:variable name="quote_done" select="str:replace($apos_done, $quote, $esc_quote)"/>
  -->

  <func:result>
    <xsl:value-of select="str:replace($apos_done)"/>
    <!-- use the value of the last variable defined here -->
  </func:result>
</func:function>

<func:function name="str:replace">
   <xsl:param name="string" select="''" />
   <xsl:param name="search" select="/.." />
   <xsl:param name="replace" select="/.." />
   <xsl:choose>
      <xsl:when test="not($string)">
        <func:result select="/.." />
      </xsl:when>

      <xsl:when test="function-available('exslt:node-set')">
         <!-- this converts the search and replace arguments to node sets
              if they are one of the other XPath types -->
         <xsl:variable name="search-nodes-rtf">
           <xsl:copy-of select="$search" />
         </xsl:variable>
         <xsl:variable name="replace-nodes-rtf">
           <xsl:copy-of select="$replace" />
         </xsl:variable>
         <xsl:variable name="replacements-rtf">
            <xsl:for-each select="exslt:node-set($search-nodes-rtf)/node()">
               <xsl:variable name="pos" select="position()" />
               <replace search="{.}">
                  <xsl:copy-of select="exslt:node-set($replace-nodes-rtf)/node()[$pos]" />
               </replace>
            </xsl:for-each>
         </xsl:variable>
         <xsl:variable name="sorted-replacements-rtf">
            <xsl:for-each select="exslt:node-set($replacements-rtf)/replace">
               <xsl:sort select="string-length(@search)" data-type="number" order="descending" />
               <xsl:copy-of select="." />
            </xsl:for-each>
         </xsl:variable>
         <xsl:variable name="result">
           <xsl:choose>
             <xsl:when test="not($search)">
               <xsl:value-of select="$string" />
             </xsl:when>
             <xsl:otherwise>
               <xsl:call-template name="str:_replace">
                  <xsl:with-param name="string" select="$string" />
                  <xsl:with-param name="replacements" select="exslt:node-set($sorted-replacements-rtf)/replace" />
               </xsl:call-template>
             </xsl:otherwise>
           </xsl:choose>
         </xsl:variable>
         <func:result select="exslt:node-set($result)/node()" />
      </xsl:when>
      <xsl:otherwise/>
   </xsl:choose>
</func:function>

<xsl:template name="str:_replace">
  <xsl:param name="string" select="''" />

  <xsl:param name="replacements" select="/.." />
  <xsl:choose>
    <xsl:when test="not($string)" />
    <xsl:when test="not($replacements)">
      <xsl:value-of select="$string" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:variable name="replacement" select="$replacements[1]" />
      <xsl:variable name="search" select="$replacement/@search" />

      <xsl:choose>
        <xsl:when test="not(string($search))">
          <xsl:value-of select="substring($string, 1, 1)" />
          <xsl:copy-of select="$replacement/node()" />
          <xsl:call-template name="str:_replace">
            <xsl:with-param name="string" select="substring($string, 2)" />
            <xsl:with-param name="replacements" select="$replacements" />
          </xsl:call-template>
        </xsl:when>

        <xsl:when test="contains($string, $search)">
          <xsl:call-template name="str:_replace">
            <xsl:with-param name="string" select="substring-before($string, $search)" />
            <xsl:with-param name="replacements" select="$replacements[position() > 1]" />
          </xsl:call-template>      
          <xsl:copy-of select="$replacement/node()" />
          <xsl:call-template name="str:_replace">
            <xsl:with-param name="string" select="substring-after($string, $search)" />
            <xsl:with-param name="replacements" select="$replacements" />

          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="str:_replace">
            <xsl:with-param name="string" select="$string" />
            <xsl:with-param name="replacements" select="$replacements[position() > 1]" />
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>

    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

  <!-- escape-xml mode: serialize XML tree to text, with indent Based very loosely on templates by Wendell Piez -->

  <xsl:variable name="nl"><xsl:text>&#10;</xsl:text></xsl:variable>
  <xsl:variable name="indent-increment" select="'  '" />
  <xsl:variable name="ns-decl-extra-indent" select="'     '" />

  <xsl:template match="*" mode="escape-xml">
    <xsl:param name="indent-string" select="$indent-increment" />
    <xsl:param name="is-top" select="'true'" /> <!-- true if this is the top of the tree being serialized -->
    <xsl:param name="exclude-prefixes" select="''" /> <!-- ns-prefixes to avoid declaring -->

    <xsl:value-of select="$indent-string" />
    <xsl:call-template name="write-starttag">
      <xsl:with-param name="is-top" select="$is-top" />
      <xsl:with-param name="indent-string" select="$indent-string" />
      <xsl:with-param name="exclude-prefixes" select="$exclude-prefixes" />
    </xsl:call-template>
    <xsl:if test="*"><xsl:value-of select="$nl" /></xsl:if>
    <xsl:apply-templates mode="escape-xml">
      <xsl:with-param name="indent-string" select="concat($indent-string, $indent-increment)" />
      <xsl:with-param name="is-top" select="'false'" />
    </xsl:apply-templates>
    <xsl:if test="*"><xsl:value-of select="$indent-string" /></xsl:if>
     <xsl:if test="*|text()|comment()|processing-instruction()"><xsl:call-template name="write-endtag" /></xsl:if>
    <xsl:value-of select="$nl" />
  </xsl:template>

  <xsl:template match="*" mode="escape-xml-no-nl">
    <xsl:param name="indent-string" select="$indent-increment" />
    <xsl:param name="is-top" select="'true'" /> <!-- true if this is the top of the tree being serialized -->
    <xsl:param name="exclude-prefixes" select="''" /> <!-- ns-prefixes to avoid declaring -->

    <xsl:if test="$is-top = 'true'"><xsl:value-of select="$nl" /></xsl:if>
    <xsl:value-of select="$indent-string" />
    <xsl:call-template name="write-starttag">
      <xsl:with-param name="is-top" select="$is-top" />
      <xsl:with-param name="indent-string" select="$indent-string" />
      <xsl:with-param name="exclude-prefixes" select="$exclude-prefixes" />
    </xsl:call-template>
<!--
    <xsl:if test="*"><xsl:value-of select="$nl" /></xsl:if>
-->
    <xsl:apply-templates mode="escape-xml-no-nl">
      <xsl:with-param name="indent-string" select="concat($indent-string, $indent-increment)" />
      <xsl:with-param name="is-top" select="'false'" />
    </xsl:apply-templates>
    <xsl:if test="*"><xsl:value-of select="$indent-string" /></xsl:if>
     <xsl:if test="*|text()|comment()|processing-instruction()"><xsl:call-template name="write-endtag" /></xsl:if>
<!--
    <xsl:value-of select="$nl" />
-->
  </xsl:template>

  <xsl:template name="write-starttag">
    <xsl:param name="is-top" select="'false'" />
    <xsl:param name="exclude-prefixes" select="''" /> <!-- ns-prefixes to avoid declaring -->
    <xsl:param name="indent-string" select="''" />

    <xsl:text>&lt;</xsl:text>
    <xsl:value-of select="name()"/>
    <xsl:for-each select="@*">
     <xsl:call-template name="write-attribute"/>
    </xsl:for-each>
    <xsl:call-template name="write-namespace-declarations">
      <xsl:with-param name="is-top" select="$is-top" />
      <xsl:with-param name="exclude-prefixes" select="$exclude-prefixes" />
      <xsl:with-param name="indent-string" select="$indent-string" />
    </xsl:call-template>
    <xsl:if test="not(*|text()|comment()|processing-instruction())"> /</xsl:if>
    <xsl:text>></xsl:text>
  </xsl:template>

  <xsl:template name="write-endtag">
     <xsl:text>&lt;/</xsl:text>
     <xsl:value-of select="name()"/>
     <xsl:text>></xsl:text>
  </xsl:template>

  <xsl:template name="write-attribute">
     <xsl:text> </xsl:text>
     <xsl:value-of select="name()"/>
     <xsl:text>="</xsl:text>
     <xsl:value-of select="."/>
     <xsl:text>"</xsl:text>
  </xsl:template>

  <!-- Output namespace declarations for the current element. -->
  <!-- Assumption: if an attribute in the source tree uses a particular namespace, its parent
   element will have a namespace node for that namespace (because the declaration for the 
   namespace must be on the parent element or one of its ancestors). -->
  <xsl:template name="write-namespace-declarations">
    <xsl:param name="is-top" select="'false'" />
    <xsl:param name="indent-string" select="''" />
    <xsl:param name="exclude-prefixes" select="''" />

    <xsl:variable name="current" select="." />
    <xsl:variable name="parent-nss" select="../namespace::*" />
    <xsl:for-each select="namespace::*">
      <xsl:variable name="ns-prefix" select="name()" />
      <xsl:variable name="ns-uri" select="string(.)" />
      <xsl:if test="not(contains(concat(' ', $exclude-prefixes, ' xml '), concat(' ', $ns-prefix, ' ')))
                  and ($is-top = 'true' or not($parent-nss[name() = $ns-prefix and string(.) = $ns-uri]))
                  ">
        <!-- This namespace node doesn't exist on the parent, at least not with that URI,
          so we need to add a declaration. -->
        <!--
          We could add the test
              and ($ns-prefix = '' or ($current//.|$current//@*)[substring-before(name(), ':') = $ns-prefix])
          i.e. "and it's used by this element or some descendant (or descendant-attribute) thereof:"
         Only problem with the above test is that sometimes namespace declarations are needed even though
          they're not used by a descendant element or attribute: e.g. if the input is a stylesheet, prefixes have
          to be declared if they're used in XPath expressions [which are in attribute values]. We could have
          problems in this area with regard to xsp-request.
        <xsl:value-of select="concat($nl, $indent-string, $ns-decl-extra-indent)" />
        <xsl:value-of select="concat(' ', '')" />
        <xsl:choose>
          <xsl:when test="$ns-prefix = ''">
            <xsl:value-of select="concat('xmlns=&quot;', $ns-uri, '&quot;')" />
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="concat('xmlns:', $ns-prefix, '=&quot;', $ns-uri, '&quot;')" />
          </xsl:otherwise>
        </xsl:choose>
        -->
      </xsl:if>
    </xsl:for-each>
  </xsl:template>

</xsl:stylesheet>

