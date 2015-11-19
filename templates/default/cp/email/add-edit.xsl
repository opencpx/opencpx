<?xml version="1.0" encoding="utf-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../cp_global.xsl" />

<xsl:variable name="message">
  <xsl:choose>
    <xsl:when test="/cp/msgs/msg[@name='email_address_exists']">
      '<xsl:value-of select="/cp/form/lhs" />@<xsl:value-of select="/cp/form/domain" />'<xsl:value-of select="/cp/strings/email_add_already_exists" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='emails_maxed_out']">
      <xsl:value-of select="/cp/strings/cp_msg_email_add_max_emails" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='add_email_permission']">
      '<xsl:value-of select="/cp/form/lhs" />@<xsl:value-of select="/cp/form/domain" />'<xsl:value-of select="/cp/strings/cp_msg_email_add_failure" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='add_email_invalid']">
      '<xsl:value-of select="/cp/form/lhs" />@<xsl:value-of select="/cp/form/domain" />'<xsl:value-of select="/cp/strings/cp_msg_email_add_failure" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='update_email_permission']">
      '<xsl:value-of select="/cp/form/lhs" />@<xsl:value-of select="/cp/form/domain" />'<xsl:value-of select="/cp/strings/cp_msg_email_update_failure" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='update_email_invalid']">
      '<xsl:value-of select="/cp/form/lhs" />@<xsl:value-of select="/cp/form/domain" />'<xsl:value-of select="/cp/strings/cp_msg_email_update_failure" />
    </xsl:when>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="message2">
  <xsl:choose>
    <xsl:when test="/cp/msgs/msg[@name='add_email_invalid']">
       <xsl:value-of select="/cp/strings/email_js_error_email_fmt" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='update_email_invalid']">
       <xsl:value-of select="/cp/strings/email_js_error_email_fmt" />
    </xsl:when>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="message3">
  <xsl:choose>
    <xsl:when test="/cp/msgs/msg[@name='add_email_invalid']">
       <xsl:value-of select="/cp/strings/cp_msg_email_failure_error" /> <xsl:value-of select="/cp/vsap/vsap[@type='error'][@caller='mail:addresses:add']/message" />
    </xsl:when>
    <xsl:when test="/cp/msgs/msg[@name='update_email_invalid']">
       <xsl:value-of select="/cp/strings/cp_msg_email_failure_error" /> <b><xsl:value-of select="/cp/vsap/vsap[@type='error'][@caller='mail:addresses:update']/message" /></b>
    </xsl:when>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="feedback">
  <xsl:if test="$message != ''">
    <xsl:call-template name="feedback_table">
      <xsl:with-param name="image">
        <xsl:choose>
          <xsl:when test="/cp/vsap/vsap[@type='error']">error</xsl:when>
          <xsl:when test="/cp/msgs/msg[@name='email_address_exists']">error</xsl:when>
          <xsl:when test="/cp/msgs/msg[@name='emails_maxed_out']">error</xsl:when>
          <xsl:otherwise>success</xsl:otherwise>
        </xsl:choose>
      </xsl:with-param>
      <xsl:with-param name="message">
        <xsl:value-of select="$message" />
      </xsl:with-param>
      <xsl:with-param name="message2">
        <xsl:value-of select="$message2" />
      </xsl:with-param>
      <xsl:with-param name="message3">
        <xsl:value-of select="$message3" />
      </xsl:with-param>
    </xsl:call-template>
  </xsl:if>
</xsl:variable>

