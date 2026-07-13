_: _final: prev: {
  pythonPackagesExtensions =
    prev.pythonPackagesExtensions
    ++ [
      (_python-final: python-prev: {
        patool = python-prev.patool.overridePythonAttrs (_oldAttrs: {
          doCheck = false;
        });
      })
    ];
}
