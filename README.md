Shiny Odds adds a selectable shiny encounter rate to Pokemon Emerald. Persona: QoL tinkerer.

Enable the mod in the mod manager, then open START > OPTIONS > EXTRAS > SHINY ODDS and use left/right to choose a rate: DEFAULT (vanilla 1/8192), 1/4096, 1/2048, 1/1024, 1/512, 1/256, 1/128, 1/64, 1/32, or 100%. The default is DEFAULT.

Any rate other than DEFAULT rolls once per Pokemon the first time its shiny status is checked, and the result is cached on that Pokemon from then on -- including Pokemon already in your save the first time they're displayed after enabling the mod. DEFAULT always uses the vanilla personality/OT formula.

The mod requests `engine_internals` access to add its row to Emerald's options menu and to override the shiny check, since neither is exposed as a public hook today.

Pull requests targeting `main` or `master` run the mod test, strict validation, lint, and packaging checks. A successful merge publishes a `vX.Y.Z` GitHub Release with an installable ZIP; the manifest's GitHub source enables the game's Update and Versions controls.

Run these commands from the workspace root:

```sh
python3 gen1recomp/tools/modkit.py --repo gen1recomp validate mods/shiny_odds --base imported
python3 gen1recomp/tools/modkit.py --repo gen1recomp lint mods/shiny_odds
python3 gen1recomp/tools/modkit.py --repo gen1recomp pack mods/shiny_odds -o shiny_odds-0.0.1.modpkg
```
