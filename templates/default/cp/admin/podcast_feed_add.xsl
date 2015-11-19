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

<xsl:variable name="edit">
  <xsl:choose>
    <xsl:when test="string(/cp/form/edit)"><xsl:value-of select="/cp/form/edit" /></xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="admin">
  <xsl:value-of select="/cp/vsap/vsap[@type='auth']/username" />
</xsl:variable>

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

<xsl:template match="/">
  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title">
      <xsl:copy-of select="/cp/strings/cp_title" />
      v<xsl:value-of select="/cp/vsap/vsap[@type='auth']/version" /> :
      <xsl:choose>
        <xsl:when test="string(cp/form/edit)">
          <xsl:copy-of select="/cp/strings/bc_podcast_feed_edit" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:copy-of select="/cp/strings/bc_podcast_feed_add" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:with-param>
    <xsl:with-param name="formaction">podcast_feed_add.xsl</xsl:with-param>
    <xsl:with-param name="feedback" select='$feedback' />
    <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_global_tools_podcast" />
    <xsl:with-param name="breadcrumb">
      <breadcrumb>
        <section>
          <name><xsl:copy-of select="/cp/strings/bc_podcast" /></name>
          <url><xsl:value-of select="$base_url"/>/cp/admin/podcast_list.xsl</url>
        </section>
        <section>
          <name><xsl:choose><xsl:when test="string(cp/form/edit)"><xsl:copy-of select="/cp/strings/bc_podcast_feed_edit" /></xsl:when><xsl:otherwise><xsl:copy-of select="/cp/strings/bc_podcast_feed_add" /></xsl:otherwise></xsl:choose></name>
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
      <input type="hidden" name="edit" value="{$edit}" />
      <tr>
        <td>
          <table class="formview" border="0" cellspacing="0" cellpadding="0">
            <tr class="title">
              <td colspan="{$colspan}">
                <xsl:choose>
                  <xsl:when test="string(cp/form/edit)">
                    <xsl:copy-of select="/cp/strings/podcast_feed_add_title_edit" />&#160;
                    <xsl:call-template name="truncate">
                      <xsl:with-param name="string" select="/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss[@ruid=$ruid]/title" />
                      <xsl:with-param name="fieldlength" select="/cp/strings/podcast_feed_add_title_length" />
                    </xsl:call-template>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:copy-of select="/cp/strings/podcast_feed_add_title_add" />
                  </xsl:otherwise>
                </xsl:choose>
              </td>
            </tr>
            <tr class="instructionrow">
              <td colspan="{$colspan}">
                <xsl:choose>
                  <xsl:when test="string(cp/form/edit)">
                    <xsl:copy-of select="/cp/strings/podcast_feed_add_description_edit" />
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:copy-of select="/cp/strings/podcast_feed_add_description_add" />
                  </xsl:otherwise>
                </xsl:choose>
              </td>
            </tr>
            <tr class="rowodd">
              <td class="label"><span class="required floatright"><xsl:value-of select="/cp/strings/podcast_feed_add_required_star" /></span><xsl:value-of select="/cp/strings/podcast_feed_add_title" /></td>
              <td class="contentwidth"><input type="text" size="40" maxlength="255" name="title" value="{/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss[@ruid=$ruid]/title}" onBlur="document.forms[0].image_title.value = document.forms[0].title.value" />&#160;<xsl:value-of select="/cp/strings/podcast_feed_add_title_ex" /></td>
            </tr>
            <tr class="roweven">
              <td class="label"><span class="required floatright"><xsl:value-of select="/cp/strings/podcast_feed_add_required_star" /></span><xsl:value-of select="/cp/strings/podcast_feed_add_domain" /></td>
              <td class="contentwidth">
                <select name="domain">
                <xsl:for-each select="/cp/vsap/vsap[@type='domain:list']/domain">
                  <xsl:sort select="translate(name, 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')" />
                  <xsl:if test="admin = $admin or (@type='server' and /cp/vsap/vsap[@type='auth']/server_admin)">
                    <option value="{name}">
                    <xsl:if test="name=/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss[@ruid=$ruid]/domain">
                      <xsl:attribute name="selected">true</xsl:attribute>
                    </xsl:if>
                    <xsl:value-of select="name" />
                    </option>
                  </xsl:if>
                </xsl:for-each>
                </select>
              </td>
            </tr>
            <tr class="rowodd">
              <td class="label"><span class="required floatright"><xsl:value-of select="/cp/strings/podcast_feed_add_required_star" /></span><xsl:value-of select="/cp/strings/podcast_feed_add_directory" /></td>
              <td class="contentwidth"><input type="text" size="40" maxlength="255" name="directory" value="{/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss[@ruid=$ruid]/directory}" />&#160;<xsl:value-of select="/cp/strings/podcast_feed_add_directory_ex" /></td>
            </tr>
            <tr class="roweven">
              <td class="label"><span class="required floatright"><xsl:value-of select="/cp/strings/podcast_feed_add_required_star" /></span><xsl:value-of select="/cp/strings/podcast_feed_add_filename" /></td>
              <td class="contentwidth"><input type="text" size="40" maxlength="255" name="filename" value="{/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss[@ruid=$ruid]/filename}" />&#160;<xsl:value-of select="/cp/strings/podcast_feed_add_filename_ex" /></td>
            </tr>
            <tr class="rowodd">
              <td class="label"><span class="required floatright"><xsl:value-of select="/cp/strings/podcast_feed_add_required_star" /></span><xsl:value-of select="/cp/strings/podcast_feed_add_weburl" /></td>
              <td class="contentwidth"><input type="text" size="40" maxlength="255" name="link" value="{/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss[@ruid=$ruid]/link}" onBlur="document.forms[0].image_link.value = document.forms[0].link.value" />&#160;<xsl:value-of select="/cp/strings/podcast_feed_add_weburl_ex" /></td>
            </tr>
            <tr class="roweven">
              <td class="label"><span class="required floatright"><xsl:value-of select="/cp/strings/podcast_feed_add_required_star" /></span><xsl:value-of select="/cp/strings/podcast_feed_add_description" /></td>
              <td class="contentwidth"><textarea cols="40" rows="4" name="description" onBlur="document.forms[0].itunes_summary.value = document.forms[0].description.value"><xsl:value-of select="/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss[@ruid=$ruid]/description" /></textarea>&#160;<xsl:value-of select="/cp/strings/podcast_feed_add_description_ex" /></td>
            </tr>
            <tr class="rowodd">
              <td class="label"><xsl:value-of select="/cp/strings/podcast_feed_add_language" /></td>
              <td class="contentwidth">
                <select name="language">
                  <xsl:for-each select="/cp/strings/podcast_language">
                    <option value="{@value}">
                      <xsl:if test="@value=/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss[@ruid=$ruid]/language">
                        <xsl:attribute name="selected">true</xsl:attribute>
                      </xsl:if>
                      <xsl:value-of select="." />
                    </option>
                  </xsl:for-each>
                </select>
              </td>
            </tr>
            <tr class="roweven">
              <td class="label"><xsl:value-of select="/cp/strings/podcast_feed_add_copyright" /></td>
              <td class="contentwidth"><input type="text" size="40" maxlength="255" name="copyright" value="{/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss[@ruid=$ruid]/copyright}" />&#160;<xsl:value-of select="/cp/strings/podcast_feed_add_copyright_ex" /></td>
            </tr>
            <tr class="rowodd">
              <td class="label"><xsl:value-of select="/cp/strings/podcast_feed_add_pubdate" /></td>
              <td class="contentwidth">
                <table class="webmailpopup">
