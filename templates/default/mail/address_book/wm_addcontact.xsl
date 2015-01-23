<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../mail_global.xsl" />
<xsl:import href="mail_addressbook_feedback.xsl" />

<xsl:variable name="status">
  <xsl:call-template name="status_message" />
</xsl:variable>

<xsl:variable name="status_image">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='error']">error</xsl:when>
    <xsl:otherwise>success</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="message">
  <xsl:if test="string($status)">
    <xsl:call-template name="feedback_table">
      <xsl:with-param name="image"><xsl:value-of select="$status_image" /></xsl:with-param>
      <xsl:with-param name="message"><xsl:copy-of select="$status" /> </xsl:with-param>
    </xsl:call-template>
  </xsl:if>
</xsl:variable>

<xsl:variable name="edit">
  <xsl:choose>
    <xsl:when test="string(cp/form/edit)">1</xsl:when>
    <xsl:otherwise></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="uid">
  <xsl:choose>
    <xsl:when test="string(/cp/form/save_another) and not(string(/cp/vsap/vsap[@type='error']))"></xsl:when>
    <xsl:when test="string(/cp/form/uid)">
      <xsl:value-of select="/cp/form/uid" />
    </xsl:when>
    <xsl:when test="string(/cp/vsap/vsap[@type='webmail:addressbook:load']/vCard/@uid)">
      <xsl:value-of select="/cp/vsap/vsap[@type='webmail:addressbook:load']/vCard/@uid" />
    </xsl:when>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="lastname">
  <xsl:choose>
    <xsl:when test="string(/cp/form/save_another) and not(string(/cp/vsap/vsap[@type='error']))"></xsl:when>
    <xsl:when test="string(/cp/form/txtLast)">
      <xsl:value-of select="/cp/form/txtLast" />
    </xsl:when>
    <xsl:when test="string(/cp/vsap/vsap[@type='webmail:addressbook:load']/vCard/Last_Name)">
      <xsl:value-of select="/cp/vsap/vsap[@type='webmail:addressbook:load']/vCard/Last_Name" />
    </xsl:when>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="firstname">
  <xsl:choose>
    <xsl:when test="string(/cp/form/save_another) and not(string(/cp/vsap/vsap[@type='error']))"></xsl:when>
    <xsl:when test="string(/cp/form/txtFirst)">
      <xsl:value-of select="/cp/form/txtFirst" />
    </xsl:when>
    <xsl:when test="string(/cp/vsap/vsap[@type='webmail:addressbook:load']/vCard/First_Name)">
      <xsl:value-of select="/cp/vsap/vsap[@type='webmail:addressbook:load']/vCard/First_Name" />
    </xsl:when>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="nickname">
  <xsl:choose>
    <xsl:when test="string(/cp/form/save_another) and not(string(/cp/vsap/vsap[@type='error']))"></xsl:when>
    <xsl:when test="string(/cp/form/txtNickname)">
      <xsl:value-of select="/cp/form/txtNickname" />
    </xsl:when>
    <xsl:when test="string(/cp/vsap/vsap[@type='webmail:addressbook:load']/vCard/Nickname)">
      <xsl:value-of select="/cp/vsap/vsap[@type='webmail:addressbook:load']/vCard/Nickname" />
    </xsl:when>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="emailaddress">
  <xsl:choose>
    <xsl:when test="string(/cp/form/save_another) and not(string(/cp/vsap/vsap[@type='error']))"></xsl:when>
    <xsl:when test="string(/cp/form/txtEmail)">
      <xsl:value-of select="/cp/form/txtEmail" />
    </xsl:when>
    <xsl:when test="string(/cp/vsap/vsap[@type='webmail:addressbook:load']/vCard/Email_Address)">
      <xsl:value-of select="/cp/vsap/vsap[@type='webmail:addressbook:load']/vCard/Email_Address" />
    </xsl:when>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="phonepersonal">
  <xsl:choose>
    <xsl:when test="string(/cp/form/save_another) and not(string(/cp/vsap/vsap[@type='error']))"></xsl:when>
    <xsl:when test="string(/cp/form/txtPhonePersonal)">
      <xsl:value-of select="/cp/form/txtPhonePersonal" />
    </xsl:when>
    <xsl:when test="string(/cp/vsap/vsap[@type='webmail:addressbook:load']/vCard/Phone_Personal)">
      <xsl:value-of select="/cp/vsap/vsap[@type='webmail:addressbook:load']/vCard/Phone_Personal" />
    </xsl:when>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="phonebusiness">
  <xsl:choose>
    <xsl:when test="string(/cp/form/save_another) and not(string(/cp/vsap/vsap[@type='error']))"></xsl:when>
    <xsl:when test="string(/cp/form/txtPhoneBusiness)">
      <xsl:value-of select="/cp/form/txtphoneBusiness" />
    </xsl:when>
    <xsl:when test="string(/cp/vsap/vsap[@type='webmail:addressbook:load']/vCard/Phone_Business)">
      <xsl:value-of select="/cp/vsap/vsap[@type='webmail:addressbook:load']/vCard/Phone_Business" />
    </xsl:when>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="phonemobile">
  <xsl:choose>
    <xsl:when test="string(/cp/form/save_another) and not(string(/cp/vsap/vsap[@type='error']))"></xsl:when>
    <xsl:when test="string(/cp/form/txtPhoneMobile)">
      <xsl:value-of select="/cp/form/txtPhoneMobile" />
    </xsl:when>
    <xsl:when test="string(/cp/vsap/vsap[@type='webmail:addressbook:load']/vCard/Phone_Mobile)">
      <xsl:value-of select="/cp/vsap/vsap[@type='webmail:addressbook:load']/vCard/Phone_Mobile" />
    </xsl:when>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="phonepager">
  <xsl:choose>
    <xsl:when test="string(/cp/form/save_another) and not(string(/cp/vsap/vsap[@type='error']))"></xsl:when>
    <xsl:when test="string(/cp/form/txtPhonePager)">
      <xsl:value-of select="/cp/form/txtPhonePager" />
    </xsl:when>
    <xsl:when test="string(/cp/vsap/vsap[@type='webmail:addressbook:load']/vCard/Phone_Pager)">
      <xsl:value-of select="/cp/vsap/vsap[@type='webmail:addressbook:load']/vCard/Phone_Pager" />
    </xsl:when>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="phoneother">
  <xsl:choose>
    <xsl:when test="string(/cp/form/save_another) and not(string(/cp/vsap/vsap[@type='error']))"></xsl:when>
    <xsl:when test="string(/cp/form/txtPhoneOther)">
      <xsl:value-of select="/cp/form/txtPhoneOther" />
    </xsl:when>
    <xsl:when test="string(/cp/vsap/vsap[@type='webmail:addressbook:load']/vCard/Phone_Other)">
      <xsl:value-of select="/cp/vsap/vsap[@type='webmail:addressbook:load']/vCard/Phone_Other" />
    </xsl:when>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="homestreetaddress">
  <xsl:choose>
    <xsl:when test="string(/cp/form/save_another) and not(string(/cp/vsap/vsap[@type='error']))"></xsl:when>
    <xsl:when test="string(/cp/form/txtAddress)">
      <xsl:value-of select="/cp/form/txtAddress" />
    </xsl:when>
    <xsl:when test="string(/cp/vsap/vsap[@type='webmail:addressbook:load']/vCard/Home_Street_Address)">
      <xsl:value-of select="/cp/vsap/vsap[@type='webmail:addressbook:load']/vCard/Home_Street_Address" />
    </xsl:when>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="homecity">
  <xsl:choose>
    <xsl:when test="string(/cp/form/save_another) and not(string(/cp/vsap/vsap[@type='error']))"></xsl:when>
    <xsl:when test="string(/cp/form/txtCity)">
      <xsl:value-of select="/cp/form/txtCity" />
    </xsl:when>
    <xsl:when test="string(/cp/vsap/vsap[@type='webmail:addressbook:load']/vCard/Home_City)">
      <xsl:value-of select="/cp/vsap/vsap[@type='webmail:addressbook:load']/vCard/Home_City" />
    </xsl:when>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="homestate">
  <xsl:choose>
    <xsl:when test="string(/cp/form/save_another) and not(string(/cp/vsap/vsap[@type='error']))"></xsl:when>
    <xsl:when test="string(/cp/form/txtState)">
      <xsl:value-of select="/cp/form/txtState" />
    </xsl:when>
    <xsl:when test="string(/cp/vsap/vsap[@type='webmail:addressbook:load']/vCard/Home_State)">
      <xsl:value-of select="/cp/vsap/vsap[@type='webmail:addressbook:load']/vCard/Home_State" />
    </xsl:when>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="homecountry">
  <xsl:choose>
    <xsl:when test="string(/cp/form/save_another) and not(string(/cp/vsap/vsap[@type='error']))"></xsl:when>
    <xsl:when test="string(/cp/form/txtCountry)">
      <xsl:value-of select="/cp/form/txtCountry" />
    </xsl:when>
    <xsl:when test="string(/cp/vsap/vsap[@type='webmail:addressbook:load']/vCard/Home_Country)">
      <xsl:value-of select="/cp/vsap/vsap[@type='webmail:addressbook:load']/vCard/Home_Country" />
    </xsl:when>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="homepostalcode">
  <xsl:choose>
    <xsl:when test="string(/cp/form/save_another) and not(string(/cp/vsap/vsap[@type='error']))"></xsl:when>
    <xsl:when test="string(/cp/form/txtPostalCode)">
      <xsl:value-of select="/cp/form/txtPostalCode" />
    </xsl:when>
    <xsl:when test="string(/cp/vsap/vsap[@type='webmail:addressbook:load']/vCard/Home_Postal_Code)">
      <xsl:value-of select="/cp/vsap/vsap[@type='webmail:addressbook:load']/vCard/Home_Postal_Code" />
    </xsl:when>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="company">
  <xsl:choose>
    <xsl:when test="string(/cp/form/save_another) and not(string(/cp/vsap/vsap[@type='error']))"></xsl:when>
    <xsl:when test="string(/cp/form/txtCompany)">
      <xsl:value-of select="/cp/form/txtCompany" />
    </xsl:when>
    <xsl:when test="string(/cp/vsap/vsap[@type='webmail:addressbook:load']/vCard/Company_Name)">
      <xsl:value-of select="/cp/vsap/vsap[@type='webmail:addressbook:load']/vCard/Company_Name" />
    </xsl:when>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="companystreetaddress">
  <xsl:choose>
    <xsl:when test="string(/cp/form/save_another) and not(string(/cp/vsap/vsap[@type='error']))"></xsl:when>
    <xsl:when test="string(/cp/form/txtCompanyAddress)">
      <xsl:value-of select="/cp/form/txtCompanyAddress" />
    </xsl:when>
    <xsl:when test="string(/cp/vsap/vsap[@type='webmail:addressbook:load']/vCard/Co_Street_Address)">
      <xsl:value-of select="/cp/vsap/vsap[@type='webmail:addressbook:load']/vCard/Co_Street_Address" />
    </xsl:when>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="companycity">
  <xsl:choose>
    <xsl:when test="string(/cp/form/save_another) and not(string(/cp/vsap/vsap[@type='error']))"></xsl:when>
    <xsl:when test="string(/cp/form/txtCompanyCity)">
      <xsl:value-of select="/cp/form/txtCompanyCity" />
    </xsl:when>
    <xsl:when test="string(/cp/vsap/vsap[@type='webmail:addressbook:load']/vCard/Co_City)">
      <xsl:value-of select="/cp/vsap/vsap[@type='webmail:addressbook:load']/vCard/Co_City" />
    </xsl:when>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="companystate">
  <xsl:choose>
    <xsl:when test="string(/cp/form/save_another) and not(string(/cp/vsap/vsap[@type='error']))"></xsl:when>
    <xsl:when test="string(/cp/form/txtCompanyState)">
      <xsl:value-of select="/cp/form/txtCompanyState" />
    </xsl:when>
    <xsl:when test="string(/cp/vsap/vsap[@type='webmail:addressbook:load']/vCard/Co_State)">
      <xsl:value-of select="/cp/vsap/vsap[@type='webmail:addressbook:load']/vCard/Co_State" />
    </xsl:when>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="companycountry">
  <xsl:choose>
    <xsl:when test="string(/cp/form/save_another) and not(string(/cp/vsap/vsap[@type='error']))"></xsl:when>
    <xsl:when test="string(/cp/form/txtCompanyCountry)">
      <xsl:value-of select="/cp/form/txtCompanyCountry" />
    </xsl:when>
    <xsl:when test="string(/cp/vsap/vsap[@type='webmail:addressbook:load']/vCard/Co_Country)">
      <xsl:value-of select="/cp/vsap/vsap[@type='webmail:addressbook:load']/vCard/Co_Country" />
    </xsl:when>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="companypostalcode">
  <xsl:choose>
    <xsl:when test="string(/cp/form/save_another) and not(string(/cp/vsap/vsap[@type='error']))"></xsl:when>
    <xsl:when test="string(/cp/form/txtCompanyPostalCode)">
      <xsl:value-of select="/cp/form/txtCompanyPostalCode" />
    </xsl:when>
    <xsl:when test="string(/cp/vsap/vsap[@type='webmail:addressbook:load']/vCard/Co_Postal_Code)">
      <xsl:value-of select="/cp/vsap/vsap[@type='webmail:addressbook:load']/vCard/Co_Postal_Code" />
    </xsl:when>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="birthday">
  <xsl:choose>
    <xsl:when test="string(/cp/form/save_another) and not(string(/cp/vsap/vsap[@type='error']))"></xsl:when>
    <xsl:when test="string(/cp/form/txtBirthday)">
      <xsl:value-of select="/cp/form/txtBirthday" />
    </xsl:when>
    <xsl:when test="string(/cp/vsap/vsap[@type='webmail:addressbook:load']/vCard/Birthday)">
      <xsl:value-of select="/cp/vsap/vsap[@type='webmail:addressbook:load']/vCard/Birthday" />
    </xsl:when>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="website">
  <xsl:choose>
    <xsl:when test="string(/cp/form/save_another) and not(string(/cp/vsap/vsap[@type='error']))"></xsl:when>
    <xsl:when test="string(/cp/form/txtWebsite)">
      <xsl:value-of select="/cp/form/txtWebsite" />
    </xsl:when>
    <xsl:when test="string(/cp/vsap/vsap[@type='webmail:addressbook:load']/vCard/Website)">
      <xsl:value-of select="/cp/vsap/vsap[@type='webmail:addressbook:load']/vCard/Website" />
    </xsl:when>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="other">
  <xsl:choose>
    <xsl:when test="string(/cp/form/save_another) and not(string(/cp/vsap/vsap[@type='error']))"></xsl:when>
    <xsl:when test="string(/cp/form/txtOther)">
      <xsl:value-of select="/cp/form/txtOther" />
    </xsl:when>
    <xsl:when test="string(/cp/vsap/vsap[@type='webmail:addressbook:load']/vCard/Other)">
      <xsl:value-of select="/cp/vsap/vsap[@type='webmail:addressbook:load']/vCard/Other" />
    </xsl:when>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="comments">
  <xsl:choose>
    <xsl:when test="string(/cp/form/save_another) and not(string(/cp/vsap/vsap[@type='error']))"></xsl:when>
    <xsl:when test="string(/cp/form/txtComments)">
      <xsl:value-of select="/cp/form/txtComments" />
    </xsl:when>
    <xsl:when test="string(/cp/vsap/vsap[@type='webmail:addressbook:load']/vCard/Comments)">
      <xsl:value-of select="/cp/vsap/vsap[@type='webmail:addressbook:load']/vCard/Comments" />
    </xsl:when>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="subtitle">
  <xsl:choose>
    <xsl:when test="$edit='1'">
      <xsl:copy-of select="/cp/strings/bc_edit_contact" /> : 
      <xsl:copy-of select="concat($firstname, ' ', $lastname)"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:copy-of select="/cp/strings/bc_add_contact" />
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:template match="/">
  <xsl:call-template name="bodywrapper">
    <xsl:with-param name="title">
      <xsl:copy-of select="/cp/strings/wm_title" /> : <xsl:copy-of select="/cp/strings/nv_menu_addressbook" /> : <xsl:copy-of select="$subtitle" />
    </xsl:with-param>
    <xsl:with-param name="formaction">wm_addcontact.xsl</xsl:with-param>
    <xsl:with-param name="feedback" select="$message" />
    <xsl:with-param name="selected_navandcontent">
      <xsl:choose>
        <xsl:when test="$edit = '1'">
          <xsl:value-of select="/cp/strings/nv_addresses" />
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="/cp/strings/nv_add_contact" />
        </xsl:otherwise>
      </xsl:choose>
    </xsl:with-param>
    <xsl:with-param name="help_short" select="/cp/strings/wm_addcontact_hlp_short" />
    <xsl:with-param name="help_long" select="/cp/strings/wm_addcontact_hlp_long" />
    <xsl:with-param name="breadcrumb">
      <breadcrumb>
        <xsl:choose>
          <xsl:when test="$edit='1'">
            <section>
              <name><xsl:copy-of select="/cp/strings/bc_addresses" /></name>
              <url><xsl:value-of select="$base_url" />/mail/address_book/wm_addresses.xsl</url>
            </section>
            <section>
              <name><xsl:copy-of select="/cp/strings/bc_edit_contact" /></name>
              <url>#</url>
              <image>AddressBook</image>
            </section>
          </xsl:when>
          <xsl:otherwise>
            <section>
              <name><xsl:copy-of select="/cp/strings/bc_add_contact" /></name>
              <url>#</url>
              <image>AddressBook</image>
            </section>
          </xsl:otherwise>
        </xsl:choose>
      </breadcrumb>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="content">

      <script src="{concat($base_url, '/mail/address_book/address_book.js')}" language="JavaScript"></script>      
      <input type="hidden" name="edit" value="{$edit}" />
      <input type="hidden" name="uid" value="{$uid}" />
      <input type="hidden" name="save_contact" />
      <input type="hidden" name="save_another" />
      <table class="formview" border="0" cellspacing="0" cellpadding="0">
        <tr class="title">
          <td colspan="2">
            <xsl:choose>
              <xsl:when test="$edit = '1'">
                <xsl:copy-of select="/cp/strings/wm_editcontact_title" />
              </xsl:when>
              <xsl:otherwise>
                <xsl:copy-of select="/cp/strings/wm_addcontact_title" />
              </xsl:otherwise>
            </xsl:choose>
          </td>
        </tr>
        <tr class="instructionrow">
          <td colspan="2">
            <xsl:choose>
              <xsl:when test="$edit = '1'">
                <xsl:copy-of select="/cp/strings/wm_editcontact_instruction1" />
              </xsl:when>
              <xsl:otherwise>
                <xsl:copy-of select="/cp/strings/wm_addcontact_instruction1" />
              </xsl:otherwise>
            </xsl:choose>
            <br />
            <xsl:value-of select="/cp/strings/wm_addcontact_instruction2" /></td>
        </tr>
        <tr class="controlrow">
          <td colspan="2">
            <span class="floatright">
              <input type="submit" name="save" value="{/cp/strings/wm_addcontact_bt_save}" onClick="return verifyAddContact('save','{cp:js-escape(/cp/strings/wm_addcontact_alertNoEmailMsg)}','{cp:js-escape(/cp/strings/wm_addresses_alertFmtEmailAddrMsg)}')" />
              <xsl:if test="$edit != '1'">
                <input type="button" name="another" value="{/cp/strings/wm_addcontact_bt_savecreate}" onClick="verifyAddContact('another','{cp:js-escape(/cp/strings/wm_addcontact_alertNoEmailMsg)}','{cp:js-escape(/cp/strings/wm_addresses_alertFmtEmailAddrMsg)}')" />
              </xsl:if>
              <input type="submit" name="cancel" value="{/cp/strings/wm_addcontact_bt_cancel}" />
            </span>
          </td>
        </tr>
        <tr class="title">
          <td colspan="2"><xsl:value-of select="/cp/strings/wm_addcontact_basic" /></td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:value-of select="/cp/strings/wm_addcontact_lastname" /></td>
          <td class="contentwidth"><input type="text" name="txtLast" size="60" value="{$lastname}" /></td>
        </tr>
        <tr class="roweven">
          <td class="label"><xsl:value-of select="/cp/strings/wm_addcontact_firstname" /></td>
          <td class="contentwidth"><input type="text" name="txtFirst" size="60" value="{$firstname}" /></td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:value-of select="/cp/strings/wm_addcontact_nickname" /></td>
          <td class="contentwidth"><input type="text" name="txtNickname" size="60" value="{$nickname}" /></td>
        </tr>
        <tr class="roweven">
          <td class="label"><xsl:value-of select="/cp/strings/wm_addcontact_emailaddress" /></td>
          <td class="contentwidth"><input type="text" name="txtEmail" size="60" value="{$emailaddress}" /></td>
        </tr>
        <tr class="title">
          <td colspan="2"><xsl:value-of select="/cp/strings/wm_addcontact_phonenumbers" /></td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:value-of select="/cp/strings/wm_addcontact_personal" /></td>
          <td class="contentwidth"><input type="text" name="txtPhonePersonal" size="60" value="{$phonepersonal}"/></td>
        </tr>
        <tr class="roweven">
          <td class="label"><xsl:value-of select="/cp/strings/wm_addcontact_business" /></td>
          <td class="contentwidth"><input type="text" name="txtPhoneBusiness" size="60" value="{$phonebusiness}"/></td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:value-of select="/cp/strings/wm_addcontact_mobile" /></td>
          <td class="contentwidth"><input type="text" name="txtPhoneMobile" size="60" value="{$phonemobile}"/></td>
        </tr>
        <tr class="roweven">
          <td class="label"><xsl:value-of select="/cp/strings/wm_addcontact_pager" /></td>
          <td class="contentwidth"><input type="text" name="txtPhonePager" size="60" value="{$phonepager}"/></td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:value-of select="/cp/strings/wm_addcontact_other" /></td>
          <td class="contentwidth"><input type="text" name="txtPhoneOther" size="60" value="{$phoneother}"/></td>
        </tr>
        <tr class="title">
          <td colspan="2"><xsl:value-of select="/cp/strings/wm_addcontact_personalcontactinfo" /></td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:value-of select="/cp/strings/wm_addcontact_personalstreet" /></td>
          <td class="contentwidth"><input type="text" name="txtAddress" size="60" value="{$homestreetaddress}"/></td>
        </tr>
        <tr class="roweven">
          <td class="label"><xsl:value-of select="/cp/strings/wm_addcontact_personalcity" /></td>
          <td class="contentwidth"><input type="text" name="txtCity" size="60" value="{$homecity}"/></td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:value-of select="/cp/strings/wm_addcontact_personalstate" /></td>
          <td class="contentwidth"><input type="text" name="txtState" size="60" value="{$homestate}"/></td>
        </tr>
        <tr class="roweven">
          <td class="label"><xsl:value-of select="/cp/strings/wm_addcontact_personalcountry" /></td>
          <td class="contentwidth"><input type="text" name="txtCountry" size="60" value="{$homecountry}"/></td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:value-of select="/cp/strings/wm_addcontact_personalpostalcode" /></td>
          <td class="contentwidth"><input type="text" name="txtPostalCode" size="60" value="{$homepostalcode}"/></td>
        </tr>
        <tr class="title">
          <td colspan="2"><xsl:value-of select="/cp/strings/wm_addcontact_businesscontactinfo" /></td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:value-of select="/cp/strings/wm_addcontact_company" /></td>
          <td class="contentwidth"><input type="text" name="txtCompany" size="60" value="{$company}"/></td>
        </tr>
        <tr class="roweven">
          <td class="label"><xsl:value-of select="/cp/strings/wm_addcontact_businessstreet" /></td>
          <td class="contentwidth"><input type="text" name="txtCompanyAddress" size="60" value="{$companystreetaddress}"/></td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:value-of select="/cp/strings/wm_addcontact_businesscity" /></td>
          <td class="contentwidth"><input type="text" name="txtCompanyCity" size="60" value="{$companycity}"/></td>
        </tr>
        <tr class="roweven">
          <td class="label"><xsl:value-of select="/cp/strings/wm_addcontact_businessstate" /></td>
          <td class="contentwidth"><input type="text" name="txtCompanyState" size="60" value="{$companystate}"/></td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:value-of select="/cp/strings/wm_addcontact_businesscountry" /></td>
          <td class="contentwidth"><input type="text" name="txtCompanyCountry" size="60" value="{$companycountry}"/></td>
        </tr>
        <tr class="roweven">
          <td class="label"><xsl:value-of select="/cp/strings/wm_addcontact_businesspostalcode" /></td>
          <td class="contentwidth"><input type="text" name="txtCompanyPostalCode" size="60" value="{$companypostalcode}"/></td>
        </tr>
        <tr class="title">
          <td colspan="2"><xsl:value-of select="/cp/strings/wm_addcontact_otherinfo" /></td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:value-of select="/cp/strings/wm_addcontact_otherbirthday" /></td>
          <td class="contentwidth"><input type="text" name="txtBirthday" size="60" value="{$birthday}"/></td>
        </tr>
        <tr class="roweven">
          <td class="label"><xsl:value-of select="/cp/strings/wm_addcontact_otherwebsite" /></td>
          <td class="contentwidth"><input type="text" name="txtWebsite" size="60" value="{$website}"/></td>
        </tr>
        <tr class="rowodd">
          <td class="label"><xsl:value-of select="/cp/strings/wm_addcontact_otherother" /></td>
          <td class="contentwidth"><input type="text" name="txtOther" size="60" value="{$other}"/></td>
        </tr>
        <tr class="roweven">
          <td class="label"><xsl:value-of select="/cp/strings/wm_addcontact_othercomments" /></td>
          <td class="contentwidth"><textarea name="txtComment" rows="5" cols="45"><xsl:value-of select="$comments" /></textarea></td>
        </tr>
        <tr class="controlrow">
          <td colspan="2">
            <span class="floatright">
              <input type="submit" name="save" value="{/cp/strings/wm_addcontact_bt_save}" onClick="return verifyAddContact('save','{cp:js-escape(/cp/strings/wm_addcontact_alertNoEmailMsg)}'),'{cp:js-escape(/cp/strings/wm_addresses_alertFmtEmailAddrMsg)}'" />
              <xsl:if test="$edit != '1'">
                <input type="button" name="another" value="{/cp/strings/wm_addcontact_bt_savecreate}" onClick="verifyAddContact('another','{cp:js-escape(/cp/strings/wm_addcontact_alertNoEmailMsg)}','{cp:js-escape(/cp/strings/wm_addresses_alertFmtEmailAddrMsg)}')" />
              </xsl:if>
              <input type="submit" name="cancel" value="{/cp/strings/wm_addcontact_bt_cancel}" />
            </span>
          </td>
        </tr>
      </table>

</xsl:template>
</xsl:stylesheet>