<xsl:variable name="lhs">
  <xsl:choose>
    <xsl:when test="string(/cp/form/lhs)">
      <xsl:value-of select="/cp/form/lhs" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="domain">
  <xsl:choose>
    <xsl:when test="string(/cp/form/domain)">
      <xsl:value-of select="/cp/form/domain" />
    </xsl:when>
    <xsl:when test="string(/cp/form/select_domain)">
      <xsl:value-of select="/cp/form/select_domain" />
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="delivery">
  <xsl:choose>
    <xsl:when test="string(/cp/form/delivery)">
      <xsl:value-of select="/cp/form/delivery" />
    </xsl:when>
    <xsl:when test="/cp/form/action='edit'">
      <xsl:choose>
        <xsl:when test="/cp/vsap/vsap[@type='mail:addresses:list']/address[source=/cp/form/address]/dest/@type = 'reject'">reject</xsl:when>
        <xsl:when test="substring(/cp/vsap/vsap[@type='mail:addresses:list']/address[source=/cp/form/address]/dest,2,8) = '|exit 67'">reject</xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='mail:addresses:list']/address[source=/cp/form/address]/dest/@type = 'delete'">delete</xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='mail:addresses:list']/address[source=/cp/form/address]/dest/@type = 'local'">local</xsl:when>
        <xsl:when test="/cp/vsap/vsap[@type='mail:addresses:list']/address[source=/cp/form/address]/dest != ''">list</xsl:when>
      </xsl:choose>
    </xsl:when>
    <xsl:otherwise>reject</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="address_list">
  <xsl:choose>
    <xsl:when test="string(/cp/form/address_list)">
      <xsl:value-of select="/cp/form/address_list" />
    </xsl:when>
    <xsl:when test="string(/cp/vsap/vsap[@type='mail:addresses:list']/address[source=/cp/form/address]/dest)">
      <xsl:value-of select="/cp/vsap/vsap[@type='mail:addresses:list']/address[source=/cp/form/address]/dest"/>
    </xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="action">
  <xsl:choose>
    <xsl:when test="/cp/form/action='edit'">edit</xsl:when>
    <xsl:otherwise>save</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="navcontent">
  <xsl:choose>
    <xsl:when test="$action='edit'"><xsl:value-of select="/cp/strings/nv_email_addresses"/></xsl:when>
    <xsl:otherwise><xsl:value-of select="/cp/strings/nv_add_email"/></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="subtitle">
  <xsl:choose>
    <xsl:when test="$action='edit'">
        <xsl:value-of select="concat(/cp/strings/bc_email_edit_setup,' ',/cp/form/address)" />
    </xsl:when>
    <xsl:otherwise>
        <xsl:value-of select="/cp/strings/bc_email_add_setup" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:template match="/">
  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title">
      <xsl:value-of select="/cp/strings/cp_title" />
      v<xsl:value-of select="/cp/vsap/vsap[@type='auth']/version" /> :
      <xsl:value-of select="$subtitle" />
    </xsl:with-param>
    <xsl:with-param name="formaction">add-edit.xsl</xsl:with-param>
    <xsl:with-param name="feedback" select="$feedback" />
    <xsl:with-param name="selected_navandcontent" select="$navcontent" />
    <xsl:with-param name="help_short" select="/cp/strings/email_add_setup_hlp_short" />
    <xsl:with-param name="help_long" select="/cp/strings/email_add_setup_hlp_long" />
    <xsl:with-param name="breadcrumb">
    <breadcrumb>
      <xsl:choose>
        <xsl:when test="$action='edit'">
          <section>
            <name><xsl:value-of select="/cp/strings/bc_email_addresses" /></name>
            <url>index.xsl</url>
            <image>EmailAddresses</image>
          </section>
          <section>
            <name><xsl:value-of select="$subtitle" /></name>
            <url>#</url>
            <image>EmailAddresses</image>
          </section>
        </xsl:when>
        <xsl:otherwise>
          <section>
            <name><xsl:value-of select="$subtitle" /></name>
            <url>#</url>
            <image>EmailAddresses</image>
          </section>
        </xsl:otherwise>
      </xsl:choose>
    </breadcrumb>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

<script src="{concat($base_url, '/cp/cp.js')}" language="JavaScript"></script>

<table class="formview" border="0" cellspacing="0" cellpadding="0">
<tr class="title">
  <td colspan="2">
    <xsl:choose>
      <xsl:when test="$action='edit'">
        <xsl:value-of select="concat(/cp/strings/cp_title_email_edit_setup,' ',/cp/form/address)" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="/cp/strings/cp_title_email_add_setup" />
      </xsl:otherwise>
    </xsl:choose>
  </td>
