#include <cstrike>
#include <colors>
#include <sourcemod>
#include <autoexecconfig>
#include <myjailbreak>

//Compiler Options
#pragma semicolon 1
#pragma newdecls required

//ConVars
ConVar gc_bPlugin;
ConVar gc_sAdminFlag;

//Bools
bool IsMuted[MAXPLAYERS+1] = {false, ...};

//Strings
char g_sAdminFlag[32];

public Plugin myinfo = {
	name = "MyJailbreak - Mute all Terrorists",
	author = "shanapu",
	description = "Mute all terrorists while round run except admins or on EventDay",
	version = "1.0",
	url = "shanapu.de"
};

public void OnPluginStart()
{
	AutoExecConfig_SetFile("MuteAllT", "MyJailbreak");
	AutoExecConfig_SetCreateFile(true);
	
	gc_bPlugin = AutoExecConfig_CreateConVar("sm_mute_t_enable", "1", "0 - disabled, 1 - enable this MyJailbreak SourceMod plugin", _, true,  0.0, true, 1.0);
	gc_sAdminFlag = AutoExecConfig_CreateConVar("sm_mute_t_flag", "b", "Set flag for admin/vip to immune to mute.");
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	//Hooks
	HookEvent("round_poststart", RoundStart);
	HookEvent("round_end", RoundEnd);
	HookEvent("player_team", EventPlayerTeam);
	HookConVarChange(gc_sAdminFlag, OnSettingChanged);
	
	//FindConVar
	gc_sAdminFlag.GetString(g_sAdminFlag , sizeof(g_sAdminFlag));
}

//ConVarChange for Strings

public int OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if(convar == gc_sAdminFlag)
	{
		strcopy(g_sAdminFlag, sizeof(g_sAdminFlag), newValue);
	}
}

//Round start

public void RoundStart(Handle event, char[] name, bool dontBroadcast)
{
	if(gc_bPlugin.BoolValue)
	{
		LoopValidClients(i,false,true) if(GetClientTeam(i) == CS_TEAM_T)
			MuteClient(i);
	}
}

//Round End

public void RoundEnd(Handle event, char[] name, bool dontBroadcast)
{
	if(gc_bPlugin.BoolValue)
	{
		LoopValidClients(i,false,true) if(GetClientTeam(i) == CS_TEAM_T)
			UnMuteClient(i);
	}
}

//Player Disconnect

public void OnClientDisconnect(int client)
{
	if(gc_bPlugin.BoolValue) UnMuteClient(client);
}


//Player change team
public Action EventPlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	if(gc_bPlugin.BoolValue)
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(GetClientTeam(client) == CS_TEAM_CT) UnMuteClient(client);
		if(GetClientTeam(client) == CS_TEAM_T) MuteClient(client);
	}
}

public Action MuteClient(int client)
{
	if(IsValidClient(client,true,true) && !CheckVipFlag(client,g_sAdminFlag))
	{
		char EventDay[64];
		GetEventDay(EventDay);
		
		if(StrEqual(EventDay, "none", false))
		{
			SetClientListeningFlags(client, VOICE_MUTED);
			IsMuted[client] = true;
		}
	}
}

public int UnMuteClient(any client)
{
	if(IsValidClient(client,true,true) && IsMuted[client])
	{
		SetClientListeningFlags(client, VOICE_NORMAL);
		IsMuted[client] = false;
	}
}
