# this_file: tests/test_cli.py

from unittest import mock
import pytest
from macdefaultbrowsy import __main__


@mock.patch("macdefaultbrowsy.__main__.macdefaultbrowsy.set_default_browser")
def test_cli_with_browser_id(mock_set_default):
    """Test CLI with browser ID argument."""
    mock_set_default.return_value = True
    
    __main__.cli("chrome")
    
    mock_set_default.assert_called_once_with("chrome")


@mock.patch("macdefaultbrowsy.__main__.macdefaultbrowsy.print_browsers_list")
def test_cli_without_browser_id(mock_print_browsers):
    """Test CLI without browser ID argument - should list browsers."""
    __main__.cli()
    
    mock_print_browsers.assert_called_once()


@mock.patch("macdefaultbrowsy.__main__.macdefaultbrowsy.print_browsers_list")
def test_cli_with_none_browser_id(mock_print_browsers):
    """Test CLI with None browser ID - should list browsers."""
    __main__.cli(None)
    
    mock_print_browsers.assert_called_once()


@mock.patch("macdefaultbrowsy.__main__.fire.Fire")
def test_main_entry_point(mock_fire):
    """Test that main entry point calls Fire with cli function."""
    # Mock sys.modules to simulate running as __main__
    with mock.patch.object(__main__, '__name__', '__main__'):
        exec(open('/root/repo/src/macdefaultbrowsy/__main__.py').read())
    
    mock_fire.assert_called_once_with(__main__.cli)