<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
  xmlns:exslt="http://exslt.org/common"
  exclude-result-prefixes="exslt">

<xsl:import href="help_global.xsl" />

<xsl:variable name="message">
  <xsl:choose>
    <!-- 100 -->
    <xsl:when test="/cp/msgs/msg[@name='help_search_query_too_short']">
      <xsl:copy-of select="/cp/strings/help_search_query_too_short" />
    </xsl:when>
    <!-- 101 -->
    <xsl:when test="/cp/msgs/msg[@name='help_invalid_language']">
      <xsl:copy-of select="/cp/strings/help_invalid_language" />
    </xsl:when>
    <!-- 102 -->
    <xsl:when test="/cp/msgs/msg[@name='help_no_search_results']">
      <xsl:copy-of select="/cp/strings/help_no_search_results" />
    </xsl:when>
    <!-- 103 -->
    <xsl:when test="/cp/msgs/msg[@name='help_invalid_category']">
      <xsl:copy-of select="/cp/strings/help_invalid_category" />
    </xsl:when>
    <!-- 104 -->
    <xsl:when test="/cp/msgs/msg[@name='help_invalid_toc_file']">
      <xsl:copy-of select="/cp/strings/help_invalid_toc_file" />
    </xsl:when>
    <!-- 105 -->
    <xsl:when test="/cp/msgs/msg[@name='help_invalid_toc_xml']">
      <xsl:copy-of select="/cp/strings/help_invalid_toc_xml" />
    </xsl:when>
    <!-- 106 -->
    <xsl:when test="/cp/msgs/msg[@name='help_invalid_got_file']">
      <xsl:copy-of select="/cp/strings/help_invalid_got_file" />
    </xsl:when>
    <!-- 107 -->
    <xsl:when test="/cp/msgs/msg[@name='help_invalid_got_xml']">
      <xsl:copy-of select="/cp/strings/help_invalid_got_xml" />
    </xsl:when>
    <!-- 108 -->
    <xsl:when test="/cp/msgs/msg[@name='help_invalid_faq_file']">
      <xsl:copy-of select="/cp/strings/help_invalid_faq_file" />
    </xsl:when>
    <!-- 109 -->
    <xsl:when test="/cp/msgs/msg[@name='help_invalid_faq_xml']">
      <xsl:copy-of select="/cp/strings/help_invalid_faq_xml" />
    </xsl:when>
    <!-- 110 -->
    <xsl:when test="/cp/msgs/msg[@name='help_invalid_topic_file']">
      <xsl:copy-of select="/cp/strings/help_invalid_topic_file" />
    </xsl:when>
    <!-- 111 -->
    <xsl:when test="/cp/msgs/msg[@name='help_invalid_topic_xml']">
      <xsl:copy-of select="/cp/strings/help_invalid_topic_xml" />
    </xsl:when>
    <!-- 112 -->
    <xsl:when test="/cp/msgs/msg[@name='help_invalid_language']">
      <xsl:copy-of select="/cp/strings/help_invalid_language" />
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

<xsl:variable name='selected_nav'>
<xsl:if test='$topic'/>
<xsl:if test='$category'/>
  <xsl:choose>
    <xsl:when test='$help_toc/toc/*/topic[@id=$topic]/@title' >
      <xsl:value-of select='$help_toc/toc/*/topic[@id=$topic]/@title' />
    </xsl:when>
    <xsl:when test='string($category)'>
      <xsl:value-of select='$help_toc/toc/*/category[@id=$category]/@title' />
    </xsl:when>
  </xsl:choose>
</xsl:variable>

<xsl:variable name='section_image'>
<xsl:if test='$topic'/>
<xsl:if test='$category'/>
  <xsl:choose>
    <xsl:when test='$help_toc/toc/*/topic[@id=$topic]/@image' >
      <xsl:value-of select='$help_toc/toc/*/topic[@id=$topic]/@image' />
    </xsl:when>
    <xsl:when test='string($category)'>
      <xsl:value-of select='$help_toc/toc/*/category[@id=$category]/@image' />
    </xsl:when>
  </xsl:choose>
</xsl:variable>

