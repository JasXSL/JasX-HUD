

// 1. PLEASE ENTER YOUR API KEY IN THE API_KEY NOTECARD - You can get an API key here: http://jasx.org/api/
// 2. Drop items into the server you want to be able to give out.
// Overridable events
#ifndef onURL
	#define onURL( url )
#endif
#ifndef onTaskReceived
	#define onTaskReceived( task, data ) FALSE
#endif
#ifndef onHTTPResponse
	#define onHTTPResponse( id, status, body )
#endif

string MY_API_KEY;

// These are just visuals. Good gets a green text above the prim, med yellow and bad red
#define TYPE_GOOD 0
#define TYPE_MED 1
#define TYPE_BAD 2
// Current notice type
integer TYPE;
// Current notice
string TEXT;

// TIMERS
#define TIMER_QUERYING "a"
#define TIMER_VERIFY_URL "b"
#define TIMER_FADE "c"


// Fetch a new prim URL
#define getURL() U_REQ = llRequestURL()



// BITFLAGS
integer BFL;
#define BFL_QUERYING 1

// Current outbound http request keys
list REQS;
// Task queue
list TASKS;

// Notecard request
key N_REQ;
// LSL URL Fetch request
key U_REQ;
// Verify server still live request
key UV_REQ; 
// My prim server URL
string MY_URL;




// Queues tasks and sends at a rate of max once every 2 sec to prevent script errors
send(list tasks){
    if(tasks != [])TASKS+=tasks;
    if(TASKS == [] || BFL&BFL_QUERYING)return;
    status("Sending tasks...", TYPE_MED, 1);
    BFL = BFL|BFL_QUERYING;
    multiTimer([TIMER_QUERYING, "", 2, FALSE]);
    REQS+=sendAPI(MY_API_KEY, TASKS);
    TASKS = [];
}

// Timer event
timerEvent(string id, string data){
    // 2 sec has passed since we last sent data
    // Send any newly added tasks if possible
    if(id == TIMER_QUERYING){
        BFL = BFL&~BFL_QUERYING;
        send([]);
    }
    
    // Runs every now and then to make sure the prim URL is still good
    else if(id == TIMER_VERIFY_URL){
        UV_REQ = llHTTPRequest(MY_URL, [], "");
    }
    
    // Fade out the status text
    else if(id == TIMER_FADE){
        float alpha = (float)data - .05;
        if(alpha<=0){
            alpha = 0;
        }else{
            TEXT = "";
            multiTimer([id, alpha, .05, FALSE]);
        }
        status(TEXT, TYPE, alpha);
    }
	
	else if( startsWith(id, "IG:") ){
	
		list json = llJson2List(llGetSubString(id, 3, -1));
		llGiveInventory(l2s(json, 0), l2s(json, 1));
	
	}
	
}


// Sets the status text
status(string text, integer type, float alpha){
    list colors = [<.5,1,.5>, <1,1,.5>, <1,.5,.5>];
    if(TEXT != text){
        multiTimer([TIMER_FADE, 1, 8, FALSE]);
    }
    TEXT = text; TYPE = type;
    llSetText(text, llList2Vector(colors, type),alpha);
}

// Adds a response for the JasX server
list OUT;
addOut(string task, integer success, string data){
    OUT+=llList2Json(JSON_OBJECT, [
        "task", task,
        "success", success,
        "data", data
    ]);
}

