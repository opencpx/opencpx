<?xml version='1.0' encoding='UTF-8' ?>
<xsl:stylesheet version='1.0'
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:exslt="http://exslt.org/common"
  xmlns:func="http://exslt.org/functions"
  xmlns:cp="vsap:cp"
  extension-element-prefixes="func"
  exclude-result-prefixes="exslt">

<!-- vsap stuff -->
<!-- this template is used by the dovsap template to find out which vsap calls haven't been run -->
<xsl:template name="vsapdiff">
  <xsl:param name="nodes1" />
  <xsl:param name="nodes2" />
  <vsap>
  <xsl:for-each select="$nodes1">
    <xsl:variable name="type" select="./@type" />
    <xsl:if test="not(boolean($nodes2[@type=$type]))">
      <xsl:copy-of select="." />
    </xsl:if>
  </xsl:for-each>
  </vsap>
</xsl:template>

<xsl:template name="dovsap">
  <xsl:param name="vsap" />
  <xsl:param name="force_call" />
    <!-- 
         Setting force_call to 'yes' allows a meta file to make a second VSAP 
         call to a module if the first call to that module returns an error.   

         Please be careful when using force_call. There is a potential for an 
         infinite loop (although the loop will be stopped by the metaproc engine) 
         if the VSAP module returns an error when force_call is used and the meta 
         file continues to call dovsap with force_call set to 'yes'.
    --> 

  <!-- convert our vsap variable to a nodeset -->
  <xsl:variable name="vsapx" select="exslt:node-set($vsap)" />

  <!-- find out which vsap calls haven't been run -->
  <xsl:variable name="vsaptodo">
    <xsl:choose>
      <xsl:when test="$force_call = ''">
        <xsl:call-template name="vsapdiff">
          <xsl:with-param name="nodes1" select="$vsapx/vsap/vsap" />
          <xsl:with-param name="nodes2" select="/cp/completed/vsap/vsap" />
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="vsapdiff">
          <xsl:with-param name="nodes1" select="$vsapx/vsap/vsap" />
          <xsl:with-param name="nodes2" select="/cp/vsap/vsap" />
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <!-- parse that variable to a node-set -->
  <xsl:variable name="vsaptodox" select="exslt:node-set($vsaptodo)" />

  <xsl:choose>
    <xsl:when test="boolean(/cp/vsap[@type='error']/code)">
    </xsl:when>

    <xsl:when test="count($vsaptodox/vsap/vsap) > 0">
      <vsap>
        <xsl:for-each select="$vsaptodox/vsap/vsap">
          <xsl:copy-of select="." />
        </xsl:for-each>
      </vsap>
    </xsl:when>
  </xsl:choose>
</xsl:template>

<!-- message passing -->
<xsl:template name="set_message">
  <xsl:param name="name" />
  <xsl:param name="value">1</xsl:param>

  <xsl:if test="not(/cp/msgs/msg[@name = $name])">
    <cp>
      <msgs>
        <msg>
          <xsl:attribute name="name"><xsl:value-of select="$name" /></xsl:attribute>
          <xsl:value-of select="$value" />
        </msg>
      </msgs>
    </cp>
  </xsl:if>
</xsl:template>

