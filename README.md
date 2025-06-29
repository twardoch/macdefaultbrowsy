# macdefaultbrowsy

**Effortlessly manage your default web browser on macOS directly from the command line or your Python scripts.**

`macdefaultbrowsy` is a powerful yet simple command-line tool and Python library designed for macOS users and developers. It allows you to quickly view all installed web browsers, check the current default, and set a new default browser with a single command. Crucially, it intelligently automates the macOS confirmation dialog, so you don't have to lift a finger.

## Who is this for?

*   **macOS Power Users:** If you frequently switch browsers for different tasks or prefer keyboard-driven workflows, `macdefaultbrowsy` gives you precise control.
*   **Developers & Scripters:** Integrate default browser management into your Python applications, automation scripts, or development workflows.
*   **System Administrators:** A handy tool for configuring user setups or managing multiple machines.

## Why is it useful?

*   **Speed and Convenience:** List browsers or change your default in seconds without navigating through system settings.
*   **Seamless Automation:** Sets the default browser and automatically handles the macOS confirmation pop-up. No manual clicking is needed!
*   **Scriptable:** Easily incorporate into shell scripts or Python programs.
*   **Lightweight:** Minimal dependencies and a straightforward command-line interface.
*   **Universal:** Works on both Intel and Apple Silicon Macs.

## Features

*   **List Browsers:** Display all installed web browsers, clearly marking the current default (e.g., with `*`).
*   **Set Default Browser:** Change the system's default web browser by specifying its common name (e.g., `chrome`, `safari`, `firefox`).
*   **Automatic Dialog Confirmation:** When you set a new default browser, `macdefaultbrowsy` automatically interacts with the macOS system dialog to confirm the change.
*   **Python API:** A clean and simple API for programmatic control within Python projects.

## Installation

You can install `macdefaultbrowsy` using `uv` (or `pip`):

```bash
uv pip install --system macdefaultbrowsy
```

Alternatively, to install the latest development version directly from GitHub:

```bash
uv pip install --system git+https://github.com/twardoch/macdefaultbrowsy
```
*(Note: Using `--system` with `uv pip install` is typical for command-line tools intended for system-wide use. Adjust according to your Python environment management practices.)*

*(Homebrew installation might be available in the future.)*

## Usage

### Command-Line Interface (CLI)

The CLI is simple and intuitive.

#### List all browsers:

To see a list of all web browsers `macdefaultbrowsy` can find on your system, with the current default marked by an asterisk (`*`):

```bash
macdefaultbrowsy
```

**Example Output:**

```
* chrome
  firefox
  safari
  edge
  arc
```

#### Set default browser:

To change your default web browser, simply provide its name as an argument. `macdefaultbrowsy` will attempt to set it and handle the system confirmation.

```bash
macdefaultbrowsy firefox
```

If successful (and a change was needed), you'll see a confirmation:

```
INFO: Dialog confirmed with button: Use “Firefox”
INFO: Set firefox as default browser.
```

If the browser is already the default:

```bash
macdefaultbrowsy firefox
INFO: firefox is already the default browser.
```

If the browser name is not recognized:

```bash
macdefaultbrowsy nonexistentbrowser
ERROR: Browser 'nonexistentbrowser' not found.
```

### Python API

You can also use `macdefaultbrowsy` as a Python library in your own projects.

```python
from macdefaultbrowsy import macdefaultbrowsy
from loguru import logger # Optional: for similar logging output as CLI

# Configure logger if you want to see macdefaultbrowsy's info messages
# import sys
# logger.remove()
# logger.add(sys.stderr, format="{message}")

# Get the current default browser's short name (e.g., "chrome")
current_default = macdefaultbrowsy.get_default_browser()
if current_default:
    logger.info(f"Current default browser: {current_default}")
else:
    logger.warning("Could not determine the current default browser.")

# List all available browsers (returns a dictionary: {'name': 'bundle_id'})
available_browsers = macdefaultbrowsy.get_browsers()
logger.info("Available browsers:")
for name in sorted(available_browsers.keys()):
    bundle_id = available_browsers[name]
    logger.info(f"  - {name} (Bundle ID: {bundle_id})")

# Set a new default browser (e.g., "safari")
browser_to_set = "safari"
logger.info(f"Attempting to set '{browser_to_set}' as the default browser...")
success = macdefaultbrowsy.set_default_browser(browser_to_set)

if success:
    new_default = macdefaultbrowsy.get_default_browser()
    logger.info(f"Successfully set '{new_default}' as the default browser.")
else:
    logger.error(f"Failed to set '{browser_to_set}' as the default browser.")

# Example of trying to set a browser that's already default
# if current_default:
#   success_already_default = macdefaultbrowsy.set_default_browser(current_default)
#   logger.info(f"Attempt to set already default browser ('{current_default}') was successful: {success_already_default}")

# Example of trying to set a non-existent browser
# success_non_existent = macdefaultbrowsy.set_default_browser("fakebrowser")
# logger.info(f"Attempt to set non-existent browser was successful: {success_non_existent}")

```

