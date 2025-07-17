# this_file: tests/test_launch_services.py

from unittest import mock
import pytest
from macdefaultbrowsy import launch_services


@mock.patch("macdefaultbrowsy.launch_services.LSCopyAllHandlersForURLScheme")
def test_get_all_handlers_for_scheme(mock_ls_copy_all):
    """Test getting all handlers for a URL scheme."""
    mock_ls_copy_all.return_value = ["com.apple.Safari", "com.google.Chrome"]
    
    handlers = launch_services.get_all_handlers_for_scheme("http")
    
    assert handlers == ["com.apple.Safari", "com.google.Chrome"]
    mock_ls_copy_all.assert_called_once_with("http")


@mock.patch("macdefaultbrowsy.launch_services.LSCopyDefaultHandlerForURLScheme")
def test_get_current_handler_for_scheme(mock_ls_copy_default):
    """Test getting the current default handler for a URL scheme."""
    mock_ls_copy_default.return_value = "com.apple.Safari"
    
    handler = launch_services.get_current_handler_for_scheme("http")
    
    assert handler == "com.apple.Safari"
    mock_ls_copy_default.assert_called_once_with("http")


@mock.patch("macdefaultbrowsy.launch_services.LSSetDefaultHandlerForURLScheme")
def test_set_default_handler_for_scheme_success(mock_ls_set_default):
    """Test successfully setting default handler."""
    mock_ls_set_default.return_value = 0  # Success
    
    result = launch_services.set_default_handler_for_scheme("com.apple.Safari", "http")
    
    assert result is True
    mock_ls_set_default.assert_called_once_with("http", "com.apple.Safari")


@mock.patch("macdefaultbrowsy.launch_services.LSSetDefaultHandlerForURLScheme")
def test_set_default_handler_for_scheme_dialog_success(mock_ls_set_default):
    """Test setting default handler with confirmation dialog."""
    mock_ls_set_default.return_value = -10810  # kLSUnknownErr - dialog shown
    
    result = launch_services.set_default_handler_for_scheme("com.apple.Safari", "http")
    
    assert result is True
    mock_ls_set_default.assert_called_once_with("http", "com.apple.Safari")


@mock.patch("macdefaultbrowsy.launch_services.LSSetDefaultHandlerForURLScheme")
def test_set_default_handler_for_scheme_failure(mock_ls_set_default):
    """Test failure when setting default handler."""
    mock_ls_set_default.return_value = -42  # Some other error
    
    result = launch_services.set_default_handler_for_scheme("com.apple.Safari", "http")
    
    assert result is False
    mock_ls_set_default.assert_called_once_with("http", "com.apple.Safari")