<!-- authentication stuff -->
<xsl:template name="auth">
  <!-- These defaults assume at least end user authentication is required.
       It is up to the individual templates to enforce stricter privileges
       on user types and services -->
  <xsl:param name="require_platform">eu</xsl:param> <!-- sa, da, ma, or eu -->
  <xsl:param name="require_class">eu</xsl:param> <!-- sa, da, ma, or eu -->
  <!-- Setting these to '1' will cause the entire page to be inaccessible to
       users without the required privilege, pref, platform, or product. -->
  <xsl:param name="require_mail">0</xsl:param>
  <xsl:param name="require_webmail">0</xsl:param>
  <xsl:param name="require_ftp">0</xsl:param>
  <xsl:param name="require_shell">0</xsl:param>
  <xsl:param name="require_fileman">0</xsl:param>
  <xsl:param name="require_podcast">0</xsl:param>
  <xsl:param name="require_firewall">0</xsl:param>
  <xsl:param name="require_freebsd">0</xsl:param>
  <xsl:param name="require_linux">0</xsl:param>
  <xsl:param name="check_diskspace">1</xsl:param>


  <!-- check for any errors from vsap -->
  <xsl:choose>
    <!-- auth:100 = Bad login -->
    <xsl:when test="(/cp/vsap/vsap[@type='error'
                      and @caller='auth']/code = '100')
                      and boolean(/cp/form/username)
                      and boolean(/cp/form/password)">
      <redirect>
        <path>login.xsl</path>
      </redirect>
    </xsl:when>

    <!-- auth:101 = Session expired -->
    <xsl:when test="/cp/vsap/vsap[@type='error' and @caller='auth']/code = '101'">
      <redirect>
        <path>login.xsl</path>
      </redirect>
    </xsl:when>

    <!-- auth:103 = Encryption key file missing -->
    <xsl:when test="/cp/vsap/vsap[@type='error' and @caller='auth']/code = '103'">
      <redirect>
        <path>login.xsl</path>
      </redirect>
    </xsl:when>

    <!-- auth:104 = Home directory missing -->
    <xsl:when test="/cp/vsap/vsap[@type='error' and @caller='auth']/code = '104'">
      <redirect>
        <path>login.xsl</path>
      </redirect>
    </xsl:when>

    <!-- auth:105 = Home directory inaccessible -->
    <xsl:when test="/cp/vsap/vsap[@type='error' and @caller='auth']/code = '105'">
      <redirect>
        <path>login.xsl</path>
      </redirect>
    </xsl:when>

    <!-- auth:200 = Restart required -->
    <xsl:when test="/cp/vsap/vsap[@type='error' and @caller='auth']/code = '200'">
      <redirect>
        <path>login.xsl</path>
      </redirect>
    </xsl:when>

  </xsl:choose>

  <!-- check for logout -->
  <xsl:if test="boolean(/cp/form/logout)">

    <xsl:choose>
      <!-- first we need to remove the cookie -->
      <xsl:when test="not(boolean(/cp/request/setcookies/CP-sessionkey))">
        <cp>
          <request>
            <setcookies>
              <CP-sessionkey></CP-sessionkey>
            </setcookies>
          </request>
        </cp>
      </xsl:when>

      <!-- we've already removed the cookie, so redirect -->
      <xsl:otherwise>
        <redirect>
          <path>login.xsl</path>
        </redirect>
      </xsl:otherwise>
    </xsl:choose>

  </xsl:if>

  <!-- here's where we try to authenticate -->
  <xsl:if test="not(boolean(/cp/vsap/vsap[@type='auth']))">
    <xsl:choose>
      <xsl:when test="boolean(/cp/form/username) and boolean(/cp/form/password)">
        <vsap>
          <vsap type="auth">
            <username><xsl:value-of select="/cp/form/username" /></username>
            <password><xsl:value-of select="/cp/form/password" /></password>
            <hostname><xsl:value-of select="/cp/request/hostname" /></hostname>
          </vsap>
        </vsap>
      </xsl:when>
      <xsl:when test="string(/cp/request/cookies/CP-sessionkey) != ''">
        <vsap>
          <vsap type="auth">
            <sessionkey><xsl:value-of select="/cp/request/cookies/CP-sessionkey" /></sessionkey>
            <hostname><xsl:value-of select="/cp/request/hostname" /></hostname>
          </vsap>
        </vsap>
      </xsl:when>
      <xsl:otherwise>
        <redirect>
          <path>login.xsl</path>
        </redirect>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:if>

  <!-- here we need to tell the browser to set a cookie (by adding the following to the DOM) -->
  <!-- set the sessionkey cookie if it's included in the vsap thing, and not already set.
        we set this every time because it changes (and the expiration date changes) on every request -->
  <xsl:choose>
    <xsl:when test="boolean(/cp/vsap/vsap[@type='user:password:change']/sessionkey) and
                    not(boolean(/cp/request/setcookies/CP-sessionkey))">
      <cp>
        <request>
          <setcookies>
            <CP-sessionkey><xsl:value-of select="/cp/vsap/vsap[@type='user:password:change']/sessionkey" /></CP-sessionkey>
          </setcookies>
        </request>
      </cp>
    </xsl:when>
    <xsl:when test="boolean(/cp/vsap/vsap[@type='auth']/sessionkey) and
                    not(boolean(/cp/form/old_password)) and
                    not(boolean(/cp/request/setcookies/CP-sessionkey))">
      <cp>
        <request>
          <setcookies>
            <CP-sessionkey><xsl:value-of select="/cp/vsap/vsap[@type='auth']/sessionkey" /></CP-sessionkey>
          </setcookies>
        </request>
      </cp>
    </xsl:when>
  </xsl:choose>

  <!-- make sure that the user is allowed to visit this page -->
  <!-- server admin can access anything, regardless of privilege requirements (BUG27241) -->
  <xsl:if test="(($require_class = 'sa') and not(/cp/vsap/vsap[@type='auth']/server_admin))
                or (($require_class = 'da') and not(
                                                     (/cp/vsap/vsap[@type='auth']/server_admin)
                                                     or (/cp/vsap/vsap[@type='auth']/domain_admin)
                                                   ))
                or (($require_class = 'ma') and not(
                                                     (/cp/vsap/vsap[@type='auth']/server_admin)
                                                     or (/cp/vsap/vsap[@type='auth']/domain_admin)
                                                     or (/cp/vsap/vsap[@type='auth']/mail_admin)
                                                   ))
                or (($require_mail > 0) and not(
                                                 (/cp/vsap/vsap[@type='auth']/services/mail)
                                                 or (/cp/vsap/vsap[@type='auth']/server_admin)
                                               ))
                or (($require_webmail > 0) and not(
                                                    (/cp/vsap/vsap[@type='auth']/services/webmail)
                                                    or (/cp/vsap/vsap[@type='auth']/server_admin)
                                                  ))
                or (($require_ftp > 0) and not(
                                                (/cp/vsap/vsap[@type='auth']/services/ftp)
                                                or (/cp/vsap/vsap[@type='auth']/server_admin)
                                              ))
                or (($require_shell > 0) and not(
                                                  (/cp/vsap/vsap[@type='auth']/services/shell)
                                                  or (/cp/vsap/vsap[@type='auth']/server_admin)
                                                ))
                or (($require_fileman > 0) and not(
                                                    (/cp/vsap/vsap[@type='auth']/services/fileman)
                                                    or (/cp/vsap/vsap[@type='auth']/server_admin)
                                                  ))
                or (($require_podcast > 0) and not(
                                                    (/cp/vsap/vsap[@type='auth']/services/podcast)
                                                    or (/cp/vsap/vsap[@type='auth']/server_admin)
                                                  ))">
    <forbidden />
  </xsl:if>

  <!-- make sure that the resource is not disabled in site prefs -->
  <xsl:if test="(($require_firewall > 0) and (/cp/vsap/vsap[@type='auth']/siteprefs/disable-firewall)) or 
                (($require_podcast > 0) and (/cp/vsap/vsap[@type='auth']/siteprefs/disable-podcast)) or
                (($require_shell > 0) and (/cp/vsap/vsap[@type='auth']/siteprefs/disable-shell)) or
                (($require_webmail > 0) and (/cp/vsap/vsap[@type='auth']/siteprefs/disable-webmail))
               ">
    <forbidden />
  </xsl:if>

  <!-- make sure that the platform requirements are satisfied -->
  <xsl:if test="(($require_linux > 0) and (/cp/vsap/vsap[@type='auth']/platform != 'linux')) or
                (($require_freebsd > 0) and (/cp/vsap/vsap[@type='auth']/platform = 'linux'))
               ">
    <forbidden />
  </xsl:if>

  <!-- add vsap calls that are to appear on _every_ page here -->
  <xsl:if test="$check_diskspace='1'">
   <xsl:call-template name="dovsap">
     <xsl:with-param name="vsap">
       <vsap>
         <!-- add vsap::diskspace call for the diskspace gauge -->
         <vsap type="diskspace" />
       </vsap>
     </xsl:with-param>
   </xsl:call-template>
 </xsl:if>

</xsl:template>

</xsl:stylesheet>

