class Moose < Formula
  desc "Multiscale Object Oriented Simulation Environment"
  homepage "http://moose.ncbs.res.in"
  url "https://github.com/BhallaLab/moose-core/archive/3.1.1-beta.1.tar.gz"
  version "3.1.1-beta.1"
  sha256 "47a87460db41b4ef9d3f633097358d01c2de5850323d6c561f1231a9c42539a4"

  option "with-examples", "Install examples and snippets"

  depends_on "cmake" => :build
  depends_on "numpy" => :build

  depends_on "gsl"
  depends_on "hdf5"
  depends_on "libsbml" => "with-python"

  depends_on "python" if MacOS.version <= :snow_leopard

  if build.with?("examples")
    resource "examples" do
      url "https://github.com/BhallaLab/moose-examples/archive/3.1.1.tar.gz"
      sha256 "eb36d0b71e43be943b1fcf4d830e2c98ee52643d254af5989923901441d765bb"
    end
  end

  def install
    args = std_cmake_args
    args << "-DCMAKE_SKIP_RPATH=ON" << "-D_VERSION_MOOSE=3.1.1-beta.1"
    mkdir "_build" do
      system "cmake", '..', *args
      system "make"
      system "ctest", "--output-on-failure"
    end

    Dir.chdir("_build/python") do
      system "python", *Language::Python.setup_install_args(prefix)
    end

    if build.with?("examples")
      doc.install resource("examples")
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
