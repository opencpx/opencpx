/* ---------------------------------------------------------------
  data_table_obj Constructor.

  Purpose: 
      To create a new data table object, that can be used 
      navigate, sort and search a particular HTML table of data. 

  Notes:
      Can handle multiple table instances on the same page.
      
      Data can be read from either a pre existing table with data, 
      or a specified JS array.

      This function has a built in Refresh timer. Right now, 
      this is hard coded at 500,000 ms.
      Each time the page Method is called, a check is done to see
      if the refresh_interval has passed, andif it has
      then a location.reload() is done.
    
  Parameters:
    - table_id            (required string)
        ID of the table you want to page data in.
    - data_array          (optional AoA) 
        The data set to use. Should be an array of arrays.
        If this is blank, or empty, then the provided
        table_id is searched and any data there is used 
        as the base data set.
    - start_index         (optional Integer)
        Specifies the row index that data will be read and written 
        to in the table. If no value is specified, row index 
        0 is assumed.
        This setting is convenient for when your navigational 
        elements are in the same table as your data is displayed.
    - page_size_id        (required String)
        The ID of the data element to pull page size from.
        usually a SELECT box, or series of Checkboxes. 
    - page_number_id      (optional String) 
        The ID of the data element used to display the 
        current page number.
    - page_total_id       (optional String)
        The ID of the data element used to display the 
        Page total number. for the entire data set.
    - record_number_id    (optional String) 
        The ID of the data element used to display the 
        current record numbers. EX 1-10.
    - record_total_id     (optional String)
        The ID of the data element used to display the 
        record total of the data set.
    - first_id            (optional String)
        The ID of the link element used to navigate to the 
        first page of the data set.
    - prev_id             (optional String)
        The ID of the link element used to navigate to the 
        previous page of the data set. 
    - next_id             (optional String)
        The ID of the link element used to navigate to the 
        next page of the data set. 
    - last_id             (optional String)
        The ID of the link element used to navigate to the 
        last page of the data set. 
    - nav_active_style    (optional String) 
        The CSS style name used to represent the active 
        navigation links.
    - nav_inactive_style  (optional String) 
        The CSS style name used to represent the inactive 
        navigation links.
    - col_even_style      (optional String)
        The CSS style name used to represent the EVEN 
        table columns.
    - col_odd_style       (optional String)
        The CSS style name used to represent the ODD
        table columns.
    - sort_up_img         (optional String)
        The image url for the image used to indicate 
        an ascending sort direction.
    - sort_down_img       (optional String)
        The image url for the image used to indicate 
        an descending sort direction.

  Usage:
		var data_table0 = new data_table_obj( 
        'table0', 
        data_table_array0, 
        3,
        'page_size0', 
        'page_number0', 
        'page_total0', 
        'record_number0',
        'record_total0',
        'first_a0',
        'prev_a0',
        'next_a0',
        'last_a0',
        'nav_active_style',
        'nav_inactive_style'
        'col_even_style'
        'col_odd_style'
        '/cpimages/arrow_up.gif',
        '/cpimages/arrow_down.gif'
    ); 

  Public Methods:
    - sort
        Sorts a specified column of the current data set 
    - page
        Used to navigate the pages of data in the  data set.
    - search
        Used to search through the pages of data for  specific record 
        or sets of records.
    - search_clear
        Used to clear the Search results from a search that 
        brings back a set of records to page through.

------------------------------------------------------------------
*/
function data_table_obj( 
  table_id, 
  data_array, 
  start_index,
  page_size_id, 
  page_number_id, 
  page_total_id, 
  record_number_id,
  record_total_id,
  first_id, 
  prev_id, 
  next_id, 
  last_id, 
  nav_active_style, 
  nav_inactive_style,
  col_even_style,
  col_odd_style,
  sort_up_img,
  sort_down_img
) 
{
  this.table_obj          = document.getElementById(table_id);
  this.start_index        = parseInt(start_index, 10) || 0;
  this.page_size_obj      = document.getElementById(page_size_id);
  this.page_number_obj    = document.getElementById(page_number_id);
  this.page_total_obj     = document.getElementById(page_total_id);
  this.record_number_obj  = document.getElementById(record_number_id);
  this.record_total_obj   = document.getElementById(record_total_id);
  this.first_obj          = document.getElementById(first_id);
  this.prev_obj           = document.getElementById(prev_id);
  this.next_obj           = document.getElementById(next_id);
  this.last_obj           = document.getElementById(last_id);
  this.nav_active_style   = nav_active_style;         // css for active nav elements
  this.nav_inactive_style = nav_inactive_style;       // css for inactive nav elements
  this.col_even_style     = col_even_style;           // css for the even column rows
  this.col_odd_style      = col_odd_style;            // css for the even column rows
  this.sort_up_img        = sort_up_img;              // img for sort up elements
  this.sort_down_img      = sort_down_img;            // img for sort down elements
  this.load_time          = new Date();               // when data was retrieved last
  this.refresh_interval   = 500000;                   


  if ( (data_array.constructor == Array) && data_array.length )
  {
    this.data_array = data_array; // used supplied data set AoAs as main content 
  }
  else
  {
    // Populate main data set for this object with the 
    // data found in the provided table.
    this.data_array = new Array();

    for( var row = this.start_index; row < this.table_obj.rows.length; row++ )
    {
      this.data_array[row - this.start_index] = new Array();
     
      for( var col=0; col < this.table_obj.rows[this.start_index].cells.length; col++ )
      {       
        this.data_array[row - this.start_index][col] = this.table_obj.rows[row].cells[col].innerHTML;
      }       

    }

  }

  this.search_array       = new Array();              // search result set storage
  this.sort_direction     = 'desc';                   // 'desc' or 'asc'
  this.current_index      = 0;                        // where were currently at.
  this.page_size          = this.page_size_obj.value; // how many recs to view
  this.page_number        = new Number(1);            // page were lookin at
  this.page_total         = Math.ceil(this.data_array.length / this.page_size);
  this.next_index         = this.current_index + Math.min(this.page_size, this.data_array.length);
  this.record_total       = parseInt( this.data_array.length );
  this.record_number      = this.current_index + '-' + this.next_index;

  // Associated Public methods.
  this.sort         = sort;
  this.page         = page;
  this.search       = search;
  this.search_clear = search_clear;

  this.page();    

} // END new


