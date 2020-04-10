-- Special Abilities Threat Table
-- Class 
--  ABILITY 
--      RANK

SPECIAL_ABILITIES = {
    WARRIOR = {
        BATTLE_SHOUT = {
            5,
            11,
            17,
            26,
            39,
            55,
            70
        },
        HEROIC_STRIKE = {
            20,
            39,
            59,
            78,
            98,
            118,
            137,
            145,
            175
        },
        THUNDER_CLAP = {
            17,
            40,
            64,
            96,
            143,
            180
        },
        DEMORALIZING_SHOUT = {
            11,
            17,
            21,
            32,
            43
        },
        CLEAVE = {
            10,
            40,
            60,
            70,
            100
        },
        HAMSTRING = {
            61,
            101,
            141
        },
        REVENGE = {
            155,
            195,
            235,
            275,
            315,
            355
        },
        SUNDER_ARMOR = {
            100,
            140,
            180,
            220,
            260
        },
        SHIELD_SLAM = {
            160,
            190,
            220,
            250
        },
        SHIELD_BASH = 180
    },
    MAGE = {
        COUNTERSPELL = {
            300
        },
        REMOVE_LESSER_CURSE = {
            14
        }
    },
    DRUID = {
        COWER = {
            -240,
            -390,
            -600
        },
        DEMORALIZING_ROAR = {
            9,
            15,
            20,
            30,
            39
        },
        FAERIE_FIRE = 108;
    },
    HUNTER = {
        DISTRACTING_SHOT = {
            100,
            200,
            300,
            400,
            500,
            600
        }
    },
    PET = {
        COWER = {
            -30,
            -55,
            -85,
            -125,
            -175,
            -225
        },
        SCORPID_POISON = 5,
        SUFFERING = {
            200,
            300,
            450,
            600
        }
    },
    PALADIN = {
        HOLY_SHIELD = {
            20,
            30,
            40
        },
        CLEANSE = 40
    },
    PRIEST = {
        FADE = {
            -55,
            -155,
            -285,
            -440,
            -620,
            -820
        }
    },
    ROGUE = {
        FEINT = {
            -150,
            -240,
            -390,
            -600,
            -800
        }
    },
    SHAMAN = {
        ROCKBITER_WEAPON = {
            6,
            10,
            16,
            27,
            41,
            55,
            72
        }
    }
}

-- Stores the Indexes of threat-modifying talents in the respective talent trees. 
-- Retrieve the indexes and use with GetTalentInfo()
TALENT_MODIFIERS = {
    WARRIOR = {
        [1] = {
            3,
            9,
            2
        }
    },
    MAGE = {
        [1] = {
            3,
            12,
            2
        },
        [2] = {
            1,
            1,
            2
        },
        [3] = {
            2,
            9,
            2
        }
    },
    DRUID = {
        [1] = {
            1,
            3,
            2
        },
        [2] = {
            2,
            8,
            2
        }
    },
    PALADIN = {
        [1] = {
            2,
            7,
            1
        }
    }

}


TALENT_THREAT_INFO = {
    DEFIANCE = { percent = 3, school = 'Physical' },
    ARCANE_SUBTLETY = { percent = 20, school = 'Arcane' },
    FROST_CHANNELING = { percent = 10, school = 'Frost' },
    BURNING_SOUL = { percent = 15, school = 'Fire' },
    SILENT_RESOLVE = { percent = 8.33, school = 'All' },
    SHADOW_AFFINITY = { percent = 4, school = 'Shadow' },
    HEALING_GRACE = { percent = 5, school = 'Healing' },
    IMPROVED_RIGHTEOUS_FURY = { percent = 10, school = 'Righteous Fury' }
}