<xsl:template match="/">
  <xsl:choose>
    <!-- Just print the topic data out, if a view is requested. -->
    <xsl:when test='string($view)'>
      <xsl:call-template name='printbodywrapper'>
        <xsl:with-param name="title">
          <xsl:copy-of select="/cp/strings/help_title" />
        </xsl:with-param>
        <xsl:with-param name="content">
          <!-- Styles specific only to Help topics -->
          <style type="text/css" media="screen">
            @import url(/cpimages/onlinehelp.css);
          </style>
          <xsl:apply-templates select='$topic_data/*' mode='printable' />
        </xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>

      <xsl:call-template name="bodywrapper">
        <xsl:with-param name="title">
          <xsl:copy-of select="/cp/strings/help_title" />
        </xsl:with-param>
        <xsl:with-param name="formaction">index.xsl</xsl:with-param>
        <xsl:with-param name="selected_navandcontent" select='$selected_nav' />
        <xsl:with-param name="feedback" select="$feedback" />

        <xsl:with-param name="breadcrumb" >
          <breadcrumb>
            <section>
              <name><xsl:value-of select='$selected_nav' /></name>
              <url>?category=<xsl:value-of select="$category" /></url>
              <image><xsl:value-of select='$section_image' /></image>
            </section>
            <xsl:choose>
              <xsl:when test='($topic != $selected_nav) and string($help_toc/toc/*/category/topic[@id=$topic]/@title)'>
                <section>
                  <name><xsl:value-of select="$help_toc/toc/*/category/topic[@id=$topic]/@title"/></name>
                  <url>#</url>
                  <image><xsl:value-of select='$section_image' /></image>
                </section>
              </xsl:when>
            </xsl:choose>
         </breadcrumb>
       </xsl:with-param>
      </xsl:call-template>

    </xsl:otherwise>
  </xsl:choose>

</xsl:template>

<xsl:template name="content">

			    <!-- Styles specific only to Help topics -->
			    <style type="text/css" media="screen">
			        @import url(/cpimages/onlinehelp.css);
			    </style>
			    <script src="{concat($base_url, '/cp/cp.js')}" language="JavaScript"></script>
			    <script src="{concat($base_url, '/data_table_obj.js')}" language="JavaScript1.2"></script>
			    <script src="{concat($base_url, '/help/help.js')}" language="JavaScript1.2"></script>
			
			    <a name='top'/>
			    <table id="formview" border="0" cellspacing="0" cellpadding="0">
			    <tr>
			      <td>
			      <!-- BEGIN main content area -->
			
			        <xsl:comment>
			          CATEGORY[<xsl:value-of select='$category'/>] TOPIC[<xsl:value-of select='$topic'/>]
			        </xsl:comment>
			
			        <!--
			          BEGIN Dynamic content area.
			          This area is used by all content in the Help App.  
			        -->
			        <xsl:choose>
			          <!-- If a Search was done... -->
			          <xsl:when test="/cp/vsap/vsap[@type='help:search']">
			            <xsl:apply-templates 
                    select="/cp/vsap/vsap[@type='help:search']" mode='search' />
			          </xsl:when>
			          <xsl:when test='$topic = "glossary"'>
			             <xsl:call-template name='glossary_view' />
			          </xsl:when>
			          <xsl:when test='$topic = "getting_started"'>
			             <xsl:call-template name='getting_started_topic' />
			          </xsl:when>
			          <xsl:when test='$topic = "faq"'>
			             <xsl:call-template name='faq_topic' />
			          </xsl:when>
			          <xsl:when test='string($topic)'>
			             <xsl:call-template name='topic_view' />
			          </xsl:when>
			          <!-- Default view. Category topic listings. -->
			          <xsl:otherwise>
			            <xsl:call-template name='topic-list' />
			          </xsl:otherwise>
			        </xsl:choose>
			        <br />

			        <!-- BEGIN SEARCH AREA -->
			        <table id="searchtopic" class='listview' border="0" cellspacing="0" cellpadding="0">
			        <tr class="title">
			          <td colspan="2"><xsl:copy-of select='/cp/strings/help_search' /></td>
			        </tr>
			        <tr>
			          <td class="icon"><br /></td>
			          <td>
			            <xsl:copy-of select='/cp/strings/help_search_for' /><br />
			            <hr />
			            <input name="query" type="text" size="30" /> -in-
			            <select name="category" size="1">
			              <option value='all'>
			                <xsl:value-of select='/cp/strings/help_all_categories'/>
			              </option>
			              <xsl:for-each select='$help_toc/toc/*/category'> 
			                <xsl:if test='not(@hidden) and
			                              contains( $platform_type,  @platform_type) and
			                              contains( $user_levels,  @user_access_level) and
			                              contains( $user_attribs, @user_attrib_level)'
			                >
			                  <option value="{@id}">
			                    <xsl:if test="@id = $category">
			                      <xsl:attribute name='selected'>1</xsl:attribute>
			                    </xsl:if>
			                    <xsl:value-of select='@title'/>
			                  </option>
			                </xsl:if>
			              </xsl:for-each>
			            </select> &#160;
			            <input type="submit" name="btn_search" value="{/cp/strings/help_search_btn}" 
			              onClick="return validateSearch( 
			                document.forms[0].query,
			                '{/cp/strings/help_search_query_required}',
			                '{/cp/strings/help_search_query_too_short}',
			                '{/cp/strings/help_search_query_invalid}');"
			            />       
			            <br />
			            <input name="language" type="hidden" value="{$help_language}" />
			            <input name="case_sensitive" id="case_sensitive_search" type="checkbox" value="Case Sensitive" />
			            <label for="case_sensitive_search"><xsl:value-of select="/cp/strings/help_case_btn" /></label> 
			          </td>
			        </tr>
			        </table>
			        <br />
			        <!-- END SEARCH AREA -->
			
			      <!-- END main content area -->
			      </td>
			    </tr>
			    </table>

