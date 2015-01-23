// Contains functions used in addressbook apps 

function verifyQuickAdd(emptyAlert,invalidAlert) {
	if(document.forms[0].txtEmail.value == '') {
		alert(emptyAlert);
		return false;
	}
	if(validate_email_addr(document.forms[0].txtEmail.value)) {
		alert(invalidAlert);
		return false;
	}
	document.forms[0].save_quickadd.value = 'yes';
	document.forms[0].submit();
	return true;
}

function verifyAddContact(type,emptyText,invalidAlert) {
	if(document.forms[0].txtEmail.value == '') {
		alert(emptyText);
		return false;
	}
	if(validate_email_addr(document.forms[0].txtEmail.value)) {
		alert(invalidAlert);
		return false;
	}
	if(type == 'save') {
		document.forms[0].save_contact.value = 'yes';
	}
	if(type == 'another') {
		document.forms[0].save_another.value = 'yes';
	}
	document.forms[0].submit();
	return false;
}

function verifyAddGroup(type,alertText) {
	if(document.forms[0].txtListName.value == '' || document.forms[0].ids.value == '') {
		alert(alertText);
		return false;
	} else {
		if(type == 'save') {               
			document.forms[0].save_group.value = 'yes';
		}
		if(type == 'another') {               
			document.forms[0].save_another.value = 'yes';
		}
	}
	document.forms[0].submit();
        return false;
}

function verifyImportFile(alertText) {
	if (document.forms[0].fileupload.value == '') {
		alert(alertText)
		return false;
	}
	return true;
}

// javascript distlist search routines

var saveOrigValue = new Array();
var saveOrigText = new Array();

function initDistListSearch(saveSelect) {
	var selectLength = saveSelect.options.length;
	for(var i=0; i < selectLength; i++) {
		saveOrigValue[i] = saveSelect.options[i].value;
		saveOrigText[i] = saveSelect.options[i].text;
	}
}

function restoreViewAll(box) {
	var selectLength = saveOrigValue.length;

	if(saveOrigValue.length == 0) {
		initDistListSearch(box);
	}


	var count = 0;
	for(var i=0; i < selectLength; i++) {
		var setOption = new Option();
	
		count++;	
		setOption.value = saveOrigValue[i];
		setOption.text = saveOrigText[i];
		box.options[i] = setOption;
		box.options.length = count;
	}
}
	
function searchEmailAddressbook(box,pattern,errmsg) {
	if(pattern.value == '') {
		alert(errmsg);
		return false;
	}

	if(box.options.length == 0) {
		return false;
	}
	
	if(saveOrigValue.length == 0) {
		initDistListSearch(box);
	}	

	var selectLength = saveOrigValue.length;

	var searchPattern = new RegExp(pattern.value);
	var count = 0;
	for(var i=0; i < selectLength; i++) {
		if(searchPattern.test(saveOrigText[i])) {
			var setOption = new Option();
			setOption.value = saveOrigValue[i];
			setOption.text = saveOrigText[i];
			box.options[count] = setOption;
			count++;
		} else {
			box.options[i] = null;
		}                
	}
	box.options.length = count;
}

function initializeSelect(listAddrs) {
	var tbox = document.forms[0].elements.address_selected;

	var selectLength = tbox.length;
	for(var i = 0; i < selectLength; i++) {
		window.document.globalnav.elements["ids"].value = window.document.globalnav.elements["ids"].value + tbox.options[i].value + ",";
	}
}
	
function addToList(fbox,tbox) {
	var dup = 0;

	for(var i=0; i<fbox.options.length; i++) {
		dup = 0;
		if(fbox.options[i].selected && fbox.options[i] != "") {
			for(var c=0; c<tbox.options.length; c++) {
				if(fbox.options[i].value == tbox.options[c].value) {
					dup = 1;
					break;
				}
			}
			if(dup == 0) {
				BumpUp(tbox);
				var no = new Option();
				no.value = fbox.options[i].value;
				no.text = fbox.options[i].text;
				tbox.options[tbox.options.length] = no;
				window.document.globalnav.elements["ids"].value = window.document.globalnav.elements["ids"].value + fbox.options[i].value + ",";
			}
		}
	}
}

function removeFromList(box) {
	var newList = "";
	var box_length = box.options.length;
	var element=0;
        
	for(var i=0; i < box_length; i++) {
		if(box.options[element].selected && box.options[element] != "") {
			box.options[element] = null;
		} else {
			element++;
		}
	}
	for(i=0; i < box.options.length; i++) {
		newList = newList + box.options[i].value + ",";
	}
	window.document.globalnav.elements["ids"].value = newList;

	BumpUp(box);
}
	
function BumpUp(abox) {
	for(var i=0; i < abox.options.length; i++) {
		if(abox.options[i].value == "") {
			for(var j=i; j < abox.options.length; j++) {
				abox.options[j].value = abox.options[j + 1].value;
				abox.options[j].text = abox.options[j + 1].text;
			}
			var ln = i;
			break;
		}
	}
	if(ln < abox.options.length) {
		abox.options.length -= 1;
		BumpUp(abox);
	}
}

function validate_email_addr(email) {
	if (  /^\w+([\.-]?\w)*@\w+((\.|-+)?\w)*\.\w+$/.test(email)  )
	{
		return false;
	}

	return true;
}

