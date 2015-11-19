<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../cp_global.xsl" />

<xsl:variable name="colspan">2</xsl:variable>

<xsl:variable name="ruid">
  <xsl:choose>
    <xsl:when test="string(/cp/form/ruid)"><xsl:value-of select="/cp/form/ruid" /></xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="iuid">
  <xsl:choose>
    <xsl:when test="string(/cp/form/iuid)"><xsl:value-of select="/cp/form/iuid" /></xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="edit">
  <xsl:choose>
    <xsl:when test="string(/cp/form/edit)"><xsl:value-of select="/cp/form/edit" /></xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="message">
  <xsl:if test="string(/cp/msgs/msg)">
    <xsl:copy-of select="/cp/strings/*[local-name()=/cp/msgs/msg/@name]" />
  </xsl:if>
</xsl:variable>

<xsl:variable name="domain">
  <xsl:value-of select="/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss[@ruid=$ruid]/domain" />
</xsl:variable>

<xsl:variable name="doc_root">
  <xsl:value-of select="/cp/vsap/vsap[@type='domain:list']/domain[name=/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss[@ruid=$ruid]/domain]/doc_root" />
</xsl:variable>

<xsl:variable name="doc_path">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='auth']/server_admin"></xsl:when>
    <xsl:otherwise>/home/<xsl:value-of select="/cp/vsap/vsap[@type='domain:list']/domain[name=/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss[@ruid=$ruid]/domain]/admin" /></xsl:otherwise>
  </xsl:choose>
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

<xsl:template match="/">
  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title">
      <xsl:copy-of select="/cp/strings/cp_title" />
      v<xsl:value-of select="/cp/vsap/vsap[@type='auth']/version" /> :
      <xsl:choose>
        <xsl:when test="string(cp/form/edit)">
          <xsl:copy-of select="/cp/strings/bc_podcast_item_edit" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:copy-of select="/cp/strings/bc_podcast_item_add" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:with-param>
    <xsl:with-param name="formaction">podcast_item_add.xsl</xsl:with-param>
    <xsl:with-param name="feedback" select='$feedback' />
    <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_global_tools_podcast" />
    <xsl:with-param name="breadcrumb">
      <breadcrumb>
        <section>
          <name><xsl:copy-of select="/cp/strings/bc_podcast" /></name>
          <url><xsl:value-of select="$base_url"/>/cp/admin/podcast_list.xsl</url>
        </section>
        <section>
          <name><xsl:choose><xsl:when test="string(cp/form/edit)"><xsl:copy-of select="/cp/strings/bc_podcast_item_edit" /></xsl:when><xsl:otherwise><xsl:copy-of select="/cp/strings/bc_podcast_item_add" /></xsl:otherwise></xsl:choose></name>
          <url>#</url>
          <image>GlobalTools</image>
        </section>
      </breadcrumb>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

    <script src="{$base_url}/cp/admin/podcast.js" language="javascript" />

    <table border="0" cellspacing="0" cellpadding="0">
      <input type="hidden" name="ruid" value="{$ruid}" />
      <input type="hidden" name="iuid" value="{$iuid}" />
      <input type="hidden" name="edit" value="{$edit}" />
      <input type="hidden" name="item_list" value="off" />
      <tr>
        <td>
          <table class="formview" border="0" cellspacing="0" cellpadding="0">
            <tr class="title">
              <td colspan="{$colspan}">
                <xsl:choose>
                  <xsl:when test="string(cp/form/edit)">
                    <xsl:copy-of select="/cp/strings/podcast_item_add_title_edit" />&#160;
                    <xsl:call-template name="truncate">
                      <xsl:with-param name="string" select="/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss[@ruid=$ruid]/title" />
                      <xsl:with-param name="fieldlength" select="/cp/strings/podcast_item_add_title_length" />
                    </xsl:call-template>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:copy-of select="/cp/strings/podcast_item_add_title_add" />&#160;
                    <xsl:call-template name="truncate">
                      <xsl:with-param name="string" select="/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss[@ruid=$ruid]/title" />
                      <xsl:with-param name="fieldlength" select="/cp/strings/podcast_item_add_title_length" />
                    </xsl:call-template>
                  </xsl:otherwise>
                </xsl:choose>
              </td>
            </tr>
            <tr class="instructionrow">
              <td colspan="{$colspan}">
                <xsl:choose>
                  <xsl:when test="string(cp/form/edit)">
                    <xsl:copy-of select="/cp/strings/podcast_item_add_description_edit" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:copy-of select="/cp/strings/podcast_item_add_description_add" />
                  </xsl:otherwise>
                </xsl:choose>
              </td>
            </tr>
            <tr class="rowodd">
              <td class="label"><span class="required floatright"><xsl:value-of select="/cp/strings/podcast_item_add_required_star" /></span><xsl:value-of select="/cp/strings/podcast_item_add_title" /></td>
              <td class="contentwidth"><input type="text" size="40" maxlength="255" name="title" value="{/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss/item[@iuid=$iuid]/title}" />&#160;<xsl:value-of select="/cp/strings/podcast_item_add_title_ex" /></td>
            </tr>
            <tr class="roweven">
              <td class="label"><span class="required floatright"><xsl:value-of select="/cp/strings/podcast_item_add_required_star" /></span><xsl:value-of select="/cp/strings/podcast_item_add_fileurl" /></td>
              <td class="contentwidth"><input type="text" size="40" maxlength="255" name="fileurl" value="{/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss/item[@iuid=$iuid]/fileurl}" />&#160;<a href="#" onClick="var path = '{$doc_root}'; window.open('podcast_item_select.xsl?view_path=' + path.replace('{$doc_path}', '') + '&amp;doc_root=' + path.replace('{$doc_path}', '') + '&amp;domain={$domain}','selectFile','width=550,height=450,top=100,left=100,scrollbars=1,resizable=1'); return false;"><xsl:copy-of select="/cp/strings/podcast_item_add_fileurl_select" /></a>&#160;<xsl:value-of select="/cp/strings/podcast_item_add_fileurl_ex" /></td>
            </tr>
            <tr class="rowodd">
              <td class="label"><span class="required floatright"><xsl:value-of select="/cp/strings/podcast_item_add_required_star" /></span><xsl:value-of select="/cp/strings/podcast_item_add_description" /></td>
              <td class="contentwidth"><textarea cols="40" rows="4" name="description" onBlur="document.forms[0].itunes_summary.value = document.forms[0].description.value"><xsl:value-of select="/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss/item[@iuid=$iuid]/description" /></textarea>&#160;<xsl:value-of select="/cp/strings/podcast_item_add_description_ex" /></td>
            </tr>
            <tr class="roweven">
              <td class="label"><xsl:value-of select="/cp/strings/podcast_item_add_cauthor" /></td>
              <td class="contentwidth"><input type="text" size="40" maxlength="255" name="author" value="{/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss/item[@iuid=$iuid]/author}" />&#160;<xsl:value-of select="/cp/strings/podcast_item_add_cauthor_ex" /></td>
            </tr>
            <tr class="rowodd">
              <td class="label"><xsl:value-of select="/cp/strings/podcast_item_add_pubdate" /></td>
              <td class="contentwidth">
                <table class="webmailpopup">
                  <tr>