</xsl:template>



<xsl:template match="vsap[@type='help:search']" mode='search'>
<table id='table0' class='listview'  border="0" cellspacing="0" cellpadding="0">
  <tr class="columnhead">
    <td class="" colspan="3">
      <xsl:copy-of select='/cp/strings/help_search_results_for'/>&#160;
      "<xsl:value-of select='/cp/form/query'/>"
    </td>
  </tr>
  <tr class="controlrow">
    <td colspan="3">
      <span class="floatright">
        <xsl:copy-of select='/cp/strings/help_results'/> 
        <span id='record_number0'></span>&#160;of <span id='record_total0'></span>&#160;| 
        <a href='#' id='first_a0' onClick="data_table0.page('first');">First</a> | 
        <a href='#' id='prev_a0' onClick="data_table0.page('prev');">Prev</a> | 
        <a href='#' id='next_a0' onClick="data_table0.page('next');">Next</a> | 
        <a href='#' id='last_a0' onClick="data_table0.page('last');">Last</a> 
      </span>
      View 
      <select id='page_size0' name="page_size0" size="1" onchange='data_table0.page()' >
        <option value="5" selected='1'>5</option>
        <option value="10">10</option>
        <option value="15">15</option>
        <option value="20">20</option>
      </select> 
      <xsl:copy-of select='/cp/strings/help_results_per_page'/>
    </td>
  </tr>
  <tr class="columnhead">
    <td class=""><xsl:copy-of select='/cp/strings/help_results'/></td>
    <td class="domaincolumn"><a href=""><xsl:copy-of select='/cp/strings/help_category'/></a></td>
    <td class="domaincolumn">&#160;</td>
  </tr>

  <!-- Populate ALL of the search results set in this table. The data_table_obj
    will read this table in, and allow the data to be paged through in pages.
    This should just be a bunch of topic elements.
  -->
  <xsl:apply-templates mode='search' />

  </table>
  <!-- Create the data_table_obj that will be used to navigate the 
    search results set.
  -->
  <script language='Javascript1.2'>
    var data_table0 = new data_table_obj( 
      'table0', 
      '', 
      3,
      'page_size0', 
      'page_number0', 
      'page_total0', 
      'record_number0',
      'record_total0',
      'first_a0',
      'prev_a0',
      'next_a0',
      'last_a0',
      'nav_active',
      'nav_inactive',
      'rowodd',
      'roweven',
      '/cpimages/arrow_up.gif',
      '/cpimages/arrow_down.gif'
    ); 
  </script>
</xsl:template>


<!-- Used to display the main topic data when a topic has been selected. -->
<xsl:template name='topic_view' >

<!--
  Always shows first topic in current list.

	<xsl:variable name='prev_topic' 
		select='$help_toc/toc/*/category/topic[@id=$topic]/preceding-sibling::topic/@id'/>
-->

<!--
  Get nothing in Prev_topic
	<xsl:variable name='prev_topic' 
		select='$help_toc/toc/*/category/preceding-sibling::topic[@id=$topic]/@id'/>