/* ---------------------------------------------------------------
  Name      : search_clear  Public Method.

  Purpose: 
      To clear out the Search results set data structure
      that was poulated by a search request, that specified
      that a data set should be collected to apge through.

  Parameters: NONE
  
------------------------------------------------------------------
*/
function search_clear()
{
  this.search_array = new Array();

  this.page( 0 ); // page back to first page 

} // END search_clear


/* ---------------------------------------------------------------
  Name      : search        Public Method.

  Purpose: 
      To Search for a particular record in the data set.

  Parameters: 
    - search_string     (required string)
          The  text to look for.
    - search_column     (optional string)
          The column that the data should be looked for in.
          If not specified, then 0 is used.
    - results_set       (optional Integer)
          Boolean flag for whether a results set of all search 
          matches shoudl be compiled and stored, to page through.
          if this is set, the main data set that the table displays
          is replaced with the Search data set, and can be paged 
          through and sorted. This data set remains in the  table, 
          until the associated data_table obj 'search_clear' method 
          is called.
  
------------------------------------------------------------------
*/
function search ( search_string, search_column, results_set )
{
  //var start_time = new Date();

  search_column = parseInt(search_column) || 0;  // Default search column
  search_string = search_string + "";

  // Kill any prior search results
  this.search_array = new Array();

  // Later maybe break this up and search for each word?
  var re = new RegExp( search_string );

  for ( var row=0; row < this.data_array.length; row++ )
  {
    var found_index = this.data_array[row][search_column].match(re);

    if( found_index )
    {    
      if( results_set )
      {
        this.search_array.push( this.data_array[row] );
      }
      else
      {
        this.page( row ); // goto that index.

        return true;          
      }

    }

  } // end for rows

  this.page( 0 ); 

//  var end_time = new Date();
//  alert(end_time - start_time);

  return true;

} // END search


