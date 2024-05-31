/*
 * Kiwii, a stupid Discord bot.
 * Copyright (C) 2019-2024 Rapougnac
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:nyxx/nyxx.dart';

import '../translations.g.dart';

const choicesLocale = {
  'Français': 'fr-FR',
  'English': 'en-GB',
};

const discordLocaleToAppLocale = {
  Locale.enGb: AppLocale.enGb,
  Locale.fr: AppLocale.frFr,
};

const locales = {
  'fr-FR': AppLocale.frFr,
  'en-GB': AppLocale.enGb,
};

const overwatchEmojisMappings = <String, Map<String, String>>{
  'ANA': {
    'BIOTICRIFLE': '<:AnaBioticRifle1:1229403212381945876><:AnaBioticRifle2:1227733942317219881>',
    'SLEEPDART': '<:AnaSleepDart:1228484357384179723>',
    'BIOTICGRENADE': '<:AnaBioticGrenade:1228484775275266139>',
    'NANOBOOST': '<:AnaNanoboost:1228485098039410818>',
  },
  'ASHE': {
    'THE_VIPER': '<:AsheTheViper1:1229365514086649906><:AsheTheViper2:1229365512220446731>',
    'DYNAMITE': '<:AsheDynamite:1229365510031020103>',
    'COACH_GUN': '<:AsheDynamite:1229365510031020103>',
    'BOB': '<:AsheBob:1229365508474802196>',
  },
  'BAPTISTE': {
    'BIOTICLAUNCHER': '<:BaptisteBioticLauncher1:1229377829548982302><:BaptisteBioticLauncher2:1229377831008473110>',
    'REGENERATION_02': '<:BaptisteRegenerativeBurst:1229366401807028306>',
    'IMMORTALITY': '<:BaptisteImmortalityField:1229366400385286256>',
    'AMPLICATIONFIELD': '<:BaptisteAmplificationMatrix:1229366398959091794>',
    'EXOJUMP_02': '<:BaptisteExoBoots:1229366397591752735>',
  },
  'BASTION': {
    'CONFIGURATION_RECON': '<:BastionConfigurationRecon1:1229379873177468999><:BastionConfigurationRecon2:1229379871411666968>',
    'CONFIGURATION_ASSAULT': '<:BastionConfigurationAssault1:1229379877224841248><:BastionConfigurationAssault2:1229379874334969906>',
    'RECONFIGURE': '<:BastionReconfigure:1229379880483950694>',
    // Intended, there's a typo in their filename lmao
    'TACTICAL_GERNADE': '<:BastionA36TacticalGrenade:1229379882270589030>',
    'ARTILLERY': '<:BastionConfigurationArtillery:1229379878869139528>',
  },
  'BRIGITTE': {
    'ROCKET_FLAIL': '<:BrigitteRocketFlail1:1229404635379531817><:BrigitteRocketFlail2:1229404632376279060>',
    'BARRIER_SHIELD': '<:BrigitteBarrierShield:1229404641972850798>',
    'WHIP_SHOT': '<:BrigitteWhipShot:1229404643365486684>',
    'REPAIR_PACK': '<:BrigitteRepairPack:1229404633990955131>',
    'SHIELD_BASH': '<:BrigitteShieldBash:1229404640290803744>',
    'RALLY': '<:BrigitteRally:1229404638822924349>',
    'INSPIRE': '<:BrigitteInspire:1229404637048606770>',
  },
  'CASSIDY': {
    'PEACEKEEPER': '<:CassidyPeacekeeper1:1229453816345137274><:CassidyPeacekeeper2:1229453815263137863>',
    'COMBAT_ROLL': '<:CassidyCombatRoll:1229453813656584233>',
    // Istg, it's intentional
    'MAGNETIC_GERNADE': '<:CassidyMagneticGrenade:1229453819918942318>',
    'DEADEYE': '<:CassidyDeadeye:1229453818421575770>',
  },
  'DOOMFIST': {
    'HAND_CANNON': '<:DoomfistHandCannon1:1229470767993847879><:DoomfistHandCannon2:1229470765972197498>',
    'METEOR_STRIKE': '<:DoomfistMeteorStrike:1229470769608654980>',
    'ROCKET_PUNCH': '<:DoomfistRocketPunch:1229470764378357841>',
    'SEISMIC_SLAM': '<:DoomfistSeismicSlam:1229470772725157928>',
    'POWER_BLOCK': '<:DoomfistPowerBlock:1229470771093442560>',
  },
  'DVA': {
    'FUSIONCANNON': '<:DvaFusionsCannons1:1230431359605018666><:DvaFusionsCannons2:1230431358023766098>',
    'LIGHTGUN': '<:DvaLightGun:1230431572264488960>',
    'BOOSTERS': '<:DvaBoosters:1230431375082127393>',
    'DEFENSEMATRIX': '<:DvaDefenseMatrix:1230431373307674695>',
    'MICROMISSILES': '<:DvaMicroMissiles:1230431370682175520>',
    'SELFDESTRUCT': '<:DvaSelfDestruct:1230431368308199454>',
    'CALLMECH': '<:DvaRemech:1230431365883887636>',
    'EJECT': '<:DvaEject:1230431363837067266>',
  },
  'ECHO': {
    'Tri-Shot': '<:EchoTriShot1:1230438720142835797><:EchoTriShot2:1230438717965991946>',
    'Sticky_Bombs': '<:EchoStickyBombs:1230438764783075379>',
    'Flight': '<:EchoFlight:1230438760328597544>',
    'Focusing_Beam': '<:EchoFocusingBeam:1230438750396612628>',
    'Duplicate': '<:EchoDuplicate:1230438745455595583>',
    'Glide': '<:EchoGlide:1230438737125838869>',
  },
  'GENJI': {
    'Shuriken': '<:GenjiShuriken1:1230441668772106240><:GenjiShuriken2:1230441666914029579>',
    'Deflect': '<:GenjiDeflect:1230441675311288350>',
    'Swift_Strike': '<:GenjiSwiftStrike:1230441673562132501>',
    'Dragon_Blade': '<:GenjiDragonBlade:1230441672006045777>',
    'Cyber_Agility': '<:GenjiCyberAgility:1230441670617595944>',
  },
  'HANZO': {
    'Storm_Bow': '<:HanzoStormBow1:1230443052393566249><:HanzoStormBow2:1230443050560524390>',
    'Storm_Arrows': '<:HanzoStormArrows:1230443061180502047>',
    'Sonic_Arrow': '<:HanzoSonicArrow:1230443059372888175>',
    'Lunge': '<:HanzoLunge:1230443057850093599>',
    'Dragon_Strike': '<:HanzoDragonStrike:1230443055690154056>',
    'Wall_Climb': '<:HanzoWallClimb:1230443054100512818>',
  },
  'Illari': {
    'Solar_Primary_Fire': '<:IllariSolarRifle1:1230444401080270898><:IllariSolarRifle2:1230444398320422933>',
    'Solar_Ult': '<:IllariCaptiveSun:1230444406054588456>',
    // Intended.
    'Solor_Heal_Pylon': '<:IllariHealingPylon:1230444404498497597>',
    'Solar_Outburst': '<:IllariOutBurst:1230444402460065825>',
  },
  'JUNKER_QUEEN': {
    'SCATTERGUN': '<:JunkerQueenScattergun1:1230482096494088192><:JunkerQueenScattergun2:1230482094724091915>',
    'JAGGED_BLADE': '<:JunkerQueenJaggedBlade:1230482104995938334>',
    'COMMANDING_SHOUT': '<:JunkerQueenCommandingShout:1230482103041261700>',
    'CARNAGE': '<:JunkerQueenCarnage:1230482101191835678>',
    'RAMPAGE': '<:JunkerQueenRampage:1230482099451068478>',
    'ADRENALINE_RUSH': '<:JunkerQueenAdrenalineRush:1230482098066817034>',
  },
  'JUNKRAT': {
    'FRAG_LAUNCHER': '<:JunkratFragLauncher1:1230483425878741002><:JunkratFragLauncher2:1230483424092098560>',
    'CONCUSSION_MINE': '<:JunkratConcussionMine:1230483433717891163>',
    'STEEL_TRAP': '<:JunkratSteelTrap:1230483432027459679>',
    'RIPTIRE': '<:JunkratRIPTire:1230483430085759056>',
    'TOTAL_MAYHEM': '<:JunkratTotalMayhem:1230483427396948019>',
  },
  'KIRIKO': {
    'HEALING_OFUDA': '<:KirikoHealingOfuda:1230485023640260659>',
    'KUNAI': '<:KirikoKunai1:1230485017134895144><:KirikoKunai2:1230485015104720957>',
    'SWIFT_STEP': '<:KirikoSwiftStep:1230485022289690704>',
    'PROTECTION_SUZU': '<:KirikoProtectionSuzu:1230485020280492194>',
    // Wtf??
    'KITSUN_RUSH': '<:KirikoKitsuneRush:1230485018649038888>',
  },
  'Lifeweaver': {
    'Ability_Grip_3P': '<:LifeweaverLifeGrip:1230616346132222002>',
    'Ability_Ultimate_3P': '<:LifeweaverTreeOfLife:1230616347885437059>',
    'Ability_Dash_1P': '<:LifeweaverRejuvenatingDash:1230616350464933989>',
    'Ability_Platform_1P': '<:LifeweaverPetalPlatform:1230615734795763852>',
    'Heal_1P': '<:LifeweaverHealingBlossom:1230615717301194822>',
    'Ability_Attack_1P': '<:LifeweaverThornVolley1:1230615429215686756><:LifeweaverThornVolley2:1230615427428913224>',
  },
  'LUCIO': {
    'SONICAMPLIFIER': '<:LucioSonicAmplifier:1230618780670103612>',
    'CROSSFADE': '<:LucioCrossfade:1230618641792499733>',
    'AMPITUP': '<:LucioAmpitUp:1230618649929449553>',
    'SOUNDWAVE': '<:LucioSoundwave:1230618648012521524>',
    'SOUNDBARRIER': '<:LucioSoundBarrier:1230618646515023924>',
    'WALLRIDE': '<:GenericPassive:1230618349961216021>',
  },
  'Mauga': {
    'Berserker': '<:MaugaBerserker:1230621441402212384>',
    'Cage_fight': '<:MaugaCageFight:1230621439715971135>',
    'Cardiac': '<:MaugaCardiacOverdrive:1230621442765357116>',
    'Overrun': '<:MaugaOverrun:1230621444103344168>',
    // Where are his weapons??
  },
  'MEI': {
    'ENDOTHERMICBLAST': '<:MeiEndothemicBlaster:1230623812006055956>',
    'CRYOFREEZE': '<:MeiCryoFreeze:1230623810525597696>',
    'ICEWALL': '<:MeiIceWall:1230623808638025738>',
    'BLIZZARD': '<:MeiBlizzard:1230623807123750972>',
  },
  'MERCY': {
    'CADCEUSSTAFF': '<:MercyCaduceusStaff1:1230783290756042783><:MercyCaduceusStaff2:1230783288847634484>',
    'CADCEUSBLASTER': '<:MercyCaduceusBlaster:1230783547242188830>',
    'GUARDIANANGEL': '<:MercyGuardianAngel:1230783296716406814>',
    'RESURRECT': '<:MercyRessurect:1230783295403462696>',
    'ANGELICDESCENT': '<:MercyAngelicDescent:1230783293767684107>',
    'VALKYRIE': '<:MercyValkyrie:1230783292349874208>',
  },
  'MOIRA': {
    'BIOTICGRASP': '<:MoiraBioticGrasp1:1230784978942689341><:MoiraBioticGrasp2:1230784977038475345>',
    'BIOTICORB': '<:MoiraBioticOrb:1230784983971401739>',
    'FADE': '<:MoiraFade:1230784982675492934>',
    'COALESCENCE': '<:MoiraCoalescence:1230784981308145725>',
  },
  'ORISA': {
    'AUGMENTED_FUSION_DRIVER': '<:OrisaAugmentedFusionDriver1:1230786697797570572><:OrisaAugmentedFusionDriver2:1230786696858177556>',
    'ENERGY_JAVELIN': '<:OrisaEnergyJavelin:1230786703917318144>',
    'FORTIFY': '<:OrisaFortify:1230786702336065647>',
    'JAVELIN_SPIN': '<:OrisaJavelinSpin:1230786701178310737>',
    'TERRA_SPIN': '<:OrisaTerraSurge:1230786699609509949>',
  },
  'Pharah': {
    'Rocket_Launcher': '<:PharahRocketLauncher1:1230788586182414346><:PharahRocketLauncher2:1230788584873656350> ',
    'Dash': '<:PharahJetDash:1230788591882604575>',
    'Jump_Jet': '<:PharahJumpJet:1230788590439763970>',
    'Concussive_Blast': '<:PharahConcussiveBlast:1230788587772186635>',
    'Barrage': '<:PharahBarrage:1230788588921294919> ',
    'Hover_Jets': '<:GenericPassive:1230618349961216021>',
  },
  'Ramattra': {
    'Void_Accelerator': '<:RamattraVoidAccelerator1:1230791144758312980><:RamattraVoidAccelerator2:1230791143478788177>',
    'Void_Barrier': '<:RamattraVoidBarrier:1230791150022037546>',
    'Pummel': '<:RamattraPummel1:1230791142220628059><:RamattraPummel2:1230791140937039923>',
    'Ravenous_Vortex': '<:RamattraRavenousVortex:1230791148105236480>',
    'Annihilation': '<:RamattraAnnihilation:1230791146473783348>',
  },
  'REAPER': {
    'HELLFIRE_SHOTGUNS': '<:ReaperHellFireShotguns1:1230860777976500244><:ReaperHellFireShotguns2:1230860776755957811>',
    // Bruh
    'SHADOWSTEEP': '<:ReaperShadowStep:1230861384762527798>',
    'WRAITHFORM': '<:ReaperWraithForm:1230861383302905918>',
    'DEATH_BLOSSOM': '<:ReaperDeathBlossom:1230861381855744051>',
    'THE_REAPING': '<:ReaperTheReaping:1230860779352358952>',
  },
  'REINHARDT': {
    'ROCKET_HAMMER': '<:ReinhardtRocketHammer1:1230866692318564505><:ReinhardtRocketHammer2:1230866691014000640>',
    'CHARGE': '<:ReinhardtCharge:1230866696831631410>',
    'FIRE_STRIKE': '<:ReinhardtFireStrike:1230866693643960411>',
    'BARRIER_FIELD': '<:ReinhardtBarrierField:1230866698492706968>',
    'EARTHSHATTER': '<:ReinhardtEarthShatter:1230866694931611710>',
  },
  'ROADHOG': {
    'SCRAPGUN': '<:RoadhogScrapGun:1230869699244593213>',
    'GRAPPLEHOOK': '<:RoadhogChainHook:1230869606004949062>',
    'TAKEABREATHER': '<:RoadhogTakeABreather:1230869599176888410>',
    'PIGPEN': '<:RoadhogPigPen:1230869604503519292>',
    'WHOLEHOG': '<:RoadogWholeHog:1230869597796962324>',
  },
  'SIGMA': {
    'HYPHERSPHERES': '<:SigmaHyperSpheres:1230862385439445073>',
    'KINETICGRASP': '<:SigmaKineticGrasp:1230862384156115095>',
    // AAAAAAAAAAAAAA
    'ACCERTION': '<:SigmaAccretion:1230862382658752582>',
    'EXPERIMENTALBARRIER': '<:SigmaExperimentalBarrier:1230862381043945482>',
    'GRAVITYFLUX': '<:SigmaGraviticFlux:1230862379219161089>',
  },
  'SOUJOURN': {
    'RAILGUN': '<:SojournRailgun1:1230871624958611556><:SojournRailgun2:1230871623205261365>',
    'POWERSLIDE': '<:SojournPowerSlide:1230871626376019989>',
    'DISRUPTOR_SHOT': '<:SojournDisruptorShot:1230871629978931250>',
    'OVERCLOCK': '<:SojournOverclock:1230871627835637863>',
  },
  'SOLDIER76': {
    'Heavy_Pulse_Rifle': '<:SoldierHeavyPulseRifle1:1230872833878523914><:SoldierHeavyPulseRifle2:1230872832460718150>',
    'Sprint': '<:SoldierSprint:1230872829642407996>',
    'Biotic_Field': '<:SoldierBioticField:1230872835459776532>',
    'Helix_Rockets': '<:SoldierHelixRockets:1230872831059824711>',
    'Tactical_Visor': '<:SoldierTacticalVisor:1230872828035731477>',
  },
  'SOMBRA': {
    'MACHINE_PISTOL': '<:SombraMachinePistol1:1230881970653892708><:SombraMachinePistol2:1230881969219440771>',
    'HACK': '<:SombraHack:1230881978610352130>',
    'STEALTH': '<:SombraStealth:1230881976844681256>',
    'TRANSLOCATOR': '<:SombraTranslocator:1230881975405903912>',
    'VIRUS': '<:SombraVirus:1230881973841694790>',
    'EMP': '<:SombraEMP:1230881972142735512>',
  },
  'SYMMETRA': {
    'PHOTON_PROJECTOR': '<:SymmetraPhotonProjector:1230883252525600789>',
    'SENTRY_TURRET': '<:SymmetraSentryTurret:1230883160431001704>',
    'TELEPORTER': '<:SymmetraTeleporter:1230883167678894120>',
    'PHOTON_BARRIER': '<:SymmetraPhotonBarrier:1230883165002797100>',
  },
  'TORBJORN': {
    'RIVETGUN': '<:TorbjornRivetGun:1230884785602170961>',
    'FORGEHAMMER': '<:TorbjornForgeHammer1:1230884669302636697><:TorbjornForgeHammer2:1230884667759132703>',
    'DEPLOYTURRET': '<:TorbjornDeployTurret:1230884676521037875>',
    'OVERLOAD': '<:TorbjornOverload:1230884674818146355>',
    'MOLTENCORE': '<:TorbjornMoltenCore:1230884673320648755>',
  },
  'TRACER': {
    'PISTOLS': '<:TracerPulsePistols:1230886010997440633> ',
    'BLINK': '<:TracerBlink:1230885712258273462>',
    'RECALL': '<:TracerRecall:1230885710823952474>',
    'PULSEBOMB': '<:TracerPulseBomb:1230885709515198464>',
  },
  'VENTURE': {
    'Primary_Fire': '<:VentureSMARTExcavator1:1230892059989114995><:VentureSMARTExcavator2:1230892058651394079>',
    'Dash': '<:VentureDrillDash:1230892064364040343>',
    'Burrow': '<:VentureBurrow:1230892063000625222>',
    'Ult': '<:VentureTectonicShock:1230892061658583040>',
  },
  'WIDOWMAKER': {
    'WIDOWSKISS': '<:WidowmakerWidowsKiss1:1230890371610050581><:WidowmakerWidowsKiss2:1230890370028671006>',
    'GRAPPLINGHOOK': '<:WidowmakerGrapplingHook:1230890375535792168>',
    'VENOMMINE': '<:WidowmakerVenomMine:1230890368493424660>',
    'INFRASIGHT': '<:WidowmakerInfraSight:1230890374034096169>',
  },
  'WINSTON': {
    'TESLACANNON': '<:WinstonTeslaCannon1:1230892944345534514><:WinstonTeslaCannon2:1230892942886043730>',
    'JUMPPACK': '<:WinstonJumpPack:1230892949102002347>',
    'PROJECTEDBARRIER': '<:WinstonBarrierProjector:1230892947696783440>',
    'PRIMALRAGE': '<:WinstonPrimalRage:1230892945691906139>',
  },
  'WRECKING_BALL': {
    'QUAD_CANNONS': '<:WBQuadCannons1:1230894554706743408><:WBQuadCannons2:1230894552965972039>',
    'GRAPPLING_CLAW': '<:WBGrapplingClaw:1230894562986168412>',
    'ROLL': '<:WBRoll:1230894561342001252>',
    'PILEDRIVER': '<:WBPileDriver:1230894559375130855>',
    'ADAPTIVE_SHIELD': '<:WBAdaptiveShields:1230894557814718485>',
    'MINEFIELD': '<:WBMineField:1230894556296253542>',
  },
  'ZARYA': {
    'PARTICLECANNON': '<:ZaryaParticleCannon1:1230896898856976486><:ZaryaParticleCannon2:1230896897292501092>',
    'PARTICLEBARRIER': '<:ZaryaParticleBarrier:1230896905744285736>',
    'PROJECTEDBARRIER': '<:ZaryaProjectedBarrier:1230896904100118599>',
    'GRAVITONSURGE': '<:ZaryaGravitonSurge:1230896902141378590>',
    'ENERGY': '<:ZaryaEnergy:1230896900400746668>',
  },
  'ZENYATTA': {
    'ORBSOFDESTURUCTION': '<:ZenOrbOfDestruction:1230899334447370261>',
    'ORBOFDISCORD': '<:ZenDiscordOrb:1230899332899930212>',
    'ORBOFHARMONY': '<:ZenHarmonyOrb:1230899330815234089>',
    // Help
    'TRANSENDENCE': '<:ZenTrans:1230899329754202173>',
    'SNAPKICK': '<:ZenSnapKick:1230899328395120772>',
  }
};

const timeoutLocalizations = [
  {
    Locale.fr: '1 minute',
    Locale.de: '1 Minute',
  },
  {
    Locale.fr: '5 minutes',
    Locale.de: '5 Minuten',
  },
  {
    Locale.fr: '10 minutes',
    Locale.de: '10 Minuten',
  },
  {
    Locale.fr: '1 heure',
    Locale.de: '1 Stunde',
  },
  {
    Locale.fr: '3 heures',
    Locale.de: '3 Stunden',
  },
  {
    Locale.fr: '6 heures',
    Locale.de: '6 Stunden',
  },
  {
    Locale.fr: '12 heures',
    Locale.de: '12 Stunden',
  },
  {
    Locale.fr: '1 jour',
    Locale.de: '1 Tag',
  },
  {
    Locale.fr: '2 jours',
    Locale.de: '2 Tage',
  },
  {
    Locale.fr: '3 jours',
    Locale.de: '3 Tage',
  },
  {
    Locale.fr: '1 semaine',
    Locale.de: '1 Woche',
  }
];

const embedTitleLimit = 256;
const embedDescriptionLimit = 4096;
const embedFooterLimit = 2048;
const embedAuthorNameLimit = 256;
const embedFieldsLimit = 25;
const embedFieldNameLimit = 256;
const embedFieldValueLimit = 1024;