</tr>
<tr class="instructionrow">
  <td colspan="2">
    <xsl:choose>
      <xsl:when test="$action='edit'">
        <xsl:value-of select="/cp/strings/cp_instr_email_edit" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="/cp/strings/cp_instr_email_add" />
      </xsl:otherwise>
    </xsl:choose>
  </td>
</tr>
<tr class="rowodd">
  <td class="label"><xsl:value-of select="/cp/strings/cp_label_email_address" /></td>
  <td class="contentwidth">
    <input type="hidden" name="Save" value=""/>
    <input type="hidden" name="action" value="{/cp/form/action}"/>
    <input type="hidden" name="sort_by" value="{/cp/form/sort_by}"/>
    <input type="hidden" name="sort_type" value="{/cp/form/sort_type}"/>
    <input type="hidden" name="select_domain" value="{/cp/form/select_domain}"/>
    <input type="hidden" name="show_system" value="{/cp/form/show_system}"/>
    <input type="hidden" name="Cancel" value="" />
   
    <xsl:choose>
      <xsl:when test="/cp/form/action = 'edit'">
	<input type="hidden" name="function" value="update"/>
        <input type="hidden" name="address" value="{/cp/form/address}"/>
	<input type="hidden" name="lhs" value="{substring-before(/cp/form/address, '@')}"/>
	<input type="hidden" name="domain" value="{substring-after(/cp/form/address, '@')}"/>
	<xsl:value-of select="/cp/form/address"/>
      </xsl:when>
      <xsl:otherwise>
	<input type="hidden" name="function" value="add"/>
<!--  this javascript array is for verifying email limits in validateEmail (BUG25437) -->
      <script language="JavaScript">
        var email_add_ok_array = new Array();
          email_add_ok_array[0] = 0;
        <xsl:for-each select="/cp/vsap/vsap[@type='domain:list']/domain">
          <xsl:sort select="translate(name, 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')" />
          <xsl:variable name="index"><xsl:value-of select="position()"/></xsl:variable>
          <xsl:variable name="domain_name">
            <xsl:value-of select="name" />
          </xsl:variable>
          <xsl:variable name="email_count">
            <xsl:value-of select="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain_name]/mail_aliases/usage" />
          </xsl:variable>
          <xsl:variable name="email_limit">
            <xsl:value-of select="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain_name]/mail_aliases/limit" />
          </xsl:variable>
          <xsl:variable name="email_add_ok">
            <xsl:choose>
              <xsl:when test="$email_limit='unlimited'">1</xsl:when>
              <xsl:otherwise><xsl:value-of select="$email_limit - $email_count" /></xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          email_add_ok_array[<xsl:value-of select="$index" />] = <xsl:value-of select="$email_add_ok" />;
        </xsl:for-each>
      </script>
