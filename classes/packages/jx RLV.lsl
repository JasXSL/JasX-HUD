/*
	
	Folder structure:
	#RLV/JasX
		::Group:: A group combines multiple outfits into one. The only real purpose to a group is to let players with many outfits, to the point where RLV breaks, to combine them
		<_group> - To mark a folder as a group, start the name of the folder with _
			Avatar - Attached when the group is attached
			Default (optional) - Default clothing outfit. If not specified, no sub outfit will be attached.
			<outfit> - Name of avatar outfit
				Avatar - Attached when outfit is activated, detached when deactivated
				<state> (Dressed/Underwear/Bits)
					<slot> (Head/Arms/Torso/Crotch/Boots)
						<datafolders...>
					<datafolders...>
				<datafolders...>
			<datafolders...>
		<outfit> - Name of an outfit
			Avatar - Attached when the outfit is activated
			<state> (Dressed/Underwear/Bits)
					<slot> (Head/Arms/Torso/Crotch/Boots)
						<datafolders...>
					<datafolders..>
			<datafolders...>
			
	Datafolders: Allows you to automate tasks such as setting gender and species when a folder is activated.
	- JSON object without a bracket and , replaced with + or \,
	- Ex: {"sex":6,"spec":3} becomes "sex":6+"spec":3 or "sex":6\,"spec":3
	- You can't use unescaped commas due to the legacy RLV syntax
	- To use a plus literal, use \+
	- Tasks are not case sensitive
	Tasks:
	- sex : (int)sex - Updates sex settings. Bitwise combination. See _core.lsl
	- spec : (str)species - Updates species listing.
	- say : [(int)channel+(str)message] ex "say":[1+"hello"] - Says "hello" on channel 1
	

*/
#define USE_EVENTS
#include "jasx_hud/_core.lsl"

// This is the channel for the LSL API
#define CLOTHING_CHAN 1

// States
list ALL_STATES = ["bits", "underwear", "dressed"]; // From lowest to highest
// Slots including aliases
list ALL_SLOTS = ["[\"head\"]", "[\"arms\"]", "[\"torso\",\"chest\"]", "[\"groin\",\"crotch\"]", "[\"boots\"]"];



// Chat channels
int CHAN_INI;				// Fetches version
int CHAN_CACHE_ROOT;		// Builds an index of the root folders
int CHAN_DIAG;				// Handles user dialogs
int CHAN_DFOLDERS;			// Fetches data folders

// Active group / outfit
str GROUP;
str OUTFIT;



#define ALL_DRESSED 682 // 0b1010101010
#define ALL_UNDERWEAR 341
#define ALL_BITS 0
int SLOTS = ALL_DRESSED;	// 2-bit array of STATE_* consts, in order of SLOT_*, so 0b0000000010 = dressed head, all else nude
#define DEFAULT_SLOTS 

int BFL;
// RLV initialized
#define BFL_INIT 0x1
// Strapon currently worn
#define BFL_STRAPON 0x2

list CACHE_FOLDERS;		// Stores a list of all folders directly under #RLV/JasX

// Schedules a recache of outfits to send to the DB
#define recacheClothes() \
	llOwnerSay("@getinv:jasx="+(string)CHAN_CACHE_ROOT); multiTimer(["OT", 0, 2, FALSE])
// Fetch outfit from db4
#define recacheOutfit() \
	OUTFIT = db4$fget(table$ud, BSUD$outfit)

// Outputs API message
onOutfitChanged( key id ){
	llRegionSayTo(id, 2, "outfits:"+llList2Json(JSON_OBJECT, [ \
        "root", OUTFIT, \
        "slots", SLOTS, \
        "strapon", ((BFL&BFL_STRAPON)>0) \
    ]));
}


// Searches slot folders and returns an index. Useful because SLOTFOLDERS contains aliasing for RLV legacy issues.
int findSlotFolder(string folder){
	
	folder = llToLower(folder);
	
	int i;
	for( ; i < count(ALL_SLOTS); ++i ){
		
		list scan = llJson2List(l2s(ALL_SLOTS, i));
		if( ~llListFindList(scan, (list)folder) )
			return i;
			
	}
	
	return -1;

}
    

	
onEvt(string script, int evt, list data){

    if(script == "jx Bridge"){
        
		// Bridge initialization
        if(evt == evt$SCRIPT_INIT){
		
			multiTimer(["INI", 0, 2, FALSE]);
            llOwnerSay("@versionnum="+(string)CHAN_INI);
            recacheOutfit();
            recacheClothes();
            onOutfitChanged(llGetOwner());
			
        }
        // Bridge folder change
        else if(evt == BridgeEvt$DATA_CHANGED){
		
            setOutfit("");
			outputStatus(llGetOwner());
			
        }
        // Send outfits to websocket
        else if(evt == BridgeEvt$SOCKET_REFRESH)
            recacheClothes();
       
    }
	
}


