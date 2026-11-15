# Content audit before publishing (2026-11-15)

Two reviewers checked every Qur'an reference, hadith number, date, number, dua and quiz answer
key in `src/ReplicatedStorage/Shared/Data/` against the Qur'an (quran.com), sunnah.com numbering
and the sirah works in [sources.md](sources.md). This is **not a scholar review**. It catches wrong
citations and wording; the "Needs a scholar" lists below are what a qualified person should decide.

**Result:** no wrong quiz answer, no invented hadith, and the Prophet ﷺ is never shown or voiced.
19 problems were found (1 wrong citation, 2 misleading, 16 minor) and **all are fixed in this
change**. About 55 hadith references and 30 Qur'an references were confirmed correct.

## Fixed

| File | Was | Now |
|---|---|---|
| BattleScenarios.lua (Badr summary) | 70 killed / 70 captured cited to Bukhari 3976 (that hadith is the well of Badr) | Bukhari 3986; the 14 martyrs credited to Ibn Hisham |
| BattleMissions.lua (Uhud "Climb the slope") | Qur'an 3:153 used as heroic narration for the regroup | Framed as the verse means it: believers fled while the Messenger ﷺ called them back |
| IslamicStudies.lua (Farewell Hajj) | "his only Hajj", quiz answer "Once" | "his only Hajj after the Hijrah" (Tirmidhi 815 reports Hajj before it) |
| IslamicStudies.lua (salah quiz) | Al-Fatihah "in every rak'ah" and salam "right then left" as the only way | Explanations note the Hanafi (behind an imam) and Maliki (one salam) positions |
| IslamicStudies.lua (masjid duas) | Right/left foot cited to Muslim 713 | Citation now covers only the duas, which is what Muslim 713 contains |
| IslamicStudies.lua (Hajj rites) | "standing in prayer at Arafah" | "spending the Day of Arafah in dua and remembrance of Allah" |
| SeerahCampaign.lua (Abyssinia) | Source Qur'an 19:16-36, story says "the opening of Surah Maryam" | 19:1-36 |
| SeerahCampaign.lua (Tabuk) | Delegations came "in the following year" | "After Tabuk" (the Year of Delegations is 9 AH itself) |
| SeerahCampaign.lua (childhood) | Abu Talib cared for him "for the rest of his life" | "for the rest of Abu Talib's life" |
| SeerahCampaign.lua (Masjid an-Nabawi land) | Lesson about orphans who "could not have argued for a better price" | He insisted on paying though they offered it as a gift (Bukhari 3906) |
| SeerahCampaign.lua, BattleMissions.lua (Badr wells) | "last well" in one file, "nearest well" in the other | Both: the well nearest the enemy |
| SeerahCampaign.lua (Farewell sermon) | "no white person better than a black person" | "no light-skinned person better than a dark-skinned person" (Ahmad 23489 says "red") |
| BattleScenarios.lua (Uhud memory) | Bukhari 4422 quoted without speaker or time | Said by the Prophet ﷺ on returning from Tabuk |
| SahabiMysteries.lua (Salman) | Sold "to a man of Yathrib" | Sold at Wadi al-Qura, later taken to Yathrib (Ahmad 23737) |
| SahabiMysteries.lua (Uthman) | Tirmidhi cited with no number | Tirmidhi 3703 |
| CompanionStories.lua | "Surah Al-Ma'idah 8" | 5:8 |
| TriviaQuestions.lua | Badr distractor "The first adhan" (also before Badr) | "The Conquest of Makkah" |
| CompanionStories, IslamicStudies, TriviaQuestions, BattleMissions, BattleScenarios | About 20 mentions of "the Prophet" / "the Messenger" with no salawat | ﷺ added |

## Needs a scholar: Seerah and battles


