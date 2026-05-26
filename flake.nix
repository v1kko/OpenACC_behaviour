{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

  outputs = { self, nixpkgs, ... }:
    let
      pkgs = import nixpkgs { system = "x86_64-linux"; config.allowUnfree = true; };
      pythonpkgs = pkgs.python313Packages;
    in
    let
      mypython = pkgs.python313;
    in with pkgs; {
      devShell.x86_64-linux =
        mkShell { buildInputs = [
          pythonpkgs.mkdocs
          pythonpkgs.mkdocs-material
          gfortran
          openmpi
          gh
        ];
        pythonWithPkgs = mypython.withPackages (pythonPkgs: with pythonPkgs; [
          # This list contains tools for Python development.
          # You can also add other tools, like black.
          #
          # Note that even if you add Python packages here like PyTorch or Tensorflow,
          # they will be reinstalled when running `pip -r requirements.txt` because
          # virtualenv is used below in the shellHook.
          pip
          setuptools
          virtualenvwrapper
          wheel
        ]);
        shellHook = ''
          # fixes libstdc++ issues and libgl.so issues
          export LD_LIBRARY_PATH=''${LD_LIBRARY_PATH}:${stdenv.cc.cc.lib}/lib/
          MUSCLE_TEST_PYTHON_ONLY=1
          # Allow the use of wheels.
          SOURCE_DATE_EPOCH=$(date +%s)

          NIX_ENFORCE_NO_NATIVE=0

          # Augment the dynamic linker path
          # Setup the virtual environment if it doesn't already exist.
          VENV=.venv
          if test ! -d $VENV; then
            python -m venv $VENV
          fi

          export PYTHONPATH=`pwd`/$VENV/${mypython.sitePackages}/:$PYTHONPATH
          source ./$VENV/bin/activate
          if test -f "source_me.sh"; then
            source source_me.sh
          fi
          '';
      };
   };
}
