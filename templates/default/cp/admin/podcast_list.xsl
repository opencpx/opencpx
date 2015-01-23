<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../cp_global.xsl" />

<xsl:variable name="colspan">5</xsl:variable>

<xsl:variable name="sort_by">
  <xsl:choose>
    <xsl:when test="string(/cp/form/sort_by)"><xsl:value-of select="/cp/form/sort_by" /></xsl:when>
    <xsl:otherwise>title</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="sort_type">
  <xsl:choose>
    <xsl:when test="string(/cp/form/sort_type)"><xsl:value-of select="/cp/form/sort_type" /></xsl:when>
    <xsl:otherwise>ascending</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="sec_sort_by">
  <xsl:choose>
    <xsl:when test="string(/cp/form/sec_sort_by)"><xsl:value-of select="/cp/form/sec_sort_by" /></xsl:when>
    <xsl:otherwise>added</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="sec_sort_type">
  <xsl:choose>
    <xsl:when test="string(/cp/form/sec_sort_type)"><xsl:value-of select="/cp/form/sec_sort_type" /></xsl:when>
    <xsl:otherwise>descending</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="item_list">
  <xsl:choose>
    <xsl:when test="string(/cp/form/item_list)"><xsl:value-of select="/cp/form/item_list" /></xsl:when>
    <xsl:otherwise>off</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="ruid">
  <xsl:choose>
    <xsl:when test="string(/cp/form/ruid)"><xsl:value-of select="/cp/form/ruid" /></xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="basic_sort_url">podcast_list.xsl?</xsl:variable>
<xsl:variable name="basic_edit_url">podcast_feed_add.xsl?edit=1&amp;ruid=</xsl:variable>
<xsl:variable name="basic_delete_url">podcast_list.xsl?delete=feed&amp;ruid=</xsl:variable>
<xsl:variable name="basic_publish_url">podcast_list.xsl?publish=feed&amp;ruid=</xsl:variable>
<xsl:variable name="basic_add_url">podcast_item_add.xsl?ruid=</xsl:variable>

<xsl:variable name="message">
  <xsl:if test="string(/cp/msgs/msg)">
    <xsl:copy-of select="/cp/strings/*[local-name()=/cp/msgs/msg/@name]" />
  </xsl:if>
</xsl:variable>

<xsl:variable name="feedback">
  <xsl:if test="$message != ''">
    <xsl:call-template name="feedback_table">
      <xsl:with-param name="image">
        <xsl:choose>
          <xsl:when test="/cp/vsap/vsap[@type='error'] or /cp/msgs/msg='error'">error</xsl:when>
          <xsl:otherwise>success</xsl:otherwise>
        </xsl:choose>
      </xsl:with-param>
      <xsl:with-param name="message">
        <xsl:copy-of select="$message" />
      </xsl:with-param>
    </xsl:call-template>
  </xsl:if>
</xsl:variable>

<xsl:template match="item">

  <xsl:variable name="row_style">
    <xsl:choose>
      <xsl:when test="position() mod 2 = 0">rowodd</xsl:when>
      <xsl:otherwise>roweven</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <tr class="{$row_style}">

    <!-- Item Title -->
    <td>
      <xsl:call-template name="truncate">
        <xsl:with-param name="string" select="title" />
        <xsl:with-param name="fieldlength" select="/cp/strings/podcast_list_itemtitle_length" />
      </xsl:call-template>
    </td>

    <!-- Date Modified -->
    <td><script>document.write(getDateString(<xsl:value-of select="epoch_modify" />));</script></td>

    <!-- Date Added -->
    <td><script>document.write(getDateString(<xsl:value-of select="epoch_create" />));</script></td>

    <!-- Actions -->
    <td>
      <a href="podcast_item_add.xsl?iuid={@iuid}&amp;ruid={$ruid}&amp;edit=1"><xsl:copy-of select="/cp/strings/podcast_list_itemedit" /></a>
      <xsl:copy-of select="/cp/strings/podcast_list_bar" />
      <a href="podcast_list.xsl?iuid={@iuid}&amp;delete=item&amp;item_list={$item_list}&amp;ruid={$ruid}" onClick="return confirm('{cp:js-escape(/cp/strings/podcast_task_confirm_delitem)}');"><xsl:copy-of select="/cp/strings/podcast_list_itemdelete" /></a>
    </td>

  </tr>

</xsl:template>

