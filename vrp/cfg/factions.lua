local cfg = {}

cfg.factions = {
    ["police"] = {
        _config = {
            title = "Police",
            paycheck_interval = 10, -- (minutes) Apply to whole faction
            max_members = 40,
            max_liders = 1,
            max_co_liders = 3,
            default_permissions = {
                "police.base.menu",
                "police.radio.use"
            },
            grades = {
                [1] = {
                    name = "Recruit",
                    payment = 50,
                    permissions = {
                        "police.recruit.menu",
                        "police.recruit.callbackup",
                        "police.recruit.radio"
                    }
                },
                [2] = {
                    name = "Officer",
                    payment = 75,
                    permissions = {
                        "police.officer.menu",
                        "police.officer.handcuff",
                        "police.officer.putinvehicle",
                        "police.officer.radio",
                        "police.officer.weapon"
                    }
                },
                [3] = {
                    name = "Sergeant",
                    payment = 100,
                    permissions = {
                        "police.sergeant.menu",
                        "police.sergeant.seizeweapons",
                        "police.sergeant.drag",
                        "police.sergeant.radio",
                        "police.sergeant.weapon",
                        "police.sergeant.manage"
                    }
                },
                [4] = {
                    name = "Lieutenant",
                    payment = 125,
                    Co_Lider = true,
                    permissions = {
                        "police.lieutenant.menu",
                        "police.lieutenant.manage",
                        "police.lieutenant.checkbank",
                        "police.lieutenant.radio",
                        "police.lieutenant.weapon",
                        "police.lieutenant.promote"
                    }
                },
                [5] = {
                    name = "Chief",
                    Lider = true,
                    payment = 150,
                    permissions = {
                        "police.chief.menu",
                        "police.chief.promote",
                        "police.chief.managebudget",
                        "police.chief.radio",
                        "police.chief.weapon",
                        "police.chief.manage"
                    }
                }
            }
        }
    },
    ["gang"] = {
        _config = {
            title = "Gang",
            paycheck_interval = 10,
            max_members = 40,
            max_liders = 1,
            max_co_liders = 3,
            default_permissions = {
                "gang.base.menu",
                "gang.radio.use"
            },
            grades = {
                [1] = {
                    name = "Worker",
                    payment = 50,
                },
                [3] = {
                    name = "Co-Lider",
                    payment = 100,
                    Co_Lider = true,
                    permissions = {
                        "gang.lieutenant.weapon",
                    }
                },
                [4] = {
                    name = "Boss",
                    Lider = true,
                    payment = 150,
                    permissions = {
                        "gang.boss.weapon",
                    }
                }
            }
        }
    },
    ["ems"] = {
        _config = {
            title = "Emergency Medical Services",
            paycheck_interval = 10, -- minutes
            max_members = 40,
            max_liders = 1,
            max_co_liders = 3,
            default_permissions = {
                "ems.base.menu",
                "ems.radio.use"
            },
            grades = {
                [1] = {
                    name = "Paramedic",
                    payment = 50,
                },
                [2] = {
                    name = "Senior Paramedic",
                    payment = 75,
                },
                [3] = {
                    name = "Supervisor",
                    payment = 100,
                    Co_Lider = true,
                },
                [4] = {
                    name = "Chief",
                    Lider = true,
                    payment = 125,
                    permissions = {
                        "ems.chief.menu",
                        "ems.chief.manage"
                    }
                }
            }
        }
    }
}

return cfg
