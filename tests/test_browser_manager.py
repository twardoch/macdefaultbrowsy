# this_file: tests/test_browser_manager.py

from unittest import mock
import pytest
from macdefaultbrowsy import macdefaultbrowsy


@mock.patch("macdefaultbrowsy.macdefaultbrowsy.launch_services.get_all_handlers_for_scheme")
def test_get_browsers(mock_get_all_handlers):
    """Test getting available browsers that handle both http and https."""
    mock_get_all_handlers.side_effect = [
        ["com.apple.Safari", "com.google.Chrome"],
        ["com.apple.Safari", "com.google.Chrome", "org.mozilla.firefox"],
    ]

    browsers = macdefaultbrowsy.get_browsers()

    assert "safari" in browsers
    assert "chrome" in browsers
    assert "firefox" not in browsers  # It's not a handler for both http and https
    assert browsers["safari"] == "com.apple.Safari"


@mock.patch("macdefaultbrowsy.macdefaultbrowsy.launch_services.get_current_handler_for_scheme")
def test_get_default_browser(mock_get_current_handler):
    """Test getting the current default browser."""
    mock_get_current_handler.return_value = "com.apple.Safari"

    browser = macdefaultbrowsy.get_default_browser()

    assert browser == "safari"


@mock.patch("macdefaultbrowsy.macdefaultbrowsy.launch_services.get_current_handler_for_scheme")
def test_get_default_browser_none(mock_get_current_handler):
    """Test getting default browser when none is set."""
    mock_get_current_handler.return_value = None

    browser = macdefaultbrowsy.get_default_browser()

    assert browser is None


@mock.patch("macdefaultbrowsy.macdefaultbrowsy.get_browsers")
@mock.patch("macdefaultbrowsy.macdefaultbrowsy.launch_services.set_default_handler_for_scheme")
@mock.patch("macdefaultbrowsy.macdefaultbrowsy.dialog_automation.start_dialog_confirmation")
@mock.patch("macdefaultbrowsy.macdefaultbrowsy.get_default_browser")
def test_set_default_browser_success(mock_get_default, mock_start_dialog, mock_set_handler, mock_get_browsers):
    """Test successfully setting a default browser."""
    mock_get_browsers.return_value = {"safari": "com.apple.Safari"}
    mock_get_default.return_value = "chrome"  # Currently different browser
    mock_set_handler.return_value = True
    mock_thread = mock.Mock()
    mock_start_dialog.return_value = mock_thread

    success = macdefaultbrowsy.set_default_browser("safari")

    assert success
    mock_set_handler.assert_any_call("com.apple.Safari", "http")
    mock_set_handler.assert_any_call("com.apple.Safari", "https")
    mock_thread.join.assert_called_once_with(timeout=10.0)


@mock.patch("macdefaultbrowsy.macdefaultbrowsy.get_browsers")
@mock.patch("macdefaultbrowsy.macdefaultbrowsy.get_default_browser")
def test_set_default_browser_already_default(mock_get_default, mock_get_browsers):
    """Test setting browser that's already the default."""
    mock_get_browsers.return_value = {"safari": "com.apple.Safari"}
    mock_get_default.return_value = "safari"

    success = macdefaultbrowsy.set_default_browser("safari")

    assert success


@mock.patch("macdefaultbrowsy.macdefaultbrowsy.get_browsers")
def test_set_default_browser_not_found(mock_get_browsers):
    """Test setting a browser that doesn't exist."""
    mock_get_browsers.return_value = {"safari": "com.apple.Safari"}

    success = macdefaultbrowsy.set_default_browser("nonexistent")

    assert not success


def test_browser_name_from_bundle_id():
    """Test extracting browser name from bundle ID."""
    assert macdefaultbrowsy._browser_name_from_bundle_id("com.apple.Safari") == "safari"
    assert macdefaultbrowsy._browser_name_from_bundle_id("com.google.Chrome") == "chrome"
    assert macdefaultbrowsy._browser_name_from_bundle_id("org.mozilla.firefox") == "firefox"


@mock.patch("macdefaultbrowsy.macdefaultbrowsy.get_browsers")
@mock.patch("macdefaultbrowsy.macdefaultbrowsy.get_default_browser")
@mock.patch("macdefaultbrowsy.macdefaultbrowsy.logger")
def test_print_browsers_list(mock_logger, mock_get_default, mock_get_browsers):
    """Test printing the browsers list with default marked."""
    mock_get_browsers.return_value = {"safari": "com.apple.Safari", "chrome": "com.google.Chrome"}
    mock_get_default.return_value = "safari"

    macdefaultbrowsy.print_browsers_list()

    # Check that logger.info was called with the correct messages
    mock_logger.info.assert_any_call("* safari")
    mock_logger.info.assert_any_call("  chrome")