/* ---------------------------------------------------------------
  Name      : page      Public Method.

  Purpose: 
      To redraw a tables data display to a particular index 
      or page of the current data set.
      If a Search Results set is present, then it is always 
      used instead of the main data set. The Search results 
      data set can be cleared by the 'search_clear' method.
      This will cuse this method to go back to displaying the
      main data set.
            
  Parameters: 
    - direction   (optional string | number)
        Valid values: 'first', 'prev', 'next', 'last', or 0-N
        If a number is given, then the page containing that record 
        index is gone to.
  
------------------------------------------------------------------
*/
function page( direction ) 
{
//  var start_time = new Date();

  // REFRESH DATA LOGIC.
  // Check and see if the refresh_interval has passed since
  // the table has been drawn last. if so, reload it.
  var access_time   = new Date();

  if ( ( access_time - this.load_time ) > this.refresh_interval )
  {
    location.reload();
    return;
  }

  this.page_size    = parseInt(this.page_size_obj.value);
  var array_length  = this.search_array.length || this.data_array.length;
  direction         = direction + "";       // Make sure its a string

  // Determine direction and adjust index.
  if(direction.toLowerCase() == 'first') 
  {
    this.current_index  = 0;
    this.next_index     = this.current_index + Math.min(this.page_size, array_length);
  }
  else if(direction.toLowerCase() == 'prev') 
  {
    this.next_index     = Math.min(Math.max(this.current_index, this.page_size), array_length);
    this.current_index  = Math.max(this.current_index - this.page_size, 0);
  }
  else if(direction.toLowerCase() == 'next') 
  {
    this.current_index  = Math.max(Math.min(this.current_index+this.page_size, array_length-this.page_size),0);
    this.next_index     = this.current_index + Math.min(this.page_size, array_length);
  }
  else if(direction.toLowerCase() == 'last') 
  {
    this.current_index  = Math.max(array_length - this.page_size, 0);
    this.next_index     = array_length;
  }
  else if( (direction == '0') || parseInt(direction) ) 
  {
    this.current_index  = Math.max(Math.min( direction, array_length - this.page_size), 0);
    this.next_index     = this.current_index + Math.min(this.page_size, array_length);
  }
  else 
  {
    this.current_index  = Math.max(Math.min(this.current_index, array_length - this.page_size), 0);
    this.next_index     = this.current_index + Math.min(this.page_size, array_length);
  }  

  // Delete all old rows.
  for (  ; this.start_index < this.table_obj.rows.length;  ) 
  {
    this.table_obj.deleteRow( this.start_index );
  }

  // Recreate table to right size and with right data.
  for(var row=Math.max(this.current_index, 0); row < Math.min(this.next_index , array_length); row++) 
  { 
    var tr = this.table_obj.insertRow(this.table_obj.rows.length);

    tr.className = (this.table_obj.rows.length % 2 ) ? this.col_odd_style : this.col_even_style;

    for( var col=0; col < this.data_array[0].length; col++ )
    {
      var td = tr.insertCell(col);
      
      td.innerHTML = ( this.search_array.length ) ? this.search_array[row][col] : this.data_array[row][col];
    }

  }

  // Figure out what page were on now, and update display
  this.page_number    = Math.max(Math.ceil(this.next_index / this.page_size), 1);
  this.page_total     = Math.max(Math.ceil(array_length / this.page_size), 1);
  this.record_total   = parseInt(array_length);
  this.record_number  = (this.current_index + 1) + '-' + this.next_index;
  
  // Only write out if we were given objects to modify.
  if ( this.page_number_obj ) 
    this.page_number_obj.innerHTML    = parseInt(this.page_number, 10);
  if ( this.page_total_obj )
    this.page_total_obj.innerHTML     = parseInt(this.page_total, 10);
  if ( this.record_number_obj )
    this.record_number_obj.innerHTML  = this.record_number;
  if ( this.record_total_obj )
    this.record_total_obj.innerHTML   = parseInt(this.record_total, 10);

  // Update any of the nav links that may have changed.
  if( this.page_total == 1 )
  {
    // only one page
    if ( this.first_obj )
        this.first_obj.className = this.nav_inactive_style;
    if ( this.prev_obj )
        this.prev_obj.className  = this.nav_inactive_style;
    if ( this.next_obj )
        this.next_obj.className  = this.nav_inactive_style;
    if ( this.last_obj )
        this.last_obj.className  = this.nav_inactive_style;
  }
  else if( this.page_number == 1 )
  {
    // first page
    if ( this.first_obj )
        this.first_obj.className = this.nav_inactive_style;
    if ( this.prev_obj )
        this.prev_obj.className  = this.nav_inactive_style;
    if ( this.next_obj )
        this.next_obj.className  = this.nav_active_style;
    if ( this.last_obj )
        this.last_obj.className  = this.nav_active_style;
  }
  else if( this.page_number == this.page_total )
  {
    // last page
    if ( this.first_obj )
        this.first_obj.className = this.nav_active_style;
    if ( this.prev_obj )
        this.prev_obj.className  = this.nav_active_style;
    if ( this.next_obj )
        this.next_obj.className  = this.nav_inactive_style;
    if ( this.last_obj )
        this.last_obj.className  = this.nav_inactive_style;
  }
  else
  {
    // all other pages
    if ( this.first_obj )
        this.first_obj.className = this.nav_active_style;
    if ( this.prev_obj )
        this.prev_obj.className  = this.nav_active_style;
    if ( this.next_obj )
        this.next_obj.className  = this.nav_active_style;
    if ( this.last_obj )
        this.last_obj.className  = this.nav_active_style;
  }
  
//  var end_time = new Date();
//  alert(end_time - start_time);

} // END page


