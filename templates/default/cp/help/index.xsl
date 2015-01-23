<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:cp="vsap:cp" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
                xmlns:exslt="http://exslt.org/common">

<xsl:template match="/">

<xsl:variable name="user_type">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='auth']/server_admin">sa</xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='auth']/domain_admin">da</xsl:when>
    <xsl:when test="/cp/vsap/vsap[@type='auth']/mail_admin">ma</xsl:when>
    <xsl:otherwise>eu</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="has_filemanager">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='auth']/services/fileman">1</xsl:when>
    <xsl:otherwise>0</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="has_mail">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='auth']/services/mail">1</xsl:when>
    <xsl:otherwise>0</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="has_webmail">
  <xsl:choose>
    <xsl:when test="/cp/vsap/vsap[@type='auth']/services/webmail">1</xsl:when>
    <xsl:otherwise>0</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="help_path">/ControlPanelHelp/<xsl:value-of select="/cp/form/lang"/></xsl:variable>

<html>

<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
<title><xsl:value-of select="/cp/strings/h_cpxall_title"/></title>
</head>

<link href="/ControlPanelHelp/onlinehelp.css" type="text/css" rel="stylesheet"/>

<body>
<div id="workarea">

<p class='help-h1'>
<xsl:value-of select="/cp/strings/h_cpxall_toc"/>
</p>

<p class='help-h3'>
 <a href='{$help_path}/h_cpxall_cp_auto_logout.html'>
    <xsl:value-of select="/cp/strings/h_cpxall_cp_auto_logout"/></a>
</p>
<p class='help-h3'>
 <a href='{$help_path}/h_cpxall_cp_date_and_time_setup.html'>
    <xsl:value-of select="/cp/strings/h_cpxall_cp_date_and_time_setup"/></a>
</p>
<p class='help-h3'>
 <a href='{$help_path}/h_cpxall_cp_logging_in.html'>
    <xsl:value-of select="/cp/strings/h_cpxall_cp_logging_in"/></a>
</p>
<p class='help-h3'>
 <a href='{$help_path}/h_cpxall_cp_logging_out.html'>
    <xsl:value-of select="/cp/strings/h_cpxall_cp_logging_out"/></a>
</p>

<xsl:if test="$has_filemanager=1">
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxall_fm_change_permissions.html'>
      <xsl:value-of select="/cp/strings/h_cpxall_fm_change_permissions"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxall_fm_compressing_a_directory.htm'>
      <xsl:value-of select="/cp/strings/h_cpxall_fm_compressing_a_directory"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxall_fm_compressing_a_file.htm'>
      <xsl:value-of select="/cp/strings/h_cpxall_fm_compressing_a_file"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxall_fm_copying_a_directory.htm'>
      <xsl:value-of select="/cp/strings/h_cpxall_fm_copying_a_directory"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxall_fm_copying_a_file.htm'>
      <xsl:value-of select="/cp/strings/h_cpxall_fm_copying_a_file"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxall_fm_create_shortcut.htm'>
      <xsl:value-of select="/cp/strings/h_cpxall_fm_create_shortcut"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxall_fm_creating_a_directory.htm'>
      <xsl:value-of select="/cp/strings/h_cpxall_fm_creating_a_directory"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxall_fm_creating_a_file.htm'>
      <xsl:value-of select="/cp/strings/h_cpxall_fm_creating_a_file"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxall_fm_deleting_a_directory.htm'>
      <xsl:value-of select="/cp/strings/h_cpxall_fm_deleting_a_directory"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxall_fm_deleting_a_file.htm'>
      <xsl:value-of select="/cp/strings/h_cpxall_fm_deleting_a_file"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxall_fm_downloading_a_file.htm'>
      <xsl:value-of select="/cp/strings/h_cpxall_fm_downloading_a_file"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxall_fm_editing_a_file.htm'>
      <xsl:value-of select="/cp/strings/h_cpxall_fm_editing_a_file"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxall_fm_moving_a_file.htm'>
      <xsl:value-of select="/cp/strings/h_cpxall_fm_moving_a_file"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxall_fm_print_preview.htm'>
      <xsl:value-of select="/cp/strings/h_cpxall_fm_print_preview"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxall_fm_renaming_a_directory.htm'>
      <xsl:value-of select="/cp/strings/h_cpxall_fm_renaming_a_directory"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxall_fm_renaming_a_file.htm'>
      <xsl:value-of select="/cp/strings/h_cpxall_fm_renaming_a_file"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxall_fm_uploading_files.htm'>
      <xsl:value-of select="/cp/strings/h_cpxall_fm_uploading_files"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxall_fm_view_all_files.htm'>
      <xsl:value-of select="/cp/strings/h_cpxall_fm_view_all_files"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxall_fm_view_hidden_files.htm'>
      <xsl:value-of select="/cp/strings/h_cpxall_fm_view_hidden_files"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxall_fm_view_home_directory.htm'>
      <xsl:value-of select="/cp/strings/h_cpxall_fm_view_home_directory"/></a>
  </p>
