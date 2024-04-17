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
  }
};