// Changes the active outfit
setOutfit( string n ){

    string pre = OUTFIT;
    // If n is set, use that
    if( n )
        OUTFIT = n;
    // Otherwise update from shared
    else
        recacheOutfit();
	
    if( pre != OUTFIT )
		llOwnerSay("@detachall:JasX/"+pre+"=force,attachallover:JasX/"+OUTFIT+"/Avatar=force,attachallover:JasX/"+OUTFIT+"/Dressed=force");
	llOwnerSay("@getinv:jasx/"+OUTFIT+"="+(string)CHAN_DFOLDERS);
    onOutfitChanged(llGetOwner());
	
}

setSlotsArray( string outfitState, string outfitSlot, integer on ){

	integer stPos = llListFindList(ALL_STATES, (list)llToLower(outfitState));
	integer slPos = findSlotFolder(outfitSlot);
	if( stPos == -1 || (slPos == -1 && outfitSlot != ""))
		return;
	
	// Change a single slot
	if( ~slPos ){
					
		integer n = 3; // 0b11
		// Remove old value
		SLOTS = SLOTS &~ (n<<(slPos*2));
		if( on ){
		
			// Set new value
			n = stPos;
			SLOTS = SLOTS | (n<<(slPos*2));
			
		}
		
	}
	// Change the whole array
	else{
		
		SLOTS = 0;
		if( stPos && on )
			SLOTS = ALL_UNDERWEAR<<(stPos-1); // ALL_UNDERWEAR = 0b0101010101. ALL_BITS = 0b1010101010 stPos is 1 for underwear and 2 for dressed. So shifting 1 leftworks

	}

}

// Sets an active state and slot on the current outfit
// If slot is "" it toggles the whole state
toggleClothes( string st, string slot ){
    
	st = llToLower(st);
    slot = llToLower(slot);
	// Aliases
    if( st == "fully clothed" )
		st = "dressed";
    if( slot == "chest" )
		slot = "torso";
	
	list states = (list)st;			// Needs to be a list due to state aliases
	int pos = findSlotFolder(slot);	// Convert the slot name to an index corresponding to SLOT_* const
	if( ~pos )						// If found, convert it to a list of aliases
		states = llJson2List(l2s(ALL_SLOTS, pos));
		
	// Batch into a single command that adds and removes
    list on; list off; integer i;
	for(; i < count(states); ++i ){
	
		string targState = l2s(states, i);
		integer statePos = llListFindList(ALL_STATES, (list)targState);					// Turns state into an index in STATE_*
		
		on += "attachallover:JasX/"+OUTFIT+"/"+targState+"/"+slot;						// if slot is empty, this attaches the whole state
		on += "getinv:jasx/"+OUTFIT+"/"+targState+"/"+slot+"="+(str)CHAN_DFOLDERS; 		// Get datafolders
		
		// If slot is empty (we're changing an entire state), we'll also need to get datafolders from ALL slots of the state
		if( slot == "" ){
			
			list subTasks;
			integer a;
			for(; a < count(ALL_SLOTS); ++a ){
			
				list aliases = llJson2List(l2s(ALL_SLOTS, a));
				integer al;
				for(; al < count(aliases); ++al )
					subTasks += "getinv:jasx/"+OUTFIT+"/"+targState+"/"+l2s(aliases, al)+"="+(str)CHAN_DFOLDERS;
				
			}
			llOwnerSay("@"+llDumpList2String(subTasks, ","));
			
		}
		
		// Detach all other states (and slots if applicable)
		integer k;
		for(; k < count(ALL_SLOTS); ++k ){
		
			string v = l2s(ALL_SLOTS, k);
			if( v != targState )
				off+="detachall:JasX/"+OUTFIT+"/"+v+"/"+slot;
				
		}
		
	}
    
	setSlotsArray(st, slot, TRUE);
    
    //multiTimer([TIMER_REPEAT, on+"=force", 2, FALSE]);
    llOwnerSay("@"+implode("=force,", off)+"=force,"+implode("=force,", on)+"=force");
    
    onOutfitChanged(llGetOwner());
}

