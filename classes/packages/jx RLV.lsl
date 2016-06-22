#define USE_EVENTS
#include "jasx_hud/_core.lsl"

// Channel to listen on
#define CLOTHING_CHAN 1

// Top folders
#define SUBFOLDERS ["dressed", "underwear", "bits"]

// Subfolders
#define SLOTFOLDERS ["head", "arms", "torso", "groin", "boots"]

// Equipment slots
#define SLOT_HEAD 0
#define SLOT_ARMS 1
#define SLOT_TORSO 2
#define SLOT_GROIN 3
#define SLOT_BOOTS 4

// Not sure why I need 2 channels?
integer CHAN;
integer INV_CHAN;

// Active folder from config
string rootfolder;
// Sub folder, Dressed, Bits etc
string equipped_root;

list equipped_slots_dressed = [1,1,1,1,1];
list equipped_slots_underwear = [0,0,0,0,0];
list equipped_slots_bits = [0,0,0,0,0];

// Contains a list of all available folders
list available_folders;

integer BFL;
// RLV initialized
#define BFL_INIT 1
// Strapon currently worn
#define BFL_STRAPON 2


// Fetch clothing
#define recacheClothes() llOwnerSay("@getinv:jasx="+(string)INV_CHAN)
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
    
    
    
    
onEvt(string script, integer evt, list data){

    if(script == "jx Bridge"){
        // Bridge initialization
        if(evt == evt$SCRIPT_INIT){
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
        
    if(pre == rootfolder)return;
            
    llOwnerSay("@detachall:JasX/"+pre+"=force,attachallover:JasX/"+rootfolder+"/Avatar=force,attachallover:JasX/"+rootfolder+"/Dressed=force");
    onOutfitChanged();
}




// Toggle a folder within a slot (data only)
toggleSlot(string folder, integer slot){
    folder = llToLower(folder);
    list sf = SUBFOLDERS;
    integer a = llListFindList(sf, [folder]);
    if(a == -1)return;
    
    list f = [
        llList2Json(JSON_ARRAY, equipped_slots_dressed),
        llList2Json(JSON_ARRAY, equipped_slots_underwear),
        llList2Json(JSON_ARRAY, equipped_slots_bits)
    ];
    integer i;
    for(i=0; i<llGetListLength(f); i++){
        list bits = llJson2List(llList2String(f,i));
        
        if(i == a){
            if(slot == -1)bits = [1,1,1,1,1];
            else bits = llListReplaceList(bits, [1], slot, slot);
        }else{
            if(slot == -1)bits = [0,0,0,0,0];
            else bits = llListReplaceList(bits, [0], slot, slot);
        }
        f = llListReplaceList(f, [llList2Json(JSON_ARRAY, bits)], i, i);
    }
    equipped_slots_dressed = llJson2List(llList2String(f, 0));
    equipped_slots_underwear = llJson2List(llList2String(f, 1));
    equipped_slots_bits = llJson2List(llList2String(f, 2));
}

// Output current outfit in an RLV command
toggleClothes(string root, string sub){
    root = llToLower(root);
    sub = llToLower(sub);
    if(root == "fully clothed")root = "dressed";
    if(sub == "chest")sub = "torso";
    
    string on = "attachallover:JasX/"+rootfolder+"/"+root+"/";
    list off;
    list sf = SUBFOLDERS;
    
    
    list_each(sf, k, v, {
        if(v != root)off+="detachall:JasX/"+rootfolder+"/"+v+"/";
    });
                    
    if(isset(sub)){
        on += sub;
        list_each(off, k, v, {
            off=llListReplaceList(off, [v+sub], k, k);
        });
        
    }
    
    toggleSlot(root, llListFindList(SLOTFOLDERS, [sub]));
    
    //multiTimer([TIMER_REPEAT, on+"=force", 2, FALSE]);
    llOwnerSay("@"+implode("=force,", off)+"=force,"+on+"=force");
    
    onOutfitChanged();
}



default
{
    state_entry()
    {
        CHAN = llCeil(llFrand(0xFFFFFF));
        INV_CHAN = llCeil(llFrand(0xFFFFFF));
        
        // These are channels for the user
        llListen(0, "", llGetOwner(), "");
        llListen(CLOTHING_CHAN, "", "", ""); 
        
        // These are channels for RLV
        llListen(CHAN, "", llGetOwner(), "");       // RLV initialization
        llListen(INV_CHAN, "", llGetOwner(), "");   // Folder data fetch
        
        // Fetch from root if possible
        getRootFolder();
    }
    
    listen(integer chan, string name, key id, string message){
        idOwnerCheck
        
        // Inventory channel
        if(chan == INV_CHAN){
            // Folders fetched
            available_folders = llCSV2List(message);
            
            // Cycle folders and remove invalid options
            integer i;
            for(i=0; i<count(available_folders); i++){
                string val = llStringTrim(l2s(available_folders, i), STRING_TRIM);
                if(llToLower(val) == "onattach" || val == ""){
                    available_folders = llDeleteSubList(available_folders, i, i);
                    i--;
                }
            }
            
            db3$set([RLVShared$RLV_FOLDERS], llList2Json(JSON_ARRAY, available_folders));
            Bridge$updateClothes(available_folders);
        }
        
        
        // User/Script inputs
        if(chan == CLOTHING_CHAN || chan == 0){
            // Parse the message jasx.<method> <arg0>, <arg1>...
            list split = llParseString2List(message, [".", " "], []);
            
            // Type should be jasx (case insensitive)
            string type = llToLower(llList2String(split,0));
            if(llToLower(type) != "jasx")
                return;
            
            
            // Method is variable
            string method = llToLower(llList2String(split,1)); 
            message = llGetSubString(message, llStringLength(type+"."+method), -1);
            
            // Params contain the rest of the params
            list params = llCSV2List(message);

            // Sets a current subfolder, ex: dressed/groin
            if(method == "setclothes"){
                list struct = llParseString2List(llList2String(params,0), ["/"], []);
                string root = trim(llList2String(struct,0));
                string sub = trim(llList2String(struct,1));
                toggleClothes(root, sub);
            }
            
            // Toggles the strapon
            else if(method == "setstrapon"){
                integer on = llList2Integer(params,0);
                if(on){
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
            else if(method == "setoutfit"){
                Bridge$setFolder(llList2String(params,0));
                setRootFolder(l2s(params, 0));
                onOutfitChanged();
            }
            
            // Toggle an onattach folder
            else if(method == "onattach"){
                string game = llList2String(params,0);
                integer on = llList2Integer(params,1);
                if(on)llOwnerSay("@attachallover:JasX/onAttach/"+game+"=force");
                else llOwnerSay("@detachall:JasX/onAttach/"+game+"=force");
                
                if(on)
                    llRegionSayTo(llGetOwner(), 2, "gameattached:"+llList2Json(JSON_OBJECT, [
                        "game", llToLower(game)
                    ]));
            }
            
            // Toggle a specific folder without affecting another. Lets you take off underwear of one folder without replacing it with another for an instance.
            else if(method == "togglefolder"){
                string folder = llList2String(params,0);
                integer on = llList2Integer(params,1);
                    
                    
                if(on)llOwnerSay("@attachallover:JasX/"+rootfolder+"/"+folder+"=force");
                else llOwnerSay("@detachall:JasX/"+rootfolder+"/"+folder+"=force");
                
                list split = explode("/", folder);
                string root = llToLower(llList2String(split,0));
                string sub = llToLower(llList2String(split,1));
                list SF = SUBFOLDERS;
                
                integer rp = llListFindList(SF, [root]);
                if(rp == -1)return;
                if(sub == ""){
                    if(rp == 0)equipped_slots_dressed = [on,on,on,on,on];
                    else if(rp == 1)equipped_slots_underwear = [on,on,on,on,on];
                    else if(rp == 2)equipped_slots_bits = [on,on,on,on,on];
                    else return;
                }else{
                    list SLF = SLOTFOLDERS;
                    integer sp = llListFindList(SLF, [sub]);
                    if(rp == 0)equipped_slots_dressed = llListReplaceList(equipped_slots_dressed, [on], sp, sp);
                    else if(rp == 1)equipped_slots_underwear = llListReplaceList(equipped_slots_underwear, [on], sp, sp);
                    else if(rp == 2)equipped_slots_bits = llListReplaceList(equipped_slots_bits, [on], sp, sp);
                    else return;
                }
                onOutfitChanged();
            
            }
            
            // Reset password
            else if(method == "resetpass"){
                Bridge$resetPass();
            }
            
            else if(method == "reset"){
                qd("Resetting JasX HUD");
                resetAll();
            }
            
            // Changes sex
            else if(method == "sex")
                Bridge$setSex(llList2Integer(params, 0));
            
            // Force a settings update
            else if(method == "settings")
                Bridge$outputStatus();
            
            // Changes species
            else if(method == "species")
                Bridge$setSpecies(llList2Integer(params, 0));
                
            // Changes outfit info    
            else if(method == "getoutfitinfo")
                onOutfitChanged();
            
            else if(method == "flist")
                Bridge$setFlist(l2s(params, 0));
            
            return;
        } 
        
        if(chan != CHAN)return; 
        if(~BFL&BFL_INIT){
            if((integer)message >= 2000000){
                BFL = BFL|BFL_INIT;
                llOwnerSay("RLV successfully initialized");
            }else if((integer)message){
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
    
    if(method$isCallback)return;
    if(method$internal){
        if(METHOD == RLVMethod$setClothes)
            toggleClothes(method_arg(0), method_arg(1));
        else if(METHOD == RLVMethod$recacheFolders)
            recacheClothes();
    }
    
// End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl" 
}