<!-- This section 'removed' due to bug 20107.  Section may be actually removed, as desired.  -rand Aug. 11, 2008 
                    <td class="label"><xsl:value-of select="/cp/strings/podcast_item_add_pubdate_day" /></td>
                    <td>
                      <select name="pubdate_day">
                        <xsl:for-each select="/cp/strings/podcast_pubdate_day">
                          <option value="{@value}">
                            <xsl:if test="@value=/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss/item[@iuid=$iuid]/pubdate_day">
                              <xsl:attribute name="selected">true</xsl:attribute>
                            </xsl:if>
                            <xsl:value-of select="." />
                          </option>
                        </xsl:for-each>
                      </select>
                    </td>
/end of 'removed' section. -rand -->
                  </tr>
                  <tr>
                    <td class="label"><xsl:value-of select="/cp/strings/podcast_item_add_pubdate_date" /></td>
                    <td>
                      <select name="pubdate_date">
                        <xsl:for-each select="/cp/strings/podcast_pubdate_date">
                          <option value="{@value}">
                            <xsl:if test="@value=/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss/item[@iuid=$iuid]/pubdate_date">
                              <xsl:attribute name="selected">true</xsl:attribute>
                            </xsl:if>
                            <xsl:value-of select="." />
                          </option>
                        </xsl:for-each>
                      </select>
                    </td>
                  </tr>
                  <tr>
                    <td class="label"><xsl:value-of select="/cp/strings/podcast_item_add_pubdate_month" /></td>
                    <td>
                      <select name="pubdate_month">
                        <xsl:for-each select="/cp/strings/podcast_pubdate_month">
                          <option value="{@value}">
                            <xsl:if test="@value=/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss/item[@iuid=$iuid]/pubdate_month">
                              <xsl:attribute name="selected">true</xsl:attribute>
                            </xsl:if>
                            <xsl:value-of select="." />
                          </option>
                        </xsl:for-each>
                      </select>
                    </td>
                  </tr>
                  <tr>
                    <td class="label"><xsl:value-of select="/cp/strings/podcast_item_add_pubdate_year" /></td>
                    <td>
                      <select name="pubdate_year">
                        <xsl:for-each select="/cp/strings/podcast_pubdate_year">
                          <option value="{@value}">
                            <xsl:if test="@value=/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss/item[@iuid=$iuid]/pubdate_year">
                              <xsl:attribute name="selected">true</xsl:attribute>
                            </xsl:if>
                            <xsl:value-of select="." />
                          </option>
                        </xsl:for-each>
                      </select>
                    </td>
                  </tr>
                  <tr>
                    <td class="label"><xsl:value-of select="/cp/strings/podcast_item_add_pubdate_time" /></td>
                    <td>
                      <xsl:attribute name="nowrap" />
                      <select name="pubdate_hour">
                        <xsl:for-each select="/cp/strings/podcast_pubdate_hour">
                          <option value="{@value}">
                            <xsl:if test="@value=/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss/item[@iuid=$iuid]/pubdate_hour">
                              <xsl:attribute name="selected">true</xsl:attribute>
                            </xsl:if>
                            <xsl:value-of select="." />
                          </option>
                        </xsl:for-each>
                      </select>
                      &#160;<xsl:value-of select="/cp/strings/podcast_item_add_pubdate_time_colon" />&#160;
                      <select name="pubdate_minute">
                        <xsl:for-each select="/cp/strings/podcast_pubdate_minute">
                          <option value="{@value}">
                            <xsl:if test="@value=/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss/item[@iuid=$iuid]/pubdate_minute">
                              <xsl:attribute name="selected">true</xsl:attribute>
                            </xsl:if>
                            <xsl:value-of select="." />
                          </option>
                        </xsl:for-each>
                      </select>
                      &#160;<xsl:value-of select="/cp/strings/podcast_item_add_pubdate_time_colon" />&#160;
                      <select name="pubdate_second">
                        <xsl:for-each select="/cp/strings/podcast_pubdate_second">
                          <option value="{@value}">
                            <xsl:if test="@value=/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss/item[@iuid=$iuid]/pubdate_second">
                              <xsl:attribute name="selected">true</xsl:attribute>
                            </xsl:if>
                            <xsl:value-of select="." />
                          </option>
                        </xsl:for-each>
                      </select>
                      &#160;<xsl:value-of select="/cp/strings/podcast_item_add_pubdate_time_format" />
                    </td>
                  </tr>
                  <tr>
                   <td class="label"><xsl:value-of select="/cp/strings/podcast_item_add_pubdate_zone" /></td>
                   <td>
                      <select name="pubdate_zone">
                        <xsl:for-each select="/cp/strings/podcast_pubdate_zone">
                          <option value="{@value}">
                            <xsl:if test="@value=/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss/item[@iuid=$iuid]/pubdate_zone">
                              <xsl:attribute name="selected">true</xsl:attribute>
                            </xsl:if>
                            <xsl:value-of select="." />
                          </option>
                        </xsl:for-each>
                      </select>
                    </td>
                  </tr>
                </table>
              </td>
            </tr>
            <tr class="title">
              <td><xsl:value-of select="/cp/strings/podcast_item_add_info" /></td>
              <td class="contentwidth"><a href="#" onClick="applyOptionalDisplay(''); return false;"><xsl:value-of select="/cp/strings/podcast_item_add_show_itunes" /></a>&#160;<xsl:value-of select="/cp/strings/podcast_item_add_bar" />&#160;<a href="#" onClick="applyOptionalDisplay('none'); return false;"><xsl:value-of select="/cp/strings/podcast_item_add_hide_itunes" /></a></td>
            </tr>
          </table>
        </td>
      </tr>
      <tr>
        <td>
          <table id="optionalDisplay" style="display: none;" class="formview" border="0" cellspacing="0" cellpadding="0">
            <tr class="rowodd">
              <td class="label"><xsl:value-of select="/cp/strings/podcast_item_add_subtitle" /></td>
              <td><input type="text" size="40" maxlength="255" name="itunes_subtitle" value="{/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss/item[@iuid=$iuid]/itunes_subtitle}" />&#160;<xsl:value-of select="/cp/strings/podcast_item_add_subtitle_ex" /></td>
            </tr>
            <tr class="roweven">
              <td class="label"><xsl:value-of select="/cp/strings/podcast_item_add_author" /></td>
              <td><input type="text" size="40" maxlength="255" name="itunes_author" value="{/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss/item[@iuid=$iuid]/itunes_author}" />&#160;<xsl:value-of select="/cp/strings/podcast_item_add_author_ex" /></td>
            </tr>
            <tr class="rowodd">
              <td class="label"><xsl:value-of select="/cp/strings/podcast_item_add_summary" /></td>
              <td><textarea cols="40" rows="4" name="itunes_summary"><xsl:value-of select="/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss/item[@iuid=$iuid]/itunes_summary" /></textarea>&#160;<xsl:value-of select="/cp/strings/podcast_item_add_summary_ex" /></td>
            </tr>
            <tr class="roweven">
              <td class="label"><xsl:value-of select="/cp/strings/podcast_item_add_duration" /></td>
              <td>
                <select name="itunes_duration_hour">
                  <xsl:for-each select="/cp/strings/podcast_pubdate_hour">
                    <option value="{@value}">
                      <xsl:if test="@value=/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss/item[@iuid=$iuid]/itunes_duration_hour">
                        <xsl:attribute name="selected">true</xsl:attribute>
                      </xsl:if>
                      <xsl:value-of select="." />
                    </option>
                  </xsl:for-each>
                </select>
                &#160;<xsl:value-of select="/cp/strings/podcast_item_add_duration_colon" />&#160;
                <select name="itunes_duration_minute">
                  <xsl:for-each select="/cp/strings/podcast_pubdate_minute">
                    <option value="{@value}">
                      <xsl:if test="@value=/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss/item[@iuid=$iuid]/itunes_duration_minute">
                        <xsl:attribute name="selected">true</xsl:attribute>
                      </xsl:if>
                      <xsl:value-of select="." />
                    </option>
                  </xsl:for-each>
                </select>
                &#160;<xsl:value-of select="/cp/strings/podcast_item_add_duration_colon" />&#160;
                <select name="itunes_duration_second">
                  <xsl:for-each select="/cp/strings/podcast_pubdate_second">
                    <option value="{@value}">
                      <xsl:if test="@value=/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss/item[@iuid=$iuid]/itunes_duration_second">
                        <xsl:attribute name="selected">true</xsl:attribute>
                      </xsl:if>
                      <xsl:value-of select="." />
                    </option>
                  </xsl:for-each>
                </select>
                &#160;<xsl:value-of select="/cp/strings/podcast_item_add_duration_format" />
              </td>
            </tr>
            <tr class="rowodd">
              <td class="label"><xsl:value-of select="/cp/strings/podcast_item_add_keywords" /></td>
              <td><input type="text" size="40" maxlength="255" name="itunes_keywords" value="{/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss/item[@iuid=$iuid]/itunes_keywords}" />&#160;<xsl:value-of select="/cp/strings/podcast_item_add_keywords_format" /></td>
            </tr>
            <tr class="roweven">
              <td class="label"><xsl:value-of select="/cp/strings/podcast_item_add_explicit" /></td>
              <td>
                <select name="itunes_explicit">
                  <xsl:for-each select="/cp/strings/itunes_explicit">
                    <option value="{@value}">
                      <xsl:if test="@value=/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss/item[@iuid=$iuid]/itunes_explicit">
                        <xsl:attribute name="selected">true</xsl:attribute>
                      </xsl:if>
                      <xsl:value-of select="." />
                    </option>
                  </xsl:for-each>
                </select>
              </td>
            </tr>
            <tr class="rowodd">
              <td class="label"><xsl:value-of select="/cp/strings/podcast_item_add_block" /></td>
              <td>
                <select name="itunes_block">
                  <xsl:for-each select="/cp/strings/itunes_block">
                    <option value="{@value}">
                      <xsl:if test="@value=/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss/item[@iuid=$iuid]/itunes_block">
                        <xsl:attribute name="selected">true</xsl:attribute>
                      </xsl:if>
                      <xsl:value-of select="." />
                    </option>
                  </xsl:for-each>
                </select>
              </td>
            </tr>
          </table>
        </td>
      </tr>
    <xsl:call-template name="controlrow" />
  </table>

</xsl:template>

<xsl:template name="controlrow">
  <tr class="controlrow">
    <td colspan="{$colspan}" class="floatright">
      <input class="floatright" type="submit" name="cancel" value="{/cp/strings/podcast_item_add_btn_cancel}" onClick="document.forms[0].item_list.value = 'on';" />
      <input class="floatright" type="reset" name="btn_clear" value="{/cp/strings/podcast_item_add_btn_clear}" />
        <xsl:if test="not(string(/cp/form/edit))">
          <input class="floatright" type="submit" name="save_and_add" value="{/cp/strings/podcast_item_add_btn_saveandadd}" onClick="return validateFeed('{cp:js-escape(/cp/strings/podcast_task_confirm_additem)}','{cp:js-escape(/cp/strings/podcast_err_invalid_date)}');" />
        </xsl:if>
      <input class="floatright" type="submit" name="save" value="{/cp/strings/podcast_item_add_btn_save}" onClick="document.forms[0].item_list.value = 'on'; return validateFeed('{cp:js-escape(/cp/strings/podcast_task_confirm_additem)}','{cp:js-escape(/cp/strings/podcast_err_invalid_date)}');" />
    </td>
  </tr>
</xsl:template>

</xsl:stylesheet>
