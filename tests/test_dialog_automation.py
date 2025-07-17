# this_file: tests/test_dialog_automation.py

from unittest import mock
import pytest
import threading
from macdefaultbrowsy import dialog_automation


def test_dialog_browser_name():
    """Test browser name mapping for dialog display."""
    assert dialog_automation._dialog_browser_name("chrome") == "Chrome"
    assert dialog_automation._dialog_browser_name("safari") == "Safari"
    assert dialog_automation._dialog_browser_name("firefox") == "Firefox"
    assert dialog_automation._dialog_browser_name("firefoxdeveloperedition") == "Firefox"
    assert dialog_automation._dialog_browser_name("edgemac") == "Edge"
    assert dialog_automation._dialog_browser_name("chromium") == "Chromium"
    assert dialog_automation._dialog_browser_name("unknown") == "Unknown"


@mock.patch("macdefaultbrowsy.dialog_automation.subprocess.run")
def test_run_osascript_success(mock_run):
    """Test successful osascript execution."""
    mock_result = mock.Mock()
    mock_result.stdout = "  test output  \n"
    mock_run.return_value = mock_result
    
    result = dialog_automation._run_osascript("test script")
    
    assert result == "test output"
    mock_run.assert_called_once_with(
        ["osascript", "-e", "test script"],
        capture_output=True,
        text=True,
        check=True
    )


@mock.patch("macdefaultbrowsy.dialog_automation.subprocess.run")
def test_run_osascript_failure(mock_run):
    """Test osascript execution failure."""
    mock_run.side_effect = subprocess.CalledProcessError(1, ["osascript"])
    
    result = dialog_automation._run_osascript("test script")
    
    assert result is None


@mock.patch("macdefaultbrowsy.dialog_automation.time.sleep")
@mock.patch("macdefaultbrowsy.dialog_automation._run_osascript")
@mock.patch("macdefaultbrowsy.dialog_automation.logger")
def test_monitor_and_click_success(mock_logger, mock_run_osascript, mock_sleep):
    """Test successful dialog monitoring and clicking."""
    mock_run_osascript.return_value = "Clicked:Use Chrome"
    
    dialog_automation._monitor_and_click("chrome")
    
    mock_run_osascript.assert_called_once()
    mock_logger.info.assert_called_once_with(
        "Dialog confirmed with button: {}", "Use Chrome"
    )
    # Should only sleep once before clicking
    mock_sleep.assert_called_once_with(0.5)


@mock.patch("macdefaultbrowsy.dialog_automation.time.sleep")
@mock.patch("macdefaultbrowsy.dialog_automation._run_osascript")
@mock.patch("macdefaultbrowsy.dialog_automation.logger")
def test_monitor_and_click_timeout(mock_logger, mock_run_osascript, mock_sleep):
    """Test dialog monitoring timeout."""
    mock_run_osascript.return_value = "No-window"
    
    dialog_automation._monitor_and_click("chrome")
    
    # Should try 20 times
    assert mock_run_osascript.call_count == 20
    assert mock_sleep.call_count == 20
    mock_logger.warning.assert_called_once_with(
        "Failed to auto-confirm the default-browser dialog."
    )


@mock.patch("macdefaultbrowsy.dialog_automation._monitor_and_click")
def test_start_dialog_confirmation(mock_monitor):
    """Test starting dialog confirmation thread."""
    thread = dialog_automation.start_dialog_confirmation("chrome")
    
    assert isinstance(thread, threading.Thread)
    assert thread.daemon is False
    # Give the thread a moment to start
    thread.join(timeout=1.0)
    mock_monitor.assert_called_once_with("chrome")


@mock.patch("macdefaultbrowsy.dialog_automation.time.sleep")
@mock.patch("macdefaultbrowsy.dialog_automation._run_osascript")
@mock.patch("macdefaultbrowsy.dialog_automation.logger")
def test_monitor_and_click_no_match(mock_logger, mock_run_osascript, mock_sleep):
    """Test dialog monitoring when no matching button is found."""
    mock_run_osascript.return_value = "No-match"
    
    dialog_automation._monitor_and_click("chrome")
    
    # Should try 20 times
    assert mock_run_osascript.call_count == 20
    mock_logger.warning.assert_called_once_with(
        "Failed to auto-confirm the default-browser dialog."
    )


import subprocess  # Import for the test to work