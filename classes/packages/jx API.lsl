string MY_API_KEY;

// Debug colors
#define TYPE_GOOD 0
#define TYPE_MED 1
#define TYPE_BAD 2
// Debug data
integer TYPE;	
string TEXT;

// TIMERS
#define TIMER_QUERYING "a"
#define TIMER_VERIFY_URL "b"
#define TIMER_FADE "c"

// BITFLAGS
integer BFL;
#define BFL_QUERYING 1

list REQS;		// Active HTTP request
list TASKS;		// Queued tasks
key N_REQ;		// Request notecard line from config
key U_REQ;		// Fetch a new sim media URL
key UV_REQ; 	// Verify that our URL is still valid
string MY_URL;	// My current URL



#define getURL() U_REQ = llRequestURL()


// Sends all queued tasks to the server
send(list tasks){
    if(tasks != [])TASKS+=tasks;
    if(TASKS == [] || BFL&BFL_QUERYING)return;
    status("Sending tasks...", TYPE_MED, 1);
    BFL = BFL|BFL_QUERYING;
    multiTimer([TIMER_QUERYING, "", 2, FALSE]);
    REQS+=sendAPI(MY_API_KEY, TASKS);
    TASKS = [];
}

timerEvent(string id, string data){
	
	// We can send another query here
    if(id == TIMER_QUERYING){
        BFL = BFL&~BFL_QUERYING;
        send([]);
    }
	
	// Makes sure our URL is proper
	else if(id == TIMER_VERIFY_URL){
        UV_REQ = llHTTPRequest(MY_URL, [], "");
    }
	
	// Fades out the debug text
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
}


// Sets the debug text
status(string text, integer type, float alpha){
    list colors = [<.5,1,.5>, <1,1,.5>, <1,.5,.5>];
    if(TEXT != text)
        multiTimer([TIMER_FADE, 1, 8, FALSE]);
    
    TEXT = text; TYPE = type;
    llSetText(text, llList2Vector(colors, type),alpha);
}

