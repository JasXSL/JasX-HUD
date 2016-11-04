#define SCRIPT_IS_ROOT
#include "jasx_hud/_core.lsl"

integer BFL;
#define BFL_BROWSER_OPEN 0x1

integer P_BUTTON;
integer P_BROWSER;
integer P_CONF;
vector BROWSER_POS = <0.516400, 0.064820, 0.633541>;


toggleBrowser(integer show){
    vector pos = BROWSER_POS;
    if(!show){
        // Store position on close if open
        if(BFL&BFL_BROWSER_OPEN)
            BROWSER_POS = l2v(llGetLinkPrimitiveParams(P_BROWSER, [PRIM_POS_LOCAL]), 0);
        pos = <0.516400,0.064820,-1>;
        BFL = BFL&~BFL_BROWSER_OPEN;
    }
    else
        BFL = BFL|BFL_BROWSER_OPEN;
    
    llSetLinkPrimitiveParamsFast(P_BROWSER, [PRIM_POSITION, pos]);
}

default
{
    
    // Restart on change
    changed(integer change){
        if(change&CHANGED_OWNER){
            llDialog(llGetOwner(), "Since the JasX HUD is now open source, please take a moment to verify that you received this HUD from secondlife:///app/agent/cf2625ff-b1e9-4478-8e6b-b954abde056b/about : Do not accept HUDs from people you don't trust.", [], 3267);
            llResetScript();
        }
    }
    
    state_entry()
    {
        links_each(nr, name,
            if(name == "BUTTON")
                P_BUTTON = nr;
            else if(name == "BROWSER")
                P_BROWSER = nr;
			else if(name == "CONF")
				P_CONF = nr;
        )
                
        // Hide
        toggleBrowser(FALSE);
        
		// Build a DB schema
		list tables = [
			"jx RLV",
			"jx Bridge"
		];
		db3$addTables(tables);
		
        llSetLinkMedia(P_BROWSER, 1, [
            PRIM_MEDIA_AUTO_PLAY, TRUE,
            PRIM_MEDIA_CONTROLS, PRIM_MEDIA_CONTROLS_MINI,
            PRIM_MEDIA_FIRST_CLICK_INTERACT, TRUE,
            PRIM_MEDIA_HEIGHT_PIXELS, 1024,
            PRIM_MEDIA_WIDTH_PIXELS, 1024,
            PRIM_MEDIA_CURRENT_URL, "http://jasx.org",
            PRIM_MEDIA_HOME_URL, "http://jasx.org",
            PRIM_MEDIA_PERMS_CONTROL, PRIM_MEDIA_PERM_OWNER,
            PRIM_MEDIA_PERMS_INTERACT, PRIM_MEDIA_PERM_OWNER
        ]);
		
		memLim(1.5);
    }
    
    touch_start(integer total){
        detOwnerCheck
        
        integer ln = llDetectedLinkNumber(0);
        integer face = llDetectedTouchFace(0);
        
        if(ln == P_BUTTON)
            toggleBrowser(~BFL&BFL_BROWSER_OPEN);
        
        if(ln == P_BROWSER && (
            face == 3 || face == 2
        ))
            toggleBrowser(FALSE);
        if(ln == P_CONF)
			RLV$dialog();
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
    
    // Here's where you receive callbacks from running methods
	if(method$isCallback){
		// DB tables created
		if(id == "" && SENDER_SCRIPT == "#ROOT" && METHOD == stdMethod$setShared){
			resetAllOthers();
		}
        return;
    }
    
    
    
    
    // End link message code
    #define LM_BOTTOM  
    #include "xobj_core/_LM.lsl"  
    
}