-->

	<xsl:variable name='prev_topic' 
		select='$help_toc/toc/*/category/topic[@id=$topic]/preceding-sibling::topic[1]/@id'/>

	<xsl:variable name='next_topic' 
		select='$help_toc/toc/*/category/topic[@id=$topic]/following-sibling::topic/@id'/>

	<xsl:comment><xsl:value-of select='$topic_file'/></xsl:comment>
	<table class="listview" border="0" cellspacing="0" cellpadding="0">
  <tr class="title">
		<td><xsl:value-of select='$topic_data/topic/title'/></td>
	</tr>
  <tr>
    <td>
      <span class="floatright">
        <a href="#" onClick='helpWindow( "?view={$topic}" ); return false;' >
          <xsl:value-of select='/cp/strings/help_printable_view' /></a>
      </span>
    </td>
  </tr>
	<tr>
		<td>			 
			<xsl:choose>
				<!-- see if we have content. -->				 
				<xsl:when test='string($topic_data/topic/title)'>
					<xsl:apply-templates select='$topic_data/topic/*' />
				</xsl:when>
				<xsl:otherwise>
					<xsl:copy-of select='/cp/strings/help_no_content'/>
				</xsl:otherwise>
			</xsl:choose>
		</td>
	</tr>
	<tr class="controlrow" >
		<td>
			<xsl:if test='string($next_topic)'>
				<input class="floatright" type="button" name="next_topic" 
          value="{/cp/strings/help_next_topic}" 
          onClick='window.location.href = "?topic={$next_topic}"'/>
			</xsl:if>
			<xsl:if test='string($prev_topic)'>
				<input class="floatright" type="button" name="prev_topic" 
          value="{/cp/strings/help_previous_topic}"
					onClick='window.location.href="?topic={$prev_topic}"' />
			</xsl:if>
		</td>
	</tr>
	</table>
	<!-- this can be toggled on and off in help_global.xsl -->
	<xsl:if test='$display_help_survey' >
		<xsl:call-template name='help_survey' />
	</xsl:if>
</xsl:template>
	

<xsl:template match='topic' mode='printable' >
  <p class='help-h2'><xsl:value-of select='$topic_data/topic/title'/></p>
  <xsl:apply-templates />
</xsl:template>


<xsl:template name='topic'>
  <xsl:param name='new_info_avail'/>
  <xsl:variable name="row_style">
    <xsl:choose>
      <xsl:when test="position() mod 2 = 0">roweven</xsl:when>
      <xsl:otherwise>rowodd</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <tr class="{$row_style}">
    <td><a href='?topic={@id}'><xsl:value-of select="@title"/></a></td>
    <xsl:choose>
      <xsl:when test="@new">
        <td><span class="new"><xsl:value-of select='$new_info_avail'/></span></td>
      </xsl:when>
      <xsl:otherwise>
        <td>&#160;</td>
	    </xsl:otherwise>
	  </xsl:choose>
    <td><br/></td>
  </tr>
</xsl:template>

<xsl:template name='topic-list'>
  <xsl:variable name='cat'>
    <xsl:choose>
      <xsl:when test='string($category)'><xsl:value-of select='$category'/></xsl:when>
      <xsl:otherwise><xsl:value-of select='/cp/strings/help_default_category'/></xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <xsl:variable name='new_info_avail' select='/cp/strings/help_new_info_avail'/>

  <table class="listview" border="0" cellspacing="0" cellpadding="0">
  <tr class="title">
    <td class="">
      <xsl:value-of select='$help_toc/toc/*/category[@id=$cat]/@title'/>
    </td>
    <td class="domaincolumn" colspan="2">&#160;</td>
  </tr>
  <!-- This needs to be called like this, so that the string for 'new_info_avail' 
    is available. Once we either apply-templates to the nodeset, or step into a
    for-each loop we will no longer have access to the strings info.
    This is why we do a call-template here rather than an apply-templates.
  -->
  <xsl:for-each select='$help_toc/toc/*/category[@id=$cat]/topic' >
    <xsl:if test='not(@hidden) and
                  contains( $platform_type,  @platform_type) and
                  contains( $user_levels,  @user_access_level) and
                  contains( $user_attribs, @user_attrib_level)'
    >
      <xsl:call-template name='topic' >
        <xsl:with-param name='new_info_avail' select='$new_info_avail'/>
      </xsl:call-template>
    </xsl:if>
  </xsl:for-each>
  
  </table>
</xsl:template>

<!-- 
  topic template for list display in search results view.
-->
<xsl:template match='topic' mode='search'>
  <xsl:variable name="row_style">
    <xsl:choose>
      <xsl:when test="position() mod 2 = 0">roweven</xsl:when>
      <xsl:otherwise>rowodd</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <xsl:variable name='id' select='@id' />
  <xsl:variable name='category' select='@category' />

  <tr class="{$row_style}">
    <td>
      <a href="?topic={@id}">
        <xsl:value-of 
          select="$help_toc/toc/*/category[@id=$category]/topic[$id=@id]/@title" />
      </a>
    </td>
    <td> <xsl:value-of select="$help_toc/toc/*/category[@id=$category]/@title" /> </td>
    <td>
      <xsl:if test='@new = 1'>
        <span class="new"><xsl:value-of select='/cp/strings/help_new_info_avail' /></span>
      </xsl:if>
    </td>
  </tr>
</xsl:template>


