# LeafyTime

LeafyTime is a productivity application designed to motivate users through gamified study sessions. By combining study tracking with a relaxing 3D garden simulation, users can grow virtual plants based on the time they spend focused on productive work. Built with the Godot 4 Engine, LeafyTime promotes effective time management by transforming study sessions into a visually rewarding experience.

## Key Features

- **Interactive Study Tracking**: Earn virtual plants by completing study sessions. Watch them grow as you reach your productivity goals.
- **Customizable Study Sessions**: Set your study goals with precise durations, ranging from minutes to hours.
- **3D Garden Simulation**: Create your own garden filled with a variety of plants. Each plant represents your productivity and grows as you stay on track.
- **Exploration Mode**: Immerse yourself in your garden through first-person exploration. Experience the fruits of your focused sessions.
- **Distraction Detection (Optional)**: Track window usage during study sessions to ensure focus. This feature is entirely optional and respects user privacy.

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
   - Navigate into the `godot-cpp` directory, and compile it with scons:
     ```sh
     cd godot-cpp
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

## License
Distributed under the **MIT License**. See `LICENSE` for more information.

---

If you enjoy LeafyTime, please consider giving the repository a star! Your feedback and suggestions are always appreciated.