/* ---------------------------------------------------------------
  Name      : sort      Public Method.
  
  Purpose: 
      Sorts the data array.
      This works on the Search results set if it is present.

  Parameters:
    - sort_col      (required String)
        The index of the AoA column that you wish to sort by.
    - direction     (optional String)
        The direction of the sort.
        Valid values are 'desc' or 'asc' or NULL 
        If no value is supplied, the opposite of the last direction
        is used.
    - sort_id       (optional String)
        The id of the element used to show sort dir.

------------------------------------------------------------------
*/
function sort ( sort_col, direction, img_id )
{
  if( direction )
  {   
    this.sort_direction = direction;
  }
  else
  {
    // If no direction was provided, toggle the last direction.
    this.sort_direction = (this.sort_direction != 'desc') ? 'desc' : 'asc';  
  } 

  // Boolean flag for direasy checking. desc = 1
  var dir = (this.sort_direction == 'desc') ? 1 : 0;

  if ( img_id )
  {
    var img_obj = document.getElementById(img_id);

    img_obj.src  = (dir) ? this.sort_down_img : this.sort_up_img;
  }

  if ( this.search_array.length )
  {
    // Sort the search results if they exist.
    this.search_array.sort( function(a,b)
    {
      if (a[sort_col] < b[sort_col]) return ((dir) ? 1 : -1);
      if (a[sort_col] > b[sort_col]) return ((dir) ? -1 : 1);
      return 0;
    });
  }
  else
  {
    var dir = (this.sort_direction == 'desc') ? 1 : 0;

    this.data_array.sort( function(a,b)
    {
      if (a[sort_col] < b[sort_col]) return ((dir) ? 1 : -1);
      if (a[sort_col] > b[sort_col]) return ((dir) ? -1 : 1);
      return 0;
    });
  }

  this.page( 0 );
}