<xsl:template name='getting_started_topic'>
  <xsl:variable name='new_info_avail' select='/cp/strings/help_new_info_avail'/>
  <table class="listview" border="0" cellspacing="0" cellpadding="0">
  <tr class="title">
    <td colspan='3'><xsl:value-of select='$topic_data/topic/title'/></td>
  </tr>
  <tr class="controlrow">
    <td colspan="3">
      Choose a topic from the categories below.
    </td>
  </tr>
  <xsl:for-each select='$help_toc/toc/section/category' >
    <xsl:if test='not(@hidden) and
                  contains( $platform_type,  @platform_type) and
                  contains( $user_levels,  @user_access_level) and
                  contains( $user_attribs, @user_attrib_level)'
    >
      <xsl:call-template name='category'>
        <xsl:with-param name='new_info_avail'>
          <xsl:value-of select='$new_info_avail'/> 
        </xsl:with-param>
      </xsl:call-template>
    </xsl:if>
  </xsl:for-each>
  </table>
</xsl:template>


<xsl:template name='category'>
  <xsl:param name='new_info_avail'/>
  <xsl:if test='topic'>
    <tr class="columnhead">
      <td class=""><xsl:value-of select='@title'/></td>
      <td class="domaincolumn" colspan="2">&#160;</td>
    </tr>
    <!-- This needs to be called like this, so that the string for 'new_info_avail' 
      is available. Once we either apply-templates to the nodeset, or step into a
      for-each loop we will no longer have access to the strings info.
      This is why we do a call-template here rather than an apply-templates,
      so that this val can be passed along.
    -->
    <xsl:for-each select='topic' >
      <xsl:if test='not(@hidden) and
                   contains( $platform_type,  @platform_type) and
                   contains( $user_levels,  @user_access_level) and
                   contains( $user_attribs, @user_attrib_level)'
      >
        <xsl:call-template name='topic' >
          <xsl:with-param name='new_info_avail' select='$new_info_avail'/>
        </xsl:call-template>
      </xsl:if>
    </xsl:for-each>
  </xsl:if>
</xsl:template>


<!--
  Survey display element that appears at the bottom 
  of every topic data display
-->
<xsl:template name='help_survey'>
  <br />
  <table class="listview" border="0" cellspacing="0" cellpadding="0">
  <tr class="title">
    <td>Feedback</td>
  </tr>
  <tr>
    <td>
      <strong>Was this information useful to you?</strong>
      <blockquote>
        <input type="radio" id="useful_yes" name="useful" value="yes" /><label for="useful_yes">Yes</label><br />
        <input type="radio" id="useful_no" name="useful" value="no" /><label for="useful_no">No</label><br />
      </blockquote>
    </td>
  </tr>
  <tr>
    <td>
      <strong>Didn't get your question answered, or have another topic suggestion for help?</strong>
      <blockquote>
        Enter it here: <input type="text" size="40" />
      </blockquote>
    </td>
  </tr>
  <tr class="controlrow">
    <td><input class="floatright" type="submit" name="submitButtonName" value="Submit"/></td>
  </tr>
  </table>
  <br />
</xsl:template>


