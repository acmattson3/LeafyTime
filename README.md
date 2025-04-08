# LeafyTime

[LeafyTime](https://www.andrew-mattson.com/projects/programming/leafytime) is a productivity application designed to motivate users through gamified study sessions. By combining study tracking with a relaxing 3D garden simulation, users can grow virtual plants based on the time they spend focused on productive work. Built with the Godot 4 Engine, LeafyTime promotes effective time management by transforming study sessions into a visually rewarding experience.

## Features

- **Interactive Study Tracking**: Grow virtual plants by completing study sessions. Watch them grow as you reach your productivity goals.
- **Customizable Study Sessions**: Set your study goals with precise durations, ranging from minutes to hours.
- **3D Garden Simulation**: Create your own garden filled with a variety of plants. Each plant represents your productivity and grows as you stay on track.
- **Exploration Mode**: Immerse yourself in your garden through first-person exploration. Experience the fruits of your focused sessions.
- **Distraction Detection (Optional)**: Track window usage during study sessions to ensure focus. This feature is entirely optional and respects user privacy.
- **Pomodoro Timers (Optional)**: Choose to use Pomodoro-style timers rather than the built-in study system.

## Getting Started

### How to Use
If you are simply wanting to use this application as-is, simply **download the application from the** [**releases page**](https://github.com/acmattson3/LeafyTime/releases). 

If your platform isn't supported and you would like to make it work, or if you want to customize this project to your liking, you will need to **build it for yourself** within Godot. If that is you, continue reading.

### Prerequisites for Building Yourself
- **Godot 4.3** or newer.
- **SCons** (for building GDExtensions).
- **WSL2** (if building on Windows).

### Installation
1. **Clone the Repository**
   ```sh
   git clone https://github.com/acmattson3/LeafyTime.git
   cd LeafyTime
   ```
2. **Compile GDExtensions**
   - Navigate into the `cpp_src` directory, and clone the godot-cpp repository:
     ```sh
     cd cpp_src
     git clone https://github.com/godotengine/godot-cpp
     ```
   - Navigate into the `godot-cpp` directory, checkout the relevant branch version, and compile it with scons:
     ```sh
     cd godot-cpp
     git checkout 4.3
     scons platform=<your platform>
     ```
   - Navigate back into the `cpp_src` directory and compile the source code with scons to build the extensions:
     ```sh
     scons platform=<your platform>
     ```

3. **Open Project in Godot**
   - Start **Godot 4**, navigate to the project folder, and open `project.godot`.

## Contributing
Contributions are welcome! If you have ideas for enhancing LeafyTime, feel free to fork the repository, make your changes, and submit a pull request.

### How to Contribute
1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Future Ideas
Here is an extensive list of features I may add to the project at some point if others find interest in it:
* [ ] Ability to change plant traits (e.g., color) using "fertilizer" currency earned through studying.
* [ ] Allow users to delete plants.
* [ ] Allow users to transplant plants (once a day?).
* [ ] Allow users to earn exceptions for not completing study sessions.
* [ ] Add creatures (bugs, critters) that interact with plants.
  * [ ] Maybe certain creatures only show up when certain combinations of plants are nearby (Ex., A tree next to a flower might spawn bees)
* [ ] Exploration quests with a camera (i.e., take a photo of a bee on a flower)
* [ ] Journaling (shows what creatures you have discovered with sections for custom notes; keeps all of your taken photos)
* [ ] Bigger map with more features (waterfalls, rivers, hills, etc)
* [ ] Achievements/Challenges with placeable trophies for each upon completion
* [ ] "Raindrop" currency for unlocking decor (benches, fountains, fences, etc)
* [ ] World sharing (see your friends' worlds)
  * [ ] Full multiplayer worlds; hang out with friends in your worlds.
  * [ ] Collaborative challenges
* [ ] Unlockable expansion areas (using currencies or study time, or a combination)
* [ ] Unlockable environments that interact with plants or introduce new creatures
* [ ] Seasons (and with them, special events)
* [ ] Weather system
* [ ] Plant interactivity (i.e., pick flowers, harvest fruit)
* [ ] Integrated task list with goal linking
* [ ] Session statistics (# of distractions n stuff)
* [ ] Leaderboards

## License
Distributed under the **MIT License**. See `LICENSE` for more information.

---

If you enjoy LeafyTime, please consider giving the repository a star! Your feedback and suggestions are always appreciated.

