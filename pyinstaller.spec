# -*- mode: python ; coding: utf-8 -*-
# this_file: pyinstaller.spec

import os
import sys
from pathlib import Path

# Get the source directory
src_dir = Path(__file__).parent / "src"
main_script = src_dir / "macdefaultbrowsy" / "__main__.py"

block_cipher = None

a = Analysis(
    [str(main_script)],
    pathex=[str(src_dir)],
    binaries=[],
    datas=[],
    hiddenimports=[
        'macdefaultbrowsy',
        'macdefaultbrowsy.macdefaultbrowsy', 
        'macdefaultbrowsy.launch_services',
        'macdefaultbrowsy.dialog_automation',
        'LaunchServices',
        'loguru',
        'fire',
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name='macdefaultbrowsy',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=True,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)