<xsl:template name='faq_topic'>
  <xsl:variable name='help_faq' select="document( $help_faq_file )" /> 
  <xsl:variable name='cat'>
    <xsl:choose>
      <xsl:when test='string($category)'><xsl:value-of select='$category'/></xsl:when>
      <xsl:otherwise></xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:comment><xsl:value-of select='$topic_file'/></xsl:comment>
  <table class="listview" border="0" cellspacing="0" cellpadding="0">
  <tr class="title">
    <td><xsl:copy-of select='/cp/strings/help_faq'/></td>
  </tr>
  <tr class="controlrow">
     <td>

        <span class="floatright">
          <xsl:copy-of select='/cp/strings/help_view'/>
          <select id='page_size0' name="page_size0" size="1"
            onchange='data_table0.page(); data_table1.page();' >
            <option value="5" selected='1'>5</option>
            <option value="10">10</option>
            <option value="15">15</option>
            <option value="20">20</option>
          </select>
          <xsl:copy-of select='/cp/strings/help_topics_per_page'/><br />
          <span id='record_number0'></span>&#160;of <span id='record_total0'></span>&#160;|
          <a href='#' id='first_a0' onClick="data_table0.page('first'); data_table1.page('first');">First</a> |
          <a href='#' id='prev_a0' onClick="data_table0.page('prev'); data_table1.page('prev');">Prev</a> |
          <a href='#' id='next_a0' onClick="data_table0.page('next'); data_table1.page('next');">Next</a> |
          <a href='#' id='last_a0' onClick="data_table0.page('last'); data_table1.page('last');">Last</a>
        </span>
        <xsl:copy-of select='/cp/strings/help_view_faq_in'/> 

        <select name="category" size="1" 
          onchange='getElementById("cat").innerHTML=this.options[this.selectedIndex].text;data_table0.search( this.value, 0, 1);data_table1.search( this.value, 1, 1);'>
          <option value=' '><xsl:value-of select='/cp/strings/help_all_categories'/></option>
          <xsl:for-each select='$help_faq/faq/category'>
            <xsl:if test='not(@hidden) and
                          contains( $platform_type,  @platform_type) and
                          contains( $user_levels,  @user_access_level) and
                          contains( $user_attribs, @user_attrib_level)'
            >
              <option value="{@id}">
              <xsl:if test="@id = $cat">
                <xsl:attribute name='selected'>1</xsl:attribute>
              </xsl:if>
                <xsl:value-of select='@title'/>
              </option>
            </xsl:if>
          </xsl:for-each>
        </select> &#160;

      </td>
    </tr>

    <tr class="columnhead">
      <td>
        Category: <span id='cat'><xsl:value-of select='/cp/strings/help_all_categories'/></span>
      </td>
    </tr>

    <tr>
      <td>
        <a name="top"></a>
        <table class='qa' id='link_data_table' border='0' cellspacing="0" cellpadding="0">
          <xsl:apply-templates select='$help_faq/faq/category/question' mode='list'/> 
        </table>
      </td>
    </tr>
    </table>

    <table id='faq_data_table' class='faq' border="0" cellspacing="0" cellpadding="0" width='740'>
      <xsl:apply-templates select='$help_faq/faq/category/question' /> 
    </table>

    <script language='Javascript1.2'>
      var data_table0 = new data_table_obj(
        'faq_data_table',
        '',
        0,
        'page_size0',
        'page_number0',
        'page_total0',
        'record_number0',
        'record_total0',
        'first_a0',
        'prev_a0',
        'next_a0',
        'last_a0',
        'nav_active',
        'nav_inactive',
        '',
        '',
        '',
        ''
      );

      var data_table1 = new data_table_obj(
        'link_data_table',
        '',
        0,
        'page_size0',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        '',
        'nav_active',
        'nav_inactive',
        '',
        '',
        '',
        ''
      );
    </script>
</xsl:template>


<xsl:template match='question'>
  <xsl:if test='not(@hidden) and
                contains( $platform_type,  @platform_type) and
                contains( $user_levels,  @user_access_level) and
                contains( $user_attribs, @user_attrib_level)'
  >
	  <tr>
	    <td>
	      <a name='{@id}'></a>
	      <div style='display:none'><xsl:value-of select='@id'/></div>
			  <table class='qa2' border='0' width='100%' cellspacing='0' cellpadding='0'>
			  <tr class='controlrow'>
			    <td>
			      <a href="#top"><span class="floatright">top</span></a>
			      <b><xsl:value-of select='@title'/><a name="{@id}"></a></b>
			    </td>
			  </tr>
			  <tr >
			    <td> <xsl:apply-templates select='answer'/> </td>
			  </tr>
			  </table>
	    </td>
	  </tr>
  </xsl:if>
</xsl:template>

<xsl:template match='question' mode='list'>
  <xsl:if test='not(@hidden) and
                contains( $platform_type,  @platform_type) and
                contains( $user_levels,  @user_access_level) and
                contains( $user_attribs, @user_attrib_level)'
  >
	  <tr>
	    <td><a href="#{@id}"><xsl:value-of select='@title'/></a></td>
	    <td width='0'>
	      <!-- The value in this TD is not to be displayed. it is here only for the usage
	        of the search function of the data_table_obj.
	        When a category of FAQ topics is selected from the SELECT pulldown, 
	        an "onchange='data_table0.search( this.value, 1, 1 )" is done. This way
	        all but thatcategory of question is displayed.
	      -->
	      <div style='display:none'><xsl:value-of select='@id'/></div>
	    </td>
	  </tr>
  </xsl:if>
</xsl:template>



