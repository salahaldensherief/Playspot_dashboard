{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();

    // Remove splash screen before running the app
    const splash = document.getElementById('splash');
    if (splash) {
      splash.remove();
    }

    await appRunner.runApp();
  }
});
