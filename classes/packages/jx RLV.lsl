#define USE_EVENTS
#include "jasx_hud/_core.lsl"

// Channel to listen on
#define CLOTHING_CHAN 1

// Top folders
#define SUBFOLDERS ["dressed", "underwear", "bits"]

// Subfolders
#define SLOTFOLDERS ["head", "arms", "[\"torso\",\"chest\"]", "[\"groin\",\"crotch\"]", "boots"]

// Equipment slots
#define SLOT_HEAD 0
#define SLOT_ARMS 1
#define SLOT_TORSO 2
#define SLOT_GROIN 3
#define SLOT_BOOTS 4

// Not sure why I need 2 channels?
int CHAN;
int INV_CHAN;
int DIAG_CHAN;
int NOTECARD_CHAN;

// Active folder from config
string rootfolder;
// Sub folder, Dressed, Bits etc
string equipped_root;

list equipped_slots_dressed = [1,1,1,1,1];
list equipped_slots_underwear = [0,0,0,0,0];
list equipped_slots_bits = [0,0,0,0,0];

// Contains a list of all available folders
list available_folders;

int BFL;
// RLV initialized
#define BFL_INIT 1
// Strapon currently worn
#define BFL_STRAPON 2


// Fetch clothing
#define recacheClothes() llOwnerSay("@getinv:jasx="+(string)INV_CHAN); multiTimer(["OT", 0, 2, FALSE])
#define getRootFolder() rootfolder = db3$get("jx Bridge", ([BridgeShared$USER_DATA, "outfit"]))
// Outputs API message
#define onOutfitChanged() \
    llRegionSayTo(llGetOwner(), 2, "outfits:"+llList2Json(JSON_OBJECT, [ \
        "root", rootfolder, \
        "dressed", llList2Json(JSON_ARRAY, equipped_slots_dressed), \
        "underwear", llList2Json(JSON_ARRAY, equipped_slots_underwear), \
        "bits", llList2Json(JSON_ARRAY, equipped_slots_bits), \
        "strapon", ((BFL&BFL_STRAPON)>0) \
    ]))
    

// Searches slot folders and returns an index	
int findSlotFolder(string folder){
	
	list sf = SLOTFOLDERS;
	folder = llToLower(folder);
	
	int i;
	for(i=0; i<count(sf); ++i){
		
		list scan = [l2s(sf, i)];
		if(llJsonValueType(l2s(sf, i), []) == JSON_ARRAY)
			scan = llJson2List(l2s(sf, i));
			
		if(~llListFindList(scan, [folder]))
			return i;
	}
	
	return -1;

}
    
onEvt(string script, int evt, list data){

    if(script == "jx Bridge"){
        
		// Bridge initialization
        if(evt == evt$SCRIPT_INIT){
		
			multiTimer(["INI", 0, 2, FALSE]);
            llOwnerSay("@versionnum="+(string)CHAN);
            getRootFolder();
            recacheClothes();
            onOutfitChanged();
			
        }
        
        // Bridge folder change
        else if(evt == BridgeEvt$DATA_CHANGED){
            setRootFolder("");
        }
        
        // Send outfits to websocket
        else if(evt == BridgeEvt$SOCKET_REFRESH){
            recacheClothes();
        }
        
    }
}


// Changes the root folder
setRootFolder(string n){

    string pre = rootfolder;
    // If n is set, use that
    if(n)
        rootfolder = n;
    // Otherwise update from shared
    else
        getRootFolder();
	
    if(pre == rootfolder)
		return;
            
	
    llOwnerSay("@detachall:JasX/"+pre+"=force,attachallover:JasX/"+rootfolder+"/Avatar=force,attachallover:JasX/"+rootfolder+"/Dressed=force");
	llOwnerSay("@getinv:jasx/"+rootfolder+"="+(string)NOTECARD_CHAN);
    onOutfitChanged();
	
}




// Toggle a folder within a slot (data only)
toggleSlot(string folder, int slot){
    folder = llToLower(folder);
    list sf = SUBFOLDERS;
    int a = llListFindList(sf, [folder]);
    if(a == -1)return;
    
    list f = [
        llList2Json(JSON_ARRAY, equipped_slots_dressed),
        llList2Json(JSON_ARRAY, equipped_slots_underwear),
        llList2Json(JSON_ARRAY, equipped_slots_bits)
    ];
    int i;
    for(i=0; i<llGetListLength(f); i++){
        list bits = llJson2List(l2s(f,i));
        
        if(i == a){
            if(slot == -1)bits = [1,1,1,1,1];
            else bits = llListReplaceList(bits, [1], slot, slot);
        }else{
            if(slot == -1)bits = [0,0,0,0,0];
            else bits = llListReplaceList(bits, [0], slot, slot);
        }
        f = llListReplaceList(f, [llList2Json(JSON_ARRAY, bits)], i, i);
    }
    equipped_slots_dressed = llJson2List(l2s(f, 0));
    equipped_slots_underwear = llJson2List(l2s(f, 1));
    equipped_slots_bits = llJson2List(l2s(f, 2));
}

