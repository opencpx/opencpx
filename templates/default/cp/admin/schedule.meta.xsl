<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
 <xsl:import href="../../global.meta.xsl"/>
 <xsl:import href="../cp_global.meta.xsl"/>
 <xsl:template match="/">
  <meta>

    <xsl:if test="string(/cp/form/newtask)">
      <redirect>
        <path>cp/admin/schededit.xsl</path>
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

            <xsl:when test="string(/cp/form/set_mailto)">
              <xsl:choose>
                <xsl:when test="string(/cp/form/taskOptions) = 'user'">
                  <vsap type="sys:crontab:env:remove">
                    <name>MAILTO</name>
                  </vsap>
                </xsl:when>

                <xsl:when test="string(/cp/form/taskOptions) = 'other'">
                  <vsap type="sys:crontab:env">
                    <env>
                      <name>MAILTO</name>
                      <value><xsl:value-of select="/cp/form/txtMailTo"/></value>
                    </env>
                  </vsap>
                </xsl:when>

                <xsl:when test="string(/cp/form/taskOptions) = 'discard'">
                  <vsap type="sys:crontab:env">
                    <env>
                      <name>MAILTO</name>
                      <value>""</value>
                    </env>
                  </vsap>
                </xsl:when>
              </xsl:choose>
            </xsl:when>

            <xsl:when test="/cp/form/action='save_desc'">
              <vsap type="sys:crontab:add">
                <block id="{/cp/form/block}">
                  <comment><xsl:value-of select="/cp/form/description"/></comment>
                </block>
              </vsap>
            </xsl:when>

            <xsl:when test="/cp/form/action='delete_desc'">
              <vsap type="sys:crontab:add">
                <block id="{/cp/form/block}">
                  <comment/>
                </block>
              </vsap>
            </xsl:when>

            <xsl:when test="/cp/form/action='enable_event'">
              <vsap type="sys:crontab:enable">
                <block id="{/cp/form/block}">
                  <event id="{/cp/form/event}"/>
                </block>
              </vsap>
            </xsl:when>
 
            <xsl:when test="/cp/form/action='disable_event'">
              <vsap type="sys:crontab:disable">
                <block id="{/cp/form/block}">
                  <event id="{/cp/form/event}"/>
                </block>
              </vsap>
            </xsl:when>

            <xsl:when test="/cp/form/action='delete_event'">
              <vsap type="sys:crontab:delete">
                <block id="{/cp/form/block}">
                  <event id="{/cp/form/event}"/>
                </block>
              </vsap>
            </xsl:when>

            <xsl:when test="/cp/form/action='group_enable'">
              <vsap type="sys:crontab:enable">
                <xsl:for-each select="/cp/form/chk_event">
                  <block id="{substring-before(., '-')}">
                    <event id="{substring-after(., '-')}"/>
                  </block>
                </xsl:for-each>
              </vsap>
            </xsl:when>

            <xsl:when test="/cp/form/action='group_disable'">
              <vsap type="sys:crontab:disable">
                <xsl:for-each select="/cp/form/chk_event">
                  <block id="{substring-before(., '-')}">
                    <event id="{substring-after(., '-')}"/>
                  </block>
                </xsl:for-each>
              </vsap>
            </xsl:when>

            <xsl:when test="/cp/form/action='group_delete'">
              <vsap type="sys:crontab:delete">
                <xsl:for-each select="/cp/form/chk_event">
                  <block id="{substring-before(., '-')}">
                    <event id="{substring-after(., '-')}"/>
                  </block>
                </xsl:for-each>
              </vsap>
            </xsl:when>

          </xsl:choose>
          <vsap type="sys:crontab:list"/>

          <xsl:if test="count(/cp/vsap/vsap[@type='sys:crontab:list']/block[count(event)=0 and count(env)=0]) != 0">
            <vsap type="sys:crontab:delete">
              <xsl:for-each select="/cp/vsap/vsap[@type='sys:crontab:list']/block[count(event)=0 and count(env)=0]">
                <block id="{@id}"/>
              </xsl:for-each>
            </vsap>
          </xsl:if>
           
        </vsap>
      </xsl:with-param>
    </xsl:call-template>



    <xsl:choose>
      <xsl:when test="/cp/form/action='enable_event'">
        <xsl:choose>
          <xsl:when test="/cp/vsap/vsap[@type='sys:crontab:enable']/status='ok'">
            <xsl:call-template name="set_message">
              <xsl:with-param name="name" select="'task_enable_successful'"/>
              <xsl:with-param name="value" select="'ok'"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="set_message">
              <xsl:with-param name="name" select="'task_enable_failure'"/>
              <xsl:with-param name="value" select="'error'"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>

      <xsl:when test="/cp/form/action='disable_event'">
        <xsl:choose>
          <xsl:when test="/cp/vsap/vsap[@type='sys:crontab:enable']/status='ok'">
            <xsl:call-template name="set_message">
              <xsl:with-param name="name" select="'task_disable_successful'"/>
              <xsl:with-param name="value" select="'ok'"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="set_message">
              <xsl:with-param name="name" select="'task_disable_failure'"/>
              <xsl:with-param name="value" select="'error'"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>

      <xsl:when test="/cp/form/action='delete_event'">
        <xsl:choose>
          <xsl:when test="/cp/vsap/vsap[@type='sys:crontab:delete']/status='ok'">
            <xsl:call-template name="set_message">
              <xsl:with-param name="name" select="'task_delete_successful'"/>
              <xsl:with-param name="value" select="'ok'"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="set_message">
              <xsl:with-param name="name" select="'task_delete_failure'"/>
              <xsl:with-param name="value" select="'error'"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>

      <xsl:when test="/cp/form/action='group_enable'">
        <xsl:choose>
          <xsl:when test="/cp/vsap/vsap[@type='sys:crontab:enable']/status='ok'">
            <xsl:call-template name="set_message">
              <xsl:with-param name="name" select="'task_group_enable_successful'"/>
              <xsl:with-param name="value" select="'ok'"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="set_message">
              <xsl:with-param name="name" select="'task_group_enable_failure'"/>
              <xsl:with-param name="value" select="'error'"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>

      <xsl:when test="/cp/form/action='group_disable'">
        <xsl:choose>
          <xsl:when test="/cp/vsap/vsap[@type='sys:crontab:enable']/status='ok'">
            <xsl:call-template name="set_message">
              <xsl:with-param name="name" select="'task_group_disable_successful'"/>
              <xsl:with-param name="value" select="'ok'"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="set_message">
              <xsl:with-param name="name" select="'task_group_disable_failure'"/>
              <xsl:with-param name="value" select="'error'"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>

      <xsl:when test="/cp/form/action='group_delete'">
        <xsl:choose>
          <xsl:when test="/cp/vsap/vsap[@type='sys:crontab:delete']/status='ok'">
            <xsl:call-template name="set_message">
              <xsl:with-param name="name" select="'task_group_delete_successful'"/>
              <xsl:with-param name="value" select="'ok'"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="set_message">
              <xsl:with-param name="name" select="'task_group_delete_failure'"/>
              <xsl:with-param name="value" select="'error'"/>
            </xsl:call-template>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>

      <xsl:when test="/cp/form/action='mailto_event'">
        <xsl:if test="/cp/vsap/vsap[@type='sys:crontab:env']/set_status='success' or 
                      /cp/vsap/vsap[@type='sys:crontab:env:remove']/set_status='success'">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name" select="'task_mailto_change_successful'"/>
            <xsl:with-param name="value" select="'ok'"/>
          </xsl:call-template>
        </xsl:if>
        <xsl:if test="string(/cp/vsap/vsap[@type='error'])">
          <xsl:choose>
            <xsl:when test="/cp/vsap/vsap[@type='error'][@caller='sys:crontab:env']/code = 107">
              <xsl:call-template name="set_message">
                <xsl:with-param name="name" select="'task_mailto_change_failure'" />
                <xsl:with-param name="value" select="'error'" />
              </xsl:call-template>
            </xsl:when>
          </xsl:choose>
        </xsl:if>
      </xsl:when>

      <xsl:when test="string(/cp/form/btn_save)">
        <!-- From schededit page, no need to test for errors, if edit/create fails the edit page handles the error -->
        <xsl:call-template name="set_message">
          <xsl:with-param name="name" select="'task_save_successful'"/>
          <xsl:with-param name="value" select="'ok'"/>
        </xsl:call-template>
      </xsl:when>

      <xsl:otherwise>
        <xsl:if test="string(/cp/vsap/vsap[@type='error'])">
          <xsl:call-template name="set_message">
            <xsl:with-param name="name" select="'task_list_error'" />
            <xsl:with-param name="value" select="'error'" />
          </xsl:call-template>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>


    <showpage/>

  </meta>
 </xsl:template>
</xsl:stylesheet>