## Technical Deep Dive

This section provides a more detailed look into how `macdefaultbrowsy` works, its codebase, and guidelines for contributors.

### How it Works

`macdefaultbrowsy` interacts with macOS at two main levels:

1.  **Launch Services API:**
    *   The core functionality of identifying available browsers and managing the default browser setting relies on the macOS Launch Services framework. This is accessed via the `pyobjc-framework-CoreServices` Python bindings.
    *   **Discovering Browsers:** The tool queries Launch Services for all registered application handlers for `http` and `https` URL schemes using `LSCopyAllHandlersForURLScheme`. An application is considered a web browser if it can handle both schemes. The common name (e.g., "chrome") is derived from its bundle ID (e.g., "com.google.Chrome").
    *   **Getting Default Browser:** The current default browser is determined by calling `LSCopyDefaultHandlerForURLScheme` for the `http` scheme.
    *   **Setting Default Browser:** To set a new default browser, `macdefaultbrowsy` calls `LSSetDefaultHandlerForURLScheme` for both `http` and `https` schemes, providing the bundle ID of the chosen browser.

2.  **Automatic Dialog Confirmation:**
    *   When the default browser is changed programmatically via Launch Services, macOS typically presents a confirmation dialog: *"Do you want to use <BrowserX> as your default browser?"*. This dialog is managed by the `CoreServicesUIAgent` process.
    *   To provide a seamless command-line experience, `macdefaultbrowsy` automates clicking the confirmation button (usually labeled "Use <BrowserX>" or similar).
    *   This automation is handled by `src/macdefaultbrowsy/dialog_automation.py`. When `set_default_browser` is called (and a change is necessary):
        *   A separate thread is spawned *before* the Launch Services call to change the default.
        *   This thread runs an AppleScript snippet using `osascript`. The script polls for the `CoreServicesUIAgent` window for up to 10 seconds (checking every 0.5 seconds).
        *   If the dialog appears, the script identifies the confirmation button by looking for titles containing the browser's display name (e.g., "Chrome", "Safari") or the word "Use". It then programmatically clicks this button.
        *   The main thread waits for the dialog automation thread to complete (with a timeout) after attempting to set the browser.
    *   If the browser is already the default, this dialog automation step is skipped to prevent hanging, as no dialog will appear.

### Code Structure

The project follows a standard Python package structure:

*   `src/macdefaultbrowsy/`: Main package directory.
    *   `__init__.py`: Package initializer, defines `__version__` (dynamically set by `hatch-vcs`).
    *   `macdefaultbrowsy.py`: Contains the core public API and logic:
        *   `get_browsers()`: Discovers available browsers.
        *   `get_default_browser()`: Retrieves the current default browser.
        *   `set_default_browser()`: Sets a new default browser, orchestrating Launch Services calls and dialog automation.
        *   `print_browsers_list()`: CLI helper to print the browser list.
        *   `_browser_name_from_bundle_id()`: Utility to simplify bundle IDs to common names.
    *   `__main__.py`: Provides the command-line interface using the `fire` library. It defines the `cli()` function that `fire` exposes.
    *   `launch_services.py`: A thin wrapper around the necessary `LaunchServices` API functions from `pyobjc-framework-CoreServices`. This isolates the `pyobjc` interactions.
    *   `dialog_automation.py`: Manages the AppleScript execution for automatic dialog confirmation.
        *   `start_dialog_confirmation()`: Starts the monitoring thread.
        *   `_monitor_and_click()`: The function running in the thread that polls and clicks the dialog button.
        *   `_dialog_browser_name()`: Helper to map internal browser names to display names used in dialogs.
        *   `_run_osascript()`: Executes an AppleScript string.
    *   `py.typed`: Marker file for PEP 561 compatibility, indicating the package supports type checking.
