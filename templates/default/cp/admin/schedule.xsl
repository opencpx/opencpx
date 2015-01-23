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

<xsl:template match="/">
  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title"><xsl:copy-of select="/cp/strings/cp_title" /> : <xsl:copy-of select="/cp/strings/bc_system_admin_schedule" /></xsl:with-param>
    <xsl:with-param name="formaction">schedule.xsl</xsl:with-param>
    <xsl:with-param name="feedback" select="$feedback" />
    <xsl:with-param name="selected_navandcontent" select="/cp/strings/nv_admin_schedule_tasks" />
    <xsl:with-param name="help_short" select="/cp/strings/system_admin_hlp_short" />
    <xsl:with-param name="help_long"><xsl:copy-of select="/cp/strings/system_admin_hlp_long" /></xsl:with-param>
    <xsl:with-param name="breadcrumb">
      <breadcrumb>
        <section>
          <name><xsl:copy-of select="/cp/strings/bc_system_admin_schedule" /></name>
          <url>#</url>
          <image>SystemAdministration</image>
        </section>
      </breadcrumb>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

    <script src="{concat($base_url, '/cp/cp.js')}" language="JavaScript"></script>
    <script src="{concat($base_url, '/cp/admin/schedule.js')}" language="javascript"/>

    <input type="hidden" name="action" value="NA"/>

    <xsl:call-template name="cp_titlenavbar">
      <xsl:with-param name="active_tab">admin</xsl:with-param>
    </xsl:call-template>

    <table class="listview" border="0" cellspacing="0" cellpadding="0">
      <tr class="instructionrow">
        <td colspan="11"><xsl:value-of select="/cp/strings/manage_crontab_tasks"/></td>
      </tr>
      <tr class="title">
        <td colspan="11"><xsl:value-of select="/cp/strings/task_output_options"/></td>
      </tr>

      <tr class="instructionrow">
        <td colspan="11">
          <!-- scottw: copy-of preserves embedded HTML in the string, but also returns the element tags (mostly harmless) -->
          <xsl:copy-of select="/cp/strings/task_output_description"/><br />

          <input type="radio" id="messages_to_owner" name="taskOptions" value="user">
            <xsl:if test="not(/cp/vsap/vsap[@type='sys:crontab:list']/block/env[name='MAILTO'])">
              <xsl:attribute name="checked">true</xsl:attribute>
            </xsl:if>
          </input>
          <label for="messages_to_owner"><xsl:value-of select="/cp/strings/task_output_user" /></label><br />

          <xsl:variable name="twoquotes">""</xsl:variable>
          <xsl:variable name="task_mailto">
            <xsl:choose>
              <!-- same test as below: keep them in sync! -->
              <xsl:when test="string(/cp/vsap/vsap[@type='sys:crontab:list']/block/env[name='MAILTO']/value) != '' and string(/cp/vsap/vsap[@type='sys:crontab:list']/block/env[name='MAILTO']/value) != $twoquotes">
                <xsl:value-of select="/cp/vsap/vsap[@type='sys:crontab:list']/block/env[name='MAILTO']/value" />
              </xsl:when>
              <xsl:otherwise></xsl:otherwise>
            </xsl:choose>
          </xsl:variable>

          <input type="radio" id="messages_to_address" name="taskOptions" value="other">
            <xsl:if test="string(/cp/vsap/vsap[@type='sys:crontab:list']/block/env[name='MAILTO']/value) != '' and string(/cp/vsap/vsap[@type='sys:crontab:list']/block/env[name='MAILTO']/value) != $twoquotes">
                <xsl:attribute name="checked">true</xsl:attribute>
            </xsl:if>
          </input>

          <label for="messages_to_address"><xsl:value-of select="/cp/strings/task_output_other"/></label>&#160;<input type="text" name="txtMailTo" size="30" value="{$task_mailto}" onFocus="document.forms[0].taskOptions[1].checked=true" /><br />

          <input type="radio" id="discard_messages" name="taskOptions" value="discard">
            <xsl:if test="string(/cp/vsap/vsap[@type='sys:crontab:list']/block/env[name='MAILTO']/value) = $twoquotes">
              <xsl:attribute name="checked">true</xsl:attribute>
            </xsl:if>
          </input>

          <label for="discard_messages"><xsl:value-of select="/cp/strings/task_output_none"/></label><br />
        </td>
      </tr>

      <tr class="controlrow">
        <td colspan="11">
          <input type="submit" value="{/cp/strings/schedule_btn_set}" name="set_mailto"
              onClick="document.forms[0].action.value='mailto_event'; return validateTaskOutputOptions(
                   '{cp:js-escape(/cp/strings/task_mailto_error_email_req)}',
                   '{cp:js-escape(/cp/strings/task_mailto_change_failure)}');"
            />
        </td>
      </tr>

      <tr class="title">
        <td colspan="11"><xsl:value-of select="/cp/strings/task_list"/></td>
      </tr>

      <tr class="instructionrow">
        <td colspan="11">
          <xsl:value-of select="/cp/strings/task_list_description" /><br />
        </td>
      </tr>

      <xsl:choose>

      <xsl:when test="not(/cp/vsap/vsap[@type='sys:crontab:list']/block/event)">
      <xsl:call-template name="no_tasks_row"/>
      </xsl:when>

      <xsl:when test="/cp/vsap/vsap[@type='sys:crontab:list']/block[count(event) != 0]">
      <xsl:call-template name="controlrow"/>

      <tr class="columnhead">
        <td class="ckboxcolumn"><input type="checkbox" name="cbSelectAll" onClick="check(this.form.chk_event)"/></td>
        <td class="cmndcolumn"><xsl:value-of select="/cp/strings/schedule_header_command"/></td>
        <td class="contentwidth"><xsl:value-of select="/cp/strings/schedule_header_enabled"/></td>
        <td class="contentwidth"><span  class="columndescription" title="{/cp/strings/schedule_title_user}"><xsl:value-of select="/cp/strings/schedule_header_user"/></span></td>
        <td class="mincolumn"><span class="columndescription" title="{/cp/strings/schedule_title_minute}"><xsl:value-of select="/cp/strings/schedule_header_minute"/></span></td>
        <td class="hrcolumn"><span class="columndescription" title="{/cp/strings/schedule_title_hour}"><xsl:value-of select="/cp/strings/schedule_header_hour"/></span></td>
        <td class="domcolumn"><span class="columndescription" title="{/cp/strings/schedule_title_day}"><xsl:value-of select="/cp/strings/schedule_header_day"/></span></td>
        <td class="mcolumn"><span class="columndescription" title="{/cp/strings/schedule_title_month}"><xsl:value-of select="/cp/strings/schedule_header_month"/></span></td>
        <td class="dwcolumn"><span class="columndescription" title="{/cp/strings/schedule_title_weekday}"><xsl:value-of select="/cp/strings/schedule_header_weekday"/></span></td>
        <td class="contentwidth"><span  class="columndescription" title="{/cp/strings/schedule_title_special}"><xsl:value-of select="/cp/strings/schedule_header_special"/></span></td>
        <td><xsl:value-of select="/cp/strings/schedule_header_actions"/></td>
      </tr>

      <xsl:for-each select="/cp/vsap/vsap[@type='sys:crontab:list']/block[count(event) != 0]">
        <xsl:variable name="block_id" select="@id"/>
        <tr class="rowodd">
          <td>&#160;</td>
          <xsl:choose>
            <xsl:when test="/cp/form/action='edit_desc' and /cp/form/block=$block_id">
              <td colspan="9"><strong><xsl:value-of select="/cp/strings/schedule_description"/></strong>&#160;
                <input name="description" value="{comment}"/>
                <input type="hidden" name="block" value="{$block_id}"/>
              </td>
              <td><a href="#" onClick="doSubmit('save_desc')"><xsl:value-of select="/cp/strings/schedule_save"/></a> | 
                  <a href="{$base_url}/cp/admin/schedule.xsl"><xsl:value-of select="/cp/strings/schedule_cancel"/></a>
              </td>
              </xsl:when>
              <xsl:otherwise>
              <td colspan="9"><strong><xsl:value-of select="/cp/strings/schedule_description"/></strong>&#160;
                <xsl:value-of select="comment"/>
              </td>
              <td><a href="{$base_url}/cp/admin/schedule.xsl?block={$block_id}&amp;action=edit_desc"><xsl:value-of select="/cp/strings/schedule_edit"/></a> | 
                  <a href="{$base_url}/cp/admin/schedule.xsl?block={$block_id}&amp;action=delete_desc"><xsl:value-of select="/cp/strings/schedule_delete"/></a>
              </td>
              </xsl:otherwise>
            </xsl:choose>
        </tr>
        <xsl:for-each select="event">

          <tr class="rowevenborder">
            <td>
              <input type="checkbox" id="{$block_id}-{@id}" name="chk_event" value="{$block_id}-{@id}"/>
            </td>
            <td>
              <label for="{$block_id}-{@id}">
                <xsl:call-template name="truncate">
                  <xsl:with-param name="string">
                    <xsl:value-of select="command"/>
                  </xsl:with-param>
                  <xsl:with-param name="fieldlength" select="/cp/strings/schedule_command_length" />
                </xsl:call-template>
              </label>
            </td>
            <td>
              <xsl:choose>
                <xsl:when test="active='1'"><span class="running">&#160;</span></xsl:when>
                <xsl:otherwise><span class="stopped">&#160;</span></xsl:otherwise>
              </xsl:choose>
            </td>
            <td nowrap="1"><xsl:value-of select="user"/></td>
            <td nowrap="1">
              <xsl:choose>
                <xsl:when test="string(schedule/minute)"><xsl:value-of select="schedule/minute"/></xsl:when>
                <xsl:otherwise><br /></xsl:otherwise>
              </xsl:choose>
            </td>
            <td nowrap="1">
              <xsl:choose>
                <xsl:when test="string(schedule/hour)"><xsl:value-of select="schedule/hour"/></xsl:when>
                <xsl:otherwise><br /></xsl:otherwise>
              </xsl:choose>
            </td>
            <td nowrap="1">
              <xsl:choose>
                <xsl:when test="string(schedule/dom)"><xsl:value-of select="schedule/dom"/></xsl:when>
                <xsl:otherwise><br /></xsl:otherwise>
              </xsl:choose>
            </td>
            <td nowrap="1">
              <xsl:choose>
                <xsl:when test="string(schedule/month)"><xsl:value-of select="schedule/month"/></xsl:when>
                <xsl:otherwise><br /></xsl:otherwise>
              </xsl:choose>
            </td>
            <td nowrap="1">
              <xsl:choose>
                <xsl:when test="string(schedule/dow)"><xsl:value-of select="schedule/dow"/></xsl:when>
                <xsl:otherwise><br /></xsl:otherwise>
              </xsl:choose>
            </td>
            <td nowrap="1">
              <xsl:choose>
                <xsl:when test="string(schedule/special)"><xsl:value-of select="schedule/special"/></xsl:when>
                <xsl:otherwise><br /></xsl:otherwise>
              </xsl:choose>
            </td>
            <td class="actions">
              <a href="{$base_url}/cp/admin/schededit.xsl?block={$block_id}&amp;event={@id}"><xsl:value-of select="/cp/strings/schedule_edit"/></a> | 
              <a href="#" onClick="return confirmAction('{cp:js-escape(/cp/strings/confirm_task_delete)}', '{$base_url}/cp/admin/schedule.xsl?block={$block_id}&amp;event={@id}&amp;action=delete_event')"><xsl:value-of select="/cp/strings/schedule_delete"/></a> | 
              <xsl:choose>
                <xsl:when test="active='1'"><a href="#" onClick="return confirmAction('{cp:js-escape(/cp/strings/confirm_task_disable)}', '{$base_url}/cp/admin/schedule.xsl?block={$block_id}&amp;event={@id}&amp;action=disable_event')"><xsl:value-of select="/cp/strings/schedule_disable"/></a></xsl:when>
                <xsl:otherwise><a href="{$base_url}/cp/admin/schedule.xsl?block={$block_id}&amp;event={@id}&amp;action=enable_event"><xsl:value-of select="/cp/strings/schedule_enable"/></a></xsl:otherwise>
              </xsl:choose>
            </td>
          </tr>
        </xsl:for-each>
      </xsl:for-each>
      <xsl:call-template name="controlrow"/>

      </xsl:when>
      </xsl:choose>
      </table>

