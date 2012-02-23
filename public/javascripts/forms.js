function formGetElementById(objectId)
{
    // cross-browser function to get an object's style object given its id
    if(document.getElementById && document.getElementById(objectId)) {
        // W3C DOM
        return document.getElementById(objectId);
    } else if (document.all && document.all(objectId)) {
        // MSIE 4 DOM
        return document.all(objectId);
    } else if (document.layers && document.layers[objectId]) {
        // NN 4 DOM.. note: this won't find nested layers
        return document.layers[objectId];
    } else {
        return false;
    }
}

function formUpdate(formid)
{
  if (formid == "foid_ldap_options")
  {
    formUpdateLdapOptions();
  }
  /*
  else if  (formid == "foid_ldap_group_dn")
  {
    formUpdateLdapGroupDn();
  }
  */
}


function formFieldAddClass(id, classname)
{
  if (id.className)
  {
    class_arr = id.className.split(" ");
    class_arr.push(classname);
    classname = class_arr.join(" ");
  }
  id.className = classname;
}

function formFieldRemClass(id, classname)
{
  if (id.className)
  {
    class_arr = id.className.split(" ");
    new_class_arr = new Array();
    
    for (j = 0 ; j < class_arr.length ; j++ )     
    {
        if ( class_arr[j] != classname )
        {
           new_class_arr.push(class_arr[j]);
        }
    }

    id.className = new_class_arr.join(" ");
  }
}


function formUpdateLdapOptions()
{
  if (
    (sasl = formGetElementById("fid_ldap_options_ldap_use_sasl"))
    && (sys_dn = formGetElementById("fid_ldap_options_ldap_sys_dn"))
    && (sys_username = formGetElementById("fid_ldap_options_ldap_sys_username"))
    && (domain_search = formGetElementById("fid_ldap_options_ldap_domain_search"))
    && (ldap_domain = formGetElementById("fid_ldap_options_ldap_domain"))
    && (ldap_host = formGetElementById("fid_ldap_options_ldap_host"))

    )
  {
    if (domain_search.checked)
    {
      // needed - 2007-12-20
      //ldap_domain.disabled = false;
      //formFieldRemClass(ldap_domain, "disabled");
      ldap_host.disabled = true;
      formFieldAddClass(ldap_host, "disabled");
    }
    else
    {
      // needed - 2007-12-20
      //ldap_domain.disabled = true;
      //formFieldAddClass(ldap_domain, "disabled");
      ldap_host.disabled = false;
      formFieldRemClass(ldap_host, "disabled");
    }
  }
}

function ldapGroupDnRenameUpdate()
{
  if ((sel = formGetElementById("fid_ldap_group_dn_list_group_dn")) &&
      (rename = formGetElementById("fid_ldap_group_dn_group_dn_rename")))
  {
    rename.value = sel.options[sel.selectedIndex].innerHTML;
    rename.disabled = false;
  }
}

function userSecEmailRenameUpdate()
{
  if ((sel = formGetElementById("fid_sec_emails_list_sec_email")) &&
      (rename = formGetElementById("fid_sec_emails_sec_email_rename")))
  {
    rename.value = sel.options[sel.selectedIndex].innerHTML;
    rename.disabled = false;
  }
}



