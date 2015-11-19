<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
  xmlns:exslt="http://exslt.org/common"
  exclude-result-prefixes="exslt">

<xsl:import href="../cp_global.xsl" />

<xsl:variable name="message">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='user:prefs:save']/status = 'ok'">
      <xsl:call-template name="feedback_table">
        <xsl:with-param name="image">success</xsl:with-param>
        <xsl:with-param name="message"><xsl:copy-of select="/cp/strings/prefs_datetime_success" /> </xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='user:prefs:save']/status = 'fail'">
      <xsl:call-template name="feedback_table">
        <xsl:with-param name="image">error</xsl:with-param>
        <xsl:with-param name="message"><xsl:copy-of select="/cp/strings/prefs_datetime_failure" /> </xsl:with-param>
      </xsl:call-template>
    </xsl:when>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="date_format">
  <xsl:choose>
    <xsl:when test="string(/cp/vsap/vsap/user_preferences/date_format)">
      <xsl:value-of select="/cp/vsap/vsap/user_preferences/date_format" />
    </xsl:when>
    <xsl:otherwise>%m-%d-%y</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="time_format">
  <xsl:choose>
    <xsl:when test="string(/cp/vsap/vsap/user_preferences/time_format)">
      <xsl:value-of select="/cp/vsap/vsap/user_preferences/time_format" />
    </xsl:when>
    <xsl:otherwise>%l:%M</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="dt_order">
  <xsl:choose>
    <xsl:when test="string(/cp/vsap/vsap/user_preferences/dt_order)">
      <xsl:value-of select="/cp/vsap/vsap/user_preferences/dt_order" />
    </xsl:when>
    <xsl:otherwise>date</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="tz" select="/cp/vsap/vsap[@type='user:prefs:load']/user_preferences/time_zone"/>

<xsl:template match="/">
<xsl:call-template name="bodywrapper">

  <xsl:with-param name="title">
    <xsl:copy-of select="/cp/strings/cp_title" />
    v<xsl:value-of select="/cp/vsap/vsap[@type='auth']/version" /> :
    <xsl:copy-of select="/cp/strings/bc_prefs_datetime" />
  </xsl:with-param>

  <xsl:with-param name="formaction">datetime.xsl</xsl:with-param>
  <xsl:with-param name="feedback"><xsl:copy-of select="$message" /></xsl:with-param>

  <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_date_time" />
  <xsl:with-param name="help_short" select="/cp/strings/prefs_datetime_hlp_short" />
  <xsl:with-param name="help_long" select="/cp/strings/prefs_datetime_hlp_long" />
  <xsl:with-param name="breadcrumb">
    <breadcrumb>
      <section>
        <name><xsl:copy-of select="/cp/strings/bc_prefs_datetime" /></name>
        <url>#</url>
        <image>Preferences</image>
      </section>
    </breadcrumb>
  </xsl:with-param>

</xsl:call-template>
</xsl:template>

<xsl:template name="content">

        <table class="formview" border="0" cellspacing="0" cellpadding="0">
          <tr class="title">
            <td colspan="2"><xsl:copy-of select="/cp/strings/prefs_datetime_title" /></td>
          </tr>
          <tr class="instructionrow">
            <td colspan="2"><xsl:value-of select="/cp/strings/prefs_datetime_instr"/></td>
          </tr>
          <tr class="rowodd">
            <td class="label"><xsl:value-of select="/cp/strings/prefs_datetime_tz_label"/></td>

            <td class="contentwidth">
              <select name="time_zone">
                <xsl:for-each select="/cp/strings/timezone">
                  <option value="{@value}"><xsl:if test="$tz=@value"><xsl:attribute name="selected"/></xsl:if><xsl:value-of select="." /></option>
                </xsl:for-each>
              </select>
            </td>
          </tr>

          <tr class="roweven">
            <td class="label"><xsl:value-of select="/cp/strings/prefs_datetime_date_label"/></td>
            <td class="contentwidth">
              <input type="radio" id="df1" name="date_format" value="%m-%d-%Y">
                <xsl:if test="$date_format = '%m-%d-%Y'">
                  <xsl:attribute name="checked" value="checked"/>
                </xsl:if>
              </input>
              <label for="df1"><xsl:value-of select="/cp/strings/prefs_datetime_date_mdy"/></label><br />

              <input type="radio" id="df2" name="date_format" value="%Y-%m-%d">
                <xsl:if test="$date_format = '%Y-%m-%d'">
                  <xsl:attribute name="checked" value="checked"/>
                </xsl:if>
              </input>
              <label for="df2"><xsl:value-of select="/cp/strings/prefs_datetime_date_ymd"/></label><br />

              <input type="radio" id="df3" name="date_format" value="%d-%m-%Y">
                <xsl:if test="$date_format = '%d-%m-%Y'">
                  <xsl:attribute name="checked" value="checked"/>
                </xsl:if>
              </input>
              <label for="df3"><xsl:value-of select="/cp/strings/prefs_datetime_date_dmy"/></label><br />

              </td>
            </tr>

          <tr class="rowodd">
            <td class="label"><xsl:value-of select="/cp/strings/prefs_datetime_time_label"/></td>
            <td class="contentwidth">
              <input type="radio" id="tf1" name="time_format" value="%l:%M">
                <xsl:if test="$time_format = '%l:%M'">
                  <xsl:attribute name="checked" value="checked"/>
                </xsl:if>
              </input>
              <label for="tf1"><xsl:value-of select="/cp/strings/prefs_datetime_time_12h"/></label><br />

              <input type="radio" id="tf2" name="time_format" value="%H:%M">
                <xsl:if test="$time_format ='%H:%M'">
                  <xsl:attribute name="checked" value="checked"/>
                </xsl:if>
              </input>
              <label for="tf2"><xsl:value-of select="/cp/strings/prefs_datetime_time_24h"/></label><br />
              </td>
            </tr>

          <tr class="roweven">
            <td class="label"><xsl:value-of select="/cp/strings/prefs_datetime_order_label"/></td>
            <td class="contentwidth">
              <input type="radio" id="dt1" name="dt_order" value="date">
                <xsl:if test="$dt_order = 'date'">
                  <xsl:attribute name="checked" value="checked"/>
                </xsl:if>
              </input>
              <label for="dt1"><xsl:value-of select="/cp/strings/prefs_datetime_order_dt"/></label><br />

              <input type="radio" id="dt2" name="dt_order" value="time">
                <xsl:if test="$dt_order ='time'">
                  <xsl:attribute name="checked" value="checked"/>
                </xsl:if>
              </input>
              <label for="dt2"><xsl:value-of select="/cp/strings/prefs_datetime_order_td"/></label><br />
              </td>
            </tr>

          <tr class="controlrow">
            <td colspan="2"><span class="floatright"><input type="submit" name="save" value="{/cp/strings/prefs_logout_save_btn}" /><input type="submit" name="cancel" value="{/cp/strings/prefs_logout_cancel_btn}" /></span></td>
          </tr>
        </table>

</xsl:template>
</xsl:stylesheet>