<!-- This section (pubdate_day) was 'removed' due to testing feedback on ENH17608.   
     As it was possible to enter a day (Sun-Sat) inconsistent with the date(YYYY-MM-DD) entered and since the
     pubdate_day information is always redundant or incorrect, Jeremy Jackson and I decided to remove this field.
     However, for the time-being, I will leave this section here, so that it can easily be re-added if desired. -rand 2008-07-01
                  <tr>
                    <td class="label"><xsl:value-of select="/cp/strings/podcast_feed_add_pubdate_day" /></td>
                    <td>
                      <select name="pubdate_day">
                        <xsl:for-each select="/cp/strings/podcast_pubdate_day">
                          <option value="{@value}">
                            <xsl:if test="@value=/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss[@ruid=$ruid]/pubdate_day">
                              <xsl:attribute name="selected">true</xsl:attribute>
                            </xsl:if>
                            <xsl:value-of select="." />
                          </option>
                        </xsl:for-each>
                      </select>
                    </td>
                  </tr>
-->
                  <tr>
                    <td class="label"><xsl:value-of select="/cp/strings/podcast_feed_add_pubdate_date" /></td>
                    <td>
                      <select name="pubdate_date">
                        <xsl:for-each select="/cp/strings/podcast_pubdate_date">
                          <option value="{@value}">
                            <xsl:if test="@value=/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss[@ruid=$ruid]/pubdate_date">
                              <xsl:attribute name="selected">true</xsl:attribute>
                            </xsl:if>
                            <xsl:value-of select="." />
                          </option>
                        </xsl:for-each>
                      </select>
                    </td>
                  </tr>
                  <tr>
                    <td class="label"><xsl:value-of select="/cp/strings/podcast_feed_add_pubdate_month" /></td>
                    <td>
                      <select name="pubdate_month">
                        <xsl:for-each select="/cp/strings/podcast_pubdate_month">
                          <option value="{@value}">
                            <xsl:if test="@value=/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss[@ruid=$ruid]/pubdate_month">
                              <xsl:attribute name="selected">true</xsl:attribute>
                            </xsl:if>
                            <xsl:value-of select="." />
                          </option>
                        </xsl:for-each>
                      </select>
                    </td>
                  </tr>
                  <tr>
                    <td class="label"><xsl:value-of select="/cp/strings/podcast_feed_add_pubdate_year" /></td>
                    <td>
                      <select name="pubdate_year">
                        <xsl:for-each select="/cp/strings/podcast_pubdate_year">
                          <xsl:if test="@value = '' or @value &lt;= /cp/vsap/vsap[@type='web:rss:get:parameters']/current_year">
                            <option value="{@value}">
                              <xsl:if test="@value=/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss[@ruid=$ruid]/pubdate_year">
                                <xsl:attribute name="selected">true</xsl:attribute>
                              </xsl:if>
                              <xsl:value-of select="." />
                            </option>
                          </xsl:if>
                        </xsl:for-each>
                      </select>
                    </td>
                  </tr>
                  <tr>
                    <td class="label"><xsl:value-of select="/cp/strings/podcast_feed_add_pubdate_time" /></td>
                    <td>
                      <xsl:attribute name="nowrap" />
                      <select name="pubdate_hour">
                        <xsl:for-each select="/cp/strings/podcast_pubdate_hour">
                          <option value="{@value}">
                            <xsl:if test="@value=/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss[@ruid=$ruid]/pubdate_hour">
                              <xsl:attribute name="selected">true</xsl:attribute>
                            </xsl:if>
                            <xsl:value-of select="." />
                          </option>
                        </xsl:for-each>
                      </select>
                      &#160;<xsl:value-of select="/cp/strings/podcast_feed_add_pubdate_time_colon" />&#160;
                      <select name="pubdate_minute">
                        <xsl:for-each select="/cp/strings/podcast_pubdate_minute">
                          <option value="{@value}">
                            <xsl:if test="@value=/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss[@ruid=$ruid]/pubdate_minute">
                              <xsl:attribute name="selected">true</xsl:attribute>
                            </xsl:if>
                            <xsl:value-of select="." />
                          </option>
                        </xsl:for-each>
                      </select>
                      &#160;<xsl:value-of select="/cp/strings/podcast_feed_add_pubdate_time_colon" />&#160;
                      <select name="pubdate_second">
                        <xsl:for-each select="/cp/strings/podcast_pubdate_second">
                          <option value="{@value}">
                            <xsl:if test="@value=/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss[@ruid=$ruid]/pubdate_second">
                              <xsl:attribute name="selected">true</xsl:attribute>
                            </xsl:if>
                            <xsl:value-of select="." />
                          </option>
                        </xsl:for-each>
                      </select>
                      &#160;<xsl:value-of select="/cp/strings/podcast_feed_add_pubdate_time_format" />
                    </td>
                  </tr>
                  <tr>
                   <td class="label"><xsl:value-of select="/cp/strings/podcast_feed_add_pubdate_zone" /></td>
                   <td>
                      <select name="pubdate_zone">
                        <xsl:for-each select="/cp/strings/podcast_pubdate_zone">
                          <option value="{@value}">
                            <xsl:if test="@value=/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss[@ruid=$ruid]/pubdate_zone">
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
            <tr class="roweven">
              <td class="label"><xsl:value-of select="/cp/strings/podcast_feed_add_image" /></td>
              <td class="contentwidth">
                <table class="webmailpopup">
                  <tr>
                    <td class="label"><xsl:value-of select="/cp/strings/podcast_feed_add_image_url" /></td>
                    <td><input type="text" size="40" maxlength="255" name="image_url" value="{/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss[@ruid=$ruid]/image_url}" /></td>
                  </tr>
                  <tr>
                    <td class="label"><xsl:value-of select="/cp/strings/podcast_feed_add_image_title" /></td>
                    <td><input type="text" size="40" maxlength="255" name="image_title" value="{/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss[@ruid=$ruid]/image_title}" /></td>
                  </tr>
                  <tr>
                    <td class="label"><xsl:value-of select="/cp/strings/podcast_feed_add_image_link" /></td>
                    <td><input type="text" size="40" maxlength="255" name="image_link" value="{/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss[@ruid=$ruid]/image_link}" /></td>
                  </tr>
                </table>
              </td>
            </tr>
            <tr class="title">
              <td><xsl:value-of select="/cp/strings/podcast_feed_add_info" /></td>
              <td class="contentwidth"><a href="#" onClick="applyOptionalDisplay(''); return false;"><xsl:value-of select="/cp/strings/podcast_feed_add_show_itunes" /></a>&#160;<xsl:value-of select="/cp/strings/podcast_feed_add_bar" />&#160;<a href="#" onClick="applyOptionalDisplay('none'); return false;"><xsl:value-of select="/cp/strings/podcast_feed_add_hide_itunes" /></a></td>
            </tr>
          </table>
        </td>
      </tr>
      <tr>
        <td>
          <table id="optionalDisplay" style="display: none;" class="formview" border="0" cellspacing="0" cellpadding="0">
            <tr class="rowodd">
              <td class="label"><xsl:value-of select="/cp/strings/podcast_feed_add_subtitle" /></td>
              <td><input type="text" size="40" maxlength="255" name="itunes_subtitle" value="{/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss[@ruid=$ruid]/itunes_subtitle}" />&#160;<xsl:value-of select="/cp/strings/podcast_feed_add_subtitle_ex" /></td>
            </tr>
            <tr class="roweven">
              <td class="label"><xsl:value-of select="/cp/strings/podcast_feed_add_author" /></td>
              <td><input type="text" size="40" maxlength="255" name="itunes_author" value="{/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss[@ruid=$ruid]/itunes_author}" onBlur="document.forms[0].itunes_owner_name.value = document.forms[0].itunes_author.value" />&#160;<xsl:value-of select="/cp/strings/podcast_feed_add_author_ex" /></td>
            </tr>
            <tr class="rowodd">
              <td class="label"><xsl:value-of select="/cp/strings/podcast_feed_add_summary" /></td>
              <td><textarea cols="40" rows="4" name="itunes_summary"><xsl:value-of select="/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss[@ruid=$ruid]/itunes_summary" /></textarea>&#160;<xsl:value-of select="/cp/strings/podcast_feed_add_summary_ex" /></td>
            </tr>
            <tr class="roweven">
              <td class="label"><xsl:value-of select="/cp/strings/podcast_feed_add_category" /></td>
              <td>
                <select name="itunes_category" multiple="multiple" size="5" id="categories" onchange="validateCategories('{/cp/strings/podcast_task_alert_setcat}');">
                  <xsl:for-each select="/cp/strings/podcast_category_group">
                    <xsl:choose>
                      <xsl:when test="string(@label)">
                        <optgroup label="{@label}">
                          <xsl:for-each select="podcast_category">
                            <option value="{@value}">
                            <xsl:if test="@value=/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss[@ruid=$ruid]/itunes_category">
                              <xsl:attribute name="selected">true</xsl:attribute>
                            </xsl:if>
                            <xsl:value-of select="." />
                            </option>
                          </xsl:for-each>
                        </optgroup>
                      </xsl:when>
                      <xsl:otherwise>
                        <option value="{podcast_category/@value}">
                        <xsl:if test="podcast_category/@value=/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss[@ruid=$ruid]/itunes_category">
                          <xsl:attribute name="selected">true</xsl:attribute>
                        </xsl:if>
                        <xsl:value-of select="podcast_category" />
                        </option>
                      </xsl:otherwise>
                    </xsl:choose>
                  </xsl:for-each>
                </select>
              &#160;<xsl:value-of select="/cp/strings/podcast_feed_add_category_format" /></td>
            </tr>
            <tr class="rowodd">
              <td class="label"><xsl:value-of select="/cp/strings/podcast_feed_add_owner" /></td>
              <td><input type="text" size="40" maxlength="255" name="itunes_owner_name" value="{/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss[@ruid=$ruid]/itunes_owner_name}" />&#160;<xsl:value-of select="/cp/strings/podcast_feed_add_owner_ex" /></td>
            </tr>
            <tr class="roweven">
              <td class="label"><xsl:value-of select="/cp/strings/podcast_feed_add_email" /></td>
              <td><input type="text" size="40" maxlength="255" name="itunes_owner_email" value="{/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss[@ruid=$ruid]/itunes_owner_email}" />&#160;<xsl:value-of select="/cp/strings/podcast_feed_add_email_ex" /></td>
            </tr>
            <tr class="rowodd">
              <td class="label"><xsl:value-of select="/cp/strings/podcast_feed_add_imageurl" /></td>
              <td><input type="text" size="40" maxlength="255" name="itunes_image" value="{/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss[@ruid=$ruid]/itunes_image}" onchange="validateItunesImage('{/cp/strings/podcast_task_alert_setimage}');" />&#160;<xsl:value-of select="/cp/strings/podcast_feed_add_imageurl_ex" /></td>
            </tr>
            <tr class="roweven">
              <td class="label"><xsl:value-of select="/cp/strings/podcast_feed_add_explicit" /></td>
              <td>
                <select name="itunes_explicit">
                  <xsl:for-each select="/cp/strings/itunes_explicit">
                    <option value="{@value}">
                      <xsl:if test="@value=/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss[@ruid=$ruid]/itunes_explicit">
                        <xsl:attribute name="selected">true</xsl:attribute>
                      </xsl:if>
                      <xsl:value-of select="." />
                    </option>
                  </xsl:for-each>
                </select>
              </td>
            </tr>
            <tr class="rowodd">
              <td class="label"><xsl:value-of select="/cp/strings/podcast_feed_add_block" /></td>
              <td>
                <select name="itunes_block">
                  <xsl:for-each select="/cp/strings/itunes_block">
                    <option value="{@value}">
                      <xsl:if test="@value=/cp/vsap/vsap[@type='web:rss:load:feed']/rssSet/rss[@ruid=$ruid]/itunes_block">
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
      <input class="floatright" type="submit" name="cancel" value="{/cp/strings/podcast_feed_add_btn_cancel}" />
      <input class="floatright" type="reset" name="btn_clear" value="{/cp/strings/podcast_feed_add_btn_clear}" />
        <xsl:if test="not(string(/cp/form/edit))">
          <input class="floatright" type="submit" name="save_and_add" value="{/cp/strings/podcast_feed_add_btn_saveandadd}" onClick="return validateFeed('{cp:js-escape(/cp/strings/podcast_task_confirm_addfeed)}','{cp:js-escape(/cp/strings/podcast_err_invalid_date)}');" />
        </xsl:if>
      <input class="floatright" type="submit" name="save" value="{/cp/strings/podcast_feed_add_btn_save}" onClick="return validateFeed('{cp:js-escape(/cp/strings/podcast_task_confirm_addfeed)}','{cp:js-escape(/cp/strings/podcast_err_invalid_date)}');" />
    </td>
  </tr>
</xsl:template>

</xsl:stylesheet>