<xsl:template match="/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss">

  <xsl:variable name="row_style">
    <xsl:choose>
      <xsl:when test="position() mod 2 = 0">roweven</xsl:when>
      <xsl:otherwise>rowodd</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <tr class="{$row_style}">
    <!-- Expand -->
    <td>
      <xsl:variable name="item_list_url"><xsl:value-of select="$basic_sort_url" />sort_by=<xsl:value-of select="$sort_by" />&amp;sort_type=<xsl:value-of select="$sort_type" />&amp;sec_sort_by=<xsl:value-of select="$sec_sort_by" />&amp;sec_sort_type=<xsl:value-of select="$sec_sort_type" />
        <xsl:choose>
          <xsl:when test="$item_list = 'on' and $ruid = @ruid">&amp;item_list=off</xsl:when>
          <xsl:otherwise>&amp;item_list=on&amp;ruid=<xsl:value-of select="@ruid" /></xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <a href="{$item_list_url}">
        <xsl:choose>
          <xsl:when test="$item_list = 'on' and $ruid = @ruid"><img src="/cpimages/contract.gif" border="0" valign="middle" /></xsl:when>
          <xsl:otherwise><img src="/cpimages/expand.gif" border="0" valign="middle" /></xsl:otherwise>
        </xsl:choose>
      </a>
    </td>

    <!-- Feed Title -->
    <td>
      <xsl:choose>
        <xsl:when test="$item_list = 'on' and $ruid = @ruid">
          <strong>
            <xsl:call-template name="truncate">
              <xsl:with-param name="string" select="title" />
              <xsl:with-param name="fieldlength" select="/cp/strings/podcast_list_title_length" />
            </xsl:call-template>
          </strong>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="truncate">
            <xsl:with-param name="string" select="title" />
            <xsl:with-param name="fieldlength" select="/cp/strings/podcast_list_title_length" />
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </td>

    <!-- Domain -->
    <td>
      <xsl:call-template name="truncate">
        <xsl:with-param name="string" select="domain" />
        <xsl:with-param name="fieldlength" select="/cp/strings/podcast_list_domain_length" />
      </xsl:call-template>
    </td>

    <!-- Content Items -->
    <td>
      <xsl:value-of select="count(item)" />
    </td>

    <!-- Actions -->
    <td>
      <a href="{$basic_edit_url}{@ruid}"><xsl:copy-of select="/cp/strings/podcast_list_edit" /></a>
      <xsl:copy-of select="/cp/strings/podcast_list_bar" />
      <a href="{$basic_delete_url}{@ruid}" onClick="return confirm('{cp:js-escape(/cp/strings/podcast_task_confirm_delfeed)}');"><xsl:copy-of select="/cp/strings/podcast_list_delete" /></a>
      <xsl:copy-of select="/cp/strings/podcast_list_bar" />
      <a href="{$basic_add_url}{@ruid}"><xsl:copy-of select="/cp/strings/podcast_list_add" /></a>
      <xsl:copy-of select="/cp/strings/podcast_list_bar" />
      <a href="{$basic_publish_url}{@ruid}"><xsl:copy-of select="/cp/strings/podcast_list_publish" /></a>
    </td>

  </tr>

  <!-- feed expanded view section -->
  <xsl:if test="$item_list = 'on' and $ruid = @ruid">
    <tr class="yellow">
      <td class="ckboxcolumn"></td>
      <td colspan="4">
        <table class="displaylist white" width="100%">
          <tr>
            <td class="label usertypecolumn"><xsl:copy-of select="/cp/strings/podcast_list_feedurl" /></td>
            <td><xsl:value-of select="link" /></td>
          </tr>
          <tr>
            <td class="label usertypecolumn"><xsl:copy-of select="/cp/strings/podcast_list_feedmodified" /></td>
            <td><script>document.write(getDateString(<xsl:value-of select="epoch_modify" />));</script></td>
          </tr>
          <tr>
            <td class="label usertypecolumn"><xsl:copy-of select="/cp/strings/podcast_list_feedadded" /></td>
            <td><script>document.write(getDateString(<xsl:value-of select="epoch_create" />));</script></td>
          </tr>
          <tr>
            <td class="label usertypecolumn"><xsl:copy-of select="/cp/strings/podcast_list_feedxml" /></td>
            <td><a href="http://{domain}/{directory}/{filename}" target="_blank"><img src="/cpimages/rss_20.gif" alt="{/cp/strings/podcast_list_rssalt}" border="0" /></a></td>
          </tr>
          <tr>
            <td class="label usertypecolumn"><xsl:copy-of select="/cp/strings/podcast_list_feedrss" /></td>
            <td>&lt;a href="http://<xsl:value-of select="domain" />/<xsl:value-of select="directory" />/<xsl:value-of select="filename" />"&gt;&lt;img src="/cpimages/rss_20.gif" alt="<xsl:value-of select="/cp/strings/podcast_list_rssalt" />" border="0"&gt;&lt;/a&gt;</td>
          </tr>
          <tr>
            <td colspan="2">
              <table border="0" cellspacing="0" cellpadding="0" width="100%">
                <tr class="controlrow">

                  <!-- Item Title -->
                  <td class="label destinationcolumn">
                    <xsl:variable name="itemtitlesorturl"><xsl:value-of select="$basic_sort_url" />item_list=<xsl:value-of select="$item_list" />&amp;ruid=<xsl:value-of select="$ruid" />&amp;sort_by=<xsl:value-of select="$sort_by" />&amp;sort_type=<xsl:value-of select="$sort_type" />&amp;sec_sort_by=title&amp;sec_sort_type=<xsl:choose>
                      <xsl:when test="($sec_sort_by = 'title') and ($sec_sort_type = 'ascending')">descending</xsl:when>
                      <xsl:otherwise>ascending</xsl:otherwise>
                    </xsl:choose></xsl:variable>
                    <a href="{$itemtitlesorturl}">
                      <xsl:copy-of select="/cp/strings/podcast_list_itemtitle" />
                    </a>&#160;<a href="{$itemtitlesorturl}">
                    <xsl:if test="$sec_sort_by = 'title'">
                      <xsl:choose>
                        <xsl:when test="$sec_sort_type = 'ascending'"><img src="{/cp/strings/img_sortarrowdown}" border="0" /></xsl:when>
                        <xsl:when test="$sec_sort_type = 'descending'"><img src="{/cp/strings/img_sortarrowup}" border="0" /></xsl:when>
                      </xsl:choose>
                    </xsl:if>
                    </a>
                  </td>

                  <!-- Date Modified -->
                  <td class="label">
                    <xsl:variable name="itemmodifiedsorturl"><xsl:value-of select="$basic_sort_url" />item_list=<xsl:value-of select="$item_list" />&amp;ruid=<xsl:value-of select="$ruid" />&amp;sort_by=<xsl:value-of select="$sort_by" />&amp;sort_type=<xsl:value-of select="$sort_type" />&amp;sec_sort_by=modified&amp;sec_sort_type=<xsl:choose>
                      <xsl:when test="($sec_sort_by = 'modified') and ($sec_sort_type = 'ascending')">descending</xsl:when>
                      <xsl:otherwise>ascending</xsl:otherwise>
                    </xsl:choose></xsl:variable>
                    <a href="{$itemmodifiedsorturl}">
                        <xsl:copy-of select="/cp/strings/podcast_list_itemmodified" />
                    </a>&#160;<a href="{$itemmodifiedsorturl}">
                    <xsl:if test="$sec_sort_by = 'modified'">
                      <xsl:choose>
                        <xsl:when test="$sec_sort_type = 'ascending'"><img src="{/cp/strings/img_sortarrowdown}" border="0" /></xsl:when>
                        <xsl:when test="$sec_sort_type = 'descending'"><img src="{/cp/strings/img_sortarrowup}" border="0" /></xsl:when>
                      </xsl:choose>
                    </xsl:if>
                    </a>
                  </td>

                  <!-- Date Added -->
                  <td class="label">
                    <xsl:variable name="itemaddedsorturl"><xsl:value-of select="$basic_sort_url" />item_list=<xsl:value-of select="$item_list" />&amp;ruid=<xsl:value-of select="$ruid" />&amp;sort_by=<xsl:value-of select="$sort_by" />&amp;sort_type=<xsl:value-of select="$sort_type" />&amp;sec_sort_by=added&amp;sec_sort_type=<xsl:choose>
                      <xsl:when test="($sec_sort_by = 'added') and ($sec_sort_type = 'ascending')">descending</xsl:when>
                      <xsl:otherwise>ascending</xsl:otherwise>
                    </xsl:choose></xsl:variable>
                    <a href="{$itemaddedsorturl}">
                        <xsl:copy-of select="/cp/strings/podcast_list_itemadded" />
                    </a>&#160;<a href="{$itemaddedsorturl}">
                    <xsl:if test="$sec_sort_by = 'added'">
                      <xsl:choose>
                        <xsl:when test="$sec_sort_type = 'ascending'"><img src="{/cp/strings/img_sortarrowdown}" border="0" /></xsl:when>
                        <xsl:when test="$sec_sort_type = 'descending'"><img src="{/cp/strings/img_sortarrowup}" border="0" /></xsl:when>
                      </xsl:choose>
                    </xsl:if>
                    </a>
                  </td>

                  <!-- Actions -->
                  <td class="label">
                    <xsl:copy-of select="/cp/strings/podcast_list_itemactions" />
                  </td>

                </tr>

                <!-- show all the items now -->
                <xsl:choose>
                  <xsl:when test="$sec_sort_by='title'">
                    <xsl:apply-templates select="item">
                      <xsl:sort select="title" order="{$sec_sort_type}" />
                    </xsl:apply-templates>
                  </xsl:when>
                  <xsl:when test="$sec_sort_by='modified'">
                    <xsl:apply-templates select="item">
                      <xsl:sort select="epoch_modify" order="{$sec_sort_type}" />
                      <xsl:sort select="title" order="{$sec_sort_type}" />
                    </xsl:apply-templates>
                  </xsl:when>
                  <xsl:when test="$sec_sort_by='added'">
                    <xsl:apply-templates select="item">
                      <xsl:sort select="epoch_create" order="{$sec_sort_type}" />
                      <xsl:sort select="title" order="{$sec_sort_type}" />
                    </xsl:apply-templates>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:apply-templates select="item">
                      <xsl:sort select="epoch_create" order="{$sec_sort_type}" />
                      <xsl:sort select="title" order="{$sec_sort_type}" />
                    </xsl:apply-templates>
                  </xsl:otherwise>
                </xsl:choose>

              </table>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </xsl:if>