<xsl:template name='glossary_view'>
  <xsl:variable name='glossary-menu'>
	  <tr class="controlrow">
	    <td colspan="2">
        <!--<a href="#top"><span class="floatright">top</span></a>-->
	      Go to:
	      <xsl:for-each select='$help_got/got/section'>
          <xsl:if test='not(@hidden) and
                        contains( $platform_type,  @platform_type) and
                        contains( $user_levels,  @user_access_level) and
                        contains( $user_attribs, @user_attrib_level)'
          >
	          |
	          <xsl:choose>
	            <xsl:when test='$glossary_section = @title'>
	              <b><xsl:value-of select='@title'/></b>
	            </xsl:when>
	            <xsl:otherwise>
	              <a href='?topic=glossary&amp;glossary_section={@title}'>
	                <xsl:value-of select='@title'/>
	              </a>
	            </xsl:otherwise>
	          </xsl:choose>
          </xsl:if>
	      </xsl:for-each>
	    </td>
	  </tr>
  </xsl:variable>

  <table class="listview" border="0" cellspacing="0" cellpadding="0">
  <tr class="title">
    <td colspan='2'><xsl:value-of select='$topic_data/topic/title'/></td>
  </tr>
  <xsl:copy-of select='$glossary-menu'/>
  <tr class="controlrow">
    <td colspan="2">
      <strong><xsl:value-of select='$glossary_section' /><a name="A"></a></strong>
    </td>
  </tr>

  <xsl:for-each select='$help_got/got/section[@title=$glossary_section]/term' >
    <xsl:if test='not(@hidden) and
                  contains( $platform_type,  @platform_type) and
                  contains( $user_levels,  @user_access_level) and
                  contains( $user_attribs, @user_attrib_level)'
    >
      <tr class="roweven">
        <td><b><xsl:value-of select='@title'/></b></td>
        <td><xsl:apply-templates select='.' /></td>
      </tr>
    </xsl:if>
  </xsl:for-each>

  <xsl:copy-of select='$glossary-menu'/>
</table>

<xsl:apply-templates select='$topic_data/topic/*'/>

</xsl:template>

<!--                                     -->
<!-- BEGIN topic specific template rules -->
<!--                                     -->

<xsl:template match='section-list' >
  <xsl:variable name='set' select='@set'/>
  <xsl:choose>
    <xsl:when test='@title'>
      <p class='help-h3'><xsl:value-of select='@title'/></p>
    </xsl:when>
    <xsl:otherwise>
      <p class='help-h3'>This topic contains the following sections:</p>
    </xsl:otherwise>
  </xsl:choose>

  <ul>
    <xsl:for-each select='$topic_data/topic/section'>
      
      <xsl:if test='not(@hidden) and
                    contains( $platform_type,  @platform_type) and
                    contains( $user_levels,  @user_access_level) and
                    contains( $user_attribs, @user_attrib_level)'
      >
        <xsl:if test='string(@set) = string($set)'>
          <li class='help-list-ul-1'>
            <a href='#{@id}'>
            <xsl:choose>
              <xsl:when test='@title'><xsl:value-of select='@title'/></xsl:when>
              <xsl:when test='title'>
                <xsl:apply-templates select='title' mode='link'/>
              </xsl:when>
            </xsl:choose>
            </a>
          </li>
        </xsl:if>
      </xsl:if>
    </xsl:for-each>
  </ul>
</xsl:template>


<xsl:template match='keywords' />

<xsl:template match='topic/title' >
  <!-- The title is displayed manually in the main page body. -->
  <!-- <h2><xsl:apply-templates /></h2> -->
</xsl:template>



<xsl:template match='section'>
  <xsl:if test='not(@hidden) and
                contains( $platform_type,  @platform_type) and
                contains( $user_levels,  @user_access_level) and
                contains( $user_attribs, @user_attrib_level)'
  >
    <a name='{@id|@name}'/>
    <xsl:apply-templates />
    <xsl:choose>
      <xsl:when test='@options = "top_link"' >
        <a href='#top' class='aLink'>Back to Top</a>
      </xsl:when>
    </xsl:choose>
    <!-- As long as were not the last section, put an HR between us and the next one. -->
    <xsl:if test="last() != position()" ><hr /></xsl:if>   
  </xsl:if>
</xsl:template>

<xsl:template match='section/title'>
  <p class='help-h3'><xsl:apply-templates/></p>
</xsl:template>


<!--
  P element represents a paragraph of text.
  Access to this element can be controlled thorugh the use of 

  - platform_type
      Valid values are freebsd4, freebsd6, and linux
      The platform must be the specified type in order for this block 
      to be displayed.
  - user_access_level
      Valid values are SA, DA, MA, and EU. 
      A user must be a least the spcified level in order for this block 
      to be displayed.
  - user_attrib_level
      These represent the 'capabilities' of the user. 
      A user must have the specified capability in order for this block 
      to be displayed.
-->
<xsl:template match='p' >
  <xsl:if test='not(@hidden) and
                contains( $platform_type,  @platform_type) and
                contains( $user_levels,  @user_access_level) and
                contains( $user_attribs, @user_attrib_level)'
  >
    <p class='help-text-normal'><xsl:apply-templates /></p>
  </xsl:if>
</xsl:template>


