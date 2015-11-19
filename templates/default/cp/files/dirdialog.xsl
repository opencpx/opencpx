<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" xmlns:exslt="http://exslt.org/common">

<xsl:import href="../cp_global.xsl"/>
<xsl:import href="file_global.xsl"/>

<xsl:variable name="numEndUsers">
  <xsl:if test="$userType = 'da'">
    <xsl:value-of select="count(/cp/vsap/vsap[@type='user:list:eu']/user)"/>
        </xsl:if>
</xsl:variable>

<xsl:variable name="targetUser">
  <xsl:if test="$userType = 'da' and $numEndUsers > 1">
    <xsl:choose>
      <xsl:when test="string(/cp/form/targetUser)">
        <xsl:value-of select="/cp/form/targetUser"/>
      </xsl:when>
      <xsl:when test="string(/cp/form/currentUser)">
        <xsl:value-of select="/cp/form/currentUser"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="/cp/vsap/vsap[@type='auth']/username"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:if>
</xsl:variable>

<xsl:variable name="targetArgs">
  <xsl:if test="$userType = 'da' and $numEndUsers > 1">
    <xsl:if test="$targetUser != /cp/vsap/vsap[@type='auth']/username">&amp;targetUser=<xsl:value-of select="$targetUser"/></xsl:if>
  </xsl:if>
</xsl:variable>

<xsl:variable name="hiddenCount">
  <xsl:value-of select="count(/cp/vsap/vsap[@type='files:list']/file[(type='dir' or type='dirlink') and starts-with(name, '.') and name != '.' and name != '..'])"/>
</xsl:variable>


<xsl:variable name="showHidden">
  <xsl:choose>
    <xsl:when test="/cp/form/showHidden"><xsl:value-of select="/cp/form/showHidden"/></xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='user: prefs:load']/user_preferences/fm_hidden_file_default = 'show'">true</xsl:when>
    <xsl:otherwise>false</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:template match="/">

<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <title>
      <xsl:value-of select="/cp/strings/cp_title" />
      v<xsl:value-of select="/cp/vsap/vsap[@type='auth']/version" />
    </title>
    <link href="{/cp/strings/stylesheet}" type="text/css" rel="stylesheet" media="screen" />
    <script src="/ControlPanel/allfunctions.js" language="JavaScript"></script>
  </head>

  <body>
    <div id="contentbgcontrolpanel">
    <div id="workarea">
      <form name="specialwindow" action="dirdialog.xsl" method="post" enctype="multipart/form-data">
        <table class="chooserpopup" border="0" cellspacing="0" cellpadding="0">
          <tr class="title">
            <td>Destination Directory</td>
          </tr>
          <xsl:if test="$userType = 'da' and $numEndUsers > 1">
            <tr class="rowodd">
              <td>
                <select name="targetUser" size="1">
                <xsl:for-each select="/cp/vsap/vsap[@type='user:list:eu']/user">
                  <option value="{.}">
                  <xsl:if test=". = $targetUser">
                    <xsl:attribute name="selected">true</xsl:attribute>
                  </xsl:if><xsl:value-of select="." /></option>
                </xsl:for-each>
                </select>&#160;
                <input type="submit" name="openLocation" value="{/cp/strings/file_list_btn_go}"/>
              </td>
            </tr>
          </xsl:if>

          <xsl:variable name="parentDir"><xsl:value-of select="/cp/vsap/vsap[@type='files:list']/parent_dir"/></xsl:variable>
          <xsl:variable name="currentDir"><xsl:value-of select="/cp/vsap/vsap[@type='files:list']/path"/><xsl:if test="/cp/vsap/vsap[@type='files:list']/path != '/'">/</xsl:if></xsl:variable>

          <input name="selectedPath" type="hidden" value="{$currentDir}"/>

          <tr class="rowodd">
            <td>Current Directory: <xsl:value-of select="$currentDir"/></td>
          </tr>

          <xsl:for-each select="/cp/vsap/vsap[@type='files:list']/file[(type='dir' or type='dirlink') and name != ''  and name != '.' and (starts-with(name, '.') = false or name = '.' or name = '..' or $showHidden = 'true')]">
            <xsl:sort select="name"/>  
            <xsl:variable name="rowStyle">
              <xsl:choose>
                <xsl:when test="position() mod 2 = 1">rowodd</xsl:when>
                <xsl:otherwise>roweven</xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <tr class="{$rowStyle}">
              <!--td class="filecolumn"><xsl:value-of select="name"/></td>
              <td class="filecolumn"><xsl:value-of select="type"/></td-->

              <xsl:variable name="fileFullName">
                <xsl:value-of select="$currentDir"/>
                <xsl:value-of select="name"/>
              </xsl:variable>

              <xsl:choose>
                <!-- Self directory: go to parent -->
                <xsl:when test="name = '..'">
                  <td class="filecolumn"><a href="dirdialog.xsl?showHidden={$showHidden}&amp;path={$parentDir}{$targetArgs}">[..]</a></td>
                </xsl:when>

                <!-- Sub directory -->
                <xsl:when test="type='dir'">
                  <td class="filecolumn">
                    <a href="dirdialog.xsl?showHidden={$showHidden}&amp;path={$fileFullName}{$targetArgs}"><xsl:value-of select="name"/></a>
                  </td>
                </xsl:when>
  
                <!-- Directory shortcut-->
                <xsl:when test="type='dirlink'">
                  <td class="filecolumn">
                    <a href="dirdialog.xsl?showHidden={$showHidden}&amp;path={target}{$targetArgs}"><xsl:value-of select="name"/></a>
                  </td>
                </xsl:when>
              </xsl:choose>
            </tr>
          </xsl:for-each>


          <tr class="controlrow">
            <td>
              <xsl:choose>
                <xsl:when test="$hiddenCount = 0">
                  0&#160;<xsl:value-of select="/cp/strings/file_properties_hidden_dirs"/>
                </xsl:when>
                <xsl:when test="$showHidden='true'">
                  <a href="dirdialog.xsl?showHidden=false&amp;path={/cp/form/path}{$targetArgs}">
                  <xsl:value-of select="$hiddenCount"/>&#160;<xsl:value-of select="/cp/strings/file_properties_hide_hidden_dirs"/></a>
                </xsl:when>  

                <xsl:otherwise>
                  <a href="dirdialog.xsl?showHidden=true&amp;path={/cp/form/path}{$targetArgs}">
                  <xsl:value-of select="$hiddenCount"/>&#160;<xsl:value-of select="/cp/strings/file_properties_show_hidden_dirs"/></a>

                  <!--a><xsl:attribute name="href">dirdialog.xsl?showHidden=true&amp;path=<xsl:value-of select="/cp/form/path"/></xsl:attribute>
                  <xsl:value-of select="$hiddenCount"/>&#160;<xsl:value-of select="/cp/strings/file_properties_show_hidden_dirs"/></a-->

                </xsl:otherwise>
              </xsl:choose>
            </td>
          </tr>
          <tr class="controlrow">
            <td><span class="floatright"><input onClick="closeDirectoryDialog()" type="button" name="choose" value="{/cp/strings/file_btn_choose}"/>
              <input type="button" name="cancel" value="{/cp/strings/file_btn_cancel}" onClick="window.close()" />
            </span></td>
          </tr>
        </table>
        <br></br>
      </form>
    </div>
    </div>
  </body>
</html>


</xsl:template>

</xsl:stylesheet>