</xsl:template>

<xsl:template name="controlrow">
  <tr class="controlrow">
    <td colspan="11"><span class="floatright">
      <input type="submit" name="newtask" value="{/cp/strings/schedule_btn_new}" /></span>
      <input type="button" name="group_delete" value="{/cp/strings/schedule_btn_delete}" onClick="return submitItems('{cp:js-escape(/cp/strings/tasks_item_select_prompt)}', 'chk_event','{cp:js-escape(/cp/strings/confirm_tasks_delete)}','group_delete')"/>
      <input type="button" name="group_disable" value="{/cp/strings/schedule_btn_disable}" onClick="return submitItems('{cp:js-escape(/cp/strings/tasks_item_select_prompt)}', 'chk_event','{cp:js-escape(/cp/strings/confirm_tasks_disable)}','group_disable')"/>
      <input type="button" name="group_enable" value="{/cp/strings/schedule_btn_enable}" onClick="return submitItems('{cp:js-escape(/cp/strings/tasks_item_select_prompt)}', 'chk_event', null,'group_enable')"/>
    </td>
  </tr>
</xsl:template>

<xsl:template name="no_tasks_row">
  <tr class="controlrow">
    <td colspan="5"><span class="floatleft">
      <xsl:value-of select="/cp/strings/task_no_tasks" /><br />
    </span></td>
    <td colspan="6"><span class="floatright">
      <input type="submit" name="newtask" value="{/cp/strings/schedule_btn_new}" /></span>
    </td>
  </tr>
</xsl:template>

</xsl:stylesheet>
