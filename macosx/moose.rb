class Moose < Formula
  desc "Multiscale Object Oriented Simulation Environment"
  homepage "http://moose.ncbs.res.in"
  url "https://github.com/BhallaLab/moose-core/archive/3.1.1.tar.gz"
  version "3.1.1"
  sha256 "55cd1defa8815db605b3c3ee8f0eb1f683b1155f0725346d4ae21fd8b5269d33"

  option "with-gui", "Enable GUI"
  option "with-moogli", "Enable moogli 3d visualizer"

  depends_on "cmake" => :build
  depends_on "numpy" => :build

  depends_on "gsl"
  depends_on "hdf5"
  depends_on "libsbml" => "with-python"

  depends_on "python" if MacOS.version <= :snow_leopard

  if build.with?("moogli")
    depends_on "openscenegraph"
    resource "moogli" do
      url "https://github.com/BhallaLab/moogli/archive/0.5.1.tar.gz"
      sha256 "8a0cc0652d3c468d8d88ed77bc0b05233f62613e3e0509f4ab4c0e8bd53c39c7"
    end
  end

  if build.with?("gui")
    depends_on "pyqt"
    depends_on "homebrew/python/matplotlib"

    resource "gui" do
      url "https://github.com/BhallaLab/moose-gui/archive/3.1.1.tar.gz"
      sha256 "43e0b65b9482bbdc21a59573a93d40e237adea073a442c38bf7b8767a5c1aec8"
    end

    resource "examples" do
      url "https://github.com/BhallaLab/moose-examples/archive/3.1.1.tar.gz"
      sha256 "eb36d0b71e43be943b1fcf4d830e2c98ee52643d254af5989923901441d765bb"
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

    $ pip install networkx pygraphviz
    EOS
  end

  test do
    system "python", "-c", "import moose"
  end
end
