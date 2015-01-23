<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:import href="../../global.meta.xsl" />
<xsl:template match="/">
<meta>

<!-- run auth code -->
<xsl:call-template name="auth">
  <xsl:with-param name="require_mail">1</xsl:with-param>
  <xsl:with-param name="require_webmail">1</xsl:with-param>
</xsl:call-template>

<xsl:call-template name="dovsap">
  <xsl:with-param name="vsap">
    <vsap>
      <xsl:choose>
        <xsl:when test="string(/cp/form/save_contact) or string(/cp/form/save_another)">
          <vsap type="webmail:addressbook:add">
              <xsl:if test="string(/cp/form/edit)">
                <edit />
	        <uid><xsl:value-of select="/cp/form/uid"/></uid>
              </xsl:if>
              <xsl:if test="string(/cp/form/txtLast)">
                <Last_Name><xsl:value-of select="/cp/form/txtLast" /></Last_Name>
              </xsl:if>
              <xsl:if test="string(/cp/form/txtFirst)">
                <First_Name><xsl:value-of select="/cp/form/txtFirst" /></First_Name>
              </xsl:if>
              <xsl:if test="string(/cp/form/txtNickname)">
                <Nickname><xsl:value-of select="/cp/form/txtNickname" /></Nickname>
              </xsl:if>
              <xsl:if test="string(/cp/form/txtEmail)">
                <Email_Address><xsl:value-of select="/cp/form/txtEmail" /></Email_Address>
              </xsl:if>
              <xsl:if test="string(/cp/form/txtPhonePersonal)">
                <Phone_Personal><xsl:value-of select="/cp/form/txtPhonePersonal" /></Phone_Personal>
              </xsl:if>
              <xsl:if test="string(/cp/form/txtPhoneBusiness)">
                <Phone_Business><xsl:value-of select="/cp/form/txtPhoneBusiness" /></Phone_Business>
              </xsl:if>
              <xsl:if test="string(/cp/form/txtPhoneMobile)">
                <Phone_Mobile><xsl:value-of select="/cp/form/txtPhoneMobile" /></Phone_Mobile>
              </xsl:if>
              <xsl:if test="string(/cp/form/txtPhonePager)">
                <Phone_Pager><xsl:value-of select="/cp/form/txtPhonePager" /></Phone_Pager>
              </xsl:if>
              <xsl:if test="string(/cp/form/txtPhoneOther)">
                <Phone_Other><xsl:value-of select="/cp/form/txtPhoneOther" /></Phone_Other>
              </xsl:if>
              <xsl:if test="string(/cp/form/txtAddress)">
                <Home_Street_Address><xsl:value-of select="/cp/form/txtAddress" /></Home_Street_Address>
              </xsl:if>
              <xsl:if test="string(/cp/form/txtCity)">
                <Home_City><xsl:value-of select="/cp/form/txtCity" /></Home_City>
              </xsl:if>
              <xsl:if test="string(/cp/form/txtState)">
                <Home_State><xsl:value-of select="/cp/form/txtState" /></Home_State>
              </xsl:if>
              <xsl:if test="string(/cp/form/txtCountry)">
                <Home_Country><xsl:value-of select="/cp/form/txtCountry" /></Home_Country>
              </xsl:if>
              <xsl:if test="string(/cp/form/txtPostalCode)">
                <Home_Postal_Code><xsl:value-of select="/cp/form/txtPostalCode" /></Home_Postal_Code>
              </xsl:if>
              <xsl:if test="string(/cp/form/txtCompany)">
                <Company_Name><xsl:value-of select="/cp/form/txtCompany" /></Company_Name>
              </xsl:if>
              <xsl:if test="string(/cp/form/txtCompanyAddress)">
                <Co_Street_Address><xsl:value-of select="/cp/form/txtCompanyAddress" /></Co_Street_Address>
              </xsl:if>
              <xsl:if test="string(/cp/form/txtCompanyCity)">
                <Co_City><xsl:value-of select="/cp/form/txtCompanyCity" /></Co_City>
              </xsl:if>
              <xsl:if test="string(/cp/form/txtCompanyState)">
                <Co_State><xsl:value-of select="/cp/form/txtCompanyState" /></Co_State>
              </xsl:if>
              <xsl:if test="string(/cp/form/txtCompanyCountry)">
                <Co_Country><xsl:value-of select="/cp/form/txtCompanyCountry" /></Co_Country>
              </xsl:if>
              <xsl:if test="string(/cp/form/txtCompanyPostalCode)">
                <Co_Postal_Code><xsl:value-of select="/cp/form/txtCompanyPostalCode" /></Co_Postal_Code>
              </xsl:if>
              <xsl:if test="string(/cp/form/txtBirthday)">
                <Birthday><xsl:value-of select="/cp/form/txtBirthday" /></Birthday>
              </xsl:if>
              <xsl:if test="string(/cp/form/txtWebsite)">
                <Website><xsl:value-of select="/cp/form/txtWebsite" /></Website>
              </xsl:if>
              <xsl:if test="string(/cp/form/txtOther)">
                <Other><xsl:value-of select="/cp/form/txtOther" /></Other>
              </xsl:if>
              <xsl:if test="string(/cp/form/txtComment)">
                <Comments><xsl:value-of select="/cp/form/txtComment" /></Comments>
              </xsl:if>
          </vsap>
        </xsl:when>
        <xsl:when test="string(/cp/form/to)">
          <vsap type="webmail:addressbook:load">
            <uid><xsl:value-of select="/cp/form/to" /></uid>
          </vsap>
        </xsl:when>
      </xsl:choose>
    </vsap>
  </xsl:with-param>
</xsl:call-template>

<xsl:choose>
  <xsl:when test="boolean(/cp/vsap/vsap[@type='error'])">
    <showpage />
  </xsl:when>
  <xsl:when test="string(/cp/form/save_contact) or string(/cp/form/cancel)">
    <redirect>
      <path>mail/address_book/wm_addresses.xsl</path>
    </redirect>
  </xsl:when>
  <xsl:otherwise>
    <showpage />
  </xsl:otherwise>
</xsl:choose>

</meta>
</xsl:template>
</xsl:stylesheet>