<!-- end javascript -->
	<input type="text" name="lhs" value="{$lhs}" size="24"/> @ 
	<select name="domain" size="1">
        <option value=""><xsl:value-of select="/cp/strings/cp_email_domain_default" /></option>
	<xsl:for-each select="/cp/vsap/vsap[@type='domain:list']/domain">
	  <xsl:sort select="translate(name, 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')" />
          <xsl:variable name="domain_name">
            <xsl:value-of select="name" />
          </xsl:variable>
          <xsl:variable name="email_count">
            <xsl:value-of select="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain_name]/mail_aliases/usage" />
          </xsl:variable>
          <xsl:variable name="email_limit">
            <xsl:value-of select="/cp/vsap/vsap[@type='domain:list']/domain[name=$domain_name]/mail_aliases/limit" />
          </xsl:variable>
          <xsl:variable name="email_add_ok">
            <xsl:choose>
              <xsl:when test="$email_limit='unlimited'">1</xsl:when>
              <xsl:otherwise><xsl:value-of select="$email_limit - $email_count" /></xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:variable name="email_summary">
            <xsl:choose>
              <xsl:when test="$email_limit='unlimited'">
                <xsl:value-of select="/cp/strings/email_addresses_unlimited" />
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$email_count" />
                <xsl:value-of select="/cp/strings/email_addresses_of" />
                <xsl:value-of select="$email_limit" />
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
	  <option value="{name}">
            <xsl:if test="$email_add_ok &lt;= 0">
              <xsl:attribute name="style">color:red</xsl:attribute>
            </xsl:if>
	    <xsl:if test="name = $domain">
	      <xsl:attribute name="selected">true</xsl:attribute>
	    </xsl:if><xsl:value-of select="name" /> (<xsl:value-of select="/cp/strings/cp_index_total_addresses" /> <xsl:value-of select="$email_summary" />)
	  </option>
	</xsl:for-each>
	</select>
      </xsl:otherwise>
     </xsl:choose>
    </td>
    </tr>
    <tr class="roweven">
      <td class="label"><xsl:value-of select="/cp/strings/cp_label_email_delivery" /></td>
          <td class="contentwidth">
            <input type="radio" id="delivery_reject" name="delivery" value="reject">
              <xsl:if test="$delivery = 'reject'">
                <xsl:attribute name="checked">true</xsl:attribute>
              </xsl:if>
            </input>
            <label for="delivery_reject"><xsl:value-of select="/cp/strings/cp_email_delivery_reject" /></label><br />

            <input type="radio" id="delivery_delete" name="delivery" value="delete">
              <xsl:if test="$delivery = 'delete'">
                <xsl:attribute name="checked">true</xsl:attribute>
              </xsl:if>
            </input>
            <label for="delivery_delete"><xsl:value-of select="/cp/strings/cp_email_delivery_delete" /></label><br />
         
            <input type="radio" id="delivery_local" name="delivery" value="local">
              <xsl:if test="$delivery = 'local'">
                <xsl:attribute name="checked">true</xsl:attribute>
              </xsl:if>
            </input>
            <label for="delivery_local"><xsl:value-of select="/cp/strings/cp_email_delivery_local" /></label> 

            <select name="local_mailbox" size="1">
              <option value=""><xsl:value-of select="/cp/strings/cp_email_delivery_local_default" /></option>
              <xsl:for-each select="/cp/vsap/vsap[@type='user:list_brief']/user[services/mail]"><!-- select mail users -->
                <xsl:sort select="login_id" />
                <option value="{login_id}">
                <xsl:if test="$address_list = login_id">
                  <xsl:attribute name="selected">true</xsl:attribute>
                </xsl:if><xsl:value-of select="login_id" />
               </option>
              </xsl:for-each>
            </select><br/>

            <input type="radio" id="delivery_list" name="delivery" value="list">
              <xsl:if test="$delivery = 'list'">
                <xsl:attribute name="checked">true</xsl:attribute>
              </xsl:if>
            </input>
            <label for="delivery_list"><xsl:value-of select="/cp/strings/cp_email_delivery_instr" /></label><br />
            <textarea class="indent" name="address_list" rows="8" cols="60" >
              <xsl:if test="$delivery = 'list'">
                <xsl:value-of select="$address_list" />
              </xsl:if>
            </textarea><br /> 
            <span class="indent"><span class="parenthetichelp"><xsl:value-of select="/cp/strings/cp_email_delivery_inputinstr"/></span></span><br />
          </td>
        </tr>
        <tr class="controlrow">
          <td colspan="2">
            <input class="floatright" type="button" name="btnCancel" value="{/cp/strings/email_add_btn_cancel}" 
              onClick="document.forms[0].Cancel.value='yes';document.forms[0].submit();" />
            <input class="floatright" type="submit" name="btnSave" value="{/cp/strings/email_add_btn_save}" onClick="return validateEmail('{cp:js-escape(/cp/strings/email_js_error_email_req)}','{cp:js-escape(/cp/strings/email_js_error_email_fmt)}','{cp:js-escape(/cp/strings/email_js_error_email_dlv_req)}','{cp:js-escape(/cp/strings/email_js_error_email_dlv_fmt)}','{cp:js-escape(/cp/strings/cp_msg_email_add_max_emails)}')" />
          </td>
        </tr>
      </table>

</xsl:template>

</xsl:stylesheet>
