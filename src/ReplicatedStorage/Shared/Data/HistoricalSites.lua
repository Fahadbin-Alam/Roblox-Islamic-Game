--!strict

-- The historical campaign zones. They are reconstructions of 7th-century Makkah and Madinah
-- and stand far from the present-day hub (which is built around today's Masjid al-Haram and
-- Masjid an-Nabawi) so the two are never confused. Every sign in these zones says
-- "Historical reconstruction". The Prophet Muhammad ﷺ is never shown in them: his place in
-- each scene is told only through written narration.

export type Site = {
    Id: string,
    Zone: string,
    DisplayName: string,
    Description: string,
    Position: Vector3,
    -- What the builder puts here (see HistoricalWorldBuilder).
    Kind: string,
}

export type Zone = {
    Id: string,
    DisplayName: string,
    Period: string,
    Center: Vector3,
    Size: Vector3,
    Disclaimer: string,
}

local MAKKAH = Vector3.new(4000, 0, 0)
local MADINAH = Vector3.new(4000, 0, 1900)

local zones: { Zone } = {
    {
        Id = "makkah_610",
        DisplayName = "Makkah, c. 570-630 CE",
        Period = "Historical reconstruction",
        Center = MAKKAH,
        Size = Vector3.new(1300, 0, 1300),
        Disclaimer = "Historical reconstruction for the Seerah campaign. It is not today's Makkah: visit Masjid al-Haram in the hub for that.",
    },
    {
        Id = "madinah_622",
        DisplayName = "Madinah, c. 622-632 CE",
        Period = "Historical reconstruction",
        Center = MADINAH,
        Size = Vector3.new(1300, 0, 1300),
        Disclaimer = "Historical reconstruction for the Seerah campaign. It is not today's Madinah: visit the present-day Prophet's Mosque courtyard in the hub for that.",
    },
}

local function site(id: string, zone: string, name: string, description: string, offset: Vector3, kind: string): Site
    local center = if zone == "makkah_610" then MAKKAH else MADINAH

    return {
        Id = id,
        Zone = zone,
        DisplayName = name,
        Description = description,
        Position = center + offset,
        Kind = kind,
    }
end

