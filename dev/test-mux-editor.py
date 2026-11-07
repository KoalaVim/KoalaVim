"""Exercise real Herdr split/popup proxy editors against an isolated server."""
import json
import os
import pathlib
import shutil
import subprocess
import tempfile
import time

repo = pathlib.Path.cwd()
nvim = os.environ.get('SIDEKICK_NVIM') or shutil.which('nvim')
herdr = os.environ.get('HERDR_BIN_PATH') or shutil.which('herdr')
assert nvim and herdr, 'Provide nvim (SIDEKICK_NVIM) and herdr (HERDR_BIN_PATH)'
original_split = os.environ.get('KOALA_TEST_SPLIT', 'right')
assert original_split in ('right', 'down')


def wait_for(check, timeout=10):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if check():
            return
        time.sleep(.03)
    raise AssertionError('Timed out waiting for the editor lifecycle')


with tempfile.TemporaryDirectory(prefix='kv-mux-', dir='/tmp') as directory:
    root = pathlib.Path(directory)
    config = root / 'herdr.toml'
    config.write_text('onboarding = false\n[terminal]\ndefault_shell = "/bin/sh"\n'
                      '[update]\nversion_check = false\nmanifest_check = false\n')
    env = dict(os.environ, HERDR_CONFIG_PATH=str(config), HERDR_SOCKET_PATH=str(root / 'herdr.sock'),
               XDG_CONFIG_HOME=str(root / 'config'), XDG_DATA_HOME=str(root / 'data'),
               XDG_STATE_HOME=str(root / 'state'), XDG_CACHE_HOME=str(root / 'cache'),
               NVIM_APPNAME='koala-mux-test',
               PATH=str(pathlib.Path(herdr).parent) + os.pathsep + os.environ['PATH'])
    for key in ('HERDR_ENV', 'HERDR_PANE_ID', 'NVIM'):
        env.pop(key, None)
    log = open(root / 'herdr.log', 'w+')
    server = subprocess.Popen([herdr, 'server'], env=env, stdout=log, stderr=log)
    host = None

    def cli(*args):
        output = subprocess.check_output([herdr, *args], env=env, text=True, timeout=10)
        data = json.loads(output) if output.strip() else {"result": {}}
        assert 'error' not in data, data
        return data['result']

    try:
        wait_for(lambda: (root / 'herdr.sock').exists())
        workspace = cli('workspace', 'create', '--cwd', str(root), '--focus')
        host_pane = workspace['root_pane']['pane_id']
        agent = cli('pane', 'split', '--pane', host_pane, '--direction', original_split, '--focus')['pane']['pane_id']
        cli('pane', 'report-agent', agent, '--source', 'koala-test', '--agent', 'claude', '--state', 'idle')
        marker = root / 'child-finished'
        child_config = root / 'config/koala-mux-test/init.lua'
        child_config.parent.mkdir(parents=True)
        child_config.write_text('''assert(vim.g.koala_mux_editor)
assert(vim.env.NVIM == nil and vim.env.KOALA_MODE == nil and vim.env.KOALA_RESTART == nil)
-- Simulate slow plugin shutdown: applying the prompt must bypass this wait.
vim.api.nvim_create_autocmd('VimLeavePre', {callback = function() vim.wait(2500) end})
vim.defer_fn(function()
  assert(vim.bo.filetype == 'sidekick_koala_prompt')
  vim.api.nvim_buf_set_lines(0, 0, -1, false, {'edited in Herdr'})
  vim.fn.writefile({tostring(vim.fn.getpid())}, ''' + repr(str(marker)) + ''')
  vim.cmd.quit()
end, 500)
''')
        host_init = root / 'host.lua'
        host_init.write_text('vim.opt.rtp:prepend(' + repr(str(repo)) + ')\n' +
                             'vim.opt.rtp:prepend(' + repr(str(repo.parent / 'sidekick.nvim')) + ')\n' + '''
local defaults = vim.json.decode(table.concat(vim.fn.readfile(vim.api.nvim_get_runtime_file('default_kvim.conf', false)[1]), '\\n'))
package.loaded['KoalaVim'] = {conf = defaults}
local general = require('KoalaVim.utils.ai.general')
for i = 1, 100 do
  local name = debug.getupvalue(general.open_editor_file, i)
  if not name then break end
  if name == 'setup_prompt_split' then
    debug.setupvalue(general.open_editor_file, i, function(buf, win)
      vim.defer_fn(function()
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, {'edited in host'})
        vim.api.nvim_win_close(win, true)
      end, 500)
    end)
    break
  end
end
''')
        host_env = dict(env, HERDR_PANE_ID=host_pane, HERDR_ENV='1', KOALA_MODE='ai', KOALA_RESTART='1')
        socket = str(root / 'nvim.sock')
        host = subprocess.Popen([nvim, '--headless', '-u', str(host_init), '--listen', socket],
                                env=host_env, stdout=log, stderr=log)
        wait_for(lambda: pathlib.Path(socket).exists())
        for layout, was_zoomed in (('pane-right', True), ('pane-down', False),
                                   ('floating', True), ('floating', False)):
            if marker.exists():
                marker.unlink()
            expression = "luaeval(\"(function() require('KoalaVim').conf.ai.mux.editor = '" + layout + "'; return true end)()\")"
            subprocess.run([nvim, '--server', socket, '--remote-expr', expression], check=True,
                           capture_output=True, timeout=10)
            cli('pane', 'zoom', agent, '--on' if was_zoomed else '--off')
            cli('pane', 'resize', '--pane', host_pane, '--direction', original_split, '--amount', '0.07')
            before = cli('pane', 'layout', '--pane', agent)['layout']
            prompt = root / (layout + " ' prompt.txt")
            prompt.write_text('original')
            proxy_env = dict(env, NVIM=socket, SIDEKICK_NVIM=nvim, HERDR_PANE_ID=agent)
            proxy = subprocess.Popen([str(repo / 'bin/sidekick-editor-proxy-gedit'), str(prompt)], env=proxy_env)
            try:
                def host_is_small():
                    current = cli('pane', 'layout', '--pane', host_pane)['layout']
                    pane = next(p for p in current['panes'] if p['pane_id'] == host_pane)
                    dimension = 'width' if original_split == 'right' else 'height'
                    return pane['rect'][dimension] <= current['area'][dimension] * .12
                wait_for(host_is_small)
                assert proxy.wait(timeout=15) == 0
                release_delay = time.time() - marker.stat().st_mtime
                assert release_delay < 1.5, ('Agent waited for editor shutdown', release_delay)
            finally:
                if proxy.poll() is None:
                    proxy.kill()
                    proxy.wait()

            assert prompt.read_text() == 'edited in Herdr\n', layout
            assert int(marker.read_text()) != host.pid
            def layout_restored():
                after = cli('pane', 'layout', '--pane', agent)['layout']
                return (len(after['panes']) == 2 and after['zoomed'] == was_zoomed
                        and after['focused_pane_id'] == agent
                        and len(after['splits']) == len(before['splits'])
                        and all(old['id'] == restored['id'] and abs(old['ratio'] - restored['ratio']) < .00001
                                for old, restored in zip(before['splits'], after['splits'])))
            wait_for(layout_restored)
            close_delay = time.time() - marker.stat().st_mtime
            assert close_delay < 1.5, ('Pane close waited for editor shutdown', close_delay)
            cli('pane', 'swap', '--source-pane', host_pane, '--target-pane', agent)
            assert host.poll() is None
            print(f'{layout}: agent released in {release_delay:.3f}s; pane closed and layout restored in {close_delay:.3f}s')
        # Disabling the option keeps the in-host editor. If Herdr rejects an
        # enabled editor (the linked plugin was removed), fall back there too.
        cli('plugin', 'unlink', 'koalavim-editor')
        for setting in ('false', "'floating'"):
            expression = "luaeval(\"(function() require('KoalaVim').conf.ai.mux.editor = " + setting + "; return true end)()\")"
            subprocess.run([nvim, '--server', socket, '--remote-expr', expression], check=True,
                           capture_output=True, timeout=10)
            prompt = root / ('host-' + setting.replace("'", '') + '.txt')
            prompt.write_text('original')
            before = cli('pane', 'layout', '--pane', agent)['layout']
            subprocess.run([str(repo / 'bin/sidekick-editor-proxy-gedit'), str(prompt)],
                           env=proxy_env, check=True, timeout=15)
            assert prompt.read_text() == 'edited in host\n'
            after = cli('pane', 'layout', '--pane', agent)['layout']
            for old, restored in zip(before['splits'], after['splits']):
                assert old['id'] == restored['id'] and abs(old['ratio'] - restored['ratio']) < .00001
            assert host.poll() is None
            print(setting + ': host editor completed successfully')
    except Exception:
        log.flush()
        print((root / 'herdr.log').read_text())
        try:
            panes = cli('pane', 'list')
            print(panes)
            for pane in panes.get('panes', []):
                print(subprocess.check_output([herdr, 'pane', 'read', pane['pane_id'], '--source', 'recent', '--lines', '30'], env=env, text=True))
        except Exception as error:
            print(error)
        raise
    finally:
        if host:
            host.terminate()
            host.communicate(timeout=5)
        server.terminate()
        server.wait(timeout=10)
        log.close()
