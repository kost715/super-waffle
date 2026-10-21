// Keep the native license catalog/API, but manage PMC establishment in its app.
(() => {
  const lic = window.lic;
  if (!lic || lic.ALSPMC_phoneOnly) return;
  const nativeSet = lic.set;
  lic.set = function (state) {
    return nativeSet.call(this, {...state, list: state.list.filter(row => row[0] !== "alspmc_pmc")});
  };
  lic.ALSPMC_phoneOnly = true;
})();
