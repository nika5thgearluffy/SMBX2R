--HURT map
for k,v in ipairs({109, 110, 267, 268, 269, 407, 408, 428, 429, 430, 431, 511, 598, 672, 673, 682, 683, 1151}) do
    Block.config[v].customhurt = 3
end

--PLAYER BLOCK map
--[[
Block.config[639].frames = 5
Block.config[640].frames = 4
Block.config[641].frames = 5
Block.config[642].frames = 4
Block.config[643].frames = 5
Block.config[644].frames = 4
Block.config[645].frames = 5
Block.config[646].frames = 4
Block.config[647].frames = 5
Block.config[648].frames = 4
Block.config[649].frames = 5
Block.config[650].frames = 4
Block.config[651].frames = 5
Block.config[652].frames = 4
Block.config[653].frames = 5
Block.config[654].frames = 4
Block.config[655].frames = 5
Block.config[656].frames = 4
Block.config[657].frames = 5
Block.config[658].frames = 4
Block.config[659].frames = 5
Block.config[660].frames = 4
Block.config[661].frames = 5
Block.config[662].frames = 4
Block.config[663].frames = 5
Block.config[664].frames = 4
]]

--MEGASMASHY INTERACTION
for k,v in ipairs({226, 694, 188, 60, 4, 457, 526, 293, 90, 668}) do
    Block.config[v].smashable = 3
end
for k,v in ipairs({666, 667, 682, 683, 1271}) do
    Block.config[v].smashable = 2
end
for k,v in ipairs({224, 225, 192, 193, 2, 5, 88, 89, 115}) do
    Block.config[v].smashable = 1
end

-- Passthrough switches
Block.config[725].passthrough = true
Block.config[727].passthrough = true
Block.config[729].passthrough = true
Block.config[731].passthrough = true

-- Invisible Semisolid
Block.config[1007].semisolid = true

-- Airship Sizables
Block.config[1060].sizable = true
Block.config[1061].sizable = true

-- SMB1 Slopes
Block.config[1119].floorslope = -1
Block.config[1121].floorslope = 1
Block.config[1123].floorslope = -1
Block.config[1125].floorslope = 1
Block.config[1131].floorslope = -1
Block.config[1132].floorslope = 1

-- SMB3 Sand Slopes
Block.config[1127].ceilingslope = 1
Block.config[1128].ceilingslope = -1
Block.config[1129].ceilingslope = 1
Block.config[1130].ceilingslope = -1

-- SMW Escalator-related
Block.config[1135].frames = 4
Block.config[1136].frames = 4
Block.config[1137].frames = 2
Block.config[1154].frames = 4
Block.config[1155].frames = 4

-- SMW Forest Slopes
Block.config[1138].floorslope = -1
Block.config[1140].floorslope = 1

-- SMW athletic
Block.config[1156].semisolid = true

-- SMM Sizables
Block.config[1171].sizable = true
Block.config[1172].sizable = true
Block.config[1173].sizable = true

-- SMB3 Snow Slopes
Block.config[1176].floorslope = -1
Block.config[1178].floorslope = 1
Block.config[1180].floorslope = -1
Block.config[1182].floorslope = 1

-- SMB2 Snow Slopes
Block.config[1201].floorslope = -1
Block.config[1203].floorslope = 1
Block.config[1205].floorslope = -1
Block.config[1207].floorslope = 1

-- SMB2 Ice Block
Block.config[1209].semisolid = true

-- SMB2 Tower Wood
Block.config[1216].semisolid = true
Block.config[1217].semisolid = true
Block.config[1218].semisolid = true
Block.config[1219].semisolid = true

-- SMB2 Cave Slopes
Block.config[1224].floorslope = -1
Block.config[1226].floorslope = 1
Block.config[1228].floorslope = -1
Block.config[1230].floorslope = 1
Block.config[1232].ceilingslope = 1
Block.config[1233].ceilingslope = -1
Block.config[1234].ceilingslope = 1
Block.config[1235].ceilingslope = -1

-- SMB2 Desert Block
Block.config[1236].semisolid = true

-- SMB2 Ice Slopes
Block.config[1254].floorslope = -1
Block.config[1256].floorslope = 1
Block.config[1258].floorslope = -1
Block.config[1260].floorslope = 1

-- Mario Maker SMW cave tileset sizables
Block.config[1262].sizable = true
Block.config[1263].sizable = true
Block.config[1264].sizable = true
Block.config[1265].sizable = true
Block.config[1266].sizable = true
Block.config[1267].sizable = true

-- Flipped SMB3 Lava
Block.config[1268].frames = 4
Block.config[1268].lava = true

-- Mario Maker SMW bridge and rainbow sizable
Block.config[1269].sizable = true
Block.config[1270].sizable = true

-- SMB3 'Minty' and 'Candy' sizables
Block.config[1376].sizable = true
Block.config[1377].sizable = true

-- Invisible Slopes
Block.config[1378].floorslope = -1
Block.config[1379].floorslope = 1
Block.config[1380].ceilingslope = 1
Block.config[1381].ceilingslope = -1
Block.config[1382].floorslope = -1
Block.config[1383].floorslope = 1
Block.config[1384].ceilingslope = 1
Block.config[1385].ceilingslope = -1

Block.config[1386].floorslope = -1
Block.config[1386].walkpaststair = true
Block.config[1386].semisolid = true
Block.config[1387].passthrough = true
Block.config[1388].floorslope = 1
Block.config[1388].walkpaststair = true
Block.config[1388].semisolid = true
Block.config[1389].passthrough = true

Block.config[1390].floorslope = -1
Block.config[1390].semisolid = true
Block.config[1391].passthrough = true
Block.config[1392].floorslope = 1
Block.config[1392].semisolid = true
Block.config[1393].passthrough = true

Block.config[1394].floorslope = -1
Block.config[1394].semisolid = true
Block.config[1395].floorslope = 1
Block.config[1395].semisolid = true

Block.config[1396].floorslope = -1
Block.config[1396].semisolid = true
Block.config[1397].floorslope = 1
Block.config[1397].semisolid = true

Block.config[1398].floorslope = -1
Block.config[1399].floorslope = 1

Block.config[1402].ceilingslope = -1
Block.config[1404].ceilingslope = 1

Block.config[1406].ceilingslope = -1
Block.config[1408].ceilingslope = 1

Block.config[1416].floorslope = -1
Block.config[1418].floorslope = 1

Block.config[1420].ceilingslope = -1
Block.config[1422].ceilingslope = 1

Block.config[1424].ceilingslope = -1
Block.config[1425].ceilingslope = 1

return {}