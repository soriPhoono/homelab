# TODO

These are the tasks that are intended for future development goals

- [x] For each module
  - [x] Update option descriptions (multiline strings, accurate descriptions, examples where applicable)
  - [x] Each module uses with lib;
  - [x] Each module has slim imports
  - [x] Each module declares as little as possible in the root let in binding
  - [x] Each module has an enable option
  - [x] Each module uses mkMerge EVEN IF IT IS NOT NEEDED
  - [x] Each module guards dependencies (options ? "dependency name") for easy removal
  - [x] Each home manager option from nixos configuration is apropriately set
  - [x] Each home manager feature requiring prerequisite nixos configuration is apropriately guarded or errors
  - [x] EVERY variable read is properly guarded or throws documented errors
- [x] Configure hermes agent in some form
  - [x] Research if hermes agent supports multi user configuration
    - [x] if yes create server deployment as this is an always on service
- [ ] Configure hermes agent
  - [x] office skills
    - [x] pdf skills
    - [x] docx skills
    - [x] xlsx skills
    - [x] pptx skills
  - [ ] reddit search skill
  - [ ] configure local matrix server for bot accounts
- [x] Bifrucate noctalia shell configuration from core to home
  - [x] Move shell configuration to home
  - [x] Create a nix module option for shell configuration
  - [x] Update noctalia configuration to use new shell configuration
- [ ] Add support for multiple bootloaders
- [x] Finish configuring greetd display manager
- [ ] Test vr support on desktop
- [ ] Finish implementing better security hardening
- [ ] Implement impermenance on all nixos devices
- [ ] Recreate the neovim configuration system that allows for creation of nixvim customized neovim editors
- [ ] Recreate nix on droid configuration system as second type of system
- [x] Create editor system that can contain an "editor agent", allowing for easier configuration of newer editors
- [x] Fix agent system
