<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../cp_global.xsl" />

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

<xsl:variable name="mode">
  <xsl:choose>
    <xsl:when test="string(/cp/form/btn_save_new)">add</xsl:when>
    <xsl:when test="string(/cp/form/block) and string(/cp/form/event)">edit</xsl:when>
    <xsl:otherwise>add</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="subtitle">
  <xsl:choose>
    <xsl:when test="$mode='edit'"><xsl:copy-of select="/cp/strings/bc_system_admin_schedule_edit" /></xsl:when>
    <xsl:otherwise><xsl:copy-of select="/cp/strings/bc_system_admin_schedule_add" /></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:template match="/">
  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title"><xsl:copy-of select="/cp/strings/cp_title" /> : <xsl:copy-of select="/cp/strings/bc_system_admin_schedule" /> : <xsl:copy-of select="$subtitle" /> </xsl:with-param>
    <xsl:with-param name="formaction">schededit.xsl</xsl:with-param>
    <xsl:with-param name="feedback" select="$feedback" />
    <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_admin_schedule_tasks" />
    <xsl:with-param name="help_short" select="/cp/strings/system_admin_hlp_short" />
    <xsl:with-param name="help_long"><xsl:copy-of select="/cp/strings/system_admin_hlp_long" /></xsl:with-param>
    <xsl:with-param name="breadcrumb">
      <breadcrumb>
        <section>
          <name><xsl:copy-of select="/cp/strings/bc_system_admin_schedule" /></name>
          <url><xsl:value-of select="$base_url"/>/cp/admin/schedule.xsl</url>
        </section>
        <section>
          <name><xsl:copy-of select="$subtitle" /></name>
          <url>#</url>
          <image>SystemAdministration</image>
        </section>
      </breadcrumb>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

      <xsl:call-template name="cp_titlenavbar">
        <xsl:with-param name="active_tab">admin</xsl:with-param>
      </xsl:call-template>

      <script type="text/javascript" language="javascript">
         function changeColor (tempid) {
             if( tempid == 'q1' ) {
                 document.getElementById('q1').className = 'nohilite';
                 document.getElementById('q2').className = 'hilite';
             }
             else {
                 document.getElementById('q1').className = 'hilite';
                 document.getElementById('q2').className = 'nohilite';
             }
         }
      </script>

      <!-- highlight classes -->
      <style type="text/css">
        .nohilite {background-color:#FFFFFF}
        .hilite   {background-color:#FFFF00}
      </style>

      <table class="formview" border="0" cellspacing="0" cellpadding="0">
        <xsl:choose>
          <xsl:when test="$mode='edit'">
            <input type="hidden" name="block" value="{/cp/form/block}"/>
            <input type="hidden" name="event" value="{/cp/form/event}"/>
            <tr class="instructionrow">
              <td colspan="2"><xsl:value-of select="/cp/strings/schedule_edit_task_ins"/></td>
            </tr>
            <tr class="title">
              <td colspan="2"><xsl:value-of select="/cp/strings/schedule_edit_task"/></td>
            </tr>
            <tr class="roweven">
              <td class="label"><xsl:value-of select="/cp/strings/schedule_label_description"/></td>
              <td class="contentwidth"><xsl:value-of select="/cp/vsap/vsap[@type='sys:crontab:list']/block[@id=/cp/form/block]/comment"/><br />
                                     <xsl:value-of select="/cp/strings/schedule_desc_jobs_1"/>&#160;
                                     <xsl:value-of select="count(/cp/vsap/vsap[@type='sys:crontab:list']/block[@id=/cp/form/block]/event)"/>
                                     &#160;<xsl:value-of select="/cp/strings/schedule_desc_jobs_2"/></td>
            </tr>
          </xsl:when>
          <xsl:otherwise>
             <input type="hidden" name="block"/>
             <input type="hidden" name="event"/>
           <tr class="instructionrow">
              <td colspan="3"><xsl:value-of select="/cp/strings/schedule_create_task_ins"/></td>
            </tr>
            <tr class="title">
              <td colspan="3"><xsl:value-of select="/cp/strings/schedule_create_task"/></td>
            </tr>
            <tr class="roweven">
              <td class="label"><xsl:value-of select="/cp/strings/schedule_label_description"/></td>
              <td class="contentwidth"><xsl:value-of select="/cp/strings/schedule_select_choices"/></td>
            </tr>
            <tr class="roweven" style="border-bottom: 0px;">
              <td class="label"><span class="floatright"><input type="radio" id="create_new" name="desc" checked="1" value="new"/><label for="create_new"><xsl:value-of select="/cp/strings/schedule_label_create_new"/></label></span></td>
              <td class="contentwidth"><input name="newblockdesc" size="40" onfocus="document.forms[0].desc[0].checked=true"/></td>
            </tr>
            <tr class="roweven">
              <td class="label"><span class="floatright"><input type="radio" id="use_existing" name="desc" value="exits"/><label for="use_existing"><xsl:value-of select="/cp/strings/schedule_label_use_existing"/></label></span></td>
              <td class="contentwidth">
                <select name="lst_blocks" size="1" onfocus="document.forms[0].desc[1].checked=true">
                  <xsl:for-each select="/cp/vsap/vsap[@type='sys:crontab:list']/block/comment">
                    <option value="{parent::*/@id}"><xsl:value-of select="."/></option>
                  </xsl:for-each>
                </select>
              </td>
            </tr>
          </xsl:otherwise>
        </xsl:choose>

        <tr class="roweven">
          <td class="label"><xsl:value-of select="/cp/strings/schedule_label_run_as_user"/></td>
          <td class="contentwidth">
            <select name="userid" size="1">
              <xsl:for-each select="/cp/vsap/vsap[@type='user:list:system']/user">
                <xsl:sort select="translate(., 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')" />
                <option value="{.}">
                    <xsl:if test="$mode='edit' and /cp/vsap/vsap[@type='sys:crontab:list']/block[@id=/cp/form/block]/event[@id=/cp/form/event]/user=."><xsl:attribute name="selected"/></xsl:if>
                    <xsl:value-of select="."/>
                </option>
              </xsl:for-each>
            </select>
          </td>
        </tr>
        <tr class="roweven">
          <td class="label"><input type="radio" id="select_date_and_time" name="time" value="standard" checked="1" /><span id="q1"><label for="select_date_and_time"><xsl:value-of select="/cp/strings/schedule_label_select_date_time"/></label></span></td>
          <td>
            <table>
              <tr class="noborder">
                <td class="label"><xsl:value-of select="/cp/strings/schedule_label_minute"/></td>
                <td>
                  <xsl:variable name="selections" select="concat(',' , translate(/cp/vsap/vsap[@type='sys:crontab:list']/block[@id=/cp/form/block]/event[@id=/cp/form/event]/schedule/minute, ' ', ''), ',')"/>
                  <select name="minute" size="5" multiple="1" onFocus="javascript: changeColor('q2'); document.forms[0].time[0].checked=true;">
                    <xsl:for-each select="/cp/strings/schedule_minute">
                      <option value="{@value}">
                        <xsl:if test="$mode='edit' and contains($selections, concat(',' , @value , ','))"><xsl:attribute name="selected"/></xsl:if>
                        <xsl:value-of select="."/>
                      </option>
                    </xsl:for-each>
                  </select>
                </td>
              </tr>
              <tr class="noborder">
                <td class="label"><xsl:value-of select="/cp/strings/schedule_label_hour"/></td>
                <td class="contentwidth">
                  <xsl:variable name="selections" select="concat(',' , translate(/cp/vsap/vsap[@type='sys:crontab:list']/block[@id=/cp/form/block]/event[@id=/cp/form/event]/schedule/hour, ' ', ''), ',')"/>
                  <select name="hour" size="5" multiple="1" onFocus="javascript: changeColor('q2'); document.forms[0].time[0].checked=true;">
                    <xsl:for-each select="/cp/strings/schedule_hour">
                      <option value="{@value}">
                        <xsl:if test="$mode='edit' and contains($selections, concat(',' , @value , ','))"><xsl:attribute name="selected"/></xsl:if>
                        <xsl:value-of select="."/>
                      </option>
                    </xsl:for-each>
                  </select>
                </td>
              </tr>
              <tr class="noborder">
                <td class="label"><xsl:value-of select="/cp/strings/schedule_label_dom"/></td>
                <td class="contentwidth">
                  <xsl:variable name="selections" select="concat(',' , translate(/cp/vsap/vsap[@type='sys:crontab:list']/block[@id=/cp/form/block]/event[@id=/cp/form/event]/schedule/dom, ' ', ''), ',')"/>
                  <select name="dayofmonth" size="5" multiple="1" onFocus="javascript: changeColor('q2'); document.forms[0].time[0].checked=true;">
                    <xsl:for-each select="/cp/strings/schedule_dom">
                      <option value="{@value}">
                        <xsl:if test="$mode='edit' and contains($selections, concat(',' , @value , ','))"><xsl:attribute name="selected"/></xsl:if>
                        <xsl:value-of select="."/>
                      </option>
                    </xsl:for-each>
                  </select>
                </td>
              </tr>
              <tr class="noborder">
                <td class="label"><xsl:value-of select="/cp/strings/schedule_label_month"/></td>
                <td class="contentwidth">
                  <xsl:variable name="selections" select="concat(',' , translate(/cp/vsap/vsap[@type='sys:crontab:list']/block[@id=/cp/form/block]/event[@id=/cp/form/event]/schedule/month, ' ', ''), ',')"/>
                  <select name="month" size="5" multiple="1" onFocus="javascript: changeColor('q2'); document.forms[0].time[0].checked=true;">
                    <xsl:for-each select="/cp/strings/schedule_month">
                      <option value="{@value}">
                        <xsl:if test="$mode='edit' and contains($selections, concat(',' , @value , ','))"><xsl:attribute name="selected"/></xsl:if>
                        <xsl:value-of select="."/>
                      </option>
                    </xsl:for-each>
                  </select>
                </td>
              </tr>
              <tr class="noborder">
                <td class="label"><xsl:value-of select="/cp/strings/schedule_label_dow"/></td>
                <td class="contentwidth">
                  <xsl:variable name="selections" select="concat(',' , translate(/cp/vsap/vsap[@type='sys:crontab:list']/block[@id=/cp/form/block]/event[@id=/cp/form/event]/schedule/dow, ' ', ''), ',')"/>
                  <select name="dayofweek" size="5" multiple="1" onFocus="javascript: changeColor('q2'); document.forms[0].time[0].checked=true;">
                    <xsl:for-each select="/cp/strings/schedule_dow">
                      <option value="{@value}">
                        <xsl:if test="$mode='edit' and contains($selections, concat(',' , @value , ','))"><xsl:attribute name="selected"/></xsl:if>
                        <xsl:value-of select="."/>
                      </option>
                    </xsl:for-each>
                  </select>
                </td>
              </tr>
            </table>
          </td>
        </tr>

        <tr class="roweven">
          <td class="label"><input type="radio" id="select_from_template" name="time" value="special">
            <xsl:if test="$mode='edit' and string(/cp/vsap/vsap[@type='sys:crontab:list']/block[@id=/cp/form/block]/event[@id=/cp/form/event]/schedule/special)">
              <xsl:attribute name="checked"/>
            </xsl:if></input><span id="q2"><label for="select_from_template"><xsl:value-of select="/cp/strings/schedule_label_select_template"/></label></span>
          </td>
          <td class="contentwidth">
            <table>
              <tr class="noborder">
                <td class="label"><xsl:value-of select="/cp/strings/schedule_label_run_job"/></td>
                <td class="contentwidth">
                  <xsl:variable name="selections" select="concat(',' , translate(/cp/vsap/vsap[@type='sys:crontab:list']/block[@id=/cp/form/block]/event[@id=/cp/form/event]/schedule/special, ' ', ''), ',')"/>
                  <select name="special" onFocus="javascript: changeColor('q1'); document.forms[0].time[1].checked=true;">
                    <xsl:for-each select="/cp/strings/schedule_special">
                      <option value="{@value}">
                        <xsl:if test="$mode='edit' and contains($selections, concat(',' , @value , ','))"><xsl:attribute name="selected"/></xsl:if>
                        <xsl:value-of select="."/>
                      </option>
                    </xsl:for-each>
                  </select>
                </td>
              </tr>
            </table>
          </td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:value-of select="/cp/strings/schedule_label_command"/></td>
          <td class="contentwidth"><input name="croncommand" size="40"><xsl:if test="$mode='edit'"><xsl:attribute name="value"><xsl:value-of select="/cp/vsap/vsap[@type='sys:crontab:list']/block[@id=/cp/form/block]/event[@id=/cp/form/event]/command"/></xsl:attribute></xsl:if></input></td>
        </tr>
   
        <tr class="controlrow">
          <td colspan="2"><span class="floatright">
            <input type="submit" name="btn_save" value="{/cp/strings/schedule_btn_save}" />
            <input type="submit" name="btn_save_new" value="{/cp/strings/schedule_btn_save_new}" />
            <input type="reset" name="btn_clear" value="{/cp/strings/schedule_btn_reset}" />
            <input type="submit" name="btn_cancel" value="{/cp/strings/schedule_btn_cancel}" />
          </span></td>
        </tr>
      </table>

</xsl:template>
</xsl:stylesheet>
