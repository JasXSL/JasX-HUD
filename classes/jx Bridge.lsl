#define BridgeMethod$setFolder 1						// (str)folder - Sets active folder 
#define BridgeMethod$createAccountFromText 2			// (str)name
#define BridgeMethod$linkAccount 3						// (str)name
#define BridgeMethod$updateClothes 4					// clothes - Updates socket with a list of RLV folders. Args are said folders
#define BridgeMethod$resetPass 5						// void
#define BridgeMethod$login 6							// void - Fetches a new login token and updates the prim media 
#define BridgeMethod$outputStatus 10 					// void - Output status to plugins
#define BridgeMethod$setSex 11							// (int)sex
#define BridgeMethod$setSpecies 12						// (int)species 
#define BridgeMethod$setFlist 13						// (str)character

// Rem MRES 


#define Bridge$createAccountFromText(name) runMethod((string)LINK_ROOT, "jx Bridge", BridgeMethod$createAccountFromText, [name], TNN)
#define Bridge$linkAccount(name) runMethod((string)LINK_ROOT, "jx Bridge", BridgeMethod$linkAccount, [name], TNN)
#define Bridge$resetPass() runMethod((string)LINK_ROOT, "jx Bridge", BridgeMethod$resetPass, [], TNN)
#define Bridge$outputStatus() runMethod((string)LINK_ROOT, "jx Bridge", BridgeMethod$outputStatus, [], TNN)
#define Bridge$updateClothes(folders) runMethod((string)LINK_ROOT, "jx Bridge", BridgeMethod$updateClothes, folders, TNN)
#define Bridge$setFolder(folder) runMethod((string)LINK_ROOT, "jx Bridge", BridgeMethod$setFolder, [folder], TNN)
#define Bridge$setSex(sex) runMethod((string)LINK_ROOT, "jx Bridge", BridgeMethod$setSex, [sex], TNN)
#define Bridge$setSpecies(species) runMethod((string)LINK_ROOT, "jx Bridge", BridgeMethod$setSpecies, [species], TNN)
#define Bridge$setFlist(character) runMethod((string)LINK_ROOT, "jx Bridge", BridgeMethod$setFlist, [character], TNN)
#define Bridge$login() runMethod((str)LINK_ROOT, "jx Bridge", BridgeMethod$login, [], TNN)

#define BridgeEvt$SOCKET_REFRESH 1	// void - Requests subscribts to send socket data
#define BridgeEvt$DATA_CHANGED 2	// void - Userdata has changed

#define BridgeShared$USER_DATA "a"	//


#define userData() db3$get("jx Bridge", ([BridgeShared$USER_DATA])) 
	
#define BridgeShared$HUD_ALERTS "b"	// Contains a JSON object with the following keys and an integer
	#define BSHA$inventory "inv"
	#define BSHA$messages "msg"
	#define BSHA$events "evt"
	#define BSHA$plugins "plg"
	#define BSHA$lfp "lfp"
	
#define alertsData(data) ((integer)db2$get("jx Bridge", ([BridgeShared$HUD_ALERTS, data])))
	
	
	
#define LFP_SPECIES ["Undefined", "Human", "Anime", "Furry", "Other"]
#define LFP_PENIS 1
#define LFP_VAGINA 2
#define LFP_BREASTS 4

// Helper functions
	// Get nr unread notices
	#define getAlerts() (integer)llListStatistics(LIST_STAT_SUM, llList2ListStrided(llDeleteSubList(llJson2List(llJsonSetValue(db2$get("jx Bridge", [BridgeShared$HUD_ALERTS]), [BSHA$lfp], JSON_DELETE)), 0, 0), 0, -1, 2))
