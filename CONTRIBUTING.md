# Contributing to Cadenza

First off, thank you for considering contributing to Cadenza! It's people like you that make Cadenza a powerful and flexible tool for generative music.

## How Can I Contribute?

### Reporting Bugs

If you find a bug, please check the issue tracker to see if it has already been reported. If not, open a new issue using the Bug Report template. Please include as much detail as possible:

- Your operating system and ChucK version.
- Steps to reproduce the behavior.
- Any terminal output, OSC errors, or GUI console logs.

### Suggesting Enhancements

We welcome suggestions for new generative algorithms, core framework features, or GUI improvements! Open a new issue using the Feature Request template to discuss your idea before writing any code. This ensures your time is well-spent and the feature aligns with the project's goals.

### Code Contributions

1. **Fork the repository** on GitHub.
2. **Clone your fork** locally.
3. **Create a new branch** for your feature or bugfix (`git checkout -b feature/my-new-feature`).
4. **Make your changes**. 
5. **Test your changes** thoroughly. If you are modifying the core framework, ensure that existing `music/*.ck` scripts continue to run correctly.
6. **Commit your changes** with a descriptive commit message (`git commit -am 'Add some feature'`).
7. **Push to your branch** (`git push origin feature/my-new-feature`).
8. **Submit a Pull Request** against the `main` branch.

## Development Setup

Cadenza has two main components: the ChucK framework and the Node.js Dashboard.

### ChucK Framework (`/framework` and `/music`)
- Ensure you have the latest version of [ChucK](https://chuck.cs.princeton.edu/) installed.
- All core logic goes into `/framework`.
- Example songs and performance scripts belong in `/music`.

### Live Dashboard (`/gui`)
- Ensure you have [Node.js](https://nodejs.org/) installed.
- Run `npm install` inside the `gui/` directory.
- Use `npm start` to run the WebSocket bridge.
- The front-end is vanilla HTML/JS/CSS in `index.html`.

## Code Style

- **ChucK**: Follow the existing indentation style (4 spaces) and naming conventions (camelCase for variables, PascalCase for classes). Ensure scripts are deterministic where possible.
- **JavaScript**: Follow standard ES6 conventions. Keep the frontend lightweight and avoid bringing in massive frameworks unless absolutely necessary.

## License

By contributing to Cadenza, you agree that your contributions will be licensed under the MIT License.
