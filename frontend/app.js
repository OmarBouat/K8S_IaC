(function renderBuildInfo() {
  var buildMeta = window.__BUILD_META__ || {};
  var commit = buildMeta.commit || "local-dev";
  var time = buildMeta.time || new Date().toISOString();

  var commitEl = document.getElementById("build-commit");
  var timeEl = document.getElementById("build-time");

  if (commitEl) commitEl.textContent = "Commit: " + commit;
  if (timeEl) timeEl.textContent = "Built: " + time;
})();
