This game has been in production for years and needs some last few tasks to be completed. 

Resources:
Godot Docs: https://docs.godotengine.org/en/4.3/
Installed Godot Executable: ~/Apps/Godot/Godot.x86_64
Campaigns: ~/Dev/maps/



TODO:
- [ ] Windows / Mac / Linux  builds. Include build scripts to run these.
(I know we are unable to build for Mac on this machine, instead just create a placeholder script)
Shell scripts should be created for each build.

- [ ] Generic Launcher. The game currently uses CLI arguments to launch. There
should be a user facing launcher with a GUI that launches the game. This can
be a seperate Scene with a build that only builds on the launcher scene. The
launcher scene should not be included in the game builds. 

- [ ] User facing documentation. We need user facing documentation to explain
how to set up and run this game. AND documentation to provide the entire
isometry sdk for content creators. Use a `ebk` (a local project on this machine
for creating ebooks located at ~/Dev/ebk/) compatible format such as markdown
to write the documentation.

- [ ] Optimize. Look for easy optimizations in the code base that will improve
the game. (Be very cautions about making these types of changes as it can
easily lead to more bugs.)

- [ ] Create a simple `demo` campaign that contains an example of all entity
types. The current `Maze` campaign is okay, but it's a complete mess. 
Include the demo campaign in this project.

- [ ] Select a license. We plan to release this game for free, but it shall not be open source or be allowed for external distribution.


Clause:
Analyze this code base and understand ALL parts of it. Then tackle the above todo list.


