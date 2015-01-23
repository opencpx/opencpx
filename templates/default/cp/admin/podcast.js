
var df0 = document.forms[0];
function validateFeed(alertText, alertText2) { 
    if (df0.title.value == '' ||
	    (df0.directory && df0.directory.value == '') ||
	    (df0.filename && df0.filename.value == '') ||
	    (df0.link && df0.link.value == '') ||
	    (df0.fileurl && df0.fileurl.value == '') ||
	    df0.description.value == '') {
	alert(alertText)
	return false;
    }
    return isValidDate(alertText2);
}

//var blnTesting = true;
function isValidDate(alertText2) {
	var df_d = df0.pubdate_date;
	var df_m = df0.pubdate_month;
	var df_y = df0.pubdate_year;

	if(df_d.selectedIndex<1 && df_m.selectedIndex<1 && df_y.selectedIndex<1) {
		return true;//allow date, month and year to be all blank.
	}
	//otherwise check that month, day and year all have been selected
	if(df_d.selectedIndex<1 || df_m.selectedIndex<1 || df_y.selectedIndex<1) {
		alert(alertText2);
		return false;
	}
	var intDate = parseInt(df_d.value, 10);
 	if(intDate<29) { return true; }	
	var intMonthIndex = df_m.selectedIndex - 1; 
	var intYear = parseInt(df_y.value,10);
	var arrMaxDaysInMonth = [31,29,31,30,31,30,31,31,30,31,30,31];
	//verify that date exists in the provided month and year
	//Note: This is a leap-year simplification, which will work until Y2.1K. -rtl 
	if(intDate>arrMaxDaysInMonth[intMonthIndex] || (intMonthIndex==1 && (intYear%4)!=0)) {
		alert(alertText2);
		return false;
	}
	return true;
}

//Note: I just noticed this little function and it doesn't appear to be used anywhere.
//It looks like another call to validateFeed() was used when this function was meant to be 
//called.  However, I have already hacked up validateFeed() to suffice, so I think 
//validateItem() can safely be deleted.   Thus, I'll comment it out and see what
//havoc ensues. -rtl 
/*function validateItem(alertText) { 
    if (df0.title.value == '' ||
	    df0.fileurl.value == '' ||
	    df0.description.value == '') {
	alert(alertText)
	return false;
    }
    return true;
}*/

function validateUpload(alertText) { 
    if (df0.fileupload.value == '') {
	alert(alertText)
	return false;
    }
    return true;
}

function validateCategories(alertText) {
    var count = 0;
    var categories = document.getElementById("categories");
    for (var i = 0; i < categories.length; i++) {
        if (categories.options[i].selected == true) {
            count++;
        }
    }
    if (count > 3) {
        alert(alertText)
        return false;
    }
    return true;
}

function validateItunesImage(alertText) { 
    var regex=/\.jpg|\.png$/;
    if (df0.itunes_image.value.length==0) {
        return true;
    }
    if (regex.test(df0.itunes_image.value)) {
        return true;
    }
    alert(alertText);
    return false;
}

function applyOptionalDisplay(value) {
    document.getElementById("optionalDisplay").style.display = value;
}

function getDateString(epoch) {
    /* convert to epoch milliseconds */
    var date = new Date(epoch * 1000);
    return((date.getMonth()+1)+'/'+date.getDate()+'/'+date.getFullYear());
}

