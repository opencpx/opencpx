<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
 <xsl:import href="../../global.meta.xsl"/>
 <xsl:import href="../cp_global.meta.xsl"/>
 <xsl:template match="/">
  <meta>

    <xsl:if test="string(/cp/form/btn_cancel)">
      <redirect>
        <path>cp/admin/schedule.xsl</path>
      </redirect>
    </xsl:if>

    <xsl:call-template name="auth">
      <xsl:with-param name="require_class">sa</xsl:with-param>
    </xsl:call-template>

   <xsl:call-template name="cp_global"/>

    <xsl:call-template name="dovsap">
      <xsl:with-param name="vsap">
        <vsap>
          <xsl:choose>
            <xsl:when test="string(/cp/form/block) and string(/cp/form/event)">
              <!-- EDIT -->
              <xsl:if test="string(/cp/form/btn_save) or string(/cp/form/btn_save_new)">
                <vsap type="sys:crontab:add">
                  <block id="{/cp/form/block}">
                    <event id="{/cp/form/event}">
                      <schedule>
                        <xsl:choose>
                          <xsl:when test="/cp/form/time='standard'">
                            <minute><xsl:call-template name="csv"><xsl:with-param name="values" select="/cp/form/minute"/></xsl:call-template></minute>
                            <hour><xsl:call-template name="csv"><xsl:with-param name="values" select="/cp/form/hour"/></xsl:call-template></hour>
                            <dom><xsl:call-template name="csv"><xsl:with-param name="values" select="/cp/form/dayofmonth"/></xsl:call-template></dom>
                            <month><xsl:call-template name="csv"><xsl:with-param name="values" select="/cp/form/month"/></xsl:call-template></month>
                            <dow><xsl:call-template name="csv"><xsl:with-param name="values" select="/cp/form/dayofweek"/></xsl:call-template></dow>
                          </xsl:when>
                          <xsl:otherwise>
                            <special><xsl:call-template name="csv"><xsl:with-param name="values" select="/cp/form/special"/></xsl:call-template></special>
                          </xsl:otherwise>
                        </xsl:choose>
                      </schedule>
                      <user><xsl:value-of select="/cp/form/userid"/></user>
                      <command><xsl:value-of select="/cp/form/croncommand"/></command>
                    </event>
                  </block>
                </vsap>
              </xsl:if>
            </xsl:when>
            <xsl:otherwise>
              <!-- ADD -->
              <xsl:if test="string(/cp/form/btn_save) or string(/cp/form/btn_save_new)">
                <vsap type="sys:crontab:add">
                  <block>
                    <xsl:choose>
                      <xsl:when test="/cp/form/desc='new'">
                        <comment><xsl:value-of select="/cp/form/newblockdesc"/></comment>
                       </xsl:when>
                       <xsl:otherwise>
                         <xsl:attribute name="id"><xsl:value-of select="/cp/form/lst_blocks"/></xsl:attribute>
                       </xsl:otherwise>
                    </xsl:choose>
                    <event>
                      <schedule>
                        <xsl:choose>
                          <xsl:when test="/cp/form/time='standard'">
                            <minute><xsl:call-template name="csv"><xsl:with-param name="values" select="/cp/form/minute"/></xsl:call-template></minute>
                            <hour><xsl:call-template name="csv"><xsl:with-param name="values" select="/cp/form/hour"/></xsl:call-template></hour>
                            <dom><xsl:call-template name="csv"><xsl:with-param name="values" select="/cp/form/dayofmonth"/></xsl:call-template></dom>
                            <month><xsl:call-template name="csv"><xsl:with-param name="values" select="/cp/form/month"/></xsl:call-template></month>
                            <dow><xsl:call-template name="csv"><xsl:with-param name="values" select="/cp/form/dayofweek"/></xsl:call-template></dow>
                          </xsl:when>
                          <xsl:otherwise>
                            <special><xsl:call-template name="csv"><xsl:with-param name="values" select="/cp/form/special"/></xsl:call-template></special>
                          </xsl:otherwise>
                        </xsl:choose>
                      </schedule>
                      <user><xsl:value-of select="/cp/form/userid"/></user>
                      <command><xsl:value-of select="/cp/form/croncommand"/></command>
                    </event>
                  </block>
                </vsap>
              </xsl:if>
            </xsl:otherwise>
          </xsl:choose>
        </vsap>
      </xsl:with-param>
    </xsl:call-template>

    <xsl:choose>
      <xsl:when test="string(/cp/vsap/vsap[@type='error']) and (string(cp/form/btn_save) or string(cp/form/btn_save_new)) ">
        <!-- Save/Create Error -->
        <xsl:call-template name="set_message">
          <xsl:with-param name="name" select="'task_save_failure'" />
          <xsl:with-param name="value" select="'error'" />
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="string(/cp/vsap/vsap[@type='error'])">
        <!-- Read Error -->
        <xsl:call-template name="set_message">
          <xsl:with-param name="name" select="'task_details_error'" />
          <xsl:with-param name="value" select="'error'" />
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="string(/cp/form/btn_save)">
        <redirect>
          <path>cp/admin/schedule.xsl</path>
        </redirect>
      </xsl:when>
      <xsl:when test="string(/cp/form/btn_save_new)">
        <!-- Save OK -->
        <xsl:call-template name="set_message">
          <xsl:with-param name="name" select="'task_save_successful'" />
          <xsl:with-param name="value" select="'ok'" />
        </xsl:call-template>
      </xsl:when>
    </xsl:choose>

    <xsl:call-template name="dovsap">
      <xsl:with-param name="vsap">
        <vsap>
          <vsap type="user:list:system">
            <no_system_users/>
          </vsap>
          <xsl:choose>
            <xsl:when test="string(/cp/form/block) and string(/cp/form/event) and not(string(/cp/form/btn_save_new))">
              <!-- EDIT -->
              <vsap type="sys:crontab:list">
                <block id="{/cp/form/block}"/>
              </vsap>
            </xsl:when>
            <xsl:otherwise>
              <!-- ADD -->
              <vsap type="sys:crontab:list"/>
            </xsl:otherwise>
          </xsl:choose>
        </vsap>
      </xsl:with-param>
    </xsl:call-template>

    <showpage/>

  </meta>
 </xsl:template>

 <xsl:template name="csv">
   <xsl:param name="values"/>
   <xsl:if test="count($values/.)=0">*</xsl:if>
   <xsl:for-each select="$values/.">
     <xsl:value-of select="."/><xsl:if test="position() != last()">,</xsl:if>
   </xsl:for-each>
 </xsl:template>

</xsl:stylesheet>
