-- Powerups
for k,v in ipairs({273, 187, 186, 90, 249, 185, 184, 9, 183, 182, 14, 277, 264, 170, 287, 169, 34, 250, 425}) do
    NPC.config[v].powerup = true
end

-- Bindoswitch
NPC.config[32].iscustomswitch = true
NPC.config[238].iscustomswitch = true

-- Honkin Chonkers
NPC.config[21].weight = 1
NPC.config[37].weight = 4
NPC.config[58].weight = 1
NPC.config[67].weight = 4
NPC.config[68].weight = 8
NPC.config[69].weight = 4
NPC.config[70].weight = 8
NPC.config[71].weight = 2
NPC.config[72].weight = 2
NPC.config[73].weight = 2
NPC.config[78].weight = 4
NPC.config[79].weight = 2
NPC.config[80].weight = 4
NPC.config[81].weight = 4
NPC.config[82].weight = 4
NPC.config[83].weight = 8
NPC.config[84].weight = 4
NPC.config[164].weight = 2

-- Elementals
NPC.config[12].ishot = true
NPC.config[12].durability = -1
NPC.config[13].ishot = true
NPC.config[85].ishot = true
NPC.config[85].durability = 2
NPC.config[87].ishot = true
NPC.config[87].durability = -1
NPC.config[108].ishot = true
NPC.config[108].durability = 5
NPC.config[206].ishot = true
NPC.config[206].iselectric = true
NPC.config[206].durability = -1
NPC.config[210].ishot = true
NPC.config[210].durability = 2
NPC.config[246].ishot = true
NPC.config[246].durability = 2
NPC.config[259].ishot = true
NPC.config[259].durability = -1
NPC.config[260].ishot = true
NPC.config[260].durability = -1
NPC.config[276].ishot = true
NPC.config[276].durability = 2
NPC.config[282].ishot = true
NPC.config[282].durability = -1

NPC.config[265].iscold = true

-- Clear pipe shenanigans
NPC.config[5].useclearpipe = true
NPC.config[7].useclearpipe = true
NPC.config[10].useclearpipe = true
NPC.config[13].useclearpipe = true
NPC.config[13].clearpipegroup = "fireballs"
NPC.config[24].useclearpipe = true
NPC.config[26].useclearpipe = true
NPC.config[31].useclearpipe = true
NPC.config[32].useclearpipe = true
NPC.config[33].useclearpipe = true
NPC.config[45].useclearpipe = true
NPC.config[48].useclearpipe = true
NPC.config[88].useclearpipe = true
NPC.config[90].useclearpipe = true
NPC.config[103].useclearpipe = true
NPC.config[113].useclearpipe = true
NPC.config[114].useclearpipe = true
NPC.config[115].useclearpipe = true
NPC.config[116].useclearpipe = true
NPC.config[133].useclearpipe = true
NPC.config[138].useclearpipe = true
NPC.config[134].useclearpipe = true
NPC.config[152].useclearpipe = true
NPC.config[154].useclearpipe = true
NPC.config[155].useclearpipe = true
NPC.config[156].useclearpipe = true
NPC.config[157].useclearpipe = true
NPC.config[158].useclearpipe = true
NPC.config[172].useclearpipe = true
NPC.config[174].useclearpipe = true
NPC.config[186].useclearpipe = true
NPC.config[187].useclearpipe = true
NPC.config[188].useclearpipe = true
NPC.config[202].useclearpipe = true
NPC.config[238].useclearpipe = true
NPC.config[241].useclearpipe = true
NPC.config[251].useclearpipe = true
NPC.config[252].useclearpipe = true
NPC.config[253].useclearpipe = true
NPC.config[258].useclearpipe = true
NPC.config[263].useclearpipe = true
NPC.config[263].clearpipegroup = "iceblocks"
NPC.config[265].useclearpipe = true
NPC.config[265].clearpipegroup = "iceballs"
NPC.config[274].useclearpipe = true
NPC.config[286].useclearpipe = true
NPC.config[291].useclearpipe = true
NPC.config[293].useclearpipe = true
NPC.config[300].useclearpipe = true
NPC.config[319].useclearpipe = true
NPC.config[320].useclearpipe = true
NPC.config[321].useclearpipe = true
NPC.config[333].useclearpipe = true
NPC.config[358].useclearpipe = true
NPC.config[361].useclearpipe = true
NPC.config[390].useclearpipe = true
NPC.config[451].useclearpipe = true
NPC.config[452].useclearpipe = true
NPC.config[453].useclearpipe = true
NPC.config[454].useclearpipe = true
NPC.config[500].useclearpipe = true
NPC.config[581].useclearpipe = true
NPC.config[606].useclearpipe = true
NPC.config[607].useclearpipe = true
NPC.config[611].useclearpipe = true

for k,v in ipairs(NPC.POWERUP) do
    if v ~= 34 then
        NPC.config[v].useclearpipe = true
    end
end

return {}