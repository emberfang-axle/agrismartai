{{flutter_js}}
{{flutter_build_config}}

(function () {
  var booted = false;

  function hideLoader() {
    var loader = document.getElementById('loader');
    if (!loader || loader.classList.contains('hidden')) return;
    loader.classList.add('hidden');
    setTimeout(function () { loader.remove(); }, 400);
  }

  function showBootError(msg) {
    hideLoader();
    var el = document.getElementById('boot-error');
    if (el) {
      el.textContent = msg;
      el.style.display = 'flex';
    }
  }

  function setLoaderSub(text) {
    var el = document.querySelector('.loader-sub');
    if (el) el.textContent = text;
  }

  function onFirstFrame() {
    booted = true;
    hideLoader();
  }

  window.addEventListener('flutter-first-frame', onFirstFrame);
  document.addEventListener('flutter-first-frame', onFirstFrame);

  setTimeout(function () {
    if (!booted) setLoaderSub('Still loading... please keep this tab open.');
  }, 20000);
  setTimeout(function () {
    if (!booted) setLoaderSub('Almost ready...');
  }, 60000);

  _flutter.loader.load({
    onEntrypointLoaded: async function (engineInitializer) {
      try {
        var appRunner = await engineInitializer.initializeEngine();
        await appRunner.runApp();
      } catch (err) {
        showBootError(
          'Could not start admin dashboard. Close this tab, run .\\scripts\\start-dev.ps1, then reopen http://localhost:8080'
        );
        console.error(err);
      }
    }
  });
})();