// Output current outfit in an RLV command
toggleClothes(string root, string sub){
    root = llToLower(root);
    sub = llToLower(sub);
    if(root == "fully clothed")root = "dressed";
    if(sub == "chest")sub = "torso";
	
	
	list sf = SUBFOLDERS;
	list slotf = SLOTFOLDERS;
	list subs = [sub];
	int pos = findSlotFolder(sub);
	
	if(~pos){
		string s = l2s(slotf, pos);
		if(llJsonValueType(s, []) == JSON_ARRAY){
			subs = llJson2List(s);
		}
	}

    list on;
    list off;
    
    
    
	list_shift_each(subs, s,
		on += "attachallover:JasX/"+rootfolder+"/"+root+"/"+s;
		
		list_each(sf, k, v, 
			if(v != root)
				off+="detachall:JasX/"+rootfolder+"/"+v+"/"+s;
		)
	)
    
    toggleSlot(root, pos);
    
    //multiTimer([TIMER_REPEAT, on+"=force", 2, FALSE]);
    llOwnerSay("@"+implode("=force,", off)+"=force,"+implode("=force,", on)+"=force");
    
    onOutfitChanged();
}

openDialog(){
	string text = "
-- LINKS --
	[http:\/\/jasx.org/#hud/ Main Website @ JasX.org]
	[https:\/\/goo.gl/AkC1Ug API & Issues @ Github]
	[https:\/\/bit.ly/3aeYAdU Outfit Setup for Beginners] By Drau

-- CHAT COMMANDS -- 
Either channel 0 or /1:
	jasx.setoutfit <name> - Set outfit
	jasx.setclothes dressed/underwear/bits - Outfit state
	
-- Buttons --
	Log In - Logs you into the prim media
	Dressed/Underwear/Bits - Set clothing state
	Pass Reset - Generates a new pass";
	list buttons = ["Dressed", "Underwear", "Bits","Log In", "Pass Reset"];
	
	llDialog(llGetOwner(), text, buttons, DIAG_CHAN);
}

timerEvent(string id, string data){
	if(id == "OT")
		Bridge$updateClothes(available_folders);
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
			llOwnerSay("@versionnum="+(string)CHAN);
			
		}
		
	}
}

