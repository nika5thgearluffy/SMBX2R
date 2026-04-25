--------------
-- Profiler --
--------------

do
	ffi.cdef([[
		typedef struct
		{
			uint32_t totalWorking;
			uint32_t imgRawMem;
			uint32_t imgCompMem;
			uint32_t sndMem;
			double   imgGpuMem;
		} LunaLuaMemUsageData;
		const LunaLuaMemUsageData* LunaLuaGetMemUsage();

		const float* FFI_GetFrameTimes();
	]])
	local LunaDLL = ffi.load("LunaDll.dll")
	
	Misc.GetMemUsage = function()
		local data = LunaDLL.LunaLuaGetMemUsage()
		return {
			totalWorking = data.totalWorking,
			imgRawMem    = data.imgRawMem,
			imgCompMem   = data.imgCompMem,
			sndMem       = data.sndMem,
			imgGpuMem    = data.imgGpuMem
		}
	end

	Misc.__GetFrameTimes = function()
		local ptr = LunaDLL.FFI_GetFrameTimes()
		local ret = {}
		for i=0,127 do
			ret[i+1] = ptr[i]
		end
		return ret
	end
end

---------------------------
-- High resolution clock --
---------------------------
do
	ffi.cdef[[
		typedef long            BOOL;
		BOOL QueryPerformanceFrequency(int64_t *lpFrequency);
		BOOL QueryPerformanceCounter(int64_t *lpPerformanceCount);
	]]
	local kernel32 = ffi.load("kernel32.dll")
	
	local function GetPerformanceFrequency()
		local anum = ffi.new("int64_t[1]")
		if kernel32.QueryPerformanceFrequency(anum) == 0 then
			return nil
		end
		return tonumber(anum[0])
	end
	local function GetPerformanceCounter()
		local anum = ffi.new("int64_t[1]")
		if kernel32.QueryPerformanceCounter(anum) == 0 then
			return nil
		end
		return tonumber(anum[0])
	end
	local performanceCounterFreq = GetPerformanceFrequency()
	Misc.clock = function()
		return GetPerformanceCounter() / performanceCounterFreq
	end
end

---------------------
-- Key state array --
---------------------

do
	ffi.cdef([[
		unsigned char* LunaLuaGetKeyStateArray(int keyboardID);
	]])
	local LunaDLL = ffi.load("LunaDll.dll")
	local keyArray = {}
    local toTenNumber = 1
    while toTenNumber < 11 do
        keyArray[toTenNumber] = LunaDLL.LunaLuaGetKeyStateArray(toTenNumber - 1)
        toTenNumber = toTenNumber + 1
        if toTenNumber > 10 then
            break
        end
    end
	
	function Misc.GetKeyState(keyCode, keyboardID, nonBoolean)
        if keyboardID == nil then
            keyboardID = 1
        end
		if (type(keyCode) ~= "number") or (keyCode < 0) or (keyCode > 255) then
			error("Invalid keycode")
		end
        if nonBoolean == nil or not nonBoolean then
            return keyArray[keyboardID][keyCode] ~= 0
        elseif nonBoolean then
            return keyArray[keyboardID][keyCode]
        end
	end
end

--------------
-- GameData --
--------------

