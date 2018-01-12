// JASX API PREPROCESSOR DEFINITIONS

// IN/Out objects
// Keys for sendAPI
#define API_TASKS "t"				// (IN/OUT) Array of tasks to send or callbacks for tasks
#define API_KEY "k"					// (IN) API key is required to authenticate a user
#define API_MESSAGES "m"			// (OUT) Array of Error messages and such

// Task objects
// Keys for tasks
#define API_TASK "t"						// (int)ID of task to send
#define API_DATA "d"						// (var)data to send
#define API_CALLBACK "c"					// (var)callback that will be returned
#define API_STATUS "s"						// (OUT) (int)code - Status code detailing if the call was successful or not
	#define STATUS_FAIL_DATA_MISSING -2
	#define STATUS_FAIL_ACCESS_DENIED -1
	#define STATUS_FAIL_GENERAL 0
	#define STATUS_SUCCESS 1



// TASKS

/* 		GET DATA FROM DATABASE		*/
#define API_GET_DATA 1					// Gets data from a table
	#define DATA_TABLE "a"					// (str) Table name
	#define DATA_FIELDS "b"					// (arr) data fields
	#define DATA_LIMIT "c"					// (arr)(nested) You can use = & != !& > <  [["field=val", AND "field<val"], OR "field!=val"]...
	#define DATA_NR_FIELDS "d"				// (int)nr_results
	#define DATA_ORDER_BY "e"				// (array)[{"f":(str)field, "d":(int)descending}...]
	#define DATA_STARTFROM "f"				// (int)start from entrry
	
	
/* 		Run a method on one of your user accounts, specified by API KEY		*/
#define API_RUN_METHOD 2				
	#define METHOD_TABLE "a"
	#define METHOD_TASK "b"			// (int)task, See below
	#define METHOD_DATA "c"			// (var)data, see below



	
string apiTask(integer task, string data, string callback){
	string op = llList2Json(JSON_OBJECT, [API_TASK, task]);
	if(data)op = llJsonSetValue(op, [API_DATA], data);
	if(callback)op = llJsonSetValue(op, [API_CALLBACK], callback);
	return op;
}

key sendAPI(string api_key, list tasks){
	return llHTTPRequest("http://jasx.org/api/index.php", [HTTP_BODY_MAXLENGTH, 16384, HTTP_METHOD, "POST", HTTP_MIMETYPE, "application/x-www-form-urlencoded"], "request="+llEscapeURL(llList2Json(JSON_OBJECT, [
		API_TASKS, llList2Json(JSON_ARRAY, tasks),
		API_KEY, api_key
	])));
}



// optional functions you can define to modify server behavior

// LSL HTTP IN URL has changed
// onURL( string url ){}

// A task has been received, should return an integer. If TRUE, default behavior will be overridden
// integer onTaskReceived( string task, string data ){}


// A http response has been received
// onHTTPResponse( key id, integer status, string body )
