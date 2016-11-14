class Moose < Formula
  desc "Multiscale Object Oriented Simulation Environment"
  homepage "http://moose.ncbs.res.in"
  url "https://github.com/BhallaLab/moose-core/archive/master.tar.gz"
  version "3.0.2"
  #sha256 "e43d2609425e17e7426955ade60b6b81a699bbe1173ad6af10f09be43fd533eb"

  option "with-gui", "Enable gui support"
  option "with-sbml", "Enable sbml support"

  depends_on "cmake" => :build
  depends_on "numpy" => :build
  depends_on "gsl"
  depends_on "hdf5"

  depends_on "python" if MacOS.version <= :snow_leopard

  if build.with?("gui") 
    depends_on "pyqt"
    if OS.mac? && MacOS.version <= :mountain_lion
      depends_on "homebrew/python/matplotlib"
    else
      depends_on "matplotlib" => :python
    end

    resource "gui" do
      url "https://github.com/BhallaLab/moose-gui/archive/master.tar.gz"
      #sha256 "d54cfd70759fba0b2f67d5aedfb76967f646e40ff305f7ace8631d3aeabc6459"
    end

    resource "examples" do
      url "https://github.com/BhallaLab/moose-examples/archive/master.tar.gz"
      #sha256 "09c83f6cdc0bab1a6c2eddb919edb33e3809272db3642ea284f6a102b144861d"
    end
  end

  if build.with?("sbml")
    resource "sbml" do
      url "https://downloads.sourceforge.net/project/sbml/libsbml/5.9.0/stable/libSBML-5.9.0-core-src.tar.gz"
      sha256 "8991e4a6876721999433495b747b790af7981ae57b485e6c92b7fbb105bd7e96"
    end
  end

  def install
    args = std_cmake_args
    if build.with?("sbml")
      resource("sbml").stage {
        mkdir "_build" do
          sbml_args = std_cmake_args
          sbml_args << "-DCMAKE_INSTALL_PREFIX=#{buildpath}/_libsbml_static"
          system "cmake", "..", *sbml_args
          system "make", "install"
        end
      }
      ENV["SBML_STATIC_HOME"] = "#{buildpath}/_libsbml_static"
    end

    args << "-DCMAKE_SKIP_RPATH=ON"
    mkdir "_build" do
      system "cmake", "..", *args
      system "make"
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
    You need to install `networkx` and `suds-jurko` using python-pip. Open terminal
    and execute following command:
    
    $ pip install suds-jurko networkx
    EOS
  end

  test do
    system "python", "-c", "import moose"
  end
end
