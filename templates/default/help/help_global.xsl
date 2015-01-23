<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

  <xsl:import href="../global.xsl" />

  <!-- This will tell the global template which app we are in -->
  <xsl:variable name="app_name">help</xsl:variable>

  <!-- 
    Whether a Help Survey form is displayed at the bottom of each 
    topic data listing.
  -->
  <xsl:variable name="display_help_survey"></xsl:variable>


  <!-- Indicates whether user has help access -->
  <xsl:variable name="help_user">
    <xsl:choose>
      <xsl:when test="/cp/vsap/vsap[@type='auth']/services/help">1</xsl:when>
      <xsl:otherwise>1</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>



  <!-- Establish Auth Hierarchy used for checking what should be displayed to user.-->
  <!--
    The $platform_type, $user_levels, and $user_attribs variables are used 
    throughout the Help system template rules to easily test and make sure 
    that users only get the content that is appropriate to them.
    These variables are used like this...

    <xsl:if test='contains( $platform_type,  @platform_type) and
                  contains( $user_levels,  @user_access_level) and
                  contains( $user_attribs, @user_attrib_level)'
    >
      <xsl:comment>Stuff appropriate to users accsss level and account options</xsl:comment>
    </xsl:if>
  -->
  <xsl:variable name="platform_type">
    <xsl:value-of select="/cp/vsap/vsap[@type='auth']/platform" />
  </xsl:variable>

  <xsl:variable name="user_levels">
    <xsl:choose>
      <xsl:when test="/cp/vsap/vsap[@type='auth']/server_admin">SA,DA,MA,EU</xsl:when>
      <xsl:when test="/cp/vsap/vsap[@type='auth']/domain_admin">DA,MA,EU</xsl:when>
      <xsl:when test="/cp/vsap/vsap[@type='auth']/mail_admin">MA,EU</xsl:when>
      <xsl:otherwise>EU</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="user_attribs">
    <xsl:choose>
      <!-- Server Admins get access to all capabilities(user_attribs) -->
      <xsl:when test="/cp/vsap/vsap[@type='auth']/server_admin">
        <xsl:for-each select="/cp/vsap/vsap[@type='auth']/capabilities/*">
          <xsl:variable name="uattrib"><xsl:value-of select='name()'/></xsl:variable>
          <xsl:choose>
            <xsl:when test="$uattrib='mail-clamav'">
              <xsl:if test="$clamav_package='1'"><xsl:value-of select='string("mail-clamav,")'/></xsl:if>
            </xsl:when>
            <xsl:when test="$uattrib='mail-spamassassin'">
              <xsl:if test="$spamassassin_package='1'"><xsl:value-of select='string("mail-spamassassin,")'/></xsl:if>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select='name()'/><xsl:value-of select='string(",")'/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
      </xsl:when>
      <!-- Domain Admins and End Users are restricted to list of current services -->
      <xsl:otherwise>
        <xsl:for-each select="/cp/vsap/vsap[@type='auth']/services/*">
          <xsl:variable name="uattrib"><xsl:value-of select='name()'/></xsl:variable>
          <xsl:choose>
            <xsl:when test="$uattrib='mail-clamav'">
              <xsl:if test="$clamav_package='1'"><xsl:value-of select='string("mail-clamav,")'/></xsl:if>
            </xsl:when>
            <xsl:when test="$uattrib='mail-spamassassin'">
              <xsl:if test="$spamassassin_package='1'"><xsl:value-of select='string("mail-spamassassin,")'/></xsl:if>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select='name()'/><xsl:value-of select='string(",")'/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <!-- The current topic page we are displaying -->
  <xsl:variable name='topic'>
    <xsl:choose>
      <xsl:when test='string(/cp/form/topic)'><xsl:value-of select='/cp/form/topic'/></xsl:when>
      <xsl:when test='string(/cp/form/view)'><xsl:value-of select='/cp/form/view'/></xsl:when>
      <xsl:otherwise>
        <!-- 
            If we see that there is a form value specified for category
          it means that we do not need to provide a Default topic
          A Default topic value should only be checked for and supplied
          if there are no form vars indicating that something else other 
          than the default view is being requested.
        -->
        <xsl:choose>
          <xsl:when test='string(/cp/form/category)'></xsl:when>
          <xsl:otherwise>
            <xsl:value-of select='/cp/strings/help_default_topic' />
          </xsl:otherwise>
        </xsl:choose>

      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <!-- The current category of topics we are in. There should always be a category set. -->
  <xsl:variable name='category' >
    <xsl:if test='$topic' /> <!-- Make sure this var is initialized first -->
    <xsl:if test='$view' /> <!-- Make sure this var is initialized first -->
    <xsl:choose>
      <xsl:when test='string(/cp/form/category)'><xsl:value-of select='/cp/form/category'/></xsl:when>
      <xsl:when test='string($topic)'>
        <xsl:value-of select='$help_toc/toc/*/category/topic[@id=$topic]/../@id' />
      </xsl:when>   
      <xsl:when test='string($view)'>
        <xsl:value-of select='$help_toc/toc/*/category/topic[@id=$view]/../@id' />
      </xsl:when>   
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name='glossary_section'>
    <xsl:choose>
      <xsl:when test='string(/cp/form/glossary_section)'>
        <xsl:value-of select='/cp/form/glossary_section' />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select='$help_got/got/section[1]/@title'/>
      </xsl:otherwise>
    </xsl:choose> 
  </xsl:variable>


  <xsl:variable name="image_url">/cpimages/</xsl:variable>
  <xsl:variable name="base_dir">../../../help/</xsl:variable>
  <xsl:variable name="view" select="/cp/form/view" />
  <xsl:variable name='help_language' select='/cp/strings/help_language' />
  <xsl:variable name='topic_dir' select='concat($base_dir, $help_language, "/", $category, "/" )'/>
  <xsl:variable name='help_toc_file' select='concat($base_dir, $help_language, "/", "help_toc.xml")'/>
  <xsl:variable name='help_got_file' select='concat($base_dir, $help_language, "/", "help_got.xml")'/>
  <xsl:variable name='help_faq_file' select='concat($base_dir, $help_language, "/", "help_faq.xml")'/>
  <xsl:variable name='topic_file' select='concat( $topic_dir, $topic, ".xml" )' />
  <xsl:variable name='topic_data' select='document($topic_file )' />
  <xsl:variable name='help_toc' select="document( $help_toc_file )" /> 
  <xsl:variable name='help_got' select="document( $help_got_file )" /> 


  <!-- This will build the "navandcontent" menu for the help section -->
  <xsl:variable name="navandcontent_items">
    <xsl:if test='$user_attribs' /> <!-- Make sure $user_attribs var is set -->
    <xsl:if test='$user_levels' />  <!-- Make sure $user_level var is set -->
    <xsl:if test='$platform_type' />  <!-- Make sure $platform_type var is set -->
    <xsl:if test='$category' />  <!-- Make sure $category var is set -->

    <menu_items>
        <xsl:apply-templates select='$help_toc/toc/section' mode='menu' /> 
    </menu_items>
  </xsl:variable>



  <!-- BEGIN Set of menu generation templates. -->    
    <!-- 
      The $user_attrib, $user_levels, and $platform_type variables are used
      to determine what categories are appropriate. I found that unless these
      variables are accessed before I start looping through the $help_toc tree, 
      the values do not get set right. I believe that this is because for some
      reason I do not have access to the original DOM until I exit the loop again. 
      This may be due to the way I use the ducument() call to populate $help_toc
    -->
	<xsl:template match='topic' mode='menu'>
	  <xsl:if test='not(@hidden) and 
	                contains( $platform_type,  @platform_type) and
	                contains( $user_levels,  @user_access_level) and
	                contains( $user_attribs, @user_attrib_level)'
	  >
	    <item href="?topic={@id}">
	      <xsl:value-of select='@title'/>
	    </item>
	  </xsl:if>
	</xsl:template>
	
	<xsl:template match='section' mode='menu'>
	  <menu id="help_category" name="{@title}">
	    <xsl:apply-templates mode='menu' />
	  </menu>
	</xsl:template>
	
	<xsl:template match='category' mode='menu'>
	  <xsl:if test='not(@hidden) and 
	                contains( $platform_type,  @platform_type) and
	                contains( $user_levels,  @user_access_level) and
	                contains( $user_attribs, @user_attrib_level)'
	  >
	    <item href="?category={@id}">
	      <xsl:value-of select='@title'/>
	    </item>
	  </xsl:if>
	</xsl:template>
  <!-- END Menu specific generation templates. -->



  <xsl:template match='glossary'>
    <xsl:variable name='word' select='@word' />
    <xsl:variable name='definition'>
      <xsl:apply-templates select='$help_got/got/section/term[@title=$word]' />
    </xsl:variable>
    <a href='#' onClick='alert( "{cp:js-escape($definition)}" ); return false' >
      <xsl:value-of select='$word' />
    </a> 
	</xsl:template>

</xsl:stylesheet>
