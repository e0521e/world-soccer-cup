-- Client entry point — initializes Knit and registers all Controllers
local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

-- Recursively discover and register every ModuleScript under controllers/
-- NOTE: Rojo 7's init.* convention makes src/client/ the LocalScript instance,
-- so children are accessed via script.X, not script.Parent.X.
--       Child names match the filesystem casing (lowercase).
Knit.AddControllersDeep(script.controllers)

-- Start Knit and wait until all Services are ready before proceeding
Knit.Start({ServicePromises = false}):catch(warn):await()
