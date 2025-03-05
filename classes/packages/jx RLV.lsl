/*	
	Folder structure:
	#RLV/JasX
		::Group:: A group combines multiple outfits into one. The only real use for groups is for players with so many outfits that RLV breaks
		<+group> - To mark a folder as a group, start the name of the folder with +
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
		<outfit> - An outfit is the old and easiest behavior. One outfit, one avatar.
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
list ALL_SLOTS = ["head", "arms", "torso", "crotch", "boots"];
list OLD_SLOTS = ["chest","groin"]; // Todo: Should warn if it detects these


// Chat channels
int CHAN_INI;				// Fetches version
int CHAN_CACHE_ROOT;		// Builds an index of the root folders
int CHAN_CACHE_GROUP;		// Builds an index of a group
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

// Performs a refresh of the JasX HUD RLV folder cache
#define snapshotRoot() \
	{cGROUPS = []; cRootListen = llListen(CHAN_CACHE_ROOT, "", llGetOwner(), ""); llOwnerSay("@getinv:jasx="+(string)CHAN_CACHE_ROOT);}
#define snapshotGroup(group) \
	{cGroupListen = llListen(CHAN_CACHE_GROUP, "", llGetOwner(), ""); llOwnerSay("@getinv:JasX/"+(str)(group)+"="+(string)CHAN_CACHE_GROUP);}

// Fetch outfit from db4
#define recacheOutfit() \
	OUTFIT = userData(BSUD$outfit)
#define recacheGroup() \
	GROUP = userData(BSUD$outfit_group)

// Returns true if changed
bool setSpecies( str species ){
	
	species = llStringTrim(species, STRING_TRIM);
	if( userData(BSUD$species) == species )
		return FALSE;
		
	if( species == "" ){
		llOwnerSay("Unable to update species: Name empty.");
		return FALSE;
	}
	string test = llToUpper(species);
	if( llStringLength(test) > 20 ){
		llOwnerSay("Unable to set species: Name can be max 20 characters.");
		return FALSE;
	}
	
	
	
	integer i;
	for(; i < llStringLength(test); ++i ){
		integer ord = llOrd(test, i);
		integer accept = 
			ord == 32 || // Space
			ord == 45 || // Dash
			(ord >= 48 && ord <= 57) || // Numbers
			(ord >= 65 && ord <= 90)	// Upper case
		;
		if( !accept ){
			llOwnerSay("Unable to set species: Name can only contain alphanumeric characters, spaces, and dashes.");
			return FALSE;
		}
	}
	
	
	setUserData(BSUD$species, species);
	Bridge$setSpecies(species);
	outputStatus(llGetOwner());
	return TRUE;
	
}

getDataFolders( list paths ){
	
	list cmds;
	integer i;
	for(; i < count(paths); ++i )
		cmds += ("getinv:"+l2s(paths, i)+"="+(str)CHAN_DFOLDERS);
	llOwnerSay("@"+llDumpList2String(cmds, ","));
	
}

// Gets datafolder paths for all slots of group/outfit/state
list getDataFoldersSlotsPaths( string g, string o, string s ){
	
	list paths; integer i;
	for(; i < count(ALL_SLOTS); ++i )
		paths += path(g, o, s, l2s(ALL_SLOTS, i));
	return paths;
	
}

// Outputs API message
outputOutfitState( key id ){
	llRegionSayTo(id, 2, "outfits:"+llList2Json(JSON_OBJECT, [ \
        "root", OUTFIT, \
        "slots", SLOTS, \
        "strapon", ((BFL&BFL_STRAPON)>0) \
    ]));
}

// Takes a group, outfit, state, slot and generates a path
string path( string g, string o, string st, string sl ){
	list out;
	// Group is optional
	if( g )
		out += g;
	if( o )
		out += o;				// Outfit is optional, though should always be used unless you're only setting a group
	if( st != "" && o != "" )  // State relies on outfit being present
		out += st;
	if( sl != "" && st != "" && o != "" ) // Slot is optional but requires the above
		out += sl;
	return "JasX/"+llDumpList2String(out, "/");
}

list cGROUPS;	// Groups found under RLV/JasX to cache
cacheNextGroup(){
	
	// No more folders to cache
	if( !count(cGROUPS) ){
		llListenRemove(cGroupListen);
		return;
	}
	snapshotGroup(l2s(cGROUPS, 0));
	
}
	
onEvt(string script, int evt, list data){

    if(script == "jx Bridge"){
        
		// Bridge initialization
        if( evt == evt$SCRIPT_INIT ){
			
			BFL = BFL&~BFL_INIT;
			multiTimer(["INI", 0, 2, FALSE]);
			iniListen = llListen(CHAN_INI, "", llGetOwner(), "");       	// RLV initialization
            llOwnerSay("@versionnum="+(string)CHAN_INI);
			recacheOutfit();
			recacheGroup();
            outputOutfitState(llGetOwner());
			
        }
        // Bridge folder change
        else if(evt == BridgeEvt$DATA_CHANGED){
		
			string outfit = userData(BSUD$outfit);
			string group = userData(BSUD$outfit_group);
			
			integer ofChange = OUTFIT != outfit;
			integer grChange = GROUP != group;
			if( grChange )
				setGroup(group, !ofChange);
			if( ofChange )
				setOutfit(outfit);
				
			outputStatus(llGetOwner());
			
        }
        // Send outfits to websocket
        else if( evt == BridgeEvt$OUTFIT_REFRESH ){
            snapshotRoot();
		}
		// Folders directly under #RLV/JasX have been set. Now cache the groups
		else if( evt == BridgeEvt$RLV_GROUPS_SET ){
			cacheNextGroup();
		}
	   
    }
	
	
}

// setDefaultOutfit will also call setOutfit("default") - Can be turned off if you're setting bhoth group and outfit at the same time
setGroup( string g, integer setDefaultOutfit ){
	
	string pre = GROUP;
	GROUP = g;

	
	// If no group was set, an outfit will be root, in which case it needs to be removed
	if( pre == "" )
		pre = OUTFIT;
	// Detach on change. But allow attach always, provided a group is actually set
	if( pre != GROUP )
		llOwnerSay("@detachall:"+path(pre, "", "", "")+"=force");
		
	// Have this script store it in LSD in case bridge is down
	setUserData(BSUD$outfit_group, GROUP);
	
	// If we're actually setting a group, and not a root outfit, we'll need to attach the root avatar and get datafolders
	if( GROUP ){
		
		llOwnerSay("@attachallover:"+path(GROUP, "avatar", "", "")+"=force");
		getDataFolders((list)path(GROUP, "", "", ""));	// The group only needs the group datafolders. setOutfit handles the rest
		
	}
	if( setDefaultOutfit ){
		
		// If we've changed group, we already detached everything above, so by setting OUTFIT to default, it prevents setOutfit from detaching, only doing an attach call.
		// Otherwise this is basically the same as "jasx.setoutfit default"
		if( pre != GROUP )
			OUTFIT = "default";
		setOutfit("default");	// Setting to an existing outfit will force an attach call, but not a detach
		
	}
	// Attempt some extra stag parsing after changing outfit
	multiTimer(["SP0",0,5, FALSE]);
	multiTimer(["SP1",0,10, FALSE]);
	multiTimer(["SP2",0,20, FALSE]);
	
	
}

// Changes the active outfit
setOutfit( string n ){

	if( n == "" )
		return;

    string pre = OUTFIT;
    OUTFIT = n;

	
	// Store it in LSD in case bridge is down
	setUserData(BSUD$outfit, OUTFIT);
	
	// Detach old unless it's the same
    if( pre != OUTFIT )
		llOwnerSay("@detachall:"+path(GROUP, pre, "", "")+"=force");
	// Force attach everything again
	llOwnerSay("@attachallover:"+path(GROUP, OUTFIT, "avatar", "")+"=force,attachallover:"+path(GROUP, OUTFIT, "dressed", "")+"=force");
	
	// Any folder and subfolder involved in this attach needs to check data folders
	getDataFolders((list)
		path(GROUP, OUTFIT, "", "") +
		path(GROUP, OUTFIT, "avatar", "") +
		path(GROUP, OUTFIT, "dressed", "") +
		getDataFoldersSlotsPaths(GROUP, OUTFIT, "dressed")
	);
	outputOutfitState(llGetOwner());
	
}

setSlotsArray( string outfitState, string outfitSlot, integer on ){

	integer stPos = llListFindList(ALL_STATES, (list)llToLower(outfitState));
	integer slPos = llListFindList(ALL_SLOTS, (list)outfitSlot);
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
setState( string st, string slot ){
    
	st = llToLower(st);
    slot = llToLower(slot);
	// Old projects may be trying to set the old folders. We'll have to convert them into the modern slots.
	if( slot == "groin" )
		slot = "crotch";
	else if( slot == "chest" )
		slot = "torso";
		
	if( st == "fully clothed" )
		st = "dressed";
		
	int slotIdx = llListFindList(ALL_SLOTS, (list)slot);	// Convert the slot name to an index corresponding to SLOT_* const
	integer stateIdx = llListFindList(ALL_STATES, (list)st);					// Turns state into an index in STATE_*
	// Invalid state/slot
	if( stateIdx == -1 ){
		llOwnerSay("Trying to set invalid state: "+st);
		return;
	}
	if( slotIdx == -1 && slot != "" ){
		llOwnerSay("Trying to set invalid slot: "+slot);
		return;
	}
	
	// Batch into a single command that adds and removes
    list on; list off; 	
	list dFolderPaths; // Paths to changed datafolders
	
	
	on += "attachallover:"+path(GROUP, OUTFIT, st, slot);						// if slot is empty, this attaches the whole state
	dFolderPaths += path(GROUP, OUTFIT, st, slot); 		// Datafolder of the particular slot that changed, or st if slot is empty
	
	// If slot is empty (we're changing an entire state), we'll also need to get datafolders from ALL slots of the state
	if( slot == "" )
		dFolderPaths += getDataFoldersSlotsPaths(GROUP, OUTFIT, st);
	
	// Figure out what to detach
	integer k;
	for(; k < count(ALL_STATES); ++k ){
		
		// We don't need to touch anything in the activated state. So start by filtering that out.
		if( stateIdx != k ){
			
			string tState = l2s(ALL_STATES, k); // State we want to remove from
			off += "detachall:"+path(GROUP, OUTFIT, tState, slot);	// If slot is empty, this will remove the whole state. Otherwise it removes the slot
			
		}
			
	}
	
		
	setSlotsArray(st, slot, TRUE);
    
    //multiTimer([TIMER_REPEAT, on+"=force", 2, FALSE]);
    llOwnerSay("@"+implode("=force,", off)+"=force,"+implode("=force,", on)+"=force");
    getDataFolders(dFolderPaths);
	
    outputOutfitState(llGetOwner());
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
	
	string out = mkarr((list)
		sex + species + flags + SLOTS
	);
	// Note: This should be designed to be parsed as a JSON array by adding [] to the ends
	llSetObjectDesc(llGetSubString(out, 1, -2));
	
	llRegionSayTo(
		target, 
		2, 
		"settings:"+llList2Json(JSON_OBJECT, pairs)
	);
	
}

// Sets sex by a label or integer
setSex( string sex ){
	
	integer out = (int)sex;
	sex = llToLower(sex);
	
	// Preset labels when setting sex by text
	list labels = [
		"female", GENITALS_VAGINA|GENITALS_BREASTS,
		"male", GENITALS_PENIS,
		"herm", GENITALS_ALL,
		"cuntboy", GENITALS_VAGINA,
		"c-boy", GENITALS_VAGINA,
		"andromorph", GENITALS_VAGINA,
		"muffin man", GENITALS_VAGINA,
		"shemale", GENITALS_BREASTS|GENITALS_PENIS,
		"futa", GENITALS_BREASTS|GENITALS_PENIS,
		"dickgirl", GENITALS_BREASTS|GENITALS_PENIS
	];
	int pos = llListFindList(labels, (list)sex);
	if( ~pos )
		out = l2i(labels, pos+1);
	
	setGenitals(out);

}

// Returns true on success 
bool setFlist( string flist ){
	
	if( flist == userData(BSUD$flist) )
		return FALSE;
	setUserData(BSUD$flist, flist);	
	Bridge$setFlist(flist);
	return TRUE;
	
}

// Returns true on success
bool setGenitals( integer sex ){
	
	if( (int)userData(BSUD$sex) == sex )
		return FALSE;
		
	sex = sex&GENITALS_ALL;
	Bridge$setSex(sex);
	setUserData(BSUD$sex, sex);
	return TRUE;
	
}

timerEvent( string id, string data ){

	if( id == "INI" ){
		
		int d = (int)data;
		if( d > 5 )
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
	else if( id == "GR" ){
		cacheNextGroup();
	}
	else if( llGetSubString(id, 0, 1) == "SP" )
		stagParse();
	
}

integer iniListen;
integer cRootListen;
integer cGroupListen;

stagParse(){
	
	string flist;
	string species;
	integer sex;
	
	list all = sTagAv( llGetOwner(), "", [], 0);
	integer i = count(all);
	while( i-- ){
		
		list val = explode("_", l2s(all, i));
		string label = l2s(val, 0);
		val = llDeleteSubList(val, 0, 0);
		if( label == "spec" )
			species = implode("_", val);
		else if( label == "bits" ){
			string sub = llGetSubString(l2s(val, 0), 0, 0);
			sex = sex|((sub=="p")*GENITALS_PENIS);
			sex = sex|((sub=="v")*GENITALS_VAGINA);
			sex = sex|((sub=="b")*GENITALS_BREASTS);				
		}
		else if( label == "flist" )
			flist = implode("_", val);
		
	}
	
	integer ch;
	if( species )
		ch += setSpecies(species);
	if( sex )
		ch += setGenitals(sex);
	if( flist )
		ch += setFlist(flist);
	if( ch )
		outputStatus(llGetOwner());
	
}

default{

    state_entry(){
	
		int c = llCeil(llFrand(0xFFFFFF));
        CHAN_INI = c;
        CHAN_CACHE_ROOT = c+1;
		CHAN_DFOLDERS = c+3;
		CHAN_CACHE_GROUP = c+4;
		
        
        // These are channels for the user
        llListen(0, "", llGetOwner(), "");
        llListen(CLOTHING_CHAN, "", "", ""); 
        
        // These are listeners for code
        llListen(CHAN_DFOLDERS, "", llGetOwner(), "");
        
        // Fetch from root if possible
        recacheOutfit();
		recacheGroup();
		outputStatus(llGetOwner());
		multiTimer(["SP", 0, 30, TRUE]);
		stagParse();
		
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
		
		
		// Caches the root folders (folders directly under #RLV/JasX)
        if( chan == CHAN_CACHE_ROOT || chan == CHAN_CACHE_GROUP ){
		
            // Folders fetched
            list folders = llCSV2List(message);
            list valid;
			
            int i;
            for( ; i<count(folders); ++i ){
			
                string val = llStringTrim(l2s(folders, i), STRING_TRIM);
				
				list split = llParseString2List(val, [], [
					// Invalid characters
					"{", "}", "&", "[", "]"
				]);
				if( count(split) > 1 )
					llOwnerSay("Error: Outfit "+val+" was ignored. Do not use special characters in your outfits.");
				// Additional filters
                else if( 
					llToLower(val) != "onattach" && 	// Ignore onAttach
					llToLower(val) != "avatar" &&		// Ignore avatar folder (needed for group)
					val != "" && 						// Ignore empty
					llGetSubString(val, 0, 0) != "\"" 	// Ignore datafolder
				){
					valid += val;
					if( llGetSubString(val, 0, 0) == RLVConst$GROUP_INDICATOR && chan == CHAN_CACHE_ROOT )
						cGROUPS += val;
				}
            }
			
			if( chan == CHAN_CACHE_ROOT ){
				db4$freplace(table$rlv, table$rlv$folders, mkarr(valid));
				Bridge$updateClothes();
				llListenRemove(cRootListen);
			}
			else{
				string group = l2s(cGROUPS, 0);
				cGROUPS = llDeleteSubList(cGROUPS, 0, 0);
				Bridge$updateGroup(group, valid);
				multiTimer(["GR", 0, 0.5, FALSE]);	// Max 2 groups per sec to prevent overflow
			}
            
			return;
			
        }
		
		// Handles vars from folder names to set things like species and sex
		if( chan == CHAN_DFOLDERS ){
		
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

						if( ty == "sex" )
							setSex(val);
						else if( ty == "spec" || ty == "species" ){
							setSpecies(val);
						}
						else if( ty == "say" )
							llRegionSay((int)j(val,0), j(val, 1));
						else if( ty == "flist" )
							setFlist(val);
						
					}
					
				}
								
			}

		
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
                setState(root, sub);
				
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
                    llOwnerSay("@attachallover:"+path(GROUP, OUTFIT, "strapon", "")+"=force");
					
                }
                else{
				
                    BFL = BFL&~BFL_STRAPON;
					llOwnerSay("@detachall:"+path(GROUP, OUTFIT, "strapon", "")+"=force");
					
                }
                outputOutfitState(llGetOwner());
				
            }
            
			// Reload oufits
			else if( method == "outfits" && byOwner ){
				
				llOwnerSay("Recaching outfits...");
				snapshotRoot();
			
			}
			
            // Owner only. Set the root outfit
            else if( method == "setoutfit" && byOwner ){
			
				// Setting both outfit and group
				// Starting with underscore means we're setting a group (and optionally an outfit
				string outfit = llStringTrim(l2s(params, 0), STRING_TRIM);
				if( llGetSubString(outfit, 0, 0) == RLVConst$GROUP_INDICATOR || llGetSubString(outfit, 0, 0) == "/" ){
				
					split = explode("/", l2s(params, 0));
					outfit = l2s(split, 1);
					str group = l2s(split, 0);
					if( group == RLVConst$GROUP_INDICATOR )
						group = "";
					setGroup(group, outfit == "");
					
				}
				
				if( outfit )
					setOutfit(outfit);
				Bridge$setFolder(OUTFIT, GROUP); // Outfit first for legacy reasons (HTTP request expects group second)
                outputOutfitState(llGetOwner());
				
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
                
				llOwnerSay("Resetting JasX HUD to factory default");
				llLinksetDataReset();
                resetAll();
				
            }
            
            // Owner only. Changes sex
            else if( method == "sex" && byOwner )
                setSex(l2s(params, 0));
            
            // Public. Force a settings update
            else if( method == "settings" )			
				outputStatus(id);
				
            // Owner only. Changes species
            else if( method == "species" && byOwner ){
                setSpecies(l2s(params, 0));
			}
            // Public. Get output info.
            else if( method == "getoutfitinfo" )
                outputOutfitState(id);
            // Owner only. Update f-list character
            else if( method == "flist" && byOwner )
                setFlist(l2s(params, 0));
            
            return;
			
        } 
        
        if( chan == CHAN_INI ){

			if( ~BFL&BFL_INIT ){
			
				multiTimer(["INI"]);
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
    if( method$isCallback )
		return;
    if( !method$byOwner )
		return;

	if( METHOD == RLVMethod$setClothes )
		setState(method_arg(0), method_arg(1));
	else if( METHOD == RLVMethod$refreshStag )
		stagParse();
	
    
// End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl" 
}