// Handles responses to the server
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
    on_rez(integer mew){llReleaseURL(MY_URL); llResetScript();}
    
	timer(){multiTimer([]);}
	
    state_entry()
    {
        status("Getting key...", TYPE_MED, 1);
        N_REQ = llGetNotecardLine("API_KEY", 0);
    }
    
	// Handle restarts
    changed(integer change){
        if(change&(CHANGED_INVENTORY|CHANGED_REGION|CHANGED_REGION_START)){
            llReleaseURL(MY_URL);
            llResetScript();
        }
    }
    
	// HTTP request handlers
    http_request(key id, string method, string body){
	
		// URL fetch
        if(id == U_REQ){
            if(method == URL_REQUEST_DENIED)
                status("URL request denied. The sim is having issues. Trying again in 5 min", TYPE_BAD, 1);
            else if(method == URL_REQUEST_GRANTED){
                status("Storing URL...", TYPE_MED, 1);
                MY_URL = body;
                // Save
                send([
                    apiTask(API_GAME_ACTION, gameAction(GAME_JASX, JASX_SET_CONTENTSERV_URL, MY_URL), "")
                ]);
            }
            return;
        }
        
		// Response from the JasX server
        
        // JasX server syntax, it's recommended to add your own prefix to calls if you want to connect to the content-server yourself
        if(llGetSubString(body, 0, 5) == "JASX;;"){
            list messages = [];
            
            // Cycle through the requests
            // Jasx requests are sent as [{"task":(str)task, "data":(var)data}]
            // Jasx responses are sent in the form of {"tasks":[{"task":(str)task, "success":(int)success, "data":(var)data}], "message":(str)message}

            // For JasX responses, you just need to do the following:
            // Status: addOut(task, (int)success, (optional)data);
            // Messages: messages+="My output message...";
			// Beware that your messages will be HTML escaped by the server
            
            list requests = llJson2List(llGetSubString(body, 6, -1));
            while(llGetListLength(requests)){
			
                string req = llList2String(requests, 0);
                requests = llDeleteSubList(requests, 0, 0);
                string task = llJsonGetValue(req, ["task"]);
                string data = llJsonGetValue(req, ["data"]);
                
                
                // Send an item to an agent
                if(task == "send_item"){
                    string targ = llJsonGetValue(data, ["agent"]);
                    string item = llJsonGetValue(data, ["item"]);
                    
                    // Make sure the item can be sent, and prevent this script or the API_KEY notecard from being sent
                    
                    if(llGetInventoryType(item) == INVENTORY_NONE || item==llGetScriptName() || item == "API_KEY"){
                        messages += "Item "+item+" is restricted and cannot be sent.";
                        addOut(task, FALSE, "");
                        status("Item send failed!", TYPE_MED, 1);
                    }
                    else if(llStringLength(targ) != 36){
                        messages += "Invalid target agent.";
                        addOut(task, FALSE, "");
                        status("Item send failed!", TYPE_MED, 1);
                    }
                    else{
                        status("Item send successful!", TYPE_GOOD, 1);
                        addOut(task, TRUE, "");
                        messages += "Item was sent to you on Second Life!";
                        llGiveInventory(targ, item);
                    }
					
                }
                
				// List this prim's inventory
                else if(task == "list_items"){
                    
                    list op = [];
                    integer i;
                    for(i=0; i<llGetInventoryNumber(INVENTORY_ALL); i++){
                        string ln = llGetInventoryName(INVENTORY_ALL, i);
                        if(ln != llGetScriptName() && ln != "API_KEY")op+=ln;
                    } 
                    addOut(task, TRUE, llList2Json(JSON_ARRAY, op));
                }
            }
            
            
            
            llHTTPResponse(id, 200, llList2Json(JSON_OBJECT, [
                "tasks", llList2Json(JSON_ARRAY, OUT),
                "message", llDumpList2String(messages, "<br />")
            ]));
            OUT = [];
        }
        
        else{
            // Handle non-jasx syntax calls
            llHTTPResponse(id, 200, "");
        }
        
    }
    
    http_response(key id, integer status, list meta, string body){
		
		// Our URL has been dropped
        if(id == UV_REQ){
            if(status != 200)getURL();
			return;
        }
		
		// Make sure this request came from the prim
        integer pos = llListFindList(REQS, [id]);
        if(pos== -1)return;
		
        REQS = llDeleteSubList(REQS, pos, pos);
        
		// Output messages received from the server
        if(llJsonValueType(body, [API_MESSAGES]) != JSON_INVALID){
            list m = llJson2List(llJsonGetValue(body, [API_MESSAGES]));
            while(llGetListLength(m)){
                qd(llList2String(m,0));
                m = llDeleteSubList(m, 0, 0);
            }
        }
        
		// Handle tasks
        if(llJsonValueType(body, [API_TASKS]) != JSON_INVALID){
            list m = llJson2List(llJsonGetValue(body, [API_TASKS]));

            while(llGetListLength(m)){
                string dta = llList2String(m,0);
                m = llDeleteSubList(m, 0, 0);
                
                integer task = (integer)llJsonGetValue(dta, [API_TASK]);
                string data  = llJsonGetValue(dta, [API_DATA]);
                integer status = (integer)llJsonGetValue(dta, [API_STATUS]);
                string callback = llJsonGetValue(dta, [API_CALLBACK]);
                
				// Error
                if(status != 1){
                    string txt = "Task: "+(string)task+" failed: ";
                    if(status == STATUS_FAIL_DATA_MISSING)txt+="Incomplete data fields";
                    else if(status == STATUS_FAIL_ACCESS_DENIED)txt+="Access denied";
                    else txt+="Unknown reason. See log.";
                    status(txt, TYPE_BAD, 1);
                }
				
				// Success
				else{
                    if(task == API_GAME_ACTION){
                        integer game = (int)j(data, ACTION_GAME);
                        integer atask = (integer)j(data, ACTION_TASK);
                        if(game == GAME_JASX){
                            if(atask == JASX_SET_CONTENTSERV_URL){
                                status("ContentServ online!", TYPE_GOOD, 1);
                            }
                        }
                    }
                }
                
            }
        }
        
    }
    
    dataserver(key id, string data){
        if(id == N_REQ){
            if(llGetSubString(data, 0, 1) == "//")llDialog(llGetOwner(), "Please edit the API_KEY notecard in this server and replace it with your API key. You can see or get an API key at http://jasx.org/api", [], 987);
            else{
                status("Getting URL...", TYPE_MED, 1);
                multiTimer([TIMER_VERIFY_URL, "", 300, TRUE]);
                MY_API_KEY = llStringTrim(data, STRING_TRIM);
                getURL();
            }
        }
    }
    
}
