import os, pathlib, shutil, subprocess, tempfile, time
nvim = os.environ.get('SIDEKICK_NVIM') or shutil.which('nvim')
assert nvim, 'Set SIDEKICK_NVIM or add nvim to PATH'
proxy = str(pathlib.Path('bin/sidekick-editor-proxy-gedit').resolve())
with tempfile.TemporaryDirectory(prefix='proxy-test-') as d:
    root = pathlib.Path(d)
    socket = str(root / 'nvim.sock')
    target = root / "prompt with 'quotes.txt"
    target.write_text('original')
    init = root / 'init.lua'
    sidekick = str(pathlib.Path('../sidekick.nvim').resolve())
    init.write_text('vim.opt.rtp:prepend(' + repr(sidekick) + ')\n' + '''package.preload['KoalaVim.utils.ai.general'] = function()
      return { open_editor_file = function(file, pipe, pane)
        assert(pane == 'test-pane')
        vim.schedule(function()
          vim.fn.writefile({'edited'}, file)
          vim.system({'sh', '-c', 'echo done > ' .. vim.fn.shellescape(pipe)})
        end)
        return ''
      end }
    end
    ''')
    host_env = dict(os.environ, XDG_CACHE_HOME=str(root / 'cache'), HERDR_SOCKET_PATH=str(root / 'herdr.sock'))
    server = subprocess.Popen([nvim, '--headless', '-u', str(init), '--listen', socket], stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, env=host_env)
    try:
        for _ in range(100):
            if pathlib.Path(socket).exists(): break
            time.sleep(.02)
        env = dict(os.environ, NVIM=socket, SIDEKICK_NVIM=nvim, HERDR_PANE_ID='test-pane', PATH='/usr/bin:/bin')
        subprocess.run([proxy, str(target)], env=env, check=True, timeout=10)
        assert target.read_text() == 'edited\n'
        # Publish through the actual backend, then reuse the agent's stale environment.
        subprocess.run([nvim, '--server', socket, '--remote-expr',
                        "luaeval(\"require('sidekick.cli.session.herdr').publish_editor_host({herdr_pane_id='test-pane'})\")"],
                       check=True, capture_output=True, timeout=10)
        env.update(XDG_CACHE_HOME=host_env['XDG_CACHE_HOME'], HERDR_SOCKET_PATH=host_env['HERDR_SOCKET_PATH'],
                   NVIM=str(root / 'dead-host.sock'), SIDEKICK_NVIM='/missing/old/nvim')
        target.write_text('before reattach')
        subprocess.run([proxy, str(target)], env=env, check=True, timeout=10)
        assert target.read_text() == 'edited\n'
        print('Proxy RPC, FIFO completion and reattachment with stale socket/executable passed')
    finally:
        server.terminate()
        server.communicate(timeout=5)