*   `tests/`: Contains unit tests for the project, primarily using `unittest.mock`.
*   `pyproject.toml`: Defines project metadata, dependencies, build system (`hatchling`), and tool configurations (ruff, pytest, mypy, coverage).
*   `README.md`: This file.
*   `LICENSE`: MIT License file.
*   `AGENT.md`, `CLAUDE.md`: Contain specific instructions and conventions for AI-assisted development.

### Key Dependencies

*   **`pyobjc-framework-CoreServices`**: Essential for interacting with macOS Launch Services to get and set the default browser.
*   **`fire`**: Used to quickly create the command-line interface from Python functions/objects in `__main__.py`.
*   **`loguru`**: Provides user-friendly logging for CLI output and internal messages.

Development and testing dependencies are listed in `pyproject.toml` under `[project.optional-dependencies]`.

### Development and Contribution

We welcome contributions! Please adhere to the following guidelines, many of which are inspired by `AGENT.md` and `CLAUDE.md` in this repository.

#### Setup

1.  Clone the repository.
2.  It's recommended to use a virtual environment.
3.  Install the package in editable mode with development and test dependencies:
    ```bash
    uv pip install -e ".[dev,test,all]"
    ```
4.  Install pre-commit hooks to ensure code quality before committing:
    ```bash
    pre-commit install
    ```

#### Coding Conventions & Style

*   **General Principles (from `AGENT.md`/`CLAUDE.md`):**
    *   Iterate gradually; prefer minimal viable increments.
    *   Write clear, explanatory docstrings (PEP 257, imperative mood) and comments. Explain the "what" and the "why".
    *   Maintain the `this_file: path/to/file.py` comment near the top of each Python source file.
    *   Favor flat over nested structures.
    *   Handle failures gracefully.
*   **Python Specifics:**
    *   Follow PEP 8 for code style. `ruff format` handles most of this.
    *   Use `uv pip` for package management and `python -m` when running modules or scripts where appropriate.
    *   Employ type hints (simplest form: `list`, `dict`, `|` for unions).
    *   Use f-strings for string formatting.
    *   The CLI (`__main__.py`) uses `fire` and `loguru`.
*   **Code Formatting and Linting:**
    *   This project uses `ruff` for linting and formatting. Configuration is in `pyproject.toml`.
    *   The `pre-commit` hooks will automatically run formatters and linters.
    *   To manually format and lint, you can use the `hatch` environment scripts (e.g., `hatch run lint:fix`) or the command specified in `AGENT.MD`/`CLAUDE.MD`:
        ```bash
        fd -e py -x autoflake {} \; \
        fd -e py -x pyupgrade --py311-plus {} \; \
        fd -e py -x ruff check --output-format=github --fix --unsafe-fixes {} \; \
        fd -e py -x ruff format --respect-gitignore --target-version py311 {}
        ```
        *(`fd-find` (often installed as `fd`) might be required for the `fd` command. Adapt if necessary.)*

#### Testing

*   Write tests for new features and bug fixes in the `tests/` directory.
*   This project uses `pytest`.
*   Run tests using:
    ```bash
    python -m pytest
    ```
    or via hatch:
    ```bash
    hatch run test
    ```
*   Ensure good test coverage. You can check coverage with:
    ```bash
    hatch run test:test-cov
    ```
    Coverage reports are configured in `pyproject.toml`.

#### Building the Package

*   The package is built using `hatchling`.
*   To build wheels and source distributions:
    ```bash
    python -m build
    ```
    or
    ```bash
    hatch build
    ```
    Artifacts will be placed in the `dist/` directory.

#### Versioning

*   The version is managed dynamically by `hatch-vcs` using Git tags.
*   When preparing a release, tag the commit with `vX.Y.Z` (e.g., `v0.1.1`). `hatch-vcs` will update `src/macdefaultbrowsy/__version__.py` during the build process.

#### Commit Messages and Pull Requests

*   Write clear and concise commit messages.
*   If contributing, please fork the repository, create a feature branch, and submit a pull request.

## References

*   For a similar tool written in Swift, see [macdefaultbrowser by Adam Twardoch](https://github.com/twardoch/macdefaultbrowser).

## License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for full details.
