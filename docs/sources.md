# Sources and storytelling rules

## Rules the game follows

- **The Prophet ﷺ is never shown.** There is no model, image, voice or silhouette of him. He
  appears only as his written name followed by ﷺ. A unit test (`tests/luau/seerah.spec.luau`)
  fails if any campaign text says "the Prophet" or "Prophet Muhammad" without ﷺ.
- **Companions (Sahabah) have blank faces.** `Figures.StripFaces` removes face decals,
  textures and face accessories from every guide and townsperson. In the mysteries, companions
  are only named in text and have no character model.
- **History and gameplay are kept apart.** Each Seerah chapter has a `GameplayNote`, each
  mystery has a `FictionNote`, and the co-op and battle signs say which parts are game
  inventions. Historical towns carry "Historical reconstruction" signs.
- **Present day and history are separate places.** Present-day Masjid al-Haram and the Prophet's
  Mosque are in the hub (within about 2,400 studs of the origin). Historical Makkah (610 CE) and
  Madinah (622 CE) are at x = 4000, the mystery wing and co-op trials at x = -4000. The hub test
  checks that no zone overlaps the hub or another zone.

## Main references

- The Qur'an (verses cited per chapter, for example 96:1-5, 105:1-5, 8:9-12, 3:121-172).
- Sahih al-Bukhari and Sahih Muslim (hadith numbers as in the sunnah.com numbering).
- Sunan Abi Dawud, Jami' al-Tirmidhi, Musnad Ahmad (cited where used).
- Ibn Hisham, *al-Sirah al-Nabawiyyah*, trans. A. Guillaume, *The Life of Muhammad* (1955).
- Safiur-Rahman al-Mubarakpuri, *Ar-Raheeq al-Makhtum* (The Sealed Nectar).
- Martin Lings, *Muhammad: His Life Based on the Earliest Sources*.
- Al-Dhahabi, *Siyar A'lam al-Nubala'* (for companion biographies).

The full per-chapter and per-mystery list is in [seerah-checklist.md](seerah-checklist.md).

## Review still needed

The content was written from these sources but **has not been checked by a qualified scholar**.
Before release, someone qualified should check every hadith number, date, casualty figure and
quote, especially:

- Badr and Uhud "how it ended" lines (casualty numbers follow Ibn Hisham).
- Chapter dates given as "about" (the early Makkan years are approximate in the sources).
- The Sahabi mystery clues, which paraphrase the sources.
