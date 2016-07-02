// JASX API PREPROCESSOR DEFINITIONS
/*
	
	0. Hit Ctrl+S to save this file - Put it in a directory for LSL files
	1. Use Firestorm viewer
	2. Open a script and click the cogs icon
	3. Check enable LSL preprocessor, Script optimizer and #includes from local disk
	4. Navigate the include path to where you put this file
	5. Click OK and re-open your script window.
	6. You should be able to #include "jasxAPI.lsl"

*/

// Keys for sendAPI
#define API_TASKS "t"
#define API_KEY "k"
#define API_MESSAGES "m"

// Keys for tasks
#define API_TASK "t"
#define API_DATA "d"
#define API_CALLBACK "c"
#define API_STATUS "s"
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

	
	
/* 		TRIGGER A GAME ACTION		*/
#define API_GAME_ACTION 2
	#define ACTION_GAME "a"
		#define GAME_TIS "a"
		#define GAME_SNC "b"
		#define GAME_JFISH "c"
		#define GAME_FRIGHT "d"
		#define GAME_BARE "e"
		#define GAME_JASX "f"	// Not really a game, but needed for news
		#define GAME_DOGEHUD "g"
		#define GAME_WOOHOO "h"
	#define ACTION_TASK "b"
	#define ACTION_DATA "c"

	
	
	
// ACTION_TASKs for above (JASX)
#define JASX_SET_CONF 0			// (int)bitfield - (int)bitfield_after
#define JASX_SET_SEX 1				// (int)sex - (int)sex_after
	#define SEX_UNDEFINED 0
	#define SEX_MALE 1
	#define SEX_FEMALE 2
	#define SEX_HERM 3
	#define SEX_OTHER 4
#define JASX_SET_SPECIES 2			// (int)species - (int)species_after
	#define SPECIE_UNDEFINED 0
	#define SPECIE_HUMAN 1
	#define SPECIE_ANIME 2
	#define SPECIE_FURRY 3
	#define SPECIE_OTHER 4
#define JASX_SET_FLIST 3			// (obj)flist {(int)id:(int)setting} - (obj)flist_after
#define JASX_SET_LFP_GAMES 4		// (array)games - (arr)games_after
#define JASX_TOGGLE_LFP 5			// (bool)true/false - (bool)lfp_expires	
#define JASX_SET_CONTENTSERV_URL 6	// (str)url
#define JASX_GET_LFP_COMPAT 7		// obj {"a":(int)max_amount} - Returns an array of objects containing the most compatible players currently LFP: {"i":(int)jasx_id, "k":(key)id, "n":(str)jasx_username, "c":(str)character_name, "s":(int)sex, "a":(int)avtype} - Max amount defaults to 5, sorted from highest to lowest
#define JASX_GET_PLUGIN_UPDATES 8	// null - Returns an int of nr of plugins you subscribe to that have updates available
#define JASX_DELIVER_PLUGIN 9		// int - plugin_id - Attempts to deliver a plugin. Returns any status returned from the server
#define JASX_UPDATE_PLUGINS 10		// null - Attempts to deliver all subscribed plugins that have updates to you. Returns an array of any status codes from the requests.


// ACTION_TASK for BARE
#define BARE_SET_CONF 0				/*int - Sets config to this bitfield:
	#define GPB_PENIS 2
	#define GPB_VAGINA 4 
	#define GPB_TITS 8 
	#define GPB_PG 16
	#define GPB_NOBOTS 32
	#define GPB_NOANIM 64
	#define GPB_STRAPON 256
	Returns the new config
*/
#define BARE_SET_STYLE 1			// int - style Sets your fighting style to this as long as you own it. Returns the style used after calling this. See the BARE animpack table for IDs.
#define BARE_SET_FOLDER 2			// string - folder Sets your RLV folder. Returns the new folder.
#define BARE_SET_ABILITIES 3		// array - Ability IDs. Sets your abilities. Returns your abilities after filtering. Unowned or improper abilities get replaced with the standard abilities. See the BARE abilities table for ability IDs.




string gameAction(string game, integer task, string data){
	return llList2Json(JSON_OBJECT, [
		ACTION_GAME, game,
		ACTION_TASK, task,
		ACTION_DATA, data
	]);
}
	
string apiTask(integer task, string data, string callback){
	string op = llList2Json(JSON_OBJECT, [API_TASK, task]);
	if(data)op = llJsonSetValue(op, [API_DATA], data);
	if(callback)op = llJsonSetValue(op, [API_CALLBACK], callback);
	return op;
}

key sendAPI(string api_key, list tasks){
	return llHTTPRequest("http://jasx.org/api/index.php", [HTTP_METHOD, "POST", HTTP_MIMETYPE, "application/x-www-form-urlencoded"], "request="+llEscapeURL(llList2Json(JSON_OBJECT, [
		API_TASKS, llList2Json(JSON_ARRAY, tasks),
		API_KEY, api_key
	])));
}