</xsl:if>

<xsl:if test="$has_webmail=1">
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxall_wm_ab_add_contact.html'>
      <xsl:value-of select="/cp/strings/h_cpxall_wm_ab_add_contact"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxall_wm_ab_add_list.html'>
      <xsl:value-of select="/cp/strings/h_cpxall_wm_ab_add_list"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxall_wm_ab_addresses.html'>
      <xsl:value-of select="/cp/strings/h_cpxall_wm_ab_addresses"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxall_wm_ab_delete_contact.html'>
      <xsl:value-of select="/cp/strings/h_cpxall_wm_ab_delete_contact"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxall_wm_ab_edit_contact.html'>
      <xsl:value-of select="/cp/strings/h_cpxall_wm_ab_edit_contact"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxall_wm_ab_quick_add.html'>
      <xsl:value-of select="/cp/strings/h_cpxall_wm_ab_quick_add"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxall_wm_fm_folder_list.html'>
      <xsl:value-of select="/cp/strings/h_cpxall_wm_fm_folder_list"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxall_wm_mf_attach.htm'>
      <xsl:value-of select="/cp/strings/h_cpxall_wm_mf_attach"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxall_wm_mf_compose.htm'>
      <xsl:value-of select="/cp/strings/h_cpxall_wm_mf_compose"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxall_wm_mf_download_attach.htm'>
      <xsl:value-of select="/cp/strings/h_cpxall_wm_mf_download_attach"/></a>
  </p>
  <xsl:if test="/cp/form/lang='ja_JP'">
    <p class='help-h3'>
     <a href='{$help_path}/h_cpxall_wm_mf_japanese_encoding.htm'>
        <xsl:value-of select="/cp/strings/h_cpxall_wm_mf_japanese_encoding"/></a>
    </p>
  </xsl:if>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxall_wm_mf_messages.htm'>
      <xsl:value-of select="/cp/strings/h_cpxall_wm_mf_messages"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxall_wm_mf_remove_attach.htm'>
      <xsl:value-of select="/cp/strings/h_cpxall_wm_mf_remove_attach"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxall_wm_mf_sent_items.htm'>
      <xsl:value-of select="/cp/strings/h_cpxall_wm_mf_sent_items"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxall_wm_mf_view_attach.htm'>
      <xsl:value-of select="/cp/strings/h_cpxall_wm_mf_view_attach"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxall_wm_mfol_add_folder.html'>
      <xsl:value-of select="/cp/strings/h_cpxall_wm_mfol_add_folder"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxall_wm_mfol_drafts.html'>
      <xsl:value-of select="/cp/strings/h_cpxall_wm_mfol_drafts"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxall_wm_mfol_inbox.html'>
      <xsl:value-of select="/cp/strings/h_cpxall_wm_mfol_inbox"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxall_wm_mfol_junk.htm'>
      <xsl:value-of select="/cp/strings/h_cpxall_wm_mfol_junk"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxall_wm_mfol_quarantine.html'>
      <xsl:value-of select="/cp/strings/h_cpxall_wm_mfol_quarantine"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxall_wm_mfol_trash.htm'>
      <xsl:value-of select="/cp/strings/h_cpxall_wm_mfol_trash"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxall_wm_wo_message_display.html'>
      <xsl:value-of select="/cp/strings/h_cpxall_wm_wo_message_display"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxall_wm_wo_outgoing_mail.html'>
      <xsl:value-of select="/cp/strings/h_cpxall_wm_wo_outgoing_mail"/></a>
  </p>
</xsl:if>

<xsl:if test="$has_mail=1">
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxall_wm_mfil_spam_filtering.html'>
      <xsl:value-of select="/cp/strings/h_cpxall_wm_mfil_spam_filtering"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxall_wm_mfil_virus_scanning.html'>
      <xsl:value-of select="/cp/strings/h_cpxall_wm_mfil_virus_scanning"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxall_wm_mo_autoreply.html'>
      <xsl:value-of select="/cp/strings/h_cpxall_wm_mo_autoreply"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxall_wm_mo_mail_forward.html'>
      <xsl:value-of select="/cp/strings/h_cpxall_wm_mo_mail_forward"/></a>
  </p>
</xsl:if>

