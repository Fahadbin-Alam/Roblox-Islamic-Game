--!strict

-- Every Islamic Studies lesson paired with its server-only answer key, keyed by lesson id.
-- Built once per server (ModuleScripts are cached) and shared by ProgressionService,
-- StudyCircleService and PlayerProgress. Errors at startup if the lesson file and the key
-- file have drifted apart.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local IslamicStudies = require(ReplicatedStorage:WaitForChild("Shared").Data.IslamicStudies)
local LessonAnswers = require(script.Parent.LessonAnswers)
local LessonGrading = require(script.Parent.LessonGrading)

return LessonGrading.BuildIndex(IslamicStudies, LessonAnswers)