default{

    state_entry(){
	
		int c = llCeil(llFrand(0xFFFFFF));
        CHAN = c;
        INV_CHAN = c+1;
		DIAG_CHAN = c+2;
		NOTECARD_CHAN = c+3;		// Channel for fetching notecard vars
		
        
        // These are channels for the user
        llListen(0, "", llGetOwner(), "");
        llListen(CLOTHING_CHAN, "", "", ""); 
        
        // These are channels for RLV
        llListen(CHAN, "", llGetOwner(), "");       	// RLV initialization
        llListen(INV_CHAN, "", llGetOwner(), "");   	// Folder data fetch
        llListen(DIAG_CHAN, "", llGetOwner(), "");   	// Dialog popup
        llListen(NOTECARD_CHAN, "", llGetOwner(), "");   	// Dialog popup
        
        // Fetch from root if possible
        getRootFolder();
		
    }
    
	timer(){ multiTimer([]); }
	
    listen( int chan, string name, key id, string message ){
        idOwnerCheck
        
		if(chan == DIAG_CHAN){
			
			if( message == "Log In" )
				Bridge$login();
				
			else if( message == "Pass Reset" ){
				
				llOwnerSay("Genereting a new password");
				Bridge$resetPass();
				
			}
			else if( ~llListFindList(["Dressed","Underwear","Bits"], [message]) )
				toggleClothes(message, "");
			
			
		}
		
        // Inventory channel
        if( chan == INV_CHAN ){
		
            // Folders fetched
            available_folders = llCSV2List(message);
            
            // Cycle folders and remove invalid options
            int i;
            for( ; i<count(available_folders); ++i ){
			
                string val = llStringTrim(l2s(available_folders, i), STRING_TRIM);
                if( llToLower(val) == "onattach" || val == "" ){
				
                    available_folders = llDeleteSubList(available_folders, i, i);
                    i--;
					
                }
				
            }
			
            multiTimer(["OT"]);
            db3$set([RLVShared$RLV_FOLDERS], llList2Json(JSON_ARRAY, available_folders));
            Bridge$updateClothes(available_folders);
			return;
			
        }
		
		// Handles setting folders
		if( chan == NOTECARD_CHAN ){
		
			int sex = -1;
			int spec = -1;
			
			list split = explode(",", message);
			list_shift_each(split, val,
				
				if( llGetSubString(val, 0, 0) == "$" ){
					
					list v = llDeleteSubList(explode("$", val), 0, 0);
					int i;
					for(; i < count(v); ++i ){
						
						list setting = explode("=", l2s(v, i));
						str ty = llToLower(l2s(setting, 0));
						if( ty == "sex" )
							sex = l2i(setting, 1);
						else if( ty == "spec" || ty == "species" )
							spec = l2i(setting, 1);
					
					}
					
				}
				
			)
			
			
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
            if(llToLower(type) != "jasx")
                return;
            
            
            // Method is variable
            str method = llToLower(l2s(split,1)); 
            message = llGetSubString(message, llStringLength(type+"."+method), -1);
            
            // Params contain the rest of the params
            list params = llCSV2List(message);

            // Sets a current subfolder, ex: dressed/groin
            if( method == "setclothes" ){
			
                list struct = llParseString2List(l2s(params,0), ["/"], []);
                str root = trim(l2s(struct,0));
                str sub = trim(l2s(struct,1));
                toggleClothes(root, sub);
				
            }
			
			else if( method == "setcustom" ){
			
				str folder = l2s(params, 0);
				int on = l2i(params, 1);
				if( on )
					llOwnerSay("@attachallover:JasX/"+rootfolder+"/"+folder+"=force");
				else
					llOwnerSay("@detachall:JasX/"+rootfolder+"/"+folder+"=force");
				
			}
            
            // Toggles the strapon
            else if( method == "setstrapon" ){
			
                int on = l2i(params,0);
                if( on ){
                    BFL = BFL|BFL_STRAPON;
                    llOwnerSay("@attachallover:JasX/"+rootfolder+"/Strapon=force");
                }
                else{
                    BFL = BFL&~BFL_STRAPON;
                    llOwnerSay("@detachall:JasX/"+rootfolder+"/Strapon=force");
                }
                onOutfitChanged();
				
            }
            
            // Set the root outfit
            else if( method == "setoutfit" ){
			
				list split = llParseString2List(l2s(params, 0), [], ["{", "}"]);
				if( count(split) > 1 ){
				
					llDialog(llGetOwner(), "ERROR: You cannot use curly brackets {} in outfit names due to an LSL bug: https://jira.secondlife.com/browse/BUG-6495", [], 3773);
					return;
					
				}
				
                Bridge$setFolder(l2s(params,0));
                setRootFolder(l2s(params, 0));
                onOutfitChanged();
				
            }
            
            // Toggle an onattach folder
            else if( method == "onattach" ){
			
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
            
            // Toggle a specific folder without affecting another. Lets you take off underwear of one folder without replacing it with another for an instance.
            else if( method == "togglefolder" ){
			
                str folder = l2s(params,0);
                int on = l2i(params,1);
                    
                    
                if( on )
					llOwnerSay("@attachallover:JasX/"+rootfolder+"/"+folder+"=force");
                else 
					llOwnerSay("@detachall:JasX/"+rootfolder+"/"+folder+"=force");
                
                list split = explode("/", folder);
                str root = llToLower(l2s(split,0));
                str sub = llToLower(l2s(split,1));
                list SF = SUBFOLDERS;
                
                int rp = llListFindList(SF, [root]);
                if( rp == -1 )
					return;
					
                if( sub == "" ){
				
                    if( rp == 0 )
						equipped_slots_dressed = [on,on,on,on,on];
                    else if( rp == 1 )
						equipped_slots_underwear = [on,on,on,on,on];
                    else if( rp == 2 )
						equipped_slots_bits = [on,on,on,on,on];
                    else 
						return;
						
                }else{
				
                    int sp = findSlotFolder(sub);
                    if( rp == 0 )
						equipped_slots_dressed = llListReplaceList(equipped_slots_dressed, [on], sp, sp);
                    else if( rp == 1 )
						equipped_slots_underwear = llListReplaceList(equipped_slots_underwear, [on], sp, sp);
                    else if( rp == 2 )
						equipped_slots_bits = llListReplaceList(equipped_slots_bits, [on], sp, sp);
                    else 
						return;
						
                }
                onOutfitChanged();
            
            }
            
            // Reset password
            else if( method == "resetpass" )
                Bridge$resetPass();
            
            else if( method == "reset" ){
                
				qd("Resetting JasX HUD");
                resetAll();
				
            }
            
            // Changes sex
            else if( method == "sex" )
                Bridge$setSex(l2i(params, 0));
            
            // Force a settings update
            else if( method == "settings" )
                Bridge$outputStatus();
            
            // Changes species
            else if( method == "species" )
                Bridge$setSpecies(l2i(params, 0));
                
            // Changes outfit info    
            else if( method == "getoutfitinfo" )
                onOutfitChanged();
            
            else if( method == "flist" )
                Bridge$setFlist(l2s(params, 0));
            
            return;
        } 
        
        if( chan != CHAN )
			return; 
		multiTimer(["INI"]);
        if( ~BFL&BFL_INIT ){
			
            if( (int)message >= 2000000 ){
			
                BFL = BFL|BFL_INIT;
                llOwnerSay("RLV successfully initialized");
				
            }
			else if((int)message)
                llOwnerSay("WARNING: Your RLV seems to be outdated, please update.");
            
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
    
    if(method$isCallback)return;
    if(method$internal){
        if(METHOD == RLVMethod$setClothes)
            toggleClothes(method_arg(0), method_arg(1));
        else if(METHOD == RLVMethod$recacheFolders){
            recacheClothes();
		}
		else if(METHOD == RLVMethod$dialog){
			openDialog();
		}
    }
    
// End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl" 
}