1. **SeerahCampaign.lua:818 (conquest of Makkah):** "forgiven and told they were free to go". The general amnesty is well established (Muslim 1780: safety for those in their homes, the Haram, or Abu Sufyan's house). But the famous wording "Go, you are free (al-tulaqa')" comes from Ibn Ishaq without a connected chain, and several hadith scholars grade it weak (e.g. al-Albani, Silsilat al-Da'ifah). The game paraphrases it rather than quoting it. Confirm whether the wording is acceptable.
2. **SeerahCampaign.lua:667 / BattleMissions.lua:189 (al-Hubab's advice at Badr):** Ibn Ishaq's chain for this is reported as weak by some modern muhaddithun. The text already hedges in the missions ("The sirah reports"). Consider the same hedge in the campaign.
3. **SeerahCampaign.lua:127 (Hilf al-Fudul):** "He later said he would answer such a call even in Islam". This is reported by Ibn Ishaq and al-Bayhaqi, and graded acceptable by some, but it is not in the Sahihayn. Confirm whether to label it "reported".
4. **SeerahCampaign.lua:558 / 568 (land of the two orphans):** "It was bought from them". Some editions of Bukhari 3906 (Arabic) add that he refused the gift and bought it. The common English (Khan) text on sunnah.com shows only the offer of a gift, and Bukhari 428 has Banu al-Najjar refusing payment. Confirm against the Arabic and Fath al-Bari.
5. **SeerahCampaign.lua:470 (Abu Bakr becomes al-Siddiq after the Isra):** This comes from al-Hakim's Mustadrak, not Bukhari 349, which the chapter cites. Consider adding the Mustadrak reference, or say "reported".
6. **SeerahCampaign.lua:669 (captives taught "ten" children):** Ahmad 2216 does not give the number ten. "Ten" comes from Ibn Sa'd's Tabaqat (al-Sha'bi). Ar-Raheeq al-Makhtum, which the chapter cites, does mention ten.
7. **SeerahCampaign.lua:299 ("Be patient, family of Yasir, your promised place is Paradise"):** This is in al-Hakim and Ibn Ishaq and is generally graded hasan. Fine to keep, but a scholar may want "reported".
8. **BattleMissions.lua:382 (Archers' Hill "south-west of the camp"):** This is game geography. Some sirah works place Jabal al-Rumah to the south or south-east of the Muslim position at the foot of Uhud. Decide whether players need a note that the layout is not to scale.

## Needs a scholar: studies, stories and mysteries


1. **Wudu and salah madhhab details.** The lessons carry disclaimers (IslamicStudies.lua:259, 314). A teacher may still want to review the points the steps imply:
   - intention is a fard in three schools but a sunnah for Hanafis;
   - Bismillah is wajib in a known Hanbali position, a sunnah for others;
   - the head is wiped once (Shafi'is recommend three times);
   - Maliki taslim (see the table);
   - al-Fatihah behind the imam (see the table).
2. **Hajj count (IslamicStudies.lua:967).** The pre-Hijrah Hajj reports (Tirmidhi 815) are graded weak or gharib by some. A scholar should confirm the preferred wording for children.
3. **CompanionStories.lua:31: the title as-Siddiq coming from the Isra'.** This is well known, but the report is in al-Hakim's Mustadrak and Ibn Hisham, not in the Sahihayn. Consider citing it rather than leaving it uncited.
4. **SahabiMysteries.lua:131: Salman suggesting the trench.** This is widely reported (Ibn Sa'd, al-Waqidi, and Ar-Raheeq) but is not in the Sahih collections. Fine to keep, but it rests on sirah sources.
5. **SahabiMysteries.lua:159: "Its owner sold every bucket".** This detail of the Rumah story comes from reports outside Tirmidhi 3703 (e.g. al-Baghawi and al-Tabarani). It is inside the fiction clue, so it is low risk.
6. **SahabiMysteries.lua:205, 229: Asma carrying food for three nights.** The nightly food is from Ibn Ishaq. Bukhari 3905 names Abdullah ibn Abi Bakr (news) and Amir ibn Fuhayrah (milk) for the nights in the cave. Acceptable on Ibn Hisham's authority.
7. **CompanionStories.lua:384: Tirmidhi 3686** is graded hasan gharib, not sahih. Labelled "Related Hadith", which is acceptable. A scholar may want the grade shown.
8. **HaramLearningTrail.lua:62: "thirteen minarets"** after the King Abdullah expansion. I believe this is correct but did not confirm it against an official source.