openDialog(){

	str vis = "PRIVATE";
	if( (int)userData(BSUD$hud_flags) & HUDFLAG_PINGABLE )
		vis = "PUBLIC";
		
	string text = "
[Visibility] "+vis+"

-- LINKS --
	[http:\/\/jasx.org/#hud/ JasX.org]
	[https:\/\/goo.gl/AkC1Ug API/Bugs]
	[https:\/\/bit.ly/3aeYAdU Outfit Help] By Drau

-- COMMANDS -- 
Either /0 or /1:
	jasx.setoutfit <name> - Set outfit
	jasx.setclothes dressed/underwear/bits - Outfit state
	
-- Buttons --
	Log In - Browser Login
	Dressed/Underwear/Bits - Set clothing
	Pass Reset - Reset password
	Visibility - Others can ping your HUD to see sex/avatar status
";
	
	list buttons = ["Dressed", "Underwear", "Bits", "Visibility", "Log In", "Pass Reset"];
	
	llDialog(llGetOwner(), text, buttons, CHAN_DIAG);
}

outputStatus( key target ){

	str species = userData(BSUD$species);
	int sex = (int)userData(BSUD$sex);
	int flags = (int)userData(BSUD$hud_flags);
	int id = (int)userData(BSUD$id);
	int lfp = (int)userData(BSUD$last_lfp) > 0;
	str flist = userData(BSUD$flist);
	int rp = (int)userData(BSUD$roleplay_status);
	list pairs = (list)
		"sex" + sex +
		"species" + species +
		"lfp" + lfp +
		"flist" + flist +
		"rp" + rp
	;
	
	if( llGetOwnerKey(target) == llGetOwner() )
		pairs += (list)"id" + id;
	
	// Note: This should be designed to be parsed as a JSON array by adding [] to the ends
	llSetObjectDesc((str)sex+","+(str)species+","+(str)flags);
	
	llRegionSayTo(
		target, 
		2, 
		"settings:"+llList2Json(JSON_OBJECT, pairs)
	);
	
}

timerEvent(string id, string data){
	if(id == "OT")
		Bridge$updateClothes();
	else if(id == "INI"){
		
		int d = (int)data;
		if(d > 5)
			llDialog(llGetOwner(), 
				"\nError: RLV Not found! To enable RLV, please follow these steps:\n"+
				"1. Use a supported third party viewer, such as [https://www.firestormviewer.org/downloads/ Firestorm Viewer].\n"+
				"2. Go into preferences (ctrl+p) > Firestorm tab > Extras Tab > Allow Remote Scripted Viewer Controls (RLVa).\n"+
				"3. Restart your viewer."
			, [], 17);
		else{
		
			multiTimer([id, d+1, 10, FALSE]);
			llOwnerSay("@versionnum="+(string)CHAN_INI);
			
		}
		
	}
}

integer iniListen;

default{

    state_entry(){
	
		int c = llCeil(llFrand(0xFFFFFF));
        CHAN_INI = c;
        CHAN_CACHE_ROOT = c+1;
		CHAN_DIAG = c+2;
		CHAN_DFOLDERS = c+3;
		
        
        // These are channels for the user
        llListen(0, "", llGetOwner(), "");
        llListen(CLOTHING_CHAN, "", "", ""); 
        
        // These are channels for RLV
        iniListen = llListen(CHAN_INI, "", llGetOwner(), "");       	// RLV initialization
        llListen(CHAN_CACHE_ROOT, "", llGetOwner(), "");   	// Folder data fetch
        llListen(CHAN_DIAG, "", llGetOwner(), "");   	// Dialog popup
        llListen(CHAN_DFOLDERS, "", llGetOwner(), "");   	// Dialog popup
        
        // Fetch from root if possible
        recacheOutfit();
		
    }
    
	timer(){ multiTimer([]); }
	
    listen( int chan, string name, key id, string message ){
		
		int byOwner = llGetOwnerKey(id) == llGetOwner();
		int hudFlags = (int)userData(BSUD$hud_flags);
		
		if(
			!byOwner &&
			// Only allow non-owner if
			(
				// Not pingable
				~hudFlags&HUDFLAG_PINGABLE || 
				// Or chan is not CLOTHING_CHAN. More checks below
				chan != CLOTHING_CHAN
			)
		)return;
		
		        
		if(chan == CHAN_DIAG){
			
			if( message == "Log In" )
				Bridge$login();
				
			else if( message == "Pass Reset" ){
				
				llOwnerSay("Generating a new password");
				Bridge$resetPass();
				
			}
			else if( ~llListFindList(["Dressed","Underwear","Bits"], [message]) )
				toggleClothes(message, "");
			
			else if( message == "Visibility" ){
			
				if( hudFlags & HUDFLAG_PINGABLE )
					hudFlags = hudFlags &~HUDFLAG_PINGABLE;
				else
					hudFlags = hudFlags | HUDFLAG_PINGABLE;
				Bridge$setHudFlags(hudFlags);
				
			}
				
			
		}
		
        // Inventory channel
        if( chan == CHAN_CACHE_ROOT ){
		
            // Folders fetched
            CACHE_FOLDERS = llCSV2List(message);
            
            // Cycle folders and remove invalid options
            int i;
            for( ; i<count(CACHE_FOLDERS); ++i ){
			
                string val = llStringTrim(l2s(CACHE_FOLDERS, i), STRING_TRIM);
                if( llToLower(val) == "onattach" || val == "" ){
				
                    CACHE_FOLDERS = llDeleteSubList(CACHE_FOLDERS, i, i);
                    i--;
					
                }
				
            }
			
            multiTimer(["OT"]);
			db4$freplace(table$rlv, table$rlv$folders, mkarr(CACHE_FOLDERS));
			
            Bridge$updateClothes();
			return;
			
        }
		
		// Handles vars from folder names to set things like species and sex
		if( chan == CHAN_DFOLDERS ){
		
			int sex = -1;
			int spec = -1;
			
			string esc = llChar(10);
			list split = explode(",",implode(esc, explode("\\,", message)));
						
			integer fidx;
			for(; fidx < count(split); ++fidx ){
				string val = l2s(split, fidx);
								
				val = implode(",",explode(esc, val));
				
				string obj;
				if( llGetSubString(val, 0, 0) == "\"" )
					obj = "{"+val+"}";
					
				// DEPRECATION CONVERSION
				if( llGetSubString(val, 0, 0) == "$" ){
					
					obj = "{";
					llOwnerSay("Warning: $ syntax in JasX folders has been deprecated. It now uses a JSON object without the brackets, and using + instead of commas.");
					list v = llDeleteSubList(explode("$", val), 0, 0);
					int i; string json;
					for(; i < count(v); ++i ){
						
						list setting = explode("=", l2s(v, i));
						str ty = llToLower(l2s(setting, 0));
						if( ty == "sex" )
							obj += "\"sex\":" + l2s(setting, 1) + "+";
						else if( ty == "spec" || ty == "species" )
							obj += "\"spec\":" + l2s(setting, 1) + "+";
					
					}
					obj = llDeleteSubString(obj, -1,-1);
					obj += "}";
					if( llStringLength(obj) > 2 )
						llOwnerSay("Suggestion: Rename folder: "+val+" to: "+implode("&",explode(",",llGetSubString(obj, 1, -2))));
					
				}

				if( obj ){
										
					obj = implode(esc, explode("\\+", obj));
					obj = implode(",",explode("+", obj));
					
					list tasks = llJson2List(obj);
					integer i;
					for(; i < count(tasks); i += 2 ){
						
						string ty = l2s(tasks, i);
						string val = implode("+", explode(esc, l2s(tasks, i+1)));
						// Todo: Run htmlspecialcahrs?
						
						if( ty == "sex" )
							sex = (int)val;
						else if( ty == "spec" || ty == "species" )
							spec = (int)val;
						else if( ty == "say" )
							llRegionSay((int)j(val,0), j(val, 1));
						
					}
					
				}
								
			}
			
			
			
			if( sex > -1 ){
			
				sex = sex&GENITALS_ALL;
				Bridge$setSex(sex);
				
			}
			
			if( spec > -1 && spec < 4 )
				Bridge$setSpecies(spec);
		
		}
        
        
        // User/Script inputs
        if( chan == CLOTHING_CHAN || chan == 0 ){
		
            // Parse the message jasx.<method> <arg0>, <arg1>...
            list split = llParseString2List(message, [".", " "], []);
            
            // Type should be jasx (case insensitive)
            str type = llToLower(l2s(split,0));
            if( llToLower(type) != "jasx" )
                return;
            
            
            // Method is variable
            str method = llToLower(l2s(split,1)); 
            message = llGetSubString(message, llStringLength(type+"."+method), -1);
            
            // Params contain the rest of the params
            list params = llCSV2List(message);

            // Owner only. Sets a current subfolder, ex: dressed/groin
            if( method == "setclothes" && byOwner ){
			
                list struct = llParseString2List(l2s(params,0), ["/"], []);
                str root = trim(l2s(struct,0));
                str sub = trim(l2s(struct,1));
                toggleClothes(root, sub);
				
            }
			// Owner only. Toggles a non built in subfolder
			else if( method == "setcustom" && byOwner ){
			
				str folder = l2s(params, 0);
				int on = l2i(params, 1);
				if( on )
					llOwnerSay("@attachallover:JasX/"+OUTFIT+"/"+folder+"=force");
				else
					llOwnerSay("@detachall:JasX/"+OUTFIT+"/"+folder+"=force");
				
			}
            
            // Owner only. Toggles the strapon
            else if( method == "setstrapon" && byOwner ){
			
                int on = l2i(params,0);
                if( on ){
                    
					BFL = BFL|BFL_STRAPON;
                    llOwnerSay("@attachallover:JasX/"+OUTFIT+"/Strapon=force");
					
                }
                else{
				
                    BFL = BFL&~BFL_STRAPON;
                    llOwnerSay("@detachall:JasX/"+OUTFIT+"/Strapon=force");
					
                }
                onOutfitChanged(llGetOwner());
				
            }
            
            // Owner only. Set the root outfit
            else if( method == "setoutfit" && byOwner ){
			
				list split = llParseString2List(l2s(params, 0), [], ["{", "}", "\""]);
				if( count(split) > 1 ){
				
					llDialog(llGetOwner(), "ERROR: Do not use special chars in outfit names", [], 3773);
					return;
					
				}
				
                Bridge$setFolder(l2s(params,0));
                setOutfit(l2s(params, 0));
                onOutfitChanged(llGetOwner());
				
            }
            
            // Owner only. Toggle an onattach folder
            else if( method == "onattach" && byOwner ){
			
                string game = l2s(params,0);
                int on = l2i(params,1);
                if( on )
					llOwnerSay("@attachallover:JasX/onAttach/"+game+"=force");
                else 
					llOwnerSay("@detachall:JasX/onAttach/"+game+"=force");
                
                if( on )
                    llRegionSayTo(llGetOwner(), 2, "gameattached:"+llList2Json(JSON_OBJECT, [
                        "game", llToLower(game)
                    ]));
					
            }
            
            // Owner only. Reset password
            else if( method == "resetpass" && byOwner )
                Bridge$resetPass();
				
            // Owner only. Reset the HUD.
            else if( method == "reset" && byOwner ){
                
				qd("Resetting JasX HUD");
                resetAll();
				
            }
            
            // Owner only. Changes sex
            else if( method == "sex" && byOwner )
                Bridge$setSex(l2i(params, 0));
            
            // Public. Force a settings update
            else if( method == "settings" )			
				outputStatus(id);
				
            // Owner only. Changes species
            else if( method == "species" && byOwner )
                Bridge$setSpecies(l2i(params, 0));
            // Public. Get output info.
            else if( method == "getoutfitinfo" )
                onOutfitChanged(id);
            // Owner only. Update f-list character
            else if( method == "flist" && byOwner )
                Bridge$setFlist(l2s(params, 0));
            
            return;
			
        } 
        
        if( chan == CHAN_INI ){
			 
				
			multiTimer(["INI"]);
			if( ~BFL&BFL_INIT ){
				
				if( (int)message >= 2000000 ){
				
					BFL = BFL|BFL_INIT;
					llOwnerSay("RLV successfully initialized");
					llListenRemove(iniListen);
					
				}
				else if((int)message)
					llOwnerSay("WARNING: Your RLV seems to be outdated, please update.");
				
			}
		
		}
		
    }
    
    
// This is the standard linkmessages
    #include "xobj_core/_LM.lsl" 
    /*
        Included in all these calls:
        METHOD - (int)method  
        PARAMS - (var)parameters 
        SENDER_SCRIPT - (var)parameters
        CB - The callback you specified when you sent a task 
    */ 
    
    if( method$isCallback )
		return;
    
	if( method$internal ){
	
        if( METHOD == RLVMethod$setClothes ){
		
            toggleClothes(method_arg(0), method_arg(1));
			
		}
			
        else if( METHOD == RLVMethod$recacheFolders ){
		
            recacheClothes();
		
		}
		else if( METHOD == RLVMethod$dialog ){
			
			openDialog();
			
		}
		
    }
    
// End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl" 
}