<xsl:if test="$user_type='sa'">
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxsa_dm_add_domain.html'>
      <xsl:value-of select="/cp/strings/h_cpxsa_dm_add_domain"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxsa_dm_delete_vhost_domain.htm'>
      <xsl:value-of select="/cp/strings/h_cpxsa_dm_delete_vhost_domain"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxsa_dm_disable_domain_admin.htm'>
      <xsl:value-of select="/cp/strings/h_cpxsa_dm_disable_domain_admin"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxsa_dm_edit_da_properties.htm'>
      <xsl:value-of select="/cp/strings/h_cpxsa_dm_edit_da_properties"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxsa_dm_edit_mail_catchall.htm'>
      <xsl:value-of select="/cp/strings/h_cpxsa_dm_edit_mail_catchall"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxsa_dm_enable_domain_admin.htm'>
      <xsl:value-of select="/cp/strings/h_cpxsa_dm_enable_domain_admin"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxsa_email_addresses.html'>
      <xsl:value-of select="/cp/strings/h_cpxsa_email_addresses"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxsa_mm_add_email_add.htm'>
      <xsl:value-of select="/cp/strings/h_cpxsa_mm_add_email_add"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxsa_pro_change_password.html'>
      <xsl:value-of select="/cp/strings/h_cpxsa_pro_change_password"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxsa_pro_view_profile.html'>
      <xsl:value-of select="/cp/strings/h_cpxsa_pro_view_profile"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxsa_um_add_domain_admin.html'>
      <xsl:value-of select="/cp/strings/h_cpxsa_um_add_domain_admin"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxsa_um_add_mail_admin.html'>
      <xsl:value-of select="/cp/strings/h_cpxsa_um_add_mail_admin"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxsa_um_add_end_user.html'>
      <xsl:value-of select="/cp/strings/h_cpxsa_um_add_end_user"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxsa_um_domain_list.html'>
      <xsl:value-of select="/cp/strings/h_cpxsa_um_domain_list"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxsa_um_edit_da_profile.html'>
      <xsl:value-of select="/cp/strings/h_cpxsa_um_edit_da_profile"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxsa_um_edit_domain.html'>
      <xsl:value-of select="/cp/strings/h_cpxsa_um_edit_domain"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxsa_um_edit_eu_profile.html'>
      <xsl:value-of select="/cp/strings/h_cpxsa_um_edit_eu_profile"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxsa_um_edit_mail_setup.html'>
      <xsl:value-of select="/cp/strings/h_cpxsa_um_edit_mail_setup"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxsa_um_edit_user_properties.html'>
      <xsl:value-of select="/cp/strings/h_cpxsa_um_edit_user_properties"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxsa_um_view_user_list.html'>
      <xsl:value-of select="/cp/strings/h_cpxsa_um_view_user_list"/></a>
  </p>
</xsl:if>

<xsl:if test="$user_type='da'">
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxda_dm_edit_domain_contact.htm'>
      <xsl:value-of select="/cp/strings/h_cpxda_dm_edit_domain_contact"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxda_dm_edit_mail_catchall.htm'>
      <xsl:value-of select="/cp/strings/h_cpxda_dm_edit_mail_catchall"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxda_dm_view_domain_disk_space.htm'>
      <xsl:value-of select="/cp/strings/h_cpxda_dm_view_domain_disk_space"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxda_email_addresses.html'>
      <xsl:value-of select="/cp/strings/h_cpxda_email_addresses"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxda_mm_add_email_add.htm'>
      <xsl:value-of select="/cp/strings/h_cpxda_mm_add_email_add"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxda_pro_change_password.html'>
      <xsl:value-of select="/cp/strings/h_cpxda_pro_change_password"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxda_pro_view_profile.html'>
      <xsl:value-of select="/cp/strings/h_cpxda_pro_view_profile"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxda_um_add_end_user.html'>
      <xsl:value-of select="/cp/strings/h_cpxda_um_add_end_user"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxda_um_domain_list.html'>
      <xsl:value-of select="/cp/strings/h_cpxda_um_domain_list"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxda_um_edit_domain.html'>
      <xsl:value-of select="/cp/strings/h_cpxda_um_edit_domain"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxda_um_edit_eu_profile.html'>
      <xsl:value-of select="/cp/strings/h_cpxda_um_edit_eu_profile"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxda_um_edit_mail_setup.html'>
      <xsl:value-of select="/cp/strings/h_cpxda_um_edit_mail_setup"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxda_um_edit_user_properties.html'>
      <xsl:value-of select="/cp/strings/h_cpxda_um_edit_user_properties"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxda_um_view_user_list.html'>
      <xsl:value-of select="/cp/strings/h_cpxda_um_view_user_list"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxda_understand_user_hierarchy.html'>
      <xsl:value-of select="/cp/strings/h_cpxda_understand_user_hierarchy"/></a>
  </p>
</xsl:if>

<xsl:if test="$user_type='eu'">
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxeu_pro_change_password.html'>
      <xsl:value-of select="/cp/strings/h_cpxeu_pro_change_password"/></a>
  </p>
  <p class='help-h3'>
   <a href='{$help_path}/h_cpxeu_pro_view_profile.html'>
      <xsl:value-of select="/cp/strings/h_cpxeu_pro_view_profile"/></a>
  </p>
</xsl:if>

</div>
</body>

</html>


</xsl:template>

</xsl:stylesheet>