</xsl:template>

<xsl:template match="/">
  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title"><xsl:copy-of select="/cp/strings/cp_title" /> : <xsl:copy-of select="/cp/strings/bc_podcast" /></xsl:with-param>
    <xsl:with-param name="formaction">podcast_list.xsl</xsl:with-param>
    <xsl:with-param name="feedback" select='$feedback' />
    <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_admin_podcast" />
    <xsl:with-param name="breadcrumb">
      <breadcrumb>
        <section>
          <name><xsl:copy-of select="/cp/strings/bc_podcast" /></name>
          <url>#</url>
          <image>GlobalTools</image>
        </section>
      </breadcrumb>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

    <script src="{$base_url}/cp/admin/podcast.js" language="javascript" />

    <table class="listview" border="0" cellspacing="0" cellpadding="0">
      <tr class="instructionrow">
        <td colspan="{$colspan}"><xsl:copy-of select="/cp/strings/podcast_list_description" /></td>
      </tr>

      <xsl:call-template name="controlrow" />
      <input type="hidden" name="delete" value="" />
      <input type="hidden" name="sort_by" value="{$sort_by}" />
      <input type="hidden" name="sort_type" value="{$sort_type}" />
      <input type="hidden" name="sec_sort_by" value="{$sec_sort_by}" />
      <input type="hidden" name="sec_sort_type" value="{$sec_sort_type}" />

      <tr class="columnhead">
        <!-- Expand -->
        <td />

        <!-- Feed Title -->
        <td class="subjectcolumn">
          <xsl:variable name="titlesorturl"><xsl:value-of select="$basic_sort_url" />item_list=<xsl:value-of select="$item_list" />&amp;ruid=<xsl:value-of select="$ruid" />&amp;sec_sort_by=<xsl:value-of select="$sec_sort_by" />&amp;sec_sort_type=<xsl:value-of select="$sec_sort_type" />&amp;sort_by=title&amp;sort_type=<xsl:choose>
            <xsl:when test="($sort_by = 'title') and ($sort_type = 'ascending')">descending</xsl:when>
            <xsl:otherwise>ascending</xsl:otherwise>
          </xsl:choose></xsl:variable>
          <a href="{$titlesorturl}">
            <xsl:copy-of select="/cp/strings/podcast_list_title" />
          </a>&#160;<a href="{$titlesorturl}">
            <xsl:if test="$sort_by = 'title'">
              <xsl:choose>
                <xsl:when test="$sort_type = 'ascending'"><img src="{/cp/strings/img_sortarrowdown}" border="0" /></xsl:when>
                <xsl:when test="$sort_type = 'descending'"><img src="{/cp/strings/img_sortarrowup}" border="0" /></xsl:when>
              </xsl:choose>
            </xsl:if>
          </a>
        </td>

        <!-- Domain -->
        <td>
          <xsl:variable name="domainsorturl"><xsl:value-of select="$basic_sort_url" />item_list=<xsl:value-of select="$item_list" />&amp;ruid=<xsl:value-of select="$ruid" />&amp;sec_sort_by=<xsl:value-of select="$sec_sort_by" />&amp;sec_sort_type=<xsl:value-of select="$sec_sort_type" />&amp;sort_by=domain&amp;sort_type=<xsl:choose>
            <xsl:when test="($sort_by = 'domain') and ($sort_type = 'ascending')">descending</xsl:when>
            <xsl:otherwise>ascending</xsl:otherwise>
          </xsl:choose></xsl:variable>
          <a href="{$domainsorturl}">
            <xsl:copy-of select="/cp/strings/podcast_list_domain" />
          </a>&#160;<a href="{$domainsorturl}">
            <xsl:if test="$sort_by = 'domain'">
              <xsl:choose>
                <xsl:when test="$sort_type = 'ascending'"><img src="{/cp/strings/img_sortarrowdown}" border="0" /></xsl:when>
                <xsl:when test="$sort_type = 'descending'"><img src="{/cp/strings/img_sortarrowup}" border="0" /></xsl:when>
              </xsl:choose>
            </xsl:if>
          </a>
        </td>

        <!-- Content Items -->
        <td>
          <xsl:variable name="itemsorturl"><xsl:value-of select="$basic_sort_url" />item_list=<xsl:value-of select="$item_list" />&amp;ruid=<xsl:value-of select="$ruid" />&amp;sec_sort_by=<xsl:value-of select="$sec_sort_by" />&amp;sec_sort_type=<xsl:value-of select="$sec_sort_type" />&amp;sort_by=item&amp;sort_type=<xsl:choose>
            <xsl:when test="($sort_by = 'item') and ($sort_type = 'ascending')">descending</xsl:when>
            <xsl:otherwise>ascending</xsl:otherwise>
          </xsl:choose></xsl:variable>
          <a href="{$itemsorturl}">
            <xsl:copy-of select="/cp/strings/podcast_list_items" />
          </a>&#160;<a href="{$itemsorturl}">
            <xsl:if test="$sort_by = 'item'">
              <xsl:choose>
                <xsl:when test="$sort_type = 'ascending'"><img src="{/cp/strings/img_sortarrowdown}" border="0" /></xsl:when>
                <xsl:when test="$sort_type = 'descending'"><img src="{/cp/strings/img_sortarrowup}" border="0" /></xsl:when>
              </xsl:choose>
            </xsl:if>
          </a>
        </td>

        <!-- Actions -->
        <td class="cmndcolumn"><xsl:copy-of select="/cp/strings/podcast_list_actions" /></td>

      </tr>

      <!-- show all the feeds now -->
      <xsl:choose>
        <xsl:when test="$sort_by='title'">
          <xsl:apply-templates select="/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss">
            <xsl:sort select="title" order="{$sort_type}" />
          </xsl:apply-templates>
        </xsl:when>
        <xsl:when test="$sort_by='domain'">
          <xsl:apply-templates select="/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss">
            <xsl:sort select="domain" order="{$sort_type}" />
            <xsl:sort select="title" order="{$sort_type}" />
          </xsl:apply-templates>
        </xsl:when>
        <xsl:when test="$sort_by='item'">
          <xsl:apply-templates select="/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss">
            <xsl:sort select="count(item)" order="{$sort_type}" />
          </xsl:apply-templates>
        </xsl:when>
        <xsl:otherwise>
          <xsl:apply-templates select="/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss">
            <xsl:sort select="title" order="{$sort_type}" />
          </xsl:apply-templates>
        </xsl:otherwise>
      </xsl:choose>

      <!-- empty feeds message -->
      <xsl:if test="count(/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss) = 0">
        <tr class="roweven">
          <td colspan="{$colspan}">
            <strong>
              <xsl:copy-of select="/cp/strings/podcast_list_feedempty" />
            </strong>
          </td>
        </tr>
      </xsl:if>

    <xsl:call-template name="controlrow" />
  </table>

</xsl:template>

<xsl:template name="controlrow">
  <tr class="controlrow">
    <td colspan="{$colspan}">
      <input type="submit" name="create_feed" value="{/cp/strings/podcast_list_btn_create}" />
    </td>
  </tr>
</xsl:template>

</xsl:stylesheet>