default
{
    // Restart the script on rez
    on_rez(integer mew){llResetScript();}
    
    // Handle timer
    timer(){multiTimer([]);}
    
    state_entry()
    {
        // Start by getting the API key from the notecard
        status("Getting key...", TYPE_MED, 1);
        N_REQ = llGetNotecardLine("API_KEY", 0);
    }
    
    // On inventory change, restart, since we might have changed the notecard
    changed(integer change){
        if(change&CHANGED_INVENTORY){
            llReleaseURL(MY_URL);
            llResetScript();
        }
    }
    
    // HTTP IN
    http_request(key id, string method, string body){
	
        // Response to getting prim URL
        if(id == U_REQ){
		
            // Fail, but the script will auto try
            if(method == URL_REQUEST_DENIED)
                status("URL request denied. The sim is having issues. Trying again in 5 min", TYPE_BAD, 1);
            
            else if(method == URL_REQUEST_GRANTED){
			
                // We got a prim URL
                status("Storing URL...", TYPE_MED, 1);
                MY_URL = body;
                
                // Run an API task to set the owner of the API keys content server to this prim's url
                // As such, you can only have one server active
                send([
                    apiTask(API_RUN_METHOD, llList2Json(JSON_OBJECT, [
						METHOD_TABLE, "jasx_users",
						METHOD_TASK, "contentserv",
						METHOD_DATA, MY_URL
					]), "")
                ]);
				
				onURL( body );
				
            }
            return;
        }
        
        // Request received from the JasX server start with JASX;;
        // Add your own prefix to calls if you want to connect to this prim through your own server
        if(llGetSubString(body, 0, 5) == "JASX;;"){
            // Lets you output any messages that will show up to the user on a successful response
            list messages = [];
            
            // Cycle through the requests
            // Jasx requests are sent as [{"task":(str)task, "data":(str)data}]
            // Jasx responses are sent in the form of: 
            /*
                {
                    "tasks":
                    [
                        {
                            "task":(str)task, 
                            "success":(int)success
                        }
                    ], 
                    "message":(str)message
                }
            */
            
            // To speed this up you can just use:
            /* 
                Status: 
                    addOut(
                        (str)task_received, 
                        (int)success, 
                        (optional)data
                    );
            */
            // Messages: messages+="My output message...";
            
            // Fetch the requests as a list
            list requests = llJson2List(llGetSubString(body, 6, -1));

            while( llGetListLength(requests) ){
			
                string req = llList2String(requests, 0);
                requests = llDeleteSubList(requests, 0, 0);
                
                // Here we have task and data
                string task = llJsonGetValue(req, ["task"]);
                string data = llJsonGetValue(req, ["data"]);
                
                
                // We received the send_item task where data is:
                /*
                    {
                        agent : (key)recipient,
                        item : (str)item
                    }
                */
				
				// Override default behavior
				if( onTaskReceived(task, data) ){}
                else if( task == "send_item" ){
				
                    string targ = llJsonGetValue(data, ["agent"]);
                    string item = llJsonGetValue(data, ["item"]);
                    
                    // Make sure the item can be sent, and prevent this script or the API_KEY notecard from being sent
                    if( llGetInventoryType(item) == INVENTORY_NONE || item==llGetScriptName() || item == "API_KEY" ){
					
						if( item==llGetScriptName() || item == "API_KEY" )
							messages += "Item "+item+" is restricted and cannot be sent.";
						else
							messages += "Item not found in server.";
							
                        addOut(task, FALSE, "");
                        status("Item send failed!", TYPE_MED, 1);
						
                    }
                    // If the agent key is valid
                    else if( (key)targ ){
					
                        status("Item send successful!", TYPE_GOOD, 1);
                        // Respond with a success, no data is needed
                        addOut(task, TRUE, "");
                        // Output a message to the client
                        messages += "Item was sent to you on Second Life!";
                        // Defer the item send to a timer to send the response in a timely fashion
                        multiTimer(["IG:"+mkarr(([targ, item])), 0, 0.1, FALSE]);
						
                    }
                    // The agent key was not proper
                    else{
                        messages += "Invalid target agent.";
                        addOut(task, FALSE, "");
                        status("Item send failed!", TYPE_MED, 1);
                    }
					
                }
                
                // Here the JasX server has requested an item listing
                // We need to return a JSON array of items that can be sent
                else if( task == "list_items" ){
				
                    list op = [];
                    integer i;
                    for(i=0; i<llGetInventoryNumber(INVENTORY_ALL); i++){
                        string ln = llGetInventoryName(INVENTORY_ALL, i);
                        // Don't include this script or the API key in the result
                        if(ln != llGetScriptName() && ln != "API_KEY")op+=ln;
                    } 
                    // Respond with success and the JSON array
                    addOut(task, TRUE, llList2Json(JSON_ARRAY, op));
					
                }
            }
            
            
            // Send the response with our OUT data
            llHTTPResponse(id, 200, llList2Json(JSON_OBJECT, [
                "tasks", llList2Json(JSON_ARRAY, OUT),
                "message", llDumpList2String(messages, "<br />")
            ]));
            // Purge the out data for the next request
            OUT = [];
        }
        
        else{
            // If the call wasn't from JasX, then put some code here
            // Handle non-jasx syntax calls
            llHTTPResponse(id, 200, "");
        }
        
    }
    
    
    // HTTP OUT responses
    http_response( key id, integer status, list meta, string body ){
	
        // This was an internal call to see if the prim URL is still active
        if( id == UV_REQ ){
		
            if( status != 200 )
				getURL();
            return;
			
        }
		
		onHTTPResponse( id, status, body );
        
        // Make sure the call came from this script (was an API CALL)
        integer pos = llListFindList(REQS, [id]);
        if( pos== -1 )
			return;
			
        REQS = llDeleteSubList(REQS, pos, pos);
        
		if( llJsonValueType(body, []) != JSON_OBJECT ){
		
			qd("Invalid response: "+body);
			return;
			
		}
        
        // Here we check if the body contained any messages, in that case ownersay them
        if( llJsonValueType(body, [API_MESSAGES]) != JSON_INVALID ){
		
            list m = llJson2List(llJsonGetValue(body, [API_MESSAGES]));
            while( llGetListLength(m) ){
			
                llOwnerSay(llList2String(m,0));
                m = llDeleteSubList(m, 0, 0);
				
            }
			
        }
        
        // Here we check through the tasks we sent and see how they went
        if( llJsonValueType(body, [API_TASKS]) != JSON_INVALID ){
            
			list m = llJson2List(llJsonGetValue(body, [API_TASKS]));

            while( llGetListLength(m) ){
			
                string dta = llList2String(m,0);
                m = llDeleteSubList(m, 0, 0);

                integer task = (integer)llJsonGetValue(dta, [API_TASK]);
                string data  = llJsonGetValue(dta, [API_DATA]);
                integer status = (integer)llJsonGetValue(dta, [API_STATUS]);
                string callback = llJsonGetValue(dta, [API_CALLBACK]);
                
                // Status is 1 on success, this was not a success, we can check the status code to see why
                if( status != 1 ){
				
                    string txt = "Task: "+(string)task+" failed: ";
                    if(status == STATUS_FAIL_DATA_MISSING)
						txt+="Incomplete data fields";
                    else if(status == STATUS_FAIL_ACCESS_DENIED)
						txt+="Access denied";
                    else 
						txt+="Unknown reason. See log.";
                    status(txt, TYPE_BAD, 1);
					
                }
                // This was a success
                else{
				
                    // We sent a game action
                    if( task == API_RUN_METHOD ){
					
                        string table = j(data, METHOD_TABLE);
                        string atask = j(data, METHOD_TASK);
						string adata = j(data, METHOD_DATA);
						
                        if( table == "jasx_users" ){
						
                            if( atask == "contentserv" && adata == JSON_TRUE )
                                status("ContentServ online!", TYPE_GOOD, 1);
							
                        }
						
                    }
					
                }
                
            }
        }
        
    }
    
    
    // Response from notecard fetch
    dataserver( key id, string data ){
	
        if( id != N_REQ )
			return;
        
        // If we got the default message
        if( llGetSubString(data, 0, 1) == "//" )
            llDialog(llGetOwner(), "Please edit the API_KEY notecard in this server and replace it with your API key. You can see or get an API key at http://jasx.org/api", [], 987);
        // Try to get a prim URL
        else{
            // Store our API key in a global
            MY_API_KEY = llStringTrim(data, STRING_TRIM);
            
            // Output debug
            status("Getting URL...", TYPE_MED, 1);
            
            // Start verifying that our prim URL is valid every 5 min
            multiTimer([TIMER_VERIFY_URL, "", 300, TRUE]);
            
            // Fetch our first prim URL immediately
            getURL();
        }
    }
    
}