do
	ffi.cdef([[
		typedef struct
		{
			int len;
			char data[0];
		} GameDataStruct;
		
		void LunaLuaSetGameData(const char* dataPtr, int dataLen);
		GameDataStruct* LunaLuaGetGameData();
		void LunaLuaFreeReturnedGameData(GameDataStruct* cpy);
	]])
	local LunaDLL = ffi.load("LunaDll.dll")
	
	function Misc.SetRawGameData(v)
		LunaDLL.LunaLuaSetGameData(v, #v)
	end
	
	function Misc.GetRawGameData()
		local ptr = LunaDLL.LunaLuaGetGameData();
		if ptr == nil then
			return ""
		end
		local ret = ffi.string(ptr.data, ptr.len)
		LunaDLL.LunaLuaFreeReturnedGameData(ptr)
		return ret
	end
end

--------------------------------
-- Get controller information --
--------------------------------

do
	ffi.cdef([[
		int LunaLuaGetSelectedControllerPowerLevel(int playerNum);
		typedef struct _StickPos {
			int x;
			int y;
		} StickPos;
		StickPos LunaLuaGetSelectedControllerStickPosition(int playerNum);
		const char* LunaLuaGetSelectedControllerName(int playerNum);
		void LunaLuaRumbleSelectedController(int playerNum, int ms, float strength);
	]])
	local LunaDLL = ffi.load("LunaDll.dll")
	
	function Misc.GetSelectedControllerPowerLevel(playerNum)
		if (playerNum == nil) then
			playerNum = 1
		end
		return LunaDLL.LunaLuaGetSelectedControllerPowerLevel(playerNum)
	end
	
	function Misc.GetSelectedControllerStickPosition(playerNum)
		if (playerNum == nil) then
			playerNum = 1
		end
		local stickPos = LunaDLL.LunaLuaGetSelectedControllerStickPosition(playerNum)
		return stickPos.x/32768, stickPos.y/32768
	end

	function Misc.GetSelectedControllerName(playerNum)
		if (playerNum == nil) then
			playerNum = 1
		end
		local strPtr = LunaDLL.LunaLuaGetSelectedControllerName(playerNum)
		if strPtr == nil then
			return "Unknown"
		end
		return ffi.string(strPtr)
	end
	
	function Misc.RumbleSelectedController(playerNum, ms, strength)
		if (playerNum == nil) then
			playerNum = 1
		end
		if (ms == nil) then
			ms = 1000
		end
		if (strength == nil) then
			strength = 1.0
		end
		if (ms > 0) and (strength > 0) then
			LunaDLL.LunaLuaRumbleSelectedController(playerNum, ms, strength)
		end
	end
end

---------------------
-- Disabling fixes --
---------------------

do
	ffi.cdef([[
		void LunaLuaSetPlayerFilterBounceFix(bool enable);
		void LunaLuaSetPlayerDownwardClipFix(bool enable);
		void LunaLuaSetNPCDownwardClipFix(bool enable);
		void LunaLuaSetNPCCeilingBugFix(bool enable);
		void LunaLuaSetNPCSectionFix(bool enable);
		void LunaLuaSetFenceBugFix(bool enable);
		void LunaLuaSetLinkClowncarFairyFix(bool enable);
		void LunaLuaSetSlideJumpFix(bool enable);
		void LunaLuaSetPowerupPowerdownPositionFix(bool enable);
	]])
	local LunaDLL = ffi.load("LunaDll.dll")

	function Misc.SetPlayerFilterBounceFix(enable)
		if enable then
			enable = true
		else
			enable = false
		end
		LunaDLL.LunaLuaSetPlayerFilterBounceFix(enable)
	end
	
	function Misc.SetPlayerDownwardClipFix(enable)
		if enable then
			enable = true
		else
			enable = false
		end
		LunaDLL.LunaLuaSetPlayerDownwardClipFix(enable)
	end
	
	function Misc.SetNPCDownwardClipFix(enable)
		if enable then
			enable = true
		else
			enable = false
		end
		LunaDLL.LunaLuaSetNPCDownwardClipFix(enable)
	end

	function Misc.SetNPCCeilingBugFix(enable)
		if enable then
			enable = true
		else
			enable = false
		end
		LunaDLL.LunaLuaSetNPCCeilingBugFix(enable)
	end

	function Misc.SetNPCSectionFix(enable)
		if enable then
			enable = true
		else
			enable = false
		end
		LunaDLL.LunaLuaSetNPCSectionFix(enable)
	end

	function Misc.SetLinkClowncarFairyFix(enable)
		if enable then
			enable = true
		else
			enable = false
		end
		LunaDLL.LunaLuaSetLinkClowncarFairyFix(enable)
	end

	function Misc.SetSlideJumpFix(enable)
		if enable then
			enable = true
		else
			enable = false
		end
		LunaDLL.LunaLuaSetSlideJumpFix(enable)
	end

	Misc._fenceFixEnabled = true

	function Misc.SetFenceBugFix(enable)
		if enable then
			enable = true
		else
			enable = false
			for idx = 1, Player.count() do
				local p = Player(idx)

				if p:mem(0x2C, FIELD_DWORD) < 0 then
					p:mem(0x2C, FIELD_DWORD, -1)
				end
			end

			for _, b in BGO.iterate() do
				b.speedX = 0
				b.speedY = 0
			end
		end
		Misc._fenceFixEnabled = enable
		LunaDLL.LunaLuaSetFenceBugFix(enable)
	end

	function Misc.SetPowerupPowerdownPositionFix(enable)
		if enable then
			enable = true
		else
			enable = false
		end
		LunaDLL.LunaLuaSetPowerupPowerdownPositionFix(enable)
	end
end

------------
-- Timing --
------------

do
	ffi.cdef([[
        void LunaLuaSetFrameTiming(double value);
        double LunaLuaGetFrameTiming();
	]])
	local LunaDLL = ffi.load("LunaDll.dll")
	
	local currentNominalTickTimeMs = 15.6
	local currentNominalTps = 1000.0 / currentNominalTickTimeMs
	local currentNominalSpeed = 1.0
	
	local currentTickTimeMs = LunaDLL.LunaLuaGetFrameTiming()
	local currentTps = 1000.0 / currentTickTimeMs
	local currentSpeed = currentNominalTickTimeMs / currentTickTimeMs
	
	--Nominal ticks are the logical speed of the game, only used by lua-side time computations
	function Misc.SetNominalTickDuration(t)
		if (currentNominalTickTimeMs ~= t) then
			if (lunatime ~= nil) and (lunatime._notifyTickDurationChange ~= nil) then
				lunatime._notifyTickDurationChange()
			end
			currentNominalTickTimeMs = t
			currentNominalTps = 1000.0 / t
			currentNominalSpeed = 15.6 / t
			currentSpeed = currentNominalTickTimeMs / t
		end
	end
	local Misc_SetNominalTickDuration = Misc.SetNominalTickDuration
	
	function Misc.GetNominalTickDuration()
		return currentNominalTickTimeMs
	end
	
	function Misc.SetNominaleTPS(tps)
		Misc_SetNominalTickDuration(1000.0 / tps)
	end
	
	function Misc.GetNominalTPS(tps)
		return currentNominalTps
	end
	
	function Misc.SetNominalSpeed(ratio)
		Misc_SetNominalTickDuration(15.6 / ratio)
	end
	
	function Misc.GetNominalSpeed(ratio)
		return currentNominalSpeed
	end
	
	function Misc.SetEngineTickDuration(t, matchNominalRate)
		if (matchNominalRate) then
			Misc_SetNominalTickDuration(t)
		end
		if (currentTickTimeMs ~= t) then
			LunaDLL.LunaLuaSetFrameTiming(t)
			currentTickTimeMs = t
			currentTps = 1000.0 / t
			currentSpeed = currentNominalTickTimeMs / t
		end
		
	end
	local Misc_SetEngineTickDuration = Misc.SetEngineTickDuration
	
	function Misc.GetEngineTickDuration(t)
		return currentTickTimeMs
	end
	
	function Misc.SetEngineTPS(tps, matchNominalRate)
		Misc_SetEngineTickDuration(1000.0 / tps, matchNominalRate)
	end
	
	function Misc.GetEngineTPS(tps)
		return currentTps
	end
	
	function Misc.SetEngineSpeed(ratio, matchNominalRate)
		Misc_SetEngineTickDuration(currentNominalTickTimeMs / ratio, matchNominalRate)
	end
	
	function Misc.GetEngineSpeed(ratio)
		return currentSpeed
	end
end

do
	ffi.cdef([[
		void LunaLuaSetBackgroundRenderFlag(bool val);
	]])
	local LunaDLL = ffi.load("LunaDll.dll")

	function Misc._SetVanillaBackgroundRenderFlag(val)
		LunaDLL.LunaLuaSetBackgroundRenderFlag(val)
	end
end

-----------------------------------
-- Window Title and Icon Setting --
--         mda wuz ere (:<       --
-----------------------------------
do
	ffi.cdef([[
		typedef struct _LunaImageRef LunaImageRef;

		void LunaLuaSetWindowTitle(const char* newName);
		void LunaLuaSetWindowIcon(LunaImageRef* img, int iconType);
        const char* LunaLuaGetWindowTitle();
	]])
	local LunaDLL = ffi.load("LunaDll.dll")
	local getSMBXVersionString = getSMBXVersionString

	function Misc.setWindowTitle(newName)
		if (newName ~= nil) and (type(newName) ~= "string") then
			error("Invalid type for window title.")
		end

		-- Append program name/version so it's clear what this is
		if (newName == nil) or (newName == "") then
			newName = "SMBX2 – (" .. getSMBXVersionString() .. ")"
		end

		-- Originally implemented via C++ side but it's here now
		-- for consistency with setWindowIcon, since it needed it.
		LunaDLL.LunaLuaSetWindowTitle(newName)
	end
    
    --[[function Misc.getWindowTitle()
        return LunaDLL.LunaLuaGetWindowTitle()
    end]]

	function Misc.setWindowIcon(iconImageSmall,iconImageBig)
		if type(iconImageSmall) ~= "LuaImageResource" then
			error("Invalid type for window icon.")
		end

		if iconImageBig == nil then
			-- Only one image, use small for both
			LunaDLL.LunaLuaSetWindowIcon(iconImageSmall._ref,0)
		elseif type(iconImageBig) == "LuaImageResource" then
			-- Two images, use each
			LunaDLL.LunaLuaSetWindowIcon(iconImageSmall._ref,1)
			LunaDLL.LunaLuaSetWindowIcon(iconImageBig._ref,2)
		else
			error("Invalid type for window icon.")
		end
	end
	
	-- Reset default title that includes accurate version
	-- Disabled due to this constantly swapping between titles if the episode has a custom title
	--[[if (getSMBXVersionString ~= nil) then
		Misc.setWindowTitle()
	end]]
end

----------------------------
-- Mouse cursor fanciness --
----------------------------

do
	ffi.cdef([[
		void LunaLuaSetCursor(LunaImageRef* img, uint32_t xHotspot, uint32_t yHotspot);
		void LunaLuaSetCursorHide(void);
		
		struct MousePos
		{
			double x;
			double y;
		};
		struct MousePos LunaLuaGetMousePosition();
	]])
	local LunaDLL = ffi.load("LunaDll.dll")

	function Misc.setCursor(cursor, xHotspot, yHotspot)
		-- Special case for default cursor
		if (cursor == nil) then
			LunaDLL.LunaLuaSetCursor(nil, 0, 0)
			return
		end
		
		-- Special case for no cursor
		if (cursor == false) then
			LunaDLL.LunaLuaSetCursorHide()
			return
		end
		
		if (type(cursor) ~= "LuaImageResource") then
			error("Invalid type for cursor.")
		end
		if type(xHotspot) ~= "number" then
			error("Invalid type for xHotspot")
		end
		if type(yHotspot) ~= "number" then
			error("Invalid type for yHotspot")
		end
		
		LunaDLL.LunaLuaSetCursor(cursor._ref, xHotspot, yHotspot)
	end
	
	function Misc.getCursorPosition()
		local obj = LunaDLL.LunaLuaGetMousePosition()
		return obj.x, obj.y
	end
end

----------------
-- Fullscreen --
----------------

do
	ffi.cdef([[
		void LunaLuaSetFullscreen(bool enable);
		bool LunaLuaIsFullscreen(void);
	]])
	local LunaDLL = ffi.load("LunaDll.dll")

	function Misc.setFullscreen(enable)
		if (type(enable) ~= "boolean") then
			error("Invalid type for enable.")
		end
		
		LunaDLL.LunaLuaSetFullscreen(enable)
	end
	
	function Misc.isFullscreen()
		return LunaDLL.LunaLuaIsFullscreen()
	end
end

-------------------
-- GIF Recording --
-------------------

do
	ffi.cdef([[
		bool LunaLuaIsRecordingGIF();
	]])
	local LunaDLL = ffi.load("LunaDll.dll")

	function Misc.isRecordingGIF()
		return LunaDLL.LunaLuaIsRecordingGIF()
	end
end

------------------
-- Window Scale --
------------------

do
	ffi.cdef([[
		void LunaLuaSetWindowScale(double scale);
        struct WindowSize
        {
            int w;
            int h;
        };
        struct WindowSize LunaLuaGetWindowSize();
	]])
	local LunaDLL = ffi.load("LunaDll.dll")

	function Misc.setWindowScale(scale)
        if (type(scale) ~= "number") then
			error("Invalid type for scale.")
		end

		return LunaDLL.LunaLuaSetWindowScale(scale)
	end

    function Misc.getWindowSize()
        local obj = LunaDLL.LunaLuaGetWindowSize()
		return obj.w, obj.h
	end
end



-----------------------------
-- Extra gameplay settings --
-----------------------------

do
	ffi.cdef([[
		void LunaLuaSetWeakLava(bool value);
		bool LunaLuaGetWeakLava();
	]])
	local LunaDLL = ffi.load("LunaDll.dll")

	function Misc._setWeakLava(value)
		LunaDLL.LunaLuaSetWeakLava(value)
	end
	function Misc._getWeakLava()
		return LunaDLL.LunaLuaGetWeakLava()
	end
end

------------------------
-- Run When Unfocused --
------------------------

do
	ffi.cdef([[
		void LunaLuaRunWhenUnfocused(bool value);
		bool LunaLuaIsRunningWhenUnfocused();
	]])
	local LunaDLL = ffi.load("LunaDll.dll")

	function Misc.setRunWhenUnfocused(enable)
		if (type(enable) ~= "boolean") then
			error("Invalid type for enable.")
		end
		
		LunaDLL.LunaLuaRunWhenUnfocused(enable)
	end
	
	function Misc.isRunningWhenUnfocused()
		return LunaDLL.LunaLuaIsRunningWhenUnfocused()
	end
end

-----------------------------
-- Above 2 Player Movement --
-----------------------------

do
	ffi.cdef([[
		void LunaLuaSetSimilarMovementAbove2Players(bool value);
        bool LunaLuaGetSimilarMovementAbove2Players();
	]])
	local LunaDLL = ffi.load("LunaDll.dll")

	function Misc.setSimilarMovementAbove2Players(enable)
		if (type(enable) ~= "boolean") then
			error("Invalid type for enable.")
		end
		
		LunaDLL.LunaLuaSetSimilarMovementAbove2Players(enable)
	end
	
	function Misc.isMovementAbove2PlayersSimilar()
		return LunaDLL.LunaLuaGetSimilarMovementAbove2Players()
	end
end

-------------
-- Defines --
-------------

do
	ffi.cdef([[
		void LunaLua_Defines__player_grabSideEnabled__set(bool value);
		bool LunaLua_Defines__player_grabSideEnabled__get();
		void LunaLua_Defines__player_grabTopEnabled__set(bool value);
		bool LunaLua_Defines__player_grabTopEnabled__get();
		void LunaLua_Defines__player_grabShellEnabled__set(bool value);
		bool LunaLua_Defines__player_grabShellEnabled__get();
		void LunaLua_Defines__player_link_shieldEnabled__set(bool value);
		bool LunaLua_Defines__player_link_shieldEnabled__get();
		void LunaLua_Defines__player_link_fairyVineEnabled__set(bool value);
		bool LunaLua_Defines__player_link_fairyVineEnabled__get();
		void LunaLua_Defines__pswitch_music__set(bool value);
		bool LunaLua_Defines__pswitch_music__get();
		void LunaLua_Defines__effect_Zoomer_killEffectEnabled__set(bool value);
		bool LunaLua_Defines__effect_Zoomer_killEffectEnabled__get();

		void LunaLua_Defines__effect_NpcToCoin__set(uint8_t value);
		uint8_t LunaLua_Defines__effect_NpcToCoin__get();
		void LunaLua_Defines__sound_NpcToCoin__set(uint8_t value);
		uint8_t LunaLua_Defines__sound_NpcToCoin__get();
		void LunaLua_Defines__npcToCoinValue__set(uint8_t value);
		uint8_t LunaLua_Defines__npcToCoinValue__get();
		void LunaLua_Defines__npcToCoinValueReset__set(uint8_t value);
		uint8_t LunaLua_Defines__npcToCoinValueReset__get();
		void LunaLua_Defines__smb3RouletteScoreValueStar__set(uint32_t value);
		uint32_t LunaLua_Defines__smb3RouletteScoreValueStar__get();
		void LunaLua_Defines__smb3RouletteScoreValueMushroom__set(uint32_t value);
		uint32_t LunaLua_Defines__smb3RouletteScoreValueMushroom__get();
		void LunaLua_Defines__smb3RouletteScoreValueFlower__set(uint32_t value);
		uint32_t LunaLua_Defines__smb3RouletteScoreValueFlower__get();
		void LunaLua_Defines__coinValue__set(uint8_t value);
		uint8_t LunaLua_Defines__coinValue__get();
		void LunaLua_Defines__coin5Value__set(uint8_t value);
		uint8_t LunaLua_Defines__coin5Value__get();
		void LunaLua_Defines__coin20Value__set(uint8_t value);
		uint8_t LunaLua_Defines__coin20Value__get();
		void LunaLua_Defines__block_hit_link_rupeeID1__set(uint16_t value);
		uint16_t LunaLua_Defines__block_hit_link_rupeeID1__get();
		void LunaLua_Defines__block_hit_link_rupeeID2__set(uint16_t value);
		uint16_t LunaLua_Defines__block_hit_link_rupeeID2__get();
		void LunaLua_Defines__block_hit_link_rupeeID3__set(uint16_t value);
		uint16_t LunaLua_Defines__block_hit_link_rupeeID3__get();
		void LunaLua_Defines__kill_drop_link_rupeeID1__set(uint16_t value);
		uint16_t LunaLua_Defines__kill_drop_link_rupeeID1__get();
		void LunaLua_Defines__kill_drop_link_rupeeID2__set(uint16_t value);
		uint16_t LunaLua_Defines__kill_drop_link_rupeeID2__get();
		void LunaLua_Defines__kill_drop_link_rupeeID3__set(uint16_t value);
		uint16_t LunaLua_Defines__kill_drop_link_rupeeID3__get();

		bool LunaLua_Defines_mem_set(int address, double value);
	]])
	local LunaDLL = ffi.load("LunaDll.dll")

	-- these functions are overwritten as nil when defines is loaded!

	-- return the get/set functions for the patch with the given name
	function Misc._getDefine(name)
		local get = LunaDLL["LunaLua_Defines__" .. name .. "__get"]
		local set = LunaDLL["LunaLua_Defines__" .. name .. "__set"]
		-- wrap these as plain lua functions, just in case
		local mGet = function()      return get() end
		local mSet = function(value) set(value)   end
		return mGet, mSet
	end
	function Misc._definesMemSet(addr, value)
		return LunaDLL.LunaLua_Defines_mem_set(addr, value)
	end
end

----------------------
-- Collision matrix --
----------------------

if registerEvent then -- Only run this code if we're not in a loadscreen environment
	ffi.cdef([[
		unsigned int LunaLuaCollisionMatrixAllocateIndex();
		void LunaLuaCollisionMatrixIncrementReferenceCount(unsigned int group);
		void LunaLuaCollisionMatrixDecrementReferenceCount(unsigned int group);
		void LunaLuaGlobalCollisionMatrixSetIndicesCollide(unsigned int first, unsigned int second, bool collide);
		bool LunaLuaGlobalCollisionMatrixGetIndicesCollide(unsigned int first, unsigned int second);
	]])
	local LunaDLL = ffi.load("LunaDll.dll")

	-- Mapping between collision groups and collision group indices
	local getCollisionGroupFromIndex = { "" } -- Array index 1 corresponds to collision group index 0
	local getIndexFromCollisionGroup = { [""] = 0 }

	local function getOrAllocateIndex(group)
		local groupIndex = getIndexFromCollisionGroup[group]

		if groupIndex == nil then -- No index is associated to this group
			-- Allocate new index
			groupIndex = LunaDLL.LunaLuaCollisionMatrixAllocateIndex()

			-- Update the mapping
			getCollisionGroupFromIndex[groupIndex + 1] = group
			getIndexFromCollisionGroup[group] = groupIndex
		end

		return groupIndex
	end

	-- Check whether the argument is a string
	local function checkCollisionGroup(group)
		if type(group) ~= "string" then
			error("Collision group is not a string", 3)
		end
	end

	-- Handles modifying the collision group of an object
	function Misc._ModifyCollisionGroup(oldGroupIndex, newGroup)
		checkCollisionGroup(newGroup)

		-- Get an index associated to the new collision group
		local newGroupIndex = getOrAllocateIndex(newGroup)

		-- Update reference counts
		LunaDLL.LunaLuaCollisionMatrixIncrementReferenceCount(newGroupIndex)
		LunaDLL.LunaLuaCollisionMatrixDecrementReferenceCount(oldGroupIndex)

		return newGroupIndex
	end

	-- Returns the collision group associated to an index
	function Misc._GetCollisionGroupFromIndex(groupIndex)
		return getCollisionGroupFromIndex[groupIndex + 1]
	end

	-- Called whenever a group is deallocated
	local groupDeallocationListener = {
		onGroupDeallocationInternal = function(groupIndex)
			getIndexFromCollisionGroup[getCollisionGroupFromIndex[groupIndex + 1]] = nil
		end
	}

	registerEvent(groupDeallocationListener, "onGroupDeallocationInternal", "onGroupDeallocationInternal", true)

	-- Contains all existing proxies
	local collisionMatrixProxies = {}
	local collisionMatrixMetatable = {}

	-- Creates the metatable for the proxy corresponding to the first collision group
	local function makeProxyMetatable(firstGroup)
		local proxyMetatable = {}

		-- Returns the collision matrix element corresponding to the two groups
		function proxyMetatable.__index(self, secondGroup)
			checkCollisionGroup(secondGroup)

			-- Get indices for the collision groups
			local firstGroupIndex = getOrAllocateIndex(firstGroup)
			local secondGroupIndex = getOrAllocateIndex(secondGroup)

			-- Return value in collision matrix
			return LunaDLL.LunaLuaGlobalCollisionMatrixGetIndicesCollide(firstGroupIndex, secondGroupIndex)
		end

		-- Updates the collision matrix element corresponding to the two groups
		function proxyMetatable.__newindex(self, secondGroup, newValue)
			checkCollisionGroup(secondGroup)

			-- Convert newValue to boolean
			if newValue then
				newValue = true
			else
				newValue = false
			end

			-- Get indices for the collision groups
			local firstGroupIndex = getOrAllocateIndex(firstGroup)
			local secondGroupIndex = getOrAllocateIndex(secondGroup)

			-- Return value in collision matrix
			return LunaDLL.LunaLuaGlobalCollisionMatrixSetIndicesCollide(firstGroupIndex, secondGroupIndex, newValue)
		end

		return proxyMetatable
	end

	-- Returns a proxy corresponding to the first collision group
	function collisionMatrixMetatable.__index(self, firstGroup)
		checkCollisionGroup(firstGroup)

		-- Create a proxy if it doesn't exist already
		local proxy = collisionMatrixProxies[firstGroup]
		if proxy == nil then
			proxy = setmetatable({}, makeProxyMetatable(firstGroup))
			collisionMatrixProxies[firstGroup] = proxy
		end

		return proxy
	end

	-- We don't want people to be able to write directly to Misc.groupsCollide
	function collisionMatrixMetatable.__newindex(self, firstGroup, newValue)
		error("Misc.groupsCollide can only be used with two indices", 2)
	end

	Misc.groupsCollide = setmetatable({}, collisionMatrixMetatable)

	-- More direct methods of checking whether two objects should collide, avoiding the strings system entirely
	function Misc.canCollideWith(a, b)
		return LunaDLL.LunaLuaGlobalCollisionMatrixGetIndicesCollide(a.collisionGroupIndex, b.collisionGroupIndex)
	end

	function Misc.collidesWithGroup(obj, collisionGroupString)
		checkCollisionGroup(collisionGroupString)
		local collisionGroupIndex = getIndexFromCollisionGroup[collisionGroupString]
	
		--[[
		  If collisionGroupIndex is nil, then it means that collisionGroupString is not allocated,
		  ie. that there are no objects or collision matrix entries with this collision group. This
		  implies two things:
			- obj.collisionGroup is different from collisionGroupString since obj.collisionGroup is
			  the collision group of an object
			- the behavior of any collision involving collisionGroupString should be the default
			  (in that case, since obj.collisionGroup != collisionGroupString, the groups collide)
		  Therefore, we must return true if collisionGroupIndex is nil.
		  Otherwise, we can just look at the collision matrix.
		]]
		return not collisionGroupIndex or LunaDLL.LunaLuaGlobalCollisionMatrixGetIndicesCollide(obj.collisionGroupIndex, collisionGroupIndex)
	end

end

--------------------
-- Pause warnings --
--------------------

do
	local origPause = Misc.pause
	function Misc.pause(arg)
		if not EventManager.onStartRan then
			Misc.warn("Misc.pause before onStart is not recommended")
		end
		if (arg == nil) then
			origPause()
		else
			origPause(not not arg)
		end
	end

	local origShowMessageBox = Text.showMessageBox
	function Text.showMessageBox(arg)
		if not EventManager.onStartRan then
			Misc.warn("Text.showMessageBox before onStart is not supported")
		end
		origShowMessageBox(arg)
	end
end

-----------------------
-- Debug information --
-----------------------

do
	ffi.cdef([[
		const char* LunaLuaGetPatchedRange(int i);
	]])
	local LunaDLL = ffi.load("LunaDll.dll")

	function Misc._getPatchedRanges()
		local i = 0
		return function()
			local ret = ffi.string(LunaDLL.LunaLuaGetPatchedRange(i))
			i = i + 1
			if #ret > 0 then
				return ret
			end
		end
	end
end
