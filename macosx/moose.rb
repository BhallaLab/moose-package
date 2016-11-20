class Moose < Formula
  desc "Multiscale Object Oriented Simulation Environment"
  homepage "http://moose.ncbs.res.in"
  url "https://github.com/BhallaLab/moose-core/archive/master.tar.gz"
  version "3.1.1"
  # sha256 "e43d2609425e17e7426955ade60b6b81a699bbe1173ad6af10f09be43fd533eb"

  option "with-gui", "Enable gui support"
  option "with-sbml", "Enable sbml support"
  option "with-moogli", "Enable moogli 3d visualizer"

  depends_on "cmake" => :build
  depends_on "numpy" => :build

  depends_on "gsl"
  depends_on "hdf5"
  depends_on "libsbml" => "with-python"

  depends_on "python" if MacOS.version <= :snow_leopard

  if build.with?("moogli")
    depends_on "openscenegraph"
  end

  if build.with?("gui")
    depends_on "pyqt"
    depends_on "homebrew/python/matplotlib"

    resource "gui" do
      url "https://github.com/BhallaLab/moose-gui/archive/master.tar.gz"
      # sha256 "d54cfd70759fba0b2f67d5aedfb76967f646e40ff305f7ace8631d3aeabc6459"
    end

    resource "examples" do
      url "https://github.com/BhallaLab/moose-examples/archive/master.tar.gz"
      # sha256 "09c83f6cdc0bab1a6c2eddb919edb33e3809272db3642ea284f6a102b144861d"
    end
  end

  def install
    args = std_cmake_args
    args << "-DCMAKE_SKIP_RPATH=ON"
    mkdir "_build" do
      system "cmake", "..", *args
      system "make"
      system "ctest", "--output-on-failure"
    end

    Dir.chdir("python") do
      system "python", *Language::Python.setup_install_args(prefix)
    end

    if build.with?("gui")
      libexec.install resource("gui")
      doc.install resource("examples")

      # A wrapper script to launch moose gui.
      (bin/"moosegui").write <<-EOS.undent
        #!/bin/bash
        BASEDIR="#{libexec}"
        (cd $BASEDIR && python mgui.py)
      EOS
      chmod 0755, bin/"moosegui"
    end
  end

  def caveats; <<-EOS.undent
    You need to install `networkx` and 'pygraphviz' using python-pip. Open terminal
    and execute following command:

    $ pip install networkx
    EOS
  end

  test do
    system "python", "-c", "import moose"
  end
end
