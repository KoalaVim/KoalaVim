"""Run from the repository root with SIDEKICK_NVIM set, or nvim on PATH."""
import os
import pathlib
import re
import shutil
import subprocess
import tempfile
import time

nvim = os.environ.get('SIDEKICK_NVIM') or shutil.which('nvim')
assert nvim, 'Set SIDEKICK_NVIM or add nvim to PATH'
repo = pathlib.Path.cwd()
with tempfile.TemporaryDirectory(prefix='sidekick-minimize-') as directory:
    root = pathlib.Path(directory)
    socket = str(root / 'nvim.sock')
    herdr_socket = str(root / 'herdr.sock')
    events = root / 'events'
    forwarded = root / 'forwarded'
    fake_herdr = root / 'herdr'
    fake_herdr.write_text('#!/bin/sh\nprintf "%s\\n" "$@" > "$TEST_FORWARDED"\n')
    fake_herdr.chmod(0o755)
    init = root / 'init.lua'
    init.write_text('vim.opt.rtp:prepend(' + repr(str(repo)) + ')\n' + '''
local function record(value)
  vim.fn.writefile({value}, vim.env.TEST_EVENTS, 'a')
end
package.loaded['sidekick.cli.state'] = { get = function()
  return {{session = {backend = 'herdr', herdr_token = 'owned', herdr_pane_id = 'agent'}}}
end }
package.loaded['sidekick.util'] = {exec = function(cmd)
  record(table.concat(cmd, ' '))
  return true
end}
require('KoalaVim.utils.ai.general')
''')
    env = dict(os.environ, HERDR_SOCKET_PATH=herdr_socket, HERDR_PANE_ID='editor',
               XDG_CACHE_HOME=str(root / 'cache'), TEST_EVENTS=str(events),
               TEST_FORWARDED=str(forwarded), HERDR_BIN_PATH=str(fake_herdr))
    host_dir = root / 'cache/sidekick/editor-hosts' / re.sub(r'[^a-zA-Z0-9_.-]', '_', herdr_socket)
    host_dir.mkdir(parents=True)
    for pane in ('agent', 'unowned'):
        (host_dir / pane).write_text(socket + '\n' + nvim + '\n')
    (host_dir / 'stale').write_text(str(root / 'dead.sock') + '\n' + nvim + '\n')
    server = subprocess.Popen([nvim, '--headless', '-u', str(init), '--listen', socket], env=env,
                              stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
    try:
        for _ in range(100):
            if pathlib.Path(socket).exists():
                break
            time.sleep(.02)
        for pane in ('agent', 'unowned', 'stale', 'shell'):
            key_env = dict(env, HERDR_ACTIVE_PANE_ID=pane)
            subprocess.run([str(repo / 'bin/sidekick-herdr-minimize')], env=key_env, check=True, timeout=10)
            if pane == 'agent':
                assert events.read_text().splitlines() == ['herdr pane zoom editor --on']
                assert not forwarded.exists()
            else:
                assert forwarded.read_text().splitlines() == ['pane', 'send-keys', pane, 'alt+a']
        print('Alt+a hides the attached owned pane by zooming Neovim; other and stale panes receive Alt+a unchanged')
    finally:
        server.terminate()
        server.communicate(timeout=5)