<!--
  OL element represents an Ordered list container of LI elements.
-->
<xsl:template match='ol' >
  <xsl:if test='not(@hidden) and
                contains( $platform_type,  @platform_type) and
                contains( $user_levels,  @user_access_level) and
                contains( $user_attribs, @user_attrib_level)'
  >
    <xsl:if test='string(@title)'>
      <p class='help-h3'><xsl:value-of select='@title' /></p>
    </xsl:if>
    <ol><xsl:apply-templates /></ol>
  </xsl:if>
</xsl:template>

<xsl:template match='ol/li' >
  <xsl:if test='not(@hidden) and
                contains( $platform_type,  @platform_type) and
                contains( $user_levels,  @user_access_level) and
                contains( $user_attribs, @user_attrib_level)'
  >
    <li class='help-list-ol-1'><xsl:apply-templates /></li>
  </xsl:if>
</xsl:template>

<xsl:template match='ol/ol/li | ul/ol/li | ul/li/ol/li | ol/li/ol/li' >
  <xsl:if test='not(@hidden) and
                contains( $platform_type,  @platform_type) and
                contains( $user_levels,  @user_access_level) and
                contains( $user_attribs, @user_attrib_level)'
  >
    <li class='help-list-ol-2'><xsl:apply-templates /></li>
  </xsl:if>
</xsl:template>


<!--
  UL element represents an UNordered list container of LI elements.
-->
<xsl:template match='ul' >
  <xsl:if test='not(@hidden) and
                contains( $platform_type,  @platform_type) and
                contains( $user_levels,  @user_access_level) and
                contains( $user_attribs, @user_attrib_level)'
  >
    <p class='help-h3'><xsl:value-of select='@title' /></p>
    <ul><xsl:apply-templates /></ul>
  </xsl:if>    
</xsl:template>
<xsl:template match='ul/li' >
  <xsl:if test='not(@hidden) and
                contains( $platform_type,  @platform_type) and
                contains( $user_levels,  @user_access_level) and
                contains( $user_attribs, @user_attrib_level)'
  >
    <li class='help-list-ul-1'><xsl:apply-templates /></li>
  </xsl:if>
</xsl:template>
<xsl:template match='ul/ul/li | ol/ul/li | ol/li/ul/li | ul/li/ul/li' >
  <xsl:if test='not(@hidden) and
                contains( $platform_type,  @platform_type) and
                contains( $user_levels,  @user_access_level) and
                contains( $user_attribs, @user_attrib_level)'
  >
    <li class='help-list-ul-2'><xsl:apply-templates /></li>
  </xsl:if>
</xsl:template>



<!-- 
  EM element is used to specify blocks of text that should receive special 
  emphasis when displayed. How this emphasis is displayed may vary depending 
  on the platform that it is displayed on. The type attribute specifies 
  what  type of emphasis is prefered.
-->
<xsl:template match='em' >
  <xsl:choose>
    <xsl:when test='@type = "bold"' >
      <span class='help-text-bold'><xsl:apply-templates /></span>
    </xsl:when>
    <xsl:when test='@type = "italic"' >
      <span class='help-text-italic'><xsl:apply-templates /></span>
    </xsl:when>
    <xsl:when test='@type = "bu"' >
      <span class='help-text-blue-underlined'><xsl:apply-templates /></span>
    </xsl:when>
    <xsl:when test='@type = "rb"' >
      <span class='help-text-red-bold'><xsl:apply-templates /></span>
    </xsl:when>
  </xsl:choose>
</xsl:template>


<!--
  CODE element is used to specify blocks of text that represent 
  actual code snippets.
-->
<xsl:template match='code' >
  <p class='help-text-code'><pre><xsl:apply-templates /></pre></p>
</xsl:template>


<!-- 
  A element specifies a link to another Help topic, or outside media.
-->
<xsl:template match="a">
  <xsl:choose>
    <xsl:when test='@topic'>
      <xsl:call-template name='topic_link'>
        <xsl:with-param name='topic' select='@topic'/>
        <xsl:with-param name='text'>
          <xsl:apply-templates />
        </xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <xsl:copy>
        <xsl:copy-of select='@*'/>
        <xsl:apply-templates />
      </xsl:copy>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- Used in the A template. -->
<xsl:template name='topic_link'>
  <xsl:param name='topic' />
  <xsl:param name='text' />
  <a href='?topic={$topic}'> 
    <xsl:value-of select='$text' />
  </a>
</xsl:template>

<!--
  IMG element represents image content.
-->
<xsl:template match='img'>
  <p class='help-text-normal'><img src='{$image_url}{@src}'/></p>
</xsl:template>

</xsl:stylesheet>