local sites: { Site } = {
    -- Makkah
    site("kaaba_old", "makkah_610", "The Kaaba (c. 600 CE)", "The Kaaba before the large mosque existed, with the houses of Quraysh close around it.", Vector3.new(0, 0, 0), "Kaaba"),
    site("banu_sad_camp", "makkah_610", "Banu Sa'd Tents", "Desert tents of the Banu Sa'd, where children of Makkah were nursed in the open desert.", Vector3.new(-520, 0, -480), "Camp"),
    site("makkah_market", "makkah_610", "Makkah Market", "Stalls where traders from Yemen and Syria met.", Vector3.new(-180, 0, 200), "Market"),
    site("khadijah_house", "makkah_610", "House of Khadijah", "The home of Khadijah bint Khuwaylid, a respected merchant of Makkah.", Vector3.new(170, 0, 180), "House"),
    site("jabal_nour", "makkah_610", "Jabal al-Nour and the Cave of Hira", "The mountain north-east of Makkah with the small cave where the first revelation came.", Vector3.new(-430, 0, 430), "Mountain"),
    site("dar_al_arqam", "makkah_610", "Dar al-Arqam", "The house near Safa where the first Muslims met to learn in secret.", Vector3.new(-200, 0, -40), "House"),
    site("safa_hill", "makkah_610", "Mount Safa", "The low hill near the Kaaba from which public announcements were made to Quraysh.", Vector3.new(-150, 0, -160), "Hill"),
    site("makkah_valley", "makkah_610", "The Hot Valley", "The open, sun-baked ground outside the town where weak believers were tortured.", Vector3.new(320, 0, -260), "Valley"),
    site("red_sea_harbour", "makkah_610", "Harbour and the Court of Abyssinia", "A Red Sea harbour, and a hall standing for the court of the Najashi across the sea.", Vector3.new(560, 0, 120), "Harbour"),
    site("fatimah_house", "makkah_610", "House of Fatimah bint al-Khattab", "The home of Umar's sister, where he heard Surah Ta-Ha.", Vector3.new(230, 0, -40), "House"),
    site("shib_abi_talib", "makkah_610", "Shi'b Abi Talib", "The narrow valley where Banu Hashim lived through the boycott.", Vector3.new(-360, 0, 120), "Valley"),
    site("taif_orchard", "makkah_610", "Orchard near Ta'if", "A walled vineyard on the road from Ta'if, standing for the orchard of Utbah and Shaybah.", Vector3.new(560, 0, -500), "Orchard"),
    site("aqabah_mina", "makkah_610", "Al-Aqabah at Mina", "A hillside pass at Mina where people of Yathrib met at night during the pilgrimage season.", Vector3.new(420, 0, 420), "Hill"),
    site("jabal_thawr", "makkah_610", "Jabal Thawr", "The mountain south of Makkah with the cave where the Hijrah began.", Vector3.new(0, 0, -560), "Mountain"),
    site("hudaybiyyah", "makkah_610", "Al-Hudaybiyyah", "A well and a tree on the edge of the sacred area, where the treaty was agreed.", Vector3.new(-560, 0, 0), "Camp"),
    site("arafat_plain", "makkah_610", "Plain of Arafat", "The wide plain and the Mount of Mercy where pilgrims stand on the Day of Arafah.", Vector3.new(560, 0, 560), "Plain"),

    -- Madinah
    site("quba", "madinah_622", "Quba", "The village south of Madinah where the first mosque was built.", Vector3.new(0, 0, -520), "Mosque"),
    site("masjid_early", "madinah_622", "The First Prophet's Mosque", "A mud-brick courtyard with palm-trunk pillars and a palm-frond roof.", Vector3.new(0, 0, 0), "Mosque"),
    site("abu_ayyub_house", "madinah_622", "House of Abu Ayyub al-Ansari", "The two-storey house where the Prophet ﷺ first stayed in Madinah.", Vector3.new(90, 0, -60), "House"),
    site("madinah_market", "madinah_622", "Madinah Market", "The open market of Madinah.", Vector3.new(-200, 0, -120), "Market"),
    site("council_ground", "madinah_622", "Gathering Ground", "An open space where the tribes of Madinah met and agreements were made.", Vector3.new(220, 0, 160), "Plain"),
    site("qiblatayn", "madinah_622", "Masjid al-Qiblatayn site", "A small prayer place on the north-west edge of Madinah.", Vector3.new(-380, 0, 240), "Mosque"),
    site("war_council", "madinah_622", "War Council", "The tents where the believers prepared before marching out to Badr and Uhud.", Vector3.new(260, 0, -260), "Camp"),
    site("trench_line", "madinah_622", "The Trench", "The northern edge of Madinah where the trench was dug.", Vector3.new(0, 0, 480), "Trench"),
    site("letters_house", "madinah_622", "House of the Scribes", "Where letters were written, sealed, and given to messengers.", Vector3.new(-120, 0, 120), "House"),
    site("tabuk_camp", "madinah_622", "Road North to Tabuk", "The edge of Madinah where the army left for Tabuk in the summer heat.", Vector3.new(420, 0, 460), "Camp"),
}

local siteById: { [string]: Site } = {}

for _, entry in ipairs(sites) do
    siteById[entry.Id] = entry
end

local zoneById: { [string]: Zone } = {}

for _, entry in ipairs(zones) do
    zoneById[entry.Id] = entry
end

return {
    FolderName = "HistoricalWorld",
    Zones = zones,
    Sites = sites,
    GetSite = function(id: string): Site?
        return siteById[id]
    end,
    GetZone = function(id: string): Zone?
        return zoneById[id]
    end,
}
