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
#define BridgeMethod$toggleLFP 14						// (bool)on
#define BridgeMethod$setPage 15							// (str)page, (var)arg1, arg2... - Loads a page in open JasX website browsers
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
#define Bridge$toggleLFP(on) runMethod((str)LINK_ROOT, "jx Bridge", BridgeMethod$toggleLFP, [on], TNN)
#define Bridge$setPage(page, args) runMethod((str)LINK_ROOT, "jx Bridge", BridgeMethod$setPage, [page]+args, TNN)



#define BridgeEvt$SOCKET_REFRESH 1	// void - Requests subscribts to send socket data
#define BridgeEvt$DATA_CHANGED 2	// void - Userdata has changed
#define BridgeEvt$lfpPlayers 3		// (int)nrPlayers - Nr players currently looking for group

#define BridgeShared$USER_DATA "a"	//
	#define BSUD$id "id"							// int - JasX USER ID
	#define BSUD$username "username"				// str - HTML Encoded username
	#define BSUD$accountstatus "accountstatus" 		// int - Account privileges, default 1
	#define BSUD$signupdate "signupdate"			// int - Unix timestamp of when the user signed up
	#define BSUD$avatar "avatar"					// str - HTML encoded file name of user's avatar
	#define BSUD$fullname "fullname"				// str - URL version of the user
	#define BSUD$bitflags "bitflags"				// int - Settings
	#define BSUD$last_lfp "last_lfp"				// int - Unix timestamp of the last LFP ping
	#define BSUD$sex "sex"							// int - Bitflags for sex, 1 = penis, 2 = vag, 4 = breasts
	#define BSUD$species "species"					// int - Avatar type
	#define BSUD$lfp_for "lfp_for"					// array - Games you're looking for players for
	#define BSUD$games_owned "games_owned"			// array - ids of games you own
	#define BSUD$charname "charname"				// str - SL name
	#define BSUD$currenttitle "currenttitle"		// int - ID of active title
	#define BSUD$flist "flist"						// str - html escaped version of your f-list character
	#define BSUD$outfit "outfit"					// str - Current outfit worn
	#define BSUD$spname "spname"					// str - name of avatar type
	#define BSUD$roleplay_status "roleplay_status" 	// int - Type of roleplay you're looking for in LFP

